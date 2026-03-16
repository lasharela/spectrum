import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/api_provider.dart';
import '../../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(apiClientProvider));
});

// Pending events provider
final pendingEventsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getPendingEvents();
});

// Admin posts provider (all posts including soft-deleted)
final adminPostsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(adminRepositoryProvider).getPosts();
});

// Categories provider — takes type as family parameter
final adminCategoriesProvider = FutureProvider.family<
    List<Map<String, dynamic>>, String>((ref, type) async {
  return ref.read(adminRepositoryProvider).getCategories(type);
});
