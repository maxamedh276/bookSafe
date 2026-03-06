import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/models/tenant_model.dart';
import 'package:intl/intl.dart';

class TenantsListView extends ConsumerWidget {
  const TenantsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Maamulka Ganacsiyada (Tenants)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dhamaan Ganacsiyada Diwaangashan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: tenantsAsync.when(
                data: (tenants) => _buildTenantsTable(context, ref, tenants),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantsTable(BuildContext context, WidgetRef ref, List<Tenant> tenants) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Ganacsiga')),
            DataColumn(label: Text('Mulkiilaha')),
            DataColumn(label: Text('Plan')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Expiry')),
            DataColumn(label: Text('Actions')),
          ],
          rows: tenants.map((tenant) {
            final businessName = tenant.businessName ?? 'N/A';
            final ownerName = tenant.ownerName ?? 'N/A';
            final status = tenant.status ?? 'pending';
            final plan = tenant.subscriptionPlan ?? 'basic';

            return DataRow(cells: [
              DataCell(Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(ownerName)),
              DataCell(_buildPlanBadge(plan)),
              DataCell(_buildStatusBadge(status)),
              DataCell(Text(tenant.expiryDate != null 
                ? DateFormat('dd/MM/yyyy').format(tenant.expiryDate!) 
                : '-')),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => _showUpdateStatusDialog(context, ref, tenant),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                    tooltip: 'View as Tenant',
                    onPressed: () async {
                      await ref.read(adminProvider.notifier).impersonate(tenant.id, ref);
                      if (context.mounted) {
                        context.go('/');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hadda waxaad u muuqataa sidii $businessName')),
                        );
                      }
                    },
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'blocked':
      case 'suspended':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPlanBadge(String plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        plan.toUpperCase(),
        style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context, WidgetRef ref, Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => UpdateStatusDialog(tenant: tenant),
    ).then((value) {
      if (value == true) {
        ref.invalidate(tenantsProvider);
      }
    });
  }
}

class UpdateStatusDialog extends ConsumerStatefulWidget {
  final Tenant tenant;
  const UpdateStatusDialog({super.key, required this.tenant});

  @override
  ConsumerState<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends ConsumerState<UpdateStatusDialog> {
  late String _status;
  late int _branchLimit;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _status = widget.tenant.status;
    _branchLimit = widget.tenant.branchLimit;
    _expiryDate = widget.tenant.expiryDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update ${widget.tenant.businessName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ['pending', 'active', 'suspended', 'blocked'].map((s) {
              return DropdownMenuItem(value: s, child: Text(s.toUpperCase()));
            }).toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _branchLimit.toString(),
            decoration: const InputDecoration(labelText: 'Branch Limit'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _branchLimit = int.tryParse(v) ?? _branchLimit,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Expiry Date'),
            subtitle: Text(_expiryDate == null 
              ? 'Madihin' 
              : DateFormat('dd/MM/yyyy').format(_expiryDate!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) setState(() => _expiryDate = date);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: () async {
            await ref.read(adminProvider.notifier).updateTenantStatus(
              widget.tenant.id,
              _status,
              expiryDate: _expiryDate,
              branchLimit: _branchLimit,
            );
            if (mounted) Navigator.pop(context, true);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
