import 'product_model.dart';

class SaleItem {
  final int id;
  final int productId;
  final double quantity;
  final double price;
  final double subtotal;
  final Product? product;

  SaleItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.product,
  });

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

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final productRaw = json['Product'] ?? json['product'];
    Product? product;
    if (productRaw is Map<String, dynamic>) {
      product = Product.fromJson(productRaw);
    } else if (productRaw is Map) {
      product = Product.fromJson(Map<String, dynamic>.from(productRaw));
    }

    return SaleItem(
      id: _readInt(json['id']),
      productId: _readInt(json['product_id'] ?? json['productId']),
      quantity: _readDouble(json['quantity']),
      price: _readDouble(json['price']),
      subtotal: _readDouble(json['subtotal']),
      product: product,
    );
  }

  String get productName => product?.name ?? 'Alaab #${productId}';
}
