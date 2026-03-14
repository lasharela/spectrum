import '../../../shared/api/api_client.dart';
import '../domain/user.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    final response = await _api.post('/api/auth/sign-up/email', data: {
      'email': email,
      'password': password,
      'name': name,
      'userType': userType,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null) {
      await _api.saveToken(token);
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/api/auth/sign-in/email', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null) {
      await _api.saveToken(token);
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await _api.post('/api/auth/sign-out');
    await _api.clearToken();
  }

  Future<User?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;
    try {
      final response = await _api.get('/api/auth/get-session');
      final data = response.data as Map<String, dynamic>;
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await _api.clearToken();
      return null;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    await _api.post('/api/auth/forget-password', data: {
      'email': email,
    });
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.post('/api/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }
}
