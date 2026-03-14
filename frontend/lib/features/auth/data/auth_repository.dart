import '../../../shared/api/api_client.dart';
import '../domain/user.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required String userType,
  }) async {
    final fullName = [firstName, if (middleName != null && middleName.isNotEmpty) middleName, lastName].join(' ');
    final response = await _api.post('/api/auth/sign-up/email', data: {
      'email': email,
      'password': password,
      'name': fullName,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
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
    try {
      await _api.post('/api/auth/sign-out');
    } finally {
      await _api.clearToken();
    }
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

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? middleName,
    String? state,
    String? city,
  }) async {
    final response = await _api.put('/api/me', data: {
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'state': state,
      'city': city,
    });
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<String>> getCities(String state) async {
    final response = await _api.get('/api/cities', queryParameters: {
      'state': state,
    });
    final data = response.data as Map<String, dynamic>;
    return (data['cities'] as List).cast<String>();
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
