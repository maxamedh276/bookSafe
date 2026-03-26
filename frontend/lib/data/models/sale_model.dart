import 'customer_model.dart';

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
  final Customer? customer;

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
    this.customer,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      customerId: json['customer_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      paidAmount: double.parse(json['paid_amount'].toString()),
      debtAmount: double.parse(json['debt_amount'].toString()),
      discount: json['discount'] != null ? double.parse(json['discount'].toString()) : 0.0,
      description: json['description'],
      paymentStatus: json['payment_status'],
      invoiceNumber: json['invoice_number'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      customer: json['Customer'] != null ? Customer.fromJson(json['Customer']) : null,
    );
  }
}
