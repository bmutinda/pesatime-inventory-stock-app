class User {
  final String id;
  final String name;
  final String email;
  final DateTime? dateCreated;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.dateCreated,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final dateCreatedValue = json['dateCreated'];

    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
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
      'dateCreated': dateCreated?.toIso8601String(),
    };
  }

  @override
  String toString() => toMap().toString();
}
