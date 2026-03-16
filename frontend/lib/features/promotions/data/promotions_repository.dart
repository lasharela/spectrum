import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';
import 'package:spectrum_app/shared/domain/paginated_result.dart';
import 'package:spectrum_app/shared/providers/api_provider.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository(ref.read(apiClientProvider));
});

class PromotionsRepository {
  final dynamic _api;

  PromotionsRepository(this._api);

  Future<List<FilterOption>> getPromotionCategories() async {
    try {
      final response = await _api.get('/api/filters/promotion-categories');
      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load promotion categories: $e');
      return [];
    }
  }

  Future<PaginatedResult<Promotion>> getPromotions({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'q': search,
        if (categories != null && categories.isNotEmpty)
          'category': categories.first,
      };

      final response =
          await _api.get('/api/promotions', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final promotions = (data['promotions'] as List)
          .map((j) => Promotion.fromJson(j as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        items: promotions,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      log('Failed to load promotions: $e');
      return const PaginatedResult(items: []);
    }
  }

  Future<Promotion?> getPromotion(String id) async {
    try {
      final response = await _api.get('/api/promotions/$id');
      final data = response.data as Map<String, dynamic>;
      return Promotion.fromJson(data['promotion'] as Map<String, dynamic>);
    } catch (e) {
      log('Failed to load promotion: $e');
      return null;
    }
  }

  Future<({bool liked, int likesCount})> likePromotion(String id) async {
    final response = await _api.put('/api/promotions/$id/reactions');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }

  Future<({bool liked, int likesCount})> unlikePromotion(String id) async {
    final response = await _api.delete('/api/promotions/$id/reactions');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }

  Future<void> claimPromotion(String id) async {
    try {
      await _api.post('/api/promotions/$id/claim');
    } catch (e) {
      log('Failed to claim promotion: $e');
      rethrow;
    }
  }

  Future<void> savePromotion(String id) async {
    try {
      await _api.put('/api/saved',
          data: {'itemType': 'promotion', 'itemId': id});
    } catch (e) {
      log('Failed to save promotion: $e');
    }
  }

  Future<void> unsavePromotion(String id) async {
    try {
      await _api.delete('/api/saved/promotion/$id');
    } catch (e) {
      log('Failed to unsave promotion: $e');
    }
  }

  Future<List<Promotion>> getSavedPromotions() async {
    try {
      final response = await _api.get('/api/saved/promotion');
      final data = response.data as Map<String, dynamic>;
      final groups = data['groups'] as List;
      final promotions = <Promotion>[];
      for (final group in groups) {
        final items = (group['items'] as List)
            .map((j) => Promotion.fromJson(j as Map<String, dynamic>))
            .toList();
        promotions.addAll(items);
      }
      return promotions;
    } catch (e) {
      log('Failed to load saved promotions: $e');
      return [];
    }
  }
}
