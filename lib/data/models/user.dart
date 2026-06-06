class User {
  int? id;
  String? name;

  User({
    this.id,
    this.name,
  });

  static User? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return User(
      id: json["id"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
    };
  }

  @override
  String toString() => toMap().toString();
}
