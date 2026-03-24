import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/providers/sale_provider.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/services/api_service.dart';
import 'package:intl/intl.dart';

class DebtsView extends ConsumerStatefulWidget {
  const DebtsView({super.key});

  @override
  ConsumerState<DebtsView> createState() => _DebtsViewState();
}

class _DebtsViewState extends ConsumerState<DebtsView> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Maamulka Lacagaha (Debt & Paid)',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Deyn (Debtors)', icon: Icon(Icons.money_off)),
              Tab(text: 'La Bixiyey (Paid Sales)', icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Bar - Premium Design
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Ku raadi magac, taleefan ama invoice...',
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
            
            Expanded(
              child: TabBarView(
                children: [
                  _buildDebtorsTab(),
                  _buildPaidSalesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtorsTab() {
    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      data: (customers) {
        final debtors = customers.where((c) => 
          c.debtBalance > 0 &&
          (c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (c.phone?.contains(searchQuery) ?? false))
        ).toList();

        if (debtors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.money_off_csred_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  searchQuery.isEmpty ? 'Macaamiil deyn lagu leeyahay ma jiraan.' : 'Ma jiro macmiil deyn qaba oo raadinta ku habboon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(customersProvider);
            await ref.read(customersProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: debtors.length,
            itemBuilder: (context, index) {
              final customer = debtors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppColors.error),
                  ),
                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(customer.phone ?? 'No Phone'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${customer.debtBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                      const Text('Deyn Taagan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => _showCustomerDebtDetail(customer),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPaidSalesTab() {
    final salesAsync = ref.watch(salesProvider);

    return salesAsync.when(
      data: (sales) {
        final paidSales = sales.where((s) => 
          s.paymentStatus == 'paid' &&
          (s.customer?.name.toLowerCase().contains(searchQuery.toLowerCase()) ?? false ||
          s.invoiceNumber.toLowerCase().contains(searchQuery.toLowerCase()))
        ).toList();

        if (paidSales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  searchQuery.isEmpty ? 'Ma jiraan iibyo lacagtooda la bixiyey.' : 'Ma jiro iib lacagtiisa la bixiyey oo raadinta ku habboon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(salesProvider);
            await ref.read(salesProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: paidSales.length,
            itemBuilder: (context, index) {
              final sale = paidSales[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    child: const Icon(Icons.receipt_long, color: AppColors.success),
                  ),
                  title: Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(sale.customer?.name ?? 'Macaamiil aan la magacaabin'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${sale.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                      Text(DateFormat('dd/MM/yyyy').format(sale.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showCustomerDebtDetail(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDebtDetailBoard(customer: customer),
    ).then((value) {
      if (value == true) {
        ref.invalidate(customersProvider);
        ref.invalidate(salesProvider);
      }
    });
  }
}

class CustomerDebtDetailBoard extends ConsumerStatefulWidget {
  final Customer customer;
  const CustomerDebtDetailBoard({super.key, required this.customer});

  @override
  ConsumerState<CustomerDebtDetailBoard> createState() => _CustomerDebtDetailBoardState();
}

class _CustomerDebtDetailBoardState extends ConsumerState<CustomerDebtDetailBoard> {
  
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(customerHistoryProvider(widget.customer.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(widget.customer.phone ?? '', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${widget.customer.debtBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordPaymentDialog(context),
                  icon: const Icon(Icons.add_card),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text('Taariikhda Deynta (History)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Expanded(
            child: historyAsync.when(
              data: (data) {
                // Safely handle potential nulls and types
                final List salesList = data['sales'] ?? [];
                final List paymentsList = data['payments'] ?? [];
                
                // Merge and sort by date
                final List combined = [...salesList, ...paymentsList];
                combined.sort((a, b) {
                  final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
                  final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
                  return dateB.compareTo(dateA);
                });

                if (combined.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('History ma jiro.', style: TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: combined.length,
                  itemBuilder: (context, index) {
                    final item = combined[index];
                    final isSale = item.containsKey('invoice_number');
                    final amount = double.tryParse(item[isSale ? 'debt_amount' : 'amount']?.toString() ?? '0') ?? 0.0;
                    final dateStr = item['created_at']?.toString() ?? '';
                    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: (isSale ? AppColors.error : AppColors.success).withOpacity(0.1),
                        child: Icon(
                          isSale ? Icons.shopping_bag_outlined : Icons.payments_outlined,
                          color: isSale ? AppColors.error : AppColors.success,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        isSale ? 'Iibsi (Inv: ${item['invoice_number'] ?? '-'})' : 'Lacag Bixin',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(date),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${isSale ? "+" : "-"}\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSale ? AppColors.error : AppColors.success,
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
    );
  }

  void _showRecordPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(customer: widget.customer),
    ).then((value) {
      if (value == true) {
        Navigator.pop(context, true);
      }
    });
  }
}

final customerHistoryProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/customers/$id/history');
  return response.data;
});

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;
  const RecordPaymentDialog({super.key, required this.customer});

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  void _submit() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/payments', data: {
        'customer_id': widget.customer.id,
        'amount': double.parse(_amountController.text),
        'payment_method': _paymentMethod,
      });
      
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lacagta waa laga qabtay macmiilka!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ka qabo lacag: ${widget.customer.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deynta guud: \$${widget.customer.debtBalance.toStringAsFixed(2)}', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cadadka lacagta (Amount)',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Habka lacag bixinta'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Kaash (Cash)')),
              DropdownMenuItem(value: 'mobile_money', child: Text('EVC / Zaad / Sahal')),
              DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Jooji')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading ? const CircularProgressIndicator() : const Text('Keydi Lacagta'),
        ),
      ],
    );
  }
}
