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
  static const _imageUrlKey = 'user_image_url';

  Future<void> loadProfile() async {
    final token = _prefs.getString('access_token');
    if (token == null) return;

    // Email extrait du JWT uniquement pour savoir qui appeler
    final email = _prefs.getString('user_email') ??
        AuthNotifier.decodeJwtPayload(token)?['email'] as String? ?? '';
    if (email.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      final profile = await ApiService().getUserDetail(email: email);
      // Persister l'image pour un affichage instantané au prochain démarrage
      if (profile.imageUrl != null) {
        await _prefs.setString(_imageUrlKey, profile.imageUrl!);
      }
      state = state.copyWith(isLoading: false, profile: profile);
      debugPrint('✅ Profil API : ${profile.fullName} | image: ${profile.imageUrl}');
    } catch (e) {
      debugPrint('❌ loadProfile échoué : $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    String? imagePath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().updateProfile(
        email     : email,
        firstName : firstName,
        lastName  : lastName,
        telephone : telephone,
        imagePath : imagePath,
      );
      // Recharger depuis l'API pour avoir les données à jour (image incluse)
      await loadProfile();
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
