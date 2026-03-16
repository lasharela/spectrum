import 'package:spectrum_app/shared/domain/author.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final String? imageUrl;
  final bool isOnline;
  final bool isFree;
  final String? price;
  final String status;
  final String organizerId;
  final Author organizer;
  final int attendeeCount;
  final bool saved;
  final bool rsvped;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.location,
    required this.startDate,
    this.endDate,
    this.imageUrl,
    this.isOnline = false,
    this.isFree = true,
    this.price,
    this.status = 'pending',
    required this.organizerId,
    required this.organizer,
    this.attendeeCount = 0,
    this.saved = false,
    this.rsvped = false,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'Workshop',
      location: json['location'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      isFree: json['isFree'] as bool? ?? true,
      price: json['price'] as String?,
      status: json['status'] as String? ?? 'pending',
      organizerId: json['organizerId'] as String,
      organizer: Author.fromJson(json['organizer'] as Map<String, dynamic>),
      attendeeCount: json['attendeeCount'] as int? ?? 0,
      saved: json['saved'] as bool? ?? false,
      rsvped: json['rsvped'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Event copyWith({
    bool? saved,
    bool? rsvped,
    int? attendeeCount,
    String? status,
  }) {
    return Event(
      id: id,
      title: title,
      description: description,
      category: category,
      location: location,
      startDate: startDate,
      endDate: endDate,
      imageUrl: imageUrl,
      isOnline: isOnline,
      isFree: isFree,
      price: price,
      status: status ?? this.status,
      organizerId: organizerId,
      organizer: organizer,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      saved: saved ?? this.saved,
      rsvped: rsvped ?? this.rsvped,
      createdAt: createdAt,
    );
  }
}
