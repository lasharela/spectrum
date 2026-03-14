import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum_app/shared/widgets/main_navigation_shell.dart';

void main() {
  group('MainNavigationShell', () {
    testWidgets('renders 5 navigation tabs', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                MainNavigationShell(child: child),
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const SizedBox(),
              ),
              GoRoute(
                path: '/community',
                builder: (context, state) => const SizedBox(),
              ),
              GoRoute(
                path: '/catalog',
                builder: (context, state) => const SizedBox(),
              ),
              GoRoute(
                path: '/promotions',
                builder: (context, state) => const SizedBox(),
              ),
              GoRoute(
                path: '/events',
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Catalogue'), findsOneWidget);
      expect(find.text('Promotions'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
    });
  });
}
