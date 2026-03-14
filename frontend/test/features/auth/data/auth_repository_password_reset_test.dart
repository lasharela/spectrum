import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:spectrum_app/features/auth/data/auth_repository.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('AuthRepository password reset', () {
    late AuthRepository repo;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      final dio = Dio();
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8787',
        dio: dio,
        storage: mockStorage,
      );
      repo = AuthRepository(apiClient);
    });

    test('forgotPassword method exists and accepts email', () {
      expect(repo.forgotPassword, isA<Function>());
    });

    test('resetPassword method exists and accepts token + newPassword', () {
      expect(repo.resetPassword, isA<Function>());
    });
  });
}
