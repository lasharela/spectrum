import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import '../../helpers/mocks.dart';

void main() {
  group('ApiClient', () {
    late ApiClient apiClient;
    late MockSecureStorage mockStorage;
    late Dio dio;

    setUp(() {
      mockStorage = MockSecureStorage();
      dio = Dio();
      apiClient = ApiClient(
        baseUrl: 'http://localhost:8787',
        dio: dio,
        storage: mockStorage,
      );
    });

    test('saves and retrieves token', () async {
      await apiClient.saveToken('test-token');
      final token = await apiClient.getToken();
      expect(token, 'test-token');
    });

    test('clears token', () async {
      await apiClient.saveToken('test-token');
      await apiClient.clearToken();
      final token = await apiClient.getToken();
      expect(token, isNull);
    });
  });
}
