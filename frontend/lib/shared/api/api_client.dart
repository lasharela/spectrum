import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  ApiClient({
    required String baseUrl,
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Origin'] = baseUrl;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response != null) {
          final data = error.response!.data;
          if (data is Map<String, dynamic>) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: ApiException.fromResponse(
                error.response!.statusCode ?? 500,
                data,
              ),
            ));
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
