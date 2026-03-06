class Tenant {
  final int id;
  final String businessName;
  final String ownerName;
  final String email;
  final String? phone;
  final String? address;
  final String subscriptionPlan;
  final String status;
  final int branchLimit;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    this.phone,
    this.address,
    required this.subscriptionPlan,
    required this.status,
    required this.branchLimit,
    this.expiryDate,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    try {
      return Tenant(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        businessName: (json['business_name'] ?? json['businessName'] ?? 'No Name').toString(),
        ownerName: (json['owner_name'] ?? json['ownerName'] ?? 'No Owner').toString(),
        email: (json['email'] ?? '').toString(),
        phone: json['phone']?.toString(),
        address: json['address']?.toString(),
        subscriptionPlan: (json['subscription_plan'] ?? json['subscriptionPlan'] ?? 'basic').toString(),
        status: (json['status'] ?? 'pending').toString(),
        branchLimit: json['branch_limit'] is int ? json['branch_limit'] : int.tryParse(json['branch_limit']?.toString() ?? '1') ?? 1,
        expiryDate: json['expiry_date'] != null 
            ? DateTime.tryParse(json['expiry_date'].toString()) 
            : (json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null),
        createdAt: json['created_at'] != null 
            ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
            : (json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) : DateTime.now()),
      );
    } catch (e) {
      // Fallback for extremely corrupted data
      return Tenant(
        id: 0,
        businessName: 'Error Loading',
        ownerName: '',
        email: '',
        subscriptionPlan: 'basic',
        status: 'pending',
        branchLimit: 1,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'owner_name': ownerName,
      'email': email,
      'phone': phone,
      'address': address,
      'subscription_plan': subscriptionPlan,
      'status': status,
      'branch_limit': branchLimit,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
