import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_service.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _topProducts = [];
  List<dynamic> _dailySales = [];
  List<dynamic> _topDebtors = [];

  // Date filter
  DateTime? _startDate;
  DateTime? _endDate;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Default: last 30 days
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final dateParams = _startDate != null && _endDate != null
          ? '?startDate=${_startDate!.toIso8601String()}&endDate=${_endDate!.toIso8601String()}'
          : '';

      final results = await Future.wait([
        apiService.get('/reports/sales$dateParams'),
        apiService.get('/reports/top-products'),
        apiService.get('/reports/daily-sales'),
        apiService.get('/reports/debtors'),
      ]);

      setState(() {
        _summary = results[0].data;
        _topProducts = results[1].data is List ? results[1].data : [];
        _dailySales = results[2].data is List ? results[2].data : [];
        _topDebtors = results[3].data is List ? results[3].data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      String message = 'Error: $e';
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          message = 'Doorkaagu (IT Admin) ma u oggolaado arkaynta warbixinada ganacsi gaar ah. Samee "Impersonate" si aad u aragto.';
        } else {
          message = e.response?.data?['message'] ?? message;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  void _exportCSV() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final dateParams = _startDate != null
          ? '?startDate=${_startDate!.toIso8601String()}&endDate=${_endDate!.toIso8601String()}'
          : '';

      // For web: trigger download via a browser URL approach
      // The API returns CSV directly — show info for now
      await apiService.get('/reports/export-csv$dateParams');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV export waa ku guulaysatay! Hubi Downloads folder-kaaga.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNarrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warbixinada & Analytics',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickDateRange,
                                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                                label: Text(
                                  _startDate != null
                                      ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                                      : '30 Maalmood',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _exportCSV,
                                icon: const Icon(Icons.download_outlined, size: 16),
                                label: const Text('CSV', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  side: const BorderSide(color: AppColors.success),
                                ),
                              ),
                              IconButton(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh, color: AppColors.textLight),
                                tooltip: 'Cusboonee',
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Warbixinada & Analytics',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Row(
                            children: [
                              // Date range picker
                              OutlinedButton.icon(
                                onPressed: _pickDateRange,
                                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                                label: Text(
                                  _startDate != null
                                      ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                                      : '30 Maalmood',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Export CSV button
                              OutlinedButton.icon(
                                onPressed: _exportCSV,
                                icon: const Icon(Icons.download_outlined, size: 16),
                                label: const Text('CSV', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  side: const BorderSide(color: AppColors.success),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Refresh
                              IconButton(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh, color: AppColors.textLight),
                                tooltip: 'Cusboonee',
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textLight,
                      indicatorColor: AppColors.primary,
                      isScrollable: isNarrow,
                      tabs: const [
                        Tab(text: 'Guudmar', icon: Icon(Icons.bar_chart_outlined, size: 18)),
                        Tab(text: 'Alaabta', icon: Icon(Icons.inventory_2_outlined, size: 18)),
                        Tab(text: 'Deynta', icon: Icon(Icons.account_balance_wallet_outlined, size: 18)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildTopProductsTab(),
                      _buildDebtorsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  // TAB 1: Summary + Bar chart
  // ───────────────────────────────────────────
  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards
          // Stat Cards - Responsive Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 650;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isSmall ? 2 : 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isSmall ? 1.2 : 0.9,
                children: [
                  _buildStatCard('Wadarta Iibka', '\$${(_summary?['total_sales'] ?? 0).toStringAsFixed(2)}',
                      Icons.trending_up_rounded, AppColors.primary),
                  _buildStatCard('La Bixiyey', '\$${(_summary?['total_paid'] ?? 0).toStringAsFixed(2)}',
                      Icons.check_circle_outline_rounded, AppColors.success),
                  _buildStatCard('Deynta', '\$${(_summary?['total_debt'] ?? 0).toStringAsFixed(2)}',
                      Icons.warning_amber_rounded, AppColors.error),
                  _buildStatCard('Iib №', '${_summary?['sales_count'] ?? 0}',
                      Icons.receipt_long_outlined, const Color(0xFF7C3AED)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Bar Chart Title
          Text('Iibka Maalinlaha ah (30 Maalmood)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Simple bar chart using CustomPainter
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _dailySales.isEmpty
                ? const Center(child: Text('Xog iib ah ma jirto wali.', style: TextStyle(color: AppColors.textLight)))
                : CustomPaint(
                    painter: _BarChartPainter(_dailySales),
                    size: Size.infinite,
                  ),
          ),
        ],
      ),
    ),
  );
}

  // ───────────────────────────────────────────
  // TAB 2: Top Products table
  // ───────────────────────────────────────────
  Widget _buildTopProductsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: _topProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('Ma jiraan xog weli.', style: TextStyle(color: AppColors.textLight))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.secondary.withValues(alpha: 0.05)),
                    columns: const [
                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Alaabta', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tirada La Iibiyey', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Dakhliga', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _topProducts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('${i + 1}', style: const TextStyle(color: AppColors.textLight))),
                          DataCell(Text(p['Product']?['name'] ?? 'N/A')),
                          DataCell(Text('${p['total_quantity'] ?? 0}')),
                          DataCell(Text('\$${double.tryParse(p['total_revenue']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'}')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────
  // TAB 3: Top Debtors table
  // ───────────────────────────────────────────
  Widget _buildDebtorsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: _topDebtors.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('Waxba deynta lama joogo — waad ku hambalyaysaa!', style: TextStyle(color: AppColors.success))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.error.withValues(alpha: 0.05)),
                    columns: const [
                      DataColumn(label: Text('Magaca', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Telefoon', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Deynta', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _topDebtors.map((d) {
                      return DataRow(
                        cells: [
                          DataCell(Text(d['name'] ?? 'N/A')),
                          DataCell(Text(d['phone'] ?? '')),
                          DataCell(
                            Text(
                              '\$${double.tryParse(d['debt_balance']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0'}',
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────
// Custom Bar Chart Painter for Daily Sales
// ───────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<dynamic> data;
  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.fold<double>(0.0, (max, d) {
      final v = double.tryParse(d['total_sales']?.toString() ?? '0') ?? 0;
      return v > max ? v : max;
    });
    if (maxVal == 0) return;

    final barPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final paidPaint = Paint()
      ..color = AppColors.success.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '\$${(maxVal * i / 4).toStringAsFixed(0)}',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 12));
    }

    final barGroupWidth = size.width / data.length;
    const barPadding = 3.0;
    final barWidth = (barGroupWidth - barPadding * 2) / 2;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final xStart = i * barGroupWidth + barPadding;
      final totalSales = double.tryParse(d['total_sales']?.toString() ?? '0') ?? 0;
      final totalPaid = double.tryParse(d['total_paid']?.toString() ?? '0') ?? 0;

      // Total bar
      final totalBarHeight = (totalSales / maxVal) * (size.height - 20);
      final totalRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(xStart, size.height - totalBarHeight, barWidth, totalBarHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(totalRect, barPaint);

      // Paid bar
      final paidBarHeight = (totalPaid / maxVal) * (size.height - 20);
      final paidRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(xStart + barWidth + 1, size.height - paidBarHeight, barWidth, paidBarHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(paidRect, paidPaint);

      // Date label for every 5th bar
      if (i % 5 == 0 && d['date'] != null) {
        final dateStr = d['date'].toString().substring(5); // MM-DD
        final tp = TextPainter(
          text: TextSpan(text: dateStr, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 8)),
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(xStart, size.height + 2));
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) => oldDelegate.data != data;
}
