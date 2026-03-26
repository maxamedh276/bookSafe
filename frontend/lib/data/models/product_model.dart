class Product {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final int stock;
  final String? category;

  final int? unitId;
  final String? unitName;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    required this.stock,
    this.category,
    this.unitId,
    this.unitName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? 'No Name').toString(),
      sku: json['sku']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: json['stock'] is int ? json['stock'] : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      category: json['category']?.toString(),
      unitId: json['unit_id'] is int ? json['unit_id'] : int.tryParse(json['unit_id']?.toString() ?? ''),
      unitName: json['unit'] != null ? json['unit']['short_name'] ?? json['unit']['name'] : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
