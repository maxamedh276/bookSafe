class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double debtBalance;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.debtBalance,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? 'No Name').toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      debtBalance: double.tryParse(json['debt_balance']?.toString() ?? '0') ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
