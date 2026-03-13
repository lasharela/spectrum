import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

// TODO: Replace with actual backend URL from environment config
const _baseUrl = 'http://localhost:8787';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _baseUrl);
});
