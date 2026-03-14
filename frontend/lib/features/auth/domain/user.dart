class User {
  final String id;
  final String email;
  final String name;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String userType;
  final String? state;
  final String? city;
  final String? image;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.userType,
    this.state,
    this.city,
    this.image,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String,
      userType: json['userType'] as String,
      state: json['state'] as String?,
      city: json['city'] as String?,
      image: json['image'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  User copyWith({
    String? firstName,
    String? Function()? middleName,
    String? lastName,
    String? Function()? state,
    String? Function()? city,
    String? Function()? image,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      firstName: firstName ?? this.firstName,
      middleName: middleName != null ? middleName() : this.middleName,
      lastName: lastName ?? this.lastName,
      userType: userType,
      state: state != null ? state() : this.state,
      city: city != null ? city() : this.city,
      image: image != null ? image() : this.image,
      createdAt: createdAt,
    );
  }
}
