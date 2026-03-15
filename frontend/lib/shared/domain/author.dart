class Author {
  final String id;
  final String name;
  final String? image;
  final String userType;

  const Author({
    required this.id,
    required this.name,
    this.image,
    required this.userType,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      userType: json['userType'] as String? ?? 'supporter',
    );
  }
}
