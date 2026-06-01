import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/sale_model.dart';
import '../models/customer_model.dart';
import 'package:flutter/foundation.dart';

class TodaySummary {
  final double totalSales;
  final double totalDebt;
  final int totalCustomers;
  final int lowStockCount;

  const TodaySummary({
    required this.totalSales,
    required this.totalDebt,
    this.totalCustomers = 0,
    this.lowStockCount = 0,
  });
}

/// Summary for "today" (sales + debt) used in dashboard cards
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    // Default to today for summary cards
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final response = await api.get(
      '/reports/sales',
      queryParameters: {
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final totalSales = double.tryParse(data['total_sales']?.toString() ?? '0') ?? 0;
    final totalDebt = double.tryParse(data['total_debt']?.toString() ?? '0') ?? 0;
    final totalCustomers = int.tryParse(data['total_customers']?.toString() ?? '0') ?? 0;
    final lowStockCount = int.tryParse(data['low_stock_count']?.toString() ?? '0') ?? 0;

    return TodaySummary(
      totalSales: totalSales,
      totalDebt: totalDebt,
      totalCustomers: totalCustomers,
      lowStockCount: lowStockCount,
    );
  } catch (e) {
    if (kDebugMode) {
      print('❗️ todaySummaryProvider error: $e – returning empty summary');
    }
    return const TodaySummary(totalSales: 0, totalDebt: 0);
  }
});

/// Recent sales for dashboard (limited to latest 5)

/// Recent sales for dashboard (limited to latest 5)
final recentSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/sales');
    final List<dynamic> data = response.data;
    final allSales = data.map((item) => Sale.fromJson(item)).toList();
    allSales.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allSales.take(5).toList();
  } catch (e) {
    if (kDebugMode) {
      print('❗️ recentSalesProvider error: $e – returning empty list');
    }
    return <Sale>[];
  }
});

/// Top debtors (latest debts) for dashboard
/// Top debtors (latest debts) for dashboard
final topDebtorsProvider = FutureProvider<List<Customer>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    // Use reports endpoint that already returns top debtors
    final response = await api.get('/reports/debtors');
    final List<dynamic> data = response.data;
    return data.map((item) => Customer.fromJson(item)).toList();
  } catch (e) {
    if (kDebugMode) {
      print('❗️ topDebtorsProvider error: $e – returning empty list');
    }
    return <Customer>[];
  }
});

