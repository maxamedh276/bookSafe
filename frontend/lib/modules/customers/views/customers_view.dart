import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/api_service.dart';

class CustomersView extends ConsumerStatefulWidget {
  const CustomersView({super.key});

  @override
  ConsumerState<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends ConsumerState<CustomersView> {
  String searchQuery = '';

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCustomerDialog(),
    ).then((value) {
      if (value == true) {
        ref.invalidate(customersProvider);
      }
    });
  }

  Future<void> _showEditCustomerDialog(Customer customer) async {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final emailController = TextEditingController(text: customer.email ?? '');
    final addressController = TextEditingController(text: customer.address ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.put('/customers/${customer.id}', data: {
          'name': nameController.text,
          'phone': phoneController.text,
          'email': emailController.text,
          'address': addressController.text,
        });
        ref.invalidate(customersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Ma hubtaa inaad tirtirayso "${customer.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ka noqo'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.delete('/customers/${customer.id}');
        ref.invalidate(customersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileScreen = width < 800;

    final customersAsync = ref.watch(customersProvider);

    // ───────────── MOBILE LAYOUT (simple list) ─────────────
    if (isMobileScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Macaamiisha',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Maamul macluumaadka macaamiishaada.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                    IconButton(
                      onPressed: _showAddCustomerDialog,
                      icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                      tooltip: 'Macmiil Cusub',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Search Field for Mobile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Magac ama Taleefan ku dhex raadi...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: customersAsync.when(
                  data: (customers) {
                    final filtered = customers.where((c) =>
                        c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (c.phone?.contains(searchQuery) ?? false)).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(searchQuery.isEmpty ? 'Macaamiil lama diiwaan gelin.' : 'Ma jiro macmiil ku habboon raadinta.'),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        final hasDebt = customer.debtBalance > 0;
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${customer.phone ?? '-'} • ${customer.email ?? '-'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showEditCustomerDialog(customer);
                              } else if (value == 'delete') {
                                await _deleteCustomer(customer);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${customer.debtBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: hasDebt ? AppColors.error : AppColors.textBody,
                                    fontWeight: hasDebt ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const Icon(Icons.more_vert, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ───────────── DESKTOP / TABLET LAYOUT (original table) ─────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Macaamiisha (Customers)',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('Maamul macluumaadka macaamiishaada.'),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Macmiil Cusub'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Customers list/table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: customersAsync.when(
                  data: (customers) {
                    final filtered = customers.where((c) =>
                        c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (c.phone?.contains(searchQuery) ?? false)).toList();

                    if (isMobileScreen) {
                      if (customers.isEmpty) {
                        return const Center(
                          child: Text('Macaamiil lama diiwaan gelin weli.'),
                        );
                      }
                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('Ma jiro macmiil ku habboon raadinta.'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          final hasDebt = customer.debtBalance > 0;
                          return ListTile(
                            title: Text(customer.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${customer.phone ?? '-'} • ${customer.email ?? '-'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '\$${customer.debtBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: hasDebt ? AppColors.error : AppColors.textBody,
                                fontWeight: hasDebt ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // Desktop/tablet: DataTable
                    return SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.all(AppColors.background),
                        columns: const [
                          DataColumn(
                              label:
                                  Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label:
                                  Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label:
                                  Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Debt Balance',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label:
                                  Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((customer) {
                          return DataRow(
                            cells: [
                              DataCell(Text(customer.name)),
                              DataCell(Text(customer.phone ?? '-')),
                              DataCell(Text(customer.email ?? '-')),
                              DataCell(
                                Text(
                                  '\$${customer.debtBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: customer.debtBalance > 0
                                        ? AppColors.error
                                        : AppColors.textBody,
                                    fontWeight: customer.debtBalance > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showEditCustomerDialog(customer)),
                                  IconButton(
                                      icon: const Icon(Icons.history),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Purchase history coming soon in detailed view!'))
                                        );
                                      },
                                      tooltip: 'Purchase History'),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCustomerDialog extends ConsumerStatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  ConsumerState<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.post('/customers', data: {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'address': _addressController.text,
        });
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Macmiilka waa lagu daray!'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kudar Macmiil Cusub'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Magaca Macmiilka'),
                validator: (v) => v!.isEmpty ? 'Gali magaca' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Lambarka Taleefanka'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (Optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Cinwaanka'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Keydi'),
        ),
      ],
    );
  }
}
