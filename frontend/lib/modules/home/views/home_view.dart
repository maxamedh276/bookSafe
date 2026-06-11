import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../data/providers/dashboard_provider.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final recentSalesAsync = ref.watch(recentSalesProvider);
    final topDebtorsAsync = ref.watch(topDebtorsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todaySummaryProvider);
        ref.invalidate(recentSalesProvider);
        ref.invalidate(topDebtorsProvider);
        // Wait for them to complete for the spinner to disappear nicely
        await Future.wait([
          ref.read(todaySummaryProvider.future),
          ref.read(recentSalesProvider.future),
          ref.read(topDebtorsProvider.future),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Important for pull-to-refresh
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ModernPageHeader(
              title: 'Dashboard',
              subtitle: 'Guud ahaan xaaladda ganacsigaaga ee maanta.',
            ),
            const SizedBox(height: 20),
          
          // Summary Cards (Today)
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              if (isDesktop) {
                return todaySummaryAsync.when(
                  data: (summary) => Row(
                    children: [
                      _buildSummaryCard(
                        context,
                        title: 'Iibka Maanta',
                        value: '\$${summary.totalSales.toStringAsFixed(2)}',
                        icon: Icons.shopping_cart_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        context,
                        title: 'Deynta Maanta',
                        value: '\$${summary.totalDebt.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        context,
                        title: 'Macaamiisha',
                        value: '${summary.totalCustomers}',
                        icon: Icons.people_outline,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        context,
                        title: 'Stock Hooseeya',
                        value: '${summary.lowStockCount}',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  loading: () => Row(
                    children: List.generate(4, (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 3 ? 16 : 0),
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )),
                  ),
                  error: (e, _) => Center(child: Text('Summary Error: $e')),
                );
              } else {
                return todaySummaryAsync.when(
                  data: (summary) => Column(
                    children: [
                      Row(
                        children: [
                          _buildSummaryCard(
                            context,
                            title: 'Iibka Maanta',
                            value: '\$${summary.totalSales.toStringAsFixed(2)}',
                            icon: Icons.shopping_cart_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            context,
                            title: 'Deynta Maanta',
                            value: '\$${summary.totalDebt.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSummaryCard(
                            context,
                            title: 'Macaamiisha',
                            value: '${summary.totalCustomers}',
                            icon: Icons.people_outline,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 16),
                          _buildSummaryCard(
                            context,
                            title: 'Stock Hooseeya',
                            value: '${summary.lowStockCount}',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error: $e'),
                );
              }
            },
          ),
          
          const SizedBox(height: 40),
          
          // Recent Activity
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildSection(
                        context,
                        title: 'Iibabkii u dambeeyay',
                        child: recentSalesAsync.when(
                          data: (sales) {
                            if (sales.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Center(child: Text('Ma jiraan iibab weli.')),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sales.length,
                              separatorBuilder: (_, __) => const Divider(height: 16),
                              itemBuilder: (context, index) {
                                final sale = sales[index];
                                final customerName =
                                    sale.customer?.name ?? 'Macmiil la diiwaan gelin';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${sale.invoiceNumber} • ${sale.paymentStatus == 'paid' ? 'Kash' : 'Deyn'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${sale.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (sale.debtAmount > 0)
                                        Text(
                                          'Deyn: \$${sale.debtAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.error,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, s) => Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(child: Text('Error: $e')),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildSection(
                        context,
                        title: 'Deymihii u dambeeyay',
                        child: topDebtorsAsync.when(
                          data: (debtors) {
                            if (debtors.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Center(child: Text('Ma jiraan deymo.')),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: debtors.length.clamp(0, 5),
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final c = debtors[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    c.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    c.phone ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    '\$${c.debtBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, s) => Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(child: Text('Error: $e')),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      title: 'Iibabkii u dambeeyay',
                      child: recentSalesAsync.when(
                        data: (sales) {
                          if (sales.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(child: Text('Ma jiraan iibab weli.')),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sales.length,
                            separatorBuilder: (_, __) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final sale = sales[index];
                              final customerName =
                                  sale.customer?.name ?? 'Macmiil la diiwaan gelin';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  customerName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${sale.invoiceNumber} • ${sale.paymentStatus == 'paid' ? 'Kash' : 'Deyn'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${sale.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (sale.debtAmount > 0)
                                      Text(
                                        'Deyn: \$${sale.debtAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.error,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, s) => Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(child: Text('Error: $e')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: 'Deymihii u dambeeyay',
                      child: topDebtorsAsync.when(
                        data: (debtors) {
                          if (debtors.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(child: Text('Ma jiraan deymo.')),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: debtors.length.clamp(0, 5),
                            separatorBuilder: (_, __) => const Divider(height: 12),
                            itemBuilder: (context, index) {
                              final c = debtors[index];
                              final hasDebt = c.debtBalance > 0;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  c.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  c.phone ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '\$${c.debtBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: hasDebt ? FontWeight.bold : FontWeight.normal,
                                    color: hasDebt ? AppColors.error : AppColors.textBody,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, s) => Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(child: Text('Error: $e')),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: ModernStatCard(title: title, value: value, icon: icon, color: color),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    return ModernSection(title: title, child: child);
  }
}
