import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';
import '../../../../shared/providers/api_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

final authProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required String userType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(authRepositoryProvider);
      return repo.signUp(
        email: email,
        password: password,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        userType: userType,
      );
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(authRepositoryProvider);
      return repo.signIn(email: email, password: password);
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? middleName,
    String? userState,
    String? city,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final updated = await repo.updateProfile(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      state: userState,
      city: city,
    );
    state = AsyncData(updated);
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signOut();
    } finally {
      state = const AsyncData(null);
    }
  }
}
