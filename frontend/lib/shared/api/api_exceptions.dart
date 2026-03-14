class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  const ApiException({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body) {
    final String message;
    final String code;

    if (body['error'] is Map<String, dynamic>) {
      final error = body['error'] as Map<String, dynamic>;
      message = error['message'] as String? ?? 'Unknown error';
      code = error['code'] as String? ?? 'INTERNAL_ERROR';
    } else {
      message = body['message'] as String? ??
          body['error'] as String? ??
          'Unknown error';
      code = body['code'] as String? ?? 'INTERNAL_ERROR';
    }

    return ApiException(
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  bool get isUnauthorized => code == 'UNAUTHORIZED';
  bool get isForbidden => code == 'FORBIDDEN';
  bool get isNotFound => code == 'NOT_FOUND';
  bool get isValidationError => code == 'VALIDATION_ERROR';

  @override
  String toString() => 'ApiException($code: $message)';
}
