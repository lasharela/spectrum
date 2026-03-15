import 'package:spectrum_app/shared/domain/author.dart';

class Place {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String? address;
  final String? imageUrl;
  final double averageRating;
  final int ratingCount;
  final List<String> tags;
  final List<String> ageGroups;
  final List<String> specialNeeds;
  final double? latitude;
  final double? longitude;
  final String ownerId;
  final Author owner;
  final bool saved;
  final int? userRating;
  final DateTime createdAt;

  const Place({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.address,
    this.imageUrl,
    this.averageRating = 0,
    this.ratingCount = 0,
    this.tags = const [],
    this.ageGroups = const [],
    this.specialNeeds = const [],
    this.latitude,
    this.longitude,
    required this.ownerId,
    required this.owner,
    this.saved = false,
    this.userRating,
    required this.createdAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      address: json['address'] as String?,
      imageUrl: json['imageUrl'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      ageGroups: (json['ageGroups'] as List?)?.cast<String>() ?? [],
      specialNeeds: (json['specialNeeds'] as List?)?.cast<String>() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ownerId: json['ownerId'] as String,
      owner: Author.fromJson(json['owner'] as Map<String, dynamic>),
      saved: json['saved'] as bool? ?? false,
      userRating: json['userRating'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Place copyWith({
    bool? saved,
    int? userRating,
    double? averageRating,
    int? ratingCount,
  }) {
    return Place(
      id: id,
      name: name,
      description: description,
      category: category,
      address: address,
      imageUrl: imageUrl,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      tags: tags,
      ageGroups: ageGroups,
      specialNeeds: specialNeeds,
      latitude: latitude,
      longitude: longitude,
      ownerId: ownerId,
      owner: owner,
      saved: saved ?? this.saved,
      userRating: userRating ?? this.userRating,
      createdAt: createdAt,
    );
  }
}
