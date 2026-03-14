import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum_app/core/router/app_router.dart';
import 'package:spectrum_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:spectrum_app/features/auth/domain/user.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

void main() {
  group('Auth routes configuration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('router contains /forgot-password route', () {
      final router = container.read(routerProvider);
      final routes = router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>();
      final paths = goRoutes.map((r) => r.path).toList();
      expect(paths, contains('/forgot-password'));
    });

    test('router contains /reset-password route', () {
      final router = container.read(routerProvider);
      final routes = router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>();
      final paths = goRoutes.map((r) => r.path).toList();
      expect(paths, contains('/reset-password'));
    });
  });
}
