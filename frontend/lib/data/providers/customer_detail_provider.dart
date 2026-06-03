import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../models/sale_model.dart';
import '../services/api_service.dart';

/// Date-only keys (yyyy-MM-dd) for reliable provider cache keys and API params.
class CustomerSalesFilter {
  final int customerId;
  final String startDate;
  final String endDate;

  const CustomerSalesFilter({
    required this.customerId,
    required this.startDate,
    required this.endDate,
  });

  DateTime get startDateTime {
    final p = startDate.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  DateTime get endDateTime {
    final p = endDate.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), 23, 59, 59);
  }

  @override
  bool operator ==(Object other) =>
      other is CustomerSalesFilter &&
      other.customerId == customerId &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(customerId, startDate, endDate);
}

String dateToKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

CustomerSalesFilter filterForMonth(int customerId, DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  return CustomerSalesFilter(
    customerId: customerId,
    startDate: dateToKey(start),
    endDate: dateToKey(end),
  );
}

List<Sale> filterSalesByDateRange(List<Sale> sales, CustomerSalesFilter filter) {
  final startDay = filter.startDateTime;
  final endDay = DateTime(
    filter.endDateTime.year,
    filter.endDateTime.month,
    filter.endDateTime.day,
  );

  return sales.where((sale) {
    final day = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }).toList();
}

CustomerSalesHistory buildHistoryFromSales(List<Sale> sales) {
  return CustomerSalesHistory(
    sales: sales,
    totalSales: sales.length,
    totalAmount: sales.fold(0.0, (s, x) => s + x.totalAmount),
    totalPaid: sales.fold(0.0, (s, x) => s + x.paidAmount),
    totalDebt: sales.fold(0.0, (s, x) => s + x.debtAmount),
  );
}

class CustomerSalesHistory {
  final List<Sale> sales;
  final int totalSales;
  final double totalAmount;
  final double totalPaid;
  final double totalDebt;

  const CustomerSalesHistory({
    required this.sales,
    required this.totalSales,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalDebt,
  });

  factory CustomerSalesHistory.fromJson(Map<String, dynamic> json) {
    final salesRaw = json['sales'];
    final salesList = <Sale>[];
    if (salesRaw is List) {
      for (final item in salesRaw) {
        if (item is Map<String, dynamic>) {
          salesList.add(Sale.fromJson(item));
        } else if (item is Map) {
          salesList.add(Sale.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final summary = json['summary'];
    final summaryMap = summary is Map ? Map<String, dynamic>.from(summary as Map) : <String, dynamic>{};
    return CustomerSalesHistory(
      sales: salesList,
      totalSales: summaryMap.containsKey('totalSales')
          ? _readInt(summaryMap['totalSales'])
          : salesList.length,
      totalAmount: summaryMap.containsKey('totalAmount')
          ? _readDouble(summaryMap['totalAmount'])
          : salesList.fold(0.0, (s, x) => s + x.totalAmount),
      totalPaid: summaryMap.containsKey('totalPaid')
          ? _readDouble(summaryMap['totalPaid'])
          : salesList.fold(0.0, (s, x) => s + x.paidAmount),
      totalDebt: summaryMap.containsKey('totalDebt')
          ? _readDouble(summaryMap['totalDebt'])
          : salesList.fold(0.0, (s, x) => s + x.debtAmount),
    );
  }

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

final customerByIdProvider = FutureProvider.family<Customer, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/customers/$id');
  final data = response.data;
  if (data is! Map) {
    throw Exception('Macmiilka lama helin ama jawaabta server-ka ma saxna.');
  }
  return Customer.fromJson(Map<String, dynamic>.from(data as Map));
});

final customerSalesHistoryProvider =
    FutureProvider.family<CustomerSalesHistory, CustomerSalesFilter>((ref, filter) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get(
      '/customers/${filter.customerId}/history',
      queryParameters: {
        'startDate': filter.startDate,
        'endDate': filter.endDate,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw Exception('Taariikhda iibka lama soo rari karin. Jawaabta server-ka ma saxna.');
    }
    final raw = CustomerSalesHistory.fromJson(Map<String, dynamic>.from(data as Map));
    final filtered = filterSalesByDateRange(raw.sales, filter);
    return buildHistoryFromSales(filtered);
  } catch (e) {
    throw Exception(api.formatUserError(e));
  }
});

/// Legacy history (debts module) — all time, no date filter.
final customerHistoryProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/customers/$id/history');
  return response.data as Map<String, dynamic>;
});
