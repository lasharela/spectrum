class User {
  final String id;
  final String email;
  final String name;
  final String userType;
  final String? image;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.image,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['userType'] as String,
      image: json['image'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
