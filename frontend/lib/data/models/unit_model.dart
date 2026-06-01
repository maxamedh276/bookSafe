class Unit {
  final int id;
  final String name;
  final String shortName;

  Unit({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      shortName: (json['short_name'] ?? json['shortName'] ?? '').toString(),
    );
  }

  String get displayLabel => '$name ($shortName)';
}
