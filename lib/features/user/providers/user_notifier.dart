import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../model/user/user_profile.dart';
import '../../../service/api/api_service.dart';

class UserState {
  final bool isLoading;
  final UserProfile? profile;
  final String? error;

  const UserState({this.isLoading = false, this.profile, this.error});

  UserState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? error,
    bool clearError = false,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this._prefs) : super(const UserState());

  final SharedPreferences _prefs;

  void loadProfile() {
    final token = _prefs.getString('access_token');
    if (token == null) {
      debugPrint('⚠️ loadProfile annulé : token manquant');
      return;
    }

    final payload = AuthNotifier.decodeJwtPayload(token);
    if (payload == null) {
      debugPrint('⚠️ loadProfile annulé : JWT invalide');
      return;
    }

    final profile = UserProfile(
      firstName : payload['given_name']  as String? ?? '',
      lastName  : payload['family_name'] as String? ?? '',
      email     : payload['email']       as String? ?? '',
      telephone : payload['preferred_username'] as String? ?? '',
    );

    debugPrint('✅ Profil depuis JWT : ${profile.fullName} | ${profile.email}');
    state = state.copyWith(profile: profile);
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    String? imagePath,
  }) async {
    final token = _prefs.getString('access_token');
    if (token == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().updateProfile(
        email     : email,
        firstName : firstName,
        lastName  : lastName,
        telephone : telephone,
        token     : token,
        imagePath : imagePath,
      );

      final updatedProfile = UserProfile(
        firstName : firstName,
        lastName  : lastName,
        email     : email,
        telephone : telephone,
        imageUrl  : imagePath ?? state.profile?.imageUrl,
      );
      state = state.copyWith(isLoading: false, profile: updatedProfile);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearProfile() {
    state = const UserState();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = UserNotifier(prefs);

  // Charger le profil automatiquement quand l'utilisateur se connecte
  ref.listen(authProvider, (previous, next) {
    if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
      notifier.loadProfile();
    }
    if (!next.isAuthenticated) {
      notifier.clearProfile();
    }
  });

  // Charger au démarrage si déjà connecté
  if (ref.read(authProvider).isAuthenticated) {
    notifier.loadProfile();
  }

  return notifier;
});
