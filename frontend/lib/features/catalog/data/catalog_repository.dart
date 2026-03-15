import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/catalog/domain/place.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import 'package:spectrum_app/shared/domain/paginated_result.dart';
import 'package:spectrum_app/shared/providers/api_provider.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.read(apiClientProvider));
});

class CatalogRepository {
  final ApiClient _api;

  CatalogRepository(this._api);

  // --- Filter Options ---

  Future<List<FilterOption>> getCategories() async {
    try {
      final response = await _api.get('/api/filters/catalog-categories');
      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load categories: $e');
      return [];
    }
  }

  Future<List<FilterOption>> getAgeGroups() async {
    try {
      final response = await _api.get('/api/filters/age-groups');
      final data = response.data as Map<String, dynamic>;
      return (data['ageGroups'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load age groups: $e');
      return [];
    }
  }

  Future<List<FilterOption>> getSpecialNeeds() async {
    try {
      final response = await _api.get('/api/filters/special-needs');
      final data = response.data as Map<String, dynamic>;
      return (data['specialNeeds'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load special needs: $e');
      return [];
    }
  }

  // --- Places ---

  Future<PaginatedResult<Place>> getPlaces({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
    Set<String>? ageGroups,
    Set<String>? specialNeeds,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'q': search,
        if (categories != null && categories.isNotEmpty)
          'category': categories.first,
        if (ageGroups != null && ageGroups.isNotEmpty)
          'ageGroup': ageGroups.first,
        if (specialNeeds != null && specialNeeds.isNotEmpty)
          'specialNeed': specialNeeds.first,
      };

      final response =
          await _api.get('/api/catalog', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final places = (data['places'] as List)
          .map((j) => Place.fromJson(j as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        items: places,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      log('Failed to load places: $e');
      return const PaginatedResult(items: []);
    }
  }

  Future<Place?> getPlace(String id) async {
    try {
      final response = await _api.get('/api/catalog/$id');
      final data = response.data as Map<String, dynamic>;
      return Place.fromJson(data['place'] as Map<String, dynamic>);
    } catch (e) {
      log('Failed to load place: $e');
      return null;
    }
  }

  Future<void> ratePlace(String id, int score) async {
    try {
      await _api.put('/api/catalog/$id/rating', data: {'score': score});
    } catch (e) {
      log('Failed to rate place: $e');
    }
  }

  Future<void> savePlace(String id) async {
    try {
      await _api
          .put('/api/saved', data: {'itemType': 'catalog', 'itemId': id});
    } catch (e) {
      log('Failed to save place: $e');
    }
  }

  Future<void> unsavePlace(String id) async {
    try {
      await _api.delete('/api/saved/catalog/$id');
    } catch (e) {
      log('Failed to unsave place: $e');
    }
  }

  Future<List<Place>> getSavedPlaces() async {
    try {
      final response = await _api.get('/api/saved/catalog');
      final data = response.data as Map<String, dynamic>;
      final groups = data['groups'] as List;
      final places = <Place>[];
      for (final group in groups) {
        final items = (group['items'] as List)
            .map((j) => Place.fromJson(j as Map<String, dynamic>))
            .toList();
        places.addAll(items);
      }
      return places;
    } catch (e) {
      log('Failed to load saved places: $e');
      return [];
    }
  }
}
