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
    return ApiException(
      message: body['error'] as String? ?? 'Unknown error',
      code: body['code'] as String? ?? 'INTERNAL_ERROR',
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
