class DashboardData {
  final DashboardUser user;
  final List<DashboardPost> recentPosts;
  final List<DashboardPromotion> promotions;
  final List<DashboardPlace> places;
  final List<DashboardEvent> upcomingEvents;
  final DashboardStats stats;

  const DashboardData({
    required this.user,
    required this.recentPosts,
    required this.promotions,
    required this.places,
    required this.upcomingEvents,
    required this.stats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: DashboardUser.fromJson(json['user'] as Map<String, dynamic>),
      recentPosts: (json['recentPosts'] as List)
          .map((p) => DashboardPost.fromJson(p as Map<String, dynamic>))
          .toList(),
      promotions: (json['promotions'] as List)
          .map((p) => DashboardPromotion.fromJson(p as Map<String, dynamic>))
          .toList(),
      places: (json['places'] as List)
          .map((p) => DashboardPlace.fromJson(p as Map<String, dynamic>))
          .toList(),
      upcomingEvents: (json['upcomingEvents'] as List)
          .map((e) => DashboardEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}

class DashboardUser {
  final String firstName;
  final String userType;

  const DashboardUser({required this.firstName, required this.userType});

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      firstName: json['firstName'] as String,
      userType: json['userType'] as String,
    );
  }
}

class DashboardPost {
  final String id;
  final String content;
  final String authorName;
  final String? authorImage;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  const DashboardPost({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorImage,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  factory DashboardPost.fromJson(Map<String, dynamic> json) {
    return DashboardPost(
      id: json['id'] as String,
      content: json['content'] as String,
      authorName: json['authorName'] as String,
      authorImage: json['authorImage'] as String?,
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DashboardPromotion {
  final String id;
  final String title;
  final String storeName;
  final String? discount;
  final String? imageUrl;

  const DashboardPromotion({
    required this.id,
    required this.title,
    required this.storeName,
    this.discount,
    this.imageUrl,
  });

  factory DashboardPromotion.fromJson(Map<String, dynamic> json) {
    return DashboardPromotion(
      id: json['id'] as String,
      title: json['title'] as String,
      storeName: json['storeName'] as String,
      discount: json['discount'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class DashboardPlace {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String? imageUrl;

  const DashboardPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    this.imageUrl,
  });

  factory DashboardPlace.fromJson(Map<String, dynamic> json) {
    return DashboardPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class DashboardEvent {
  final String id;
  final String title;
  final String location;
  final DateTime dateTime;

  const DashboardEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.dateTime,
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }
}

class DashboardStats {
  final int postsCount;

  const DashboardStats({required this.postsCount});

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      postsCount: json['postsCount'] as int,
    );
  }
}
