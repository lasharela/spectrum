import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/debug/ui_test_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/community/presentation/screens/feed_screen.dart';
import '../../features/community/presentation/screens/post_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/place_detail_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/promotions/presentation/screens/promotions_screen.dart';
import '../../features/promotions/presentation/screens/promotion_detail_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Auth routes that don't require authentication
const _publicPaths = {
  '/onboarding',
  '/login',
  '/signup',
  '/forgot-password',
  '/reset-password',
};

/// Notifier that bridges Riverpod auth state changes to GoRouter's
/// refreshListenable so the router re-evaluates redirects without
/// being recreated.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final path = state.uri.path;
      final isPublicRoute = _publicPaths.contains(path);

      // While auth is loading, don't redirect
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;

      // Not logged in and trying to access protected route
      if (!isLoggedIn && !isPublicRoute) {
        return '/onboarding';
      }

      // Logged in and on a public route → go to home
      if (isLoggedIn && isPublicRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/ui',
        name: 'ui',
        builder: (context, state) => const UiTestScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(token: token, email: email);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) => const FeedScreen(),
            routes: [
              GoRoute(
                path: 'post/:postId',
                builder: (context, state) => PostDetailScreen(
                  postId: state.pathParameters['postId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/catalog',
            name: 'catalog',
            builder: (context, state) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: ':placeId',
                builder: (context, state) => PlaceDetailScreen(
                  placeId: state.pathParameters['placeId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/promotions',
            name: 'promotions',
            builder: (context, state) => const PromotionsScreen(),
            routes: [
              GoRoute(
                path: ':promotionId',
                builder: (context, state) => PromotionDetailScreen(
                  promotionId: state.pathParameters['promotionId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsScreen(),
            routes: [
              GoRoute(
                path: ':eventId',
                builder: (context, state) => EventDetailScreen(
                  eventId: state.pathParameters['eventId']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
});
