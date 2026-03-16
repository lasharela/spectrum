import 'package:spectrum_app/shared/domain/author.dart';

class Promotion {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? discount;
  final String store;
  final String? brandLogoUrl;
  final String? imageUrl;
  final DateTime? expiresAt;
  final DateTime validFrom;
  final String? organizationId;
  final String createdById;
  final Author createdBy;
  final int likesCount;
  final bool liked;
  final bool saved;
  final bool claimed;
  final DateTime createdAt;

  const Promotion({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.discount,
    required this.store,
    this.brandLogoUrl,
    this.imageUrl,
    this.expiresAt,
    required this.validFrom,
    this.organizationId,
    required this.createdById,
    required this.createdBy,
    this.likesCount = 0,
    this.liked = false,
    this.saved = false,
    this.claimed = false,
    required this.createdAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      discount: json['discount'] as String?,
      store: json['store'] as String,
      brandLogoUrl: json['brandLogoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      validFrom: DateTime.parse(json['validFrom'] as String),
      organizationId: json['organizationId'] as String?,
      createdById: json['createdById'] as String,
      createdBy: Author.fromJson(json['createdBy'] as Map<String, dynamic>),
      likesCount: json['likesCount'] as int? ?? 0,
      liked: json['liked'] as bool? ?? false,
      saved: json['saved'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Promotion copyWith({
    bool? liked,
    int? likesCount,
    bool? saved,
    bool? claimed,
  }) {
    return Promotion(
      id: id,
      title: title,
      description: description,
      category: category,
      discount: discount,
      store: store,
      brandLogoUrl: brandLogoUrl,
      imageUrl: imageUrl,
      expiresAt: expiresAt,
      validFrom: validFrom,
      organizationId: organizationId,
      createdById: createdById,
      createdBy: createdBy,
      likesCount: likesCount ?? this.likesCount,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      claimed: claimed ?? this.claimed,
      createdAt: createdAt,
    );
  }

  bool get isPermanent => expiresAt == null;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get timeRemaining {
    if (expiresAt == null) return '';
    final now = DateTime.now();
    final diff = expiresAt!.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }
}
