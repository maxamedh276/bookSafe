import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/sale_detail_sheet.dart';
import '../../../data/providers/customer_provider.dart';
import '../../../data/providers/customer_detail_provider.dart';
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
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            const ModernPageHeader(
              title: 'Maamulka Lacagaha',
              subtitle: 'Deyn, lacag bixin, iyo iibyada la bixiyey.',
            ),
            const ModernTabBar(
              tabs: [
                Tab(text: 'Deyn (Debtors)', icon: Icon(Icons.money_off, size: 20)),
                Tab(text: 'La Bixiyey (Paid Sales)', icon: Icon(Icons.check_circle_outline, size: 20)),
              ],
            ),
            ModernSearchField(
              hint: 'Ku raadi magac, taleefan ama invoice...',
              onChanged: (v) => setState(() => searchQuery = v),
              showClear: searchQuery.isNotEmpty,
              onClear: () => setState(() => searchQuery = ''),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: debtors.length,
            itemBuilder: (context, index) {
              final customer = debtors[index];
              return ModernListTileCard(
                leading: CircleAvatar(
                  backgroundColor: AppColors.error.withValues(alpha: 0.12),
                  child: const Icon(Icons.person_rounded, color: AppColors.error),
                ),
                title: Text(customer.name),
                subtitle: Text(customer.phone ?? 'Taleefan ma jiro'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${customer.debtBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 17, color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    const Text('Deyn taagan', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
                onTap: () => _showCustomerDebtDetail(customer, openPayment: true),
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
        final q = searchQuery.toLowerCase();
        final paidSales = sales.where((s) {
          final matchesSearch = q.isEmpty ||
              (s.customer?.name.toLowerCase().contains(q) ?? false) ||
              s.invoiceNumber.toLowerCase().contains(q);
          return s.hasAnyPayment && matchesSearch;
        }).toList();

        if (paidSales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  searchQuery.isEmpty
                      ? 'Ma jiraan iibyo lacag laga bixiyey (qeyb ama dhammaan).'
                      : 'Ma jiro iib lacag laga bixiyey oo raadinta ku habboon.',
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: paidSales.length,
            itemBuilder: (context, index) {
              final sale = paidSales[index];
              final statusColor = sale.isFullyPaid ? AppColors.success : AppColors.warning;
              final statusLabel = sale.isFullyPaid ? 'Dhammaan' : 'Qeyb la bixiyey';
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showSaleDetailSheet(context, sale),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.1),
                          child: Icon(Icons.receipt_long, color: statusColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sale.invoiceNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sale.customer?.name ?? 'Macaamiil aan la magacaabin',
                                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'La bixiyey: \$${sale.paidAmount.toStringAsFixed(2)}'
                                '${sale.debtAmount > 0 ? ' · Ka dhiman: \$${sale.debtAmount.toStringAsFixed(2)}' : ''}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(sale.createdAt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${sale.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 17,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  void _showCustomerDebtDetail(Customer customer, {bool openPayment = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDebtDetailBoard(
        customer: customer,
        openPaymentOnStart: openPayment,
      ),
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
  final bool openPaymentOnStart;

  const CustomerDebtDetailBoard({
    super.key,
    required this.customer,
    this.openPaymentOnStart = false,
  });

  @override
  ConsumerState<CustomerDebtDetailBoard> createState() => _CustomerDebtDetailBoardState();
}

class _CustomerDebtDetailBoardState extends ConsumerState<CustomerDebtDetailBoard> {
  @override
  void initState() {
    super.initState();
    if (widget.openPaymentOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRecordPaymentDialog(context);
      });
    }
  }

  Sale? _saleFromList(List<Sale> sales, Map<String, dynamic> item) {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id != null) {
      for (final s in sales) {
        if (s.id == id) return s;
      }
    }
    final inv = item['invoice_number']?.toString();
    if (inv != null && inv.isNotEmpty) {
      for (final s in sales) {
        if (s.invoiceNumber == inv) return s;
      }
    }
    return null;
  }

  void _openSaleDetail(Map<String, dynamic> item) {
    final salesAsync = ref.read(salesProvider);
    salesAsync.whenData((sales) {
      final sale = _saleFromList(sales, item);
      if (sale != null && mounted) {
        showSaleDetailSheet(context, sale);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faahfaahinta iibka lama helin.')),
        );
      }
    });
  }

  void _openPaymentDetail(Map<String, dynamic> item) {
    final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
    final method = item['payment_method']?.toString() ?? 'cash';
    final dateStr = item['payment_date']?.toString() ?? item['created_at']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faahfaahinta Lacag Bixinta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            _PaymentDetailRow(label: 'Cadadka', value: '\$${amount.toStringAsFixed(2)}'),
            _PaymentDetailRow(label: 'Habka', value: _paymentMethodLabel(method)),
            _PaymentDetailRow(
              label: 'Taariikhda',
              value: DateFormat('dd/MM/yyyy HH:mm').format(date),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static String _paymentMethodLabel(String method) {
    switch (method) {
      case 'mobile_money':
        return 'EVC / Zaad / Sahal';
      case 'bank':
        return 'Bank Transfer';
      default:
        return 'Kaash (Cash)';
    }
  }

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
                    final total = double.tryParse(item['total_amount']?.toString() ?? '0') ?? 0.0;
                    final paid = double.tryParse(item['paid_amount']?.toString() ?? '0') ?? 0.0;
                    final debt = double.tryParse(item['debt_amount']?.toString() ?? '0') ?? 0.0;
                    final payAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                    final dateStr = item['created_at']?.toString() ?? item['payment_date']?.toString() ?? '';
                    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: (isSale ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                          child: Icon(
                            isSale ? Icons.shopping_bag_outlined : Icons.payments_outlined,
                            color: isSale ? AppColors.error : AppColors.success,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          isSale ? 'Iibsi: ${item['invoice_number'] ?? '-'}' : 'Lacag Bixin',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(date),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isSale)
                              Text(
                                'Warta: \$${total.toStringAsFixed(2)} · La bixiyey: \$${paid.toStringAsFixed(2)} · Ka dhiman: \$${debt.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isSale ? "" : "-"}\$${(isSale ? total : payAmount).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSale ? AppColors.textHeading : AppColors.success,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
                          ],
                        ),
                        onTap: () {
                          final map = Map<String, dynamic>.from(item as Map);
                          if (isSale) {
                            _openSaleDetail(map);
                          } else {
                            _openPaymentDetail(map);
                          }
                        },
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
      if (value == true && mounted) {
        Navigator.pop(context, true);
      }
    });
  }
}

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final Customer customer;
  final int? saleId;

  const RecordPaymentDialog({super.key, required this.customer, this.saleId});

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _fillFullDebt() {
    _amountController.text = widget.customer.debtBalance.toStringAsFixed(2);
  }

  void _submit() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.post('/payments', data: {
        'customer_id': widget.customer.id,
        if (widget.saleId != null) 'sale_id': widget.saleId,
        'amount': double.parse(_amountController.text),
        'payment_method': _paymentMethod,
      });
      
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lacagta waa laga qabtay macmiilka!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          maxWidth: 420,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lacag Bixin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeading,
                            ),
                          ),
                          Text(
                            widget.customer.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.textLight),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Deynta hadda taagan',
                          style: TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                      ),
                      Text(
                        '\$${widget.customer.debtBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cadadka lacagta',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHeading),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                if (widget.customer.debtBalance > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _fillFullDebt,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Bixi deynta oo dhan'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Habka lacag bixinta',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHeading),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PaymentMethodChip(
                      label: 'Kaash',
                      icon: Icons.money,
                      selected: _paymentMethod == 'cash',
                      onSelected: () => setState(() => _paymentMethod = 'cash'),
                    ),
                    _PaymentMethodChip(
                      label: 'EVC / Zaad',
                      icon: Icons.phone_android,
                      selected: _paymentMethod == 'mobile_money',
                      onSelected: () => setState(() => _paymentMethod = 'mobile_money'),
                    ),
                    _PaymentMethodChip(
                      label: 'Bank',
                      icon: Icons.account_balance,
                      selected: _paymentMethod == 'bank',
                      onSelected: () => setState(() => _paymentMethod = 'bank'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Jooji'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Keydi Lacagta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
