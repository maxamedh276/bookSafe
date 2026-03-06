class Product {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final int stock;
  final String? category;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    required this.stock,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? 'No Name').toString(),
      sku: json['sku']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: json['stock'] is int ? json['stock'] : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
