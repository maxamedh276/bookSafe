class Product {
  final int id;
  final String name;
  final String? sku;
  final double price;
  final double stock;
  final String? category;

  final int? unitId;
  /// Normalized short code: kg, pcs, thm, ...
  final String? unitName;
  /// Full unit name from API: Kilogram, Piece, ...
  final String? unitFullName;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    required this.stock,
    this.category,
    this.unitId,
    this.unitName,
    this.unitFullName,
  });

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    String? rawShort;
    String? rawName;
    final unitRaw = json['unit'];
    if (unitRaw is Map) {
      rawShort = (unitRaw['short_name'] ?? unitRaw['shortName'])?.toString();
      rawName = unitRaw['name']?.toString();
    }

    final normalized = _normalizeUnit(rawShort ?? rawName);

    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? 'No Name').toString(),
      sku: json['sku']?.toString(),
      price: _readDouble(json['price']),
      stock: _readDouble(json['stock']),
      category: json['category']?.toString(),
      unitId: json['unit_id'] is int ? json['unit_id'] : int.tryParse(json['unit_id']?.toString() ?? ''),
      unitName: normalized,
      unitFullName: rawName,
    );
  }

  static String? _normalizeUnit(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    const aliases = {
      'kilogram': 'kg',
      'kilo': 'kg',
      'gram': 'g',
      'liter': 'l',
      'litre': 'l',
      'litir': 'l',
      'milliliter': 'ml',
      'piece': 'pcs',
      'pieces': 'pcs',
      'handful': 'thm',
      'thumun': 'thm',
      'quarter kilo': 'qkg',
      'dozen': 'dz',
      'bottle': 'btl',
      'carton': 'ctn',
      'bucket': 'bkt',
    };
    if (aliases.containsKey(lower)) return aliases[lower]!;
    return lower;
  }

  bool get hasUnit => unitName != null && unitName!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
