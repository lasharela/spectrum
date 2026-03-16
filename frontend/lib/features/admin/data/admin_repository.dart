import 'dart:developer';

import '../../../shared/api/api_client.dart';

class AdminRepository {
  final ApiClient _api;

  AdminRepository(this._api);

  // Events
  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    try {
      final res = await _api.get('/api/admin/events/pending');
      final data = res.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['events'] as List);
    } catch (e) {
      log('Failed to load pending events: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> approveEvent(
      String id, String status) async {
    try {
      final res = await _api.put(
        '/api/admin/events/$id/approve',
        data: {'status': status},
      );
      final data = res.data as Map<String, dynamic>;
      return data['event'] as Map<String, dynamic>;
    } catch (e) {
      log('Failed to approve/reject event: $e');
      return null;
    }
  }

  // Posts (moderation)
  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final res = await _api.get('/api/admin/posts');
      final data = res.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['posts'] as List);
    } catch (e) {
      log('Failed to load admin posts: $e');
      return [];
    }
  }

  Future<bool> softDeletePost(String id) async {
    try {
      await _api.delete('/api/admin/posts/$id');
      return true;
    } catch (e) {
      log('Failed to soft-delete post: $e');
      return false;
    }
  }

  Future<bool> restorePost(String id) async {
    try {
      await _api.put('/api/admin/posts/$id/restore');
      return true;
    } catch (e) {
      log('Failed to restore post: $e');
      return false;
    }
  }

  Future<bool> softDeleteComment(String id) async {
    try {
      await _api.delete('/api/admin/comments/$id');
      return true;
    } catch (e) {
      log('Failed to soft-delete comment: $e');
      return false;
    }
  }

  // Categories (generic)
  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    try {
      final res = await _api.get('/api/admin/categories/$type');
      final data = res.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['categories'] as List);
    } catch (e) {
      log('Failed to load categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createCategory(
      String type, Map<String, dynamic> body) async {
    try {
      final res = await _api.post('/api/admin/categories/$type', data: body);
      final data = res.data as Map<String, dynamic>;
      return data['category'] as Map<String, dynamic>;
    } catch (e) {
      log('Failed to create category: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateCategory(
      String type, String id, Map<String, dynamic> body) async {
    try {
      final res =
          await _api.put('/api/admin/categories/$type/$id', data: body);
      final data = res.data as Map<String, dynamic>;
      return data['category'] as Map<String, dynamic>;
    } catch (e) {
      log('Failed to update category: $e');
      return null;
    }
  }

  Future<bool> deleteCategory(String type, String id) async {
    try {
      await _api.delete('/api/admin/categories/$type/$id');
      return true;
    } catch (e) {
      log('Failed to delete category: $e');
      return false;
    }
  }
}
