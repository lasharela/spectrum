import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://spectrum-api.lasharela.workers.dev',
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _baseUrl);
});
