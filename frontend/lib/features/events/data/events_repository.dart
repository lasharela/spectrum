import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/events/domain/event.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import 'package:spectrum_app/shared/domain/paginated_result.dart';
import 'package:spectrum_app/shared/providers/api_provider.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(ref.read(apiClientProvider));
});

class EventsRepository {
  final ApiClient _api;

  EventsRepository(this._api);

  // --- Filter Options ---

  Future<List<FilterOption>> getEventCategories() async {
    try {
      final response = await _api.get('/api/filters/event-categories');
      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load event categories: $e');
      return [];
    }
  }

  // --- Events ---

  Future<PaginatedResult<Event>> getEvents({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
    bool? isOnline,
    bool? isFree,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'q': search,
        if (categories != null && categories.isNotEmpty)
          'category': categories.first,
        if (isOnline != null) 'isOnline': isOnline.toString(),
        if (isFree != null) 'isFree': isFree.toString(),
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response =
          await _api.get('/api/events', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final events = (data['events'] as List)
          .map((j) => Event.fromJson(j as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        items: events,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      log('Failed to load events: $e');
      return const PaginatedResult(items: []);
    }
  }

  Future<Event?> getEvent(String id) async {
    try {
      final response = await _api.get('/api/events/$id');
      final data = response.data as Map<String, dynamic>;
      return Event.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      log('Failed to load event: $e');
      return null;
    }
  }

  Future<PaginatedResult<Event>> getMyEvents({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        'mine': 'true',
        if (cursor != null) 'cursor': cursor,
      };
      final response =
          await _api.get('/api/events', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final events = (data['events'] as List)
          .map((j) => Event.fromJson(j as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        items: events,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      log('Failed to load my events: $e');
      return const PaginatedResult(items: []);
    }
  }

  // --- RSVP ---

  Future<void> rsvp(String eventId) async {
    try {
      await _api.post('/api/events/$eventId/rsvp');
    } catch (e) {
      log('Failed to RSVP: $e');
    }
  }

  Future<void> cancelRsvp(String eventId) async {
    try {
      await _api.delete('/api/events/$eventId/rsvp');
    } catch (e) {
      log('Failed to cancel RSVP: $e');
    }
  }

  // --- Save ---

  Future<void> saveEvent(String id) async {
    try {
      await _api
          .put('/api/saved', data: {'itemType': 'event', 'itemId': id});
    } catch (e) {
      log('Failed to save event: $e');
    }
  }

  Future<void> unsaveEvent(String id) async {
    try {
      await _api.delete('/api/saved/event/$id');
    } catch (e) {
      log('Failed to unsave event: $e');
    }
  }

  Future<List<Event>> getSavedEvents() async {
    try {
      final response = await _api.get('/api/saved/event');
      final data = response.data as Map<String, dynamic>;
      final groups = data['groups'] as List;
      final events = <Event>[];
      for (final group in groups) {
        final items = (group['items'] as List)
            .map((j) => Event.fromJson(j as Map<String, dynamic>))
            .toList();
        events.addAll(items);
      }
      return events;
    } catch (e) {
      log('Failed to load saved events: $e');
      return [];
    }
  }

  // --- Create ---

  Future<Event?> createEvent({
    required String title,
    String? description,
    required String category,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    String? imageUrl,
    bool isOnline = false,
    bool isFree = true,
    String? price,
  }) async {
    try {
      final response = await _api.post('/api/events', data: {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        'imageUrl': imageUrl,
        'isOnline': isOnline,
        'isFree': isFree,
        'price': price,
      });
      final data = response.data as Map<String, dynamic>;
      return Event.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      log('Failed to create event: $e');
      return null;
    }
  }
}
