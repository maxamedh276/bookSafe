import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/sale_model.dart';
import '../../../data/providers/customer_detail_provider.dart';
import '../../../data/services/api_service.dart';

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

DateTime endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

class CustomerDetailView extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailView({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends ConsumerState<CustomerDetailView> {
  late CustomerSalesFilter _filter;
  String _periodLabel = 'Bishan';

  @override
  void initState() {
    super.initState();
    _filter = filterForMonth(widget.customerId, DateTime.now());
  }

  String get _rangeLabel =>
      '${DateFormat('dd/MM/yyyy').format(_filter.startDateTime)} – ${DateFormat('dd/MM/yyyy').format(_filter.endDateTime)}';

  void _applyFilter(CustomerSalesFilter filter, String label) {
    setState(() {
      _filter = filter;
      _periodLabel = label;
    });
  }

  void _setThisMonth() {
    _applyFilter(filterForMonth(widget.customerId, DateTime.now()), 'Bishan');
  }

  void _setLastMonth() {
    final last = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
    _applyFilter(filterForMonth(widget.customerId, last), 'Bishii hore');
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _filter.startDateTime,
        end: DateTime(
          _filter.endDateTime.year,
          _filter.endDateTime.month,
          _filter.endDateTime.day,
        ),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final label =
          '${DateFormat('dd/MM/yy').format(picked.start)} – ${DateFormat('dd/MM/yy').format(picked.end)}';
      _applyFilter(
        CustomerSalesFilter(
          customerId: widget.customerId,
          startDate: dateToKey(picked.start),
          endDate: dateToKey(picked.end),
        ),
        label,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    final salesAsync = ref.watch(customerSalesHistoryProvider(_filter));
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: ref.read(apiServiceProvider).formatUserError(e),
          onBack: () => context.pop(),
        ),
        data: (customer) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerByIdProvider(widget.customerId));
              ref.invalidate(customerSalesHistoryProvider(_filter));
              await ref.read(customerSalesHistoryProvider(_filter).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(56, 16, 20, 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (customer.phone != null && customer.phone!.isNotEmpty)
                                      Text(
                                        customer.phone!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Deyn guud',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    Text(
                                      '\$${customer.debtBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Period filter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Muddada iibka',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Muujinaya: $_rangeLabel',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PeriodChip(
                                label: 'Bishan',
                                selected: _periodLabel == 'Bishan',
                                onTap: _setThisMonth,
                              ),
                              const SizedBox(width: 8),
                              _PeriodChip(
                                label: 'Bishii hore',
                                selected: _periodLabel == 'Bishii hore',
                                onTap: _setLastMonth,
                              ),
                              const SizedBox(width: 8),
                              _PeriodChip(
                                label: _periodLabel.startsWith('Bish') ? 'Dooro taariikh' : _periodLabel,
                                selected: !_periodLabel.startsWith('Bish'),
                                icon: Icons.calendar_month_rounded,
                                onTap: _pickCustomRange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary cards
                SliverToBoxAdapter(
                  child: salesAsync.when(
                    data: (history) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 700 ? 4 : 2;
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: cols == 4 ? 1.6 : 1.45,
                            children: [
                              _StatCard(
                                label: 'Iibyo',
                                value: '${history.totalSales}',
                                icon: Icons.receipt_long_rounded,
                                color: AppColors.info,
                              ),
                              _StatCard(
                                label: 'Warta iibka',
                                value: '\$${history.totalAmount.toStringAsFixed(2)}',
                                icon: Icons.shopping_cart_rounded,
                                color: AppColors.primary,
                              ),
                              _StatCard(
                                label: 'La bixiyey',
                                value: '\$${history.totalPaid.toStringAsFixed(2)}',
                                icon: Icons.payments_rounded,
                                color: AppColors.success,
                              ),
                              _StatCard(
                                label: 'Ka dhiman',
                                value: '\$${history.totalDebt.toStringAsFixed(2)}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: history.totalDebt > 0 ? AppColors.error : AppColors.textLight,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        ref.read(apiServiceProvider).formatUserError(e),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Liiska iibka',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeading,
                          ),
                        ),
                        salesAsync.maybeWhen(
                          data: (h) => Text(
                            '${h.totalSales} iib',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                salesAsync.when(
                  data: (history) {
                    if (history.sales.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Iib ma jiro muddadan.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Muddada: $_rangeLabel',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Isku day taariikh kale ama bishii hore.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sale = history.sales[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SaleCard(sale: sale, dateFmt: dateFmt),
                            );
                          },
                          childCount: history.sales.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          ref.read(apiServiceProvider).formatUserError(e),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 4)],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryDark : AppColors.textBody,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeading,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final DateFormat dateFmt;

  const _SaleCard({required this.sale, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final isCredit = sale.paymentStatus == 'credit' || sale.debtAmount > 0;
    final isFullyPaid = sale.debtAmount <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : 'Iib #${sale.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFmt.format(sale.saleDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isFullyPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFullyPaid ? 'Kash' : (isCredit ? 'Deyn' : sale.paymentStatus),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isFullyPaid ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _AmountBlock(
                    label: 'Warta',
                    amount: sale.totalAmount,
                    color: AppColors.textHeading,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.grey.shade200),
                Expanded(
                  child: _AmountBlock(
                    label: 'La bixiyey',
                    amount: sale.paidAmount,
                    color: AppColors.success,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.grey.shade200),
                Expanded(
                  child: _AmountBlock(
                    label: 'Ka dhiman',
                    amount: sale.debtAmount,
                    color: sale.debtAmount > 0 ? AppColors.error : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountBlock({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorState({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onBack, child: const Text('Dib u noqo')),
        ],
      ),
    );
  }
}
