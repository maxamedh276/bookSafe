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
      id: json['id'],
      name: json['name'],
      shortName: json['short_name'],
    );
  }
}
