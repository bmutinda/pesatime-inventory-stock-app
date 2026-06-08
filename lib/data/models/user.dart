class User {
  final String id;
  final String name;
  final String email;
  final String businessName;
  final String unitName;
  final DateTime? dateCreated;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.businessName,
    required this.unitName,
    this.dateCreated,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final business = json['business'];
    final unit = json['unit'];
    final dateCreatedValue = user['dateCreated'];

    return User(
      id: user['_id']?.toString() ?? user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      businessName: json['businessName']?.toString() ??
          json['business_name']?.toString() ??
          (business is Map<String, dynamic>
              ? business['name']?.toString()
              : business?.toString()) ??
          '',
      unitName: json['unitName']?.toString() ??
          json['unit_name']?.toString() ??
          (unit is Map<String, dynamic> ? unit['name']?.toString() : null) ??
          '',
      dateCreated: dateCreatedValue is String
          ? DateTime.tryParse(dateCreatedValue)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'businessName': businessName,
      'unitName': unitName,
      'dateCreated': dateCreated?.toIso8601String(),
    };
  }

  @override
  String toString() => toMap().toString();
}
