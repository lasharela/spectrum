import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/home/domain/dashboard.dart';
import 'package:spectrum_app/features/home/presentation/providers/dashboard_provider.dart';
import 'package:spectrum_app/features/home/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders greeting with user name when data loaded',
        (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(() => _FakeDashboardNotifier()),
          ],
          child: MaterialApp(
            home: FTheme(
              data: AppForuiTheme.light,
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Welcome back'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      FlutterError.onError = originalOnError;
    });

    testWidgets('renders section headers', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith(() => _FakeDashboardNotifier()),
          ],
          child: MaterialApp(
            home: FTheme(
              data: AppForuiTheme.light,
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hottest Promotions'), findsOneWidget);

      // Scroll down to reveal sections that may be off-screen
      await tester.scrollUntilVisible(
        find.text('Popular Places'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Popular Places'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Upcoming Events'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Upcoming Events'), findsOneWidget);

      FlutterError.onError = originalOnError;
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider
                .overrideWith(() => _LoadingDashboardNotifier()),
          ],
          child: MaterialApp(
            home: FTheme(
              data: AppForuiTheme.light,
              child: const HomeScreen(),
            ),
          ),
        ),
      );
      // Don't settle — we want the loading state
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _FakeDashboardNotifier extends AsyncNotifier<DashboardData>
    implements DashboardNotifier {
  @override
  Future<DashboardData> build() async {
    return const DashboardData(
      user: DashboardUser(firstName: 'TestUser', userType: 'parent'),
      recentPosts: [],
      promotions: [],
      places: [],
      upcomingEvents: [],
      stats: DashboardStats(postsCount: 0),
    );
  }

  @override
  Future<void> refresh() async {}
}

class _LoadingDashboardNotifier extends AsyncNotifier<DashboardData>
    implements DashboardNotifier {
  @override
  Future<DashboardData> build() async {
    // Use a Completer that never completes — stays in loading state
    // without creating a timer that the test framework complains about.
    final completer = Completer<DashboardData>();
    return completer.future;
  }

  @override
  Future<void> refresh() async {}
}
