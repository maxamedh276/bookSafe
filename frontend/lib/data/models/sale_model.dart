import 'customer_model.dart';
import 'sale_item_model.dart';

class Sale {
  final int id;
  final int? customerId;
  final double totalAmount;
  final double paidAmount;
  final double debtAmount;
  final double discount;
  final String? description;
  final String paymentStatus;
  final String invoiceNumber;
  final DateTime createdAt;
  final DateTime saleDate;
  final Customer? customer;
  final List<SaleItem> items;

  Sale({
    required this.id,
    this.customerId,
    required this.totalAmount,
    required this.paidAmount,
    required this.debtAmount,
    this.discount = 0.0,
    this.description,
    required this.paymentStatus,
    required this.invoiceNumber,
    required this.createdAt,
    required this.saleDate,
    this.customer,
    this.items = const [],
  });

  bool get isFullyPaid => debtAmount <= 0;
  bool get isPartiallyPaid => paidAmount > 0 && debtAmount > 0;
  bool get hasAnyPayment => paidAmount > 0;

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

  static DateTime _readDate(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return fallback ?? DateTime.now();
    }
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    final created = _readDate(json['created_at'] ?? json['createdAt']);
    final saleDateRaw = json['sale_date'] ?? json['saleDate'];
    return Sale(
      id: _readInt(json['id']),
      customerId: json['customer_id'] != null ? _readInt(json['customer_id']) : null,
      totalAmount: _readDouble(json['total_amount'] ?? json['totalAmount']),
      paidAmount: _readDouble(json['paid_amount'] ?? json['paidAmount']),
      debtAmount: _readDouble(json['debt_amount'] ?? json['debtAmount']),
      discount: _readDouble(json['discount']),
      description: json['description']?.toString(),
      paymentStatus: (json['payment_status'] ?? json['paymentStatus'] ?? 'paid').toString(),
      invoiceNumber: (json['invoice_number'] ?? json['invoiceNumber'] ?? '').toString(),
      createdAt: created,
      saleDate: saleDateRaw != null ? _readDate(saleDateRaw, fallback: created) : created,
      customer: json['Customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['Customer'] as Map<String, dynamic>)
          : (json['customer'] is Map<String, dynamic>
              ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
              : null),
      items: _parseItems(json['items']),
    );
  }

  static List<SaleItem> _parseItems(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) {
          if (e is Map<String, dynamic>) return SaleItem.fromJson(e);
          if (e is Map) return SaleItem.fromJson(Map<String, dynamic>.from(e));
          return null;
        })
        .whereType<SaleItem>()
        .toList();
  }
}
