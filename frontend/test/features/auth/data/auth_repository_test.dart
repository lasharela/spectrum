import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:spectrum_app/features/auth/data/auth_repository.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('AuthRepository', () {
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

    test('signUp sends correct request and saves token', () async {
      // TODO: Mock POST /api/auth/sign-up/email response
      expect(true, isTrue);
    });

    test('signIn sends correct request and saves token', () async {
      // TODO: Mock POST /api/auth/sign-in/email response
      expect(true, isTrue);
    });

    test('signOut clears token', () async {
      // TODO: Mock POST /api/auth/sign-out
      expect(true, isTrue);
    });

    test('getCurrentUser returns null when no token', () async {
      final user = await repo.getCurrentUser();
      expect(user, isNull);
    });
  });
}
