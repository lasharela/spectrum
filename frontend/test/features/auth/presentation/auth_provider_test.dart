import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    test('authRepositoryProvider is defined', () {
      // Verify the provider is accessible (compile-time check)
      expect(authRepositoryProvider, isNotNull);
    });

    test('authProvider is defined', () {
      // Verify the provider is accessible (compile-time check)
      expect(authProvider, isNotNull);
    });
  });
}
