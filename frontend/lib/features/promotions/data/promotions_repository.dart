import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';
import 'package:spectrum_app/shared/domain/author.dart';
import 'package:spectrum_app/shared/domain/paginated_result.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => PromotionsRepository(),
);

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

final _mockAuthor = const Author(
  id: 'author-1',
  name: 'Spectrum Team',
  image: null,
  userType: 'professional',
);

final _mockPromotions = <Promotion>[
  Promotion(
    id: 'promo-1',
    title: '20% off all sensory toys and fidget tools',
    description:
        'Enjoy 20% off our entire range of sensory toys, fidget tools, and calming products. '
        'Specially curated for children and adults with autism spectrum disorder. '
        'Use code SPECTRUM20 at checkout.',
    category: 'Health & Wellness',
    discount: '20% OFF',
    store: 'SensoryWorld',
    brandLogoUrl: null,
    imageUrl: null,
    expiresAt: DateTime.now().add(const Duration(days: 14)),
    validFrom: DateTime.now().subtract(const Duration(days: 3)),
    organizationId: null,
    createdById: 'author-1',
    createdBy: _mockAuthor,
    likesCount: 34,
    liked: false,
    saved: false,
    claimed: false,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Promotion(
    id: 'promo-2',
    title: 'Free ABA therapy consultation — first session on us',
    description:
        'New families receive one complimentary 60-minute ABA therapy consultation. '
        'Our board-certified behavior analysts specialize in autism support. '
        'Available in-person and via telehealth.',
    category: 'Services',
    discount: 'FREE SESSION',
    store: 'BrightPath Therapy',
    brandLogoUrl: null,
    imageUrl: null,
    expiresAt: DateTime.now().add(const Duration(days: 30)),
    validFrom: DateTime.now().subtract(const Duration(days: 7)),
    organizationId: null,
    createdById: 'author-1',
    createdBy: _mockAuthor,
    likesCount: 89,
    liked: true,
    saved: true,
    claimed: false,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  Promotion(
    id: 'promo-3',
    title: '3 months free — autism-focused online learning platform',
    description:
        'Get three months of unlimited access to our adaptive learning platform '
        'designed specifically for learners with autism. Includes visual schedules, '
        'social stories, and life skills modules.',
    category: 'Education',
    discount: '3 MONTHS FREE',
    store: 'LearnAbility',
    brandLogoUrl: null,
    imageUrl: null,
    expiresAt: DateTime.now().add(const Duration(hours: 18)),
    validFrom: DateTime.now().subtract(const Duration(days: 1)),
    organizationId: null,
    createdById: 'author-1',
    createdBy: _mockAuthor,
    likesCount: 57,
    liked: false,
    saved: false,
    claimed: false,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Promotion(
    id: 'promo-4',
    title: 'Buy-one-get-one sensory meal kit — low sensory ingredients',
    description:
        'Our BOGO deal on sensory-friendly meal kits makes it easier for families '
        'to enjoy calm mealtimes. All kits feature low-texture, familiar foods '
        'and simple step-by-step visual recipe cards.',
    category: 'Food & Dining',
    discount: 'BOGO',
    store: 'CalmKitchen',
    brandLogoUrl: null,
    imageUrl: null,
    expiresAt: null, // permanent
    validFrom: DateTime.now().subtract(const Duration(days: 10)),
    organizationId: null,
    createdById: 'author-1',
    createdBy: _mockAuthor,
    likesCount: 23,
    liked: false,
    saved: false,
    claimed: false,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
  Promotion(
    id: 'promo-5',
    title: 'Half-price tickets to sensory-friendly movie screenings',
    description:
        'Enjoy specially adapted screenings with reduced volume, raised lighting, '
        'and a relaxed atmosphere. Ideal for children and adults on the autism spectrum. '
        '50% discount on all sensory screening tickets.',
    category: 'Entertainment',
    discount: '50% OFF',
    store: 'CineSense',
    brandLogoUrl: null,
    imageUrl: null,
    expiresAt: DateTime.now().add(const Duration(days: 7)),
    validFrom: DateTime.now().subtract(const Duration(days: 2)),
    organizationId: null,
    createdById: 'author-1',
    createdBy: _mockAuthor,
    likesCount: 112,
    liked: false,
    saved: true,
    claimed: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Promotion(
    id: 'promo-6',
    title: '\$50 off occupational therapy assessment',
    description:
        'Receive \$50 off your first occupational therapy assessment. '
        'Our OTs are experienced in sensory processing, fine motor skills, '
        'and daily living skills for children and teens with autism.',
    category: 'Health & Wellness',
    discount: '\$50 OFF',
    store: 'OT Connect',
    brandLogoUrl: null,
    imageUrl: null,
    expiresAt: DateTime.now().add(const Duration(days: 21)),
    validFrom: DateTime.now().subtract(const Duration(days: 5)),
    organizationId: null,
    createdById: 'author-1',
    createdBy: _mockAuthor,
    likesCount: 45,
    liked: false,
    saved: false,
    claimed: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class PromotionsRepository {
  // In-memory mutable state for mock interactions
  final List<Promotion> _promotions = List.from(_mockPromotions);

  Future<List<FilterOption>> getPromotionCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    const categories = [
      'Health & Wellness',
      'Education',
      'Entertainment',
      'Food & Dining',
      'Services',
    ];
    return categories
        .map(
          (c) => FilterOption(
            id: c.toLowerCase().replaceAll(' ', '-').replaceAll('&', 'and'),
            name: c,
          ),
        )
        .toList();
  }

  Future<PaginatedResult<Promotion>> getPromotions({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      var filtered = _promotions.where((p) {
        if (search != null && search.isNotEmpty) {
          final q = search.toLowerCase();
          if (!p.title.toLowerCase().contains(q) &&
              !(p.description?.toLowerCase().contains(q) ?? false) &&
              !p.store.toLowerCase().contains(q)) {
            return false;
          }
        }
        if (categories != null && categories.isNotEmpty) {
          if (!categories.contains(p.category)) return false;
        }
        return true;
      }).toList();

      // Cursor-based pagination (simple index-based mock)
      int startIndex = 0;
      if (cursor != null) {
        final idx = filtered.indexWhere((p) => p.id == cursor);
        if (idx != -1) startIndex = idx + 1;
      }

      final page = filtered.skip(startIndex).take(limit).toList();
      final hasMore = startIndex + page.length < filtered.length;
      final nextCursor = hasMore ? page.last.id : null;

      return PaginatedResult(items: page, nextCursor: nextCursor);
    } catch (e) {
      log('PromotionsRepository.getPromotions error: $e');
      return const PaginatedResult(items: []);
    }
  }

  Future<Promotion?> getPromotion(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      return _promotions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> likePromotion(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _promotions.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _promotions[idx] = _promotions[idx].copyWith(
      liked: true,
      likesCount: _promotions[idx].likesCount + 1,
    );
  }

  Future<void> unlikePromotion(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _promotions.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final current = _promotions[idx];
    _promotions[idx] = current.copyWith(
      liked: false,
      likesCount: (current.likesCount - 1).clamp(0, 999999),
    );
  }

  Future<void> claimPromotion(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final idx = _promotions.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _promotions[idx] = _promotions[idx].copyWith(claimed: true);
  }

  Future<void> savePromotion(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _promotions.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _promotions[idx] = _promotions[idx].copyWith(saved: true);
  }

  Future<void> unsavePromotion(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _promotions.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _promotions[idx] = _promotions[idx].copyWith(saved: false);
  }

  Future<List<Promotion>> getSavedPromotions() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _promotions.where((p) => p.saved).toList();
  }
}
