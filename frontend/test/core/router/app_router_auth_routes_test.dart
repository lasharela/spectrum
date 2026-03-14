import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum_app/core/router/app_router.dart';

void main() {
  group('Auth routes configuration', () {
    test('router contains /forgot-password route', () {
      final routes = AppRouter.router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>();
      final paths = goRoutes.map((r) => r.path).toList();
      expect(paths, contains('/forgot-password'));
    });

    test('router contains /reset-password route', () {
      final routes = AppRouter.router.configuration.routes;
      final goRoutes = routes.whereType<GoRoute>();
      final paths = goRoutes.map((r) => r.path).toList();
      expect(paths, contains('/reset-password'));
    });
  });
}
