import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/api/api_service.dart';
import '../../../service/auth/token_storage.dart';
import 'auth_state.dart';

const _tokenKey = 'access_token';
const _emailKey = 'user_email';
const _telephoneKey = 'user_telephone';

class AuthNotifier extends StateNotifier<AuthState> {
  // L'état initial est optimiste (un token est présent) ; tryAutoLogin()
  // au démarrage confirme ou infirme en tentant un renouvellement.
  AuthNotifier(this._prefs)
      : super(AuthState(isAuthenticated: _prefs.containsKey(_tokenKey)));

  final SharedPreferences _prefs;

  String? get email => _prefs.getString(_emailKey);

  /// Décode le payload JWT et retourne la Map complète.
  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      final padding = payload.length % 4;
      if (padding != 0) payload += '=' * (4 - padding);
      final decoded = utf8.decode(base64.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      return null;
    }
  }

  static String? _extractEmailFromJwt(String token) =>
      decodeJwtPayload(token)?['email'] as String?;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiService().login(
        username: username,
        password: password,
      );
      // Enregistre les deux tokens + la date d'expiration calculée
      await TokenStorage.instance.saveTokens(response);

      // Extraire et sauvegarder l'email depuis le JWT Keycloak
      final emailFromToken = _extractEmailFromJwt(response.accessToken);
      if (emailFromToken != null) {
        await _prefs.setString(_emailKey, emailFromToken);
        debugPrint('✅ Email extrait du token: $emailFromToken');
      } else {
        debugPrint('⚠️ Email absent du token JWT');
      }

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        telephone: telephone,
      );
      await _prefs.setString(_emailKey, email);
      // Sauvegardé pour l'écran de localisation (set-adresse)
      await _prefs.setString(_telephoneKey, telephone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().verifyOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> createPassword({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().createPassword(email: email, newPassword: newPassword);
      await _prefs.setString(_emailKey, email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Enregistre l'adresse de livraison choisie pendant l'inscription.
  /// Email et téléphone sont relus depuis les prefs (sauvegardés
  /// lors de register / createPassword).
  Future<bool> setAdresse({
    required String adresse,
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final email     = _prefs.getString(_emailKey);
      final telephone = _prefs.getString(_telephoneKey);
      if (email == null) {
        throw Exception('Email introuvable. Veuillez recommencer l\'inscription.');
      }
      await ApiService().setAdresse(
        email     : email,
        telephone : telephone ?? '',
        adresse   : adresse,
        latitude  : latitude,
        longitude : longitude,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().forgotPassword(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resendCode({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiService().resendCode(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Restaure la session au démarrage.
  ///
  /// - Token encore valide → on est connecté directement
  /// - Sinon on tente un refresh (10 jours de validité)
  /// - Échec → on efface les tokens et on repart sur le login
  Future<bool> tryAutoLogin() async {
    if (await TokenStorage.instance.hasValidToken()) {
      debugPrint('🔐 Session restaurée (token encore valide)');
      state = state.copyWith(isAuthenticated: true);
      return true;
    }

    final refresh = await TokenStorage.instance.getRefreshToken();
    if (refresh == null) return false;

    try {
      debugPrint('🔄 Renouvellement du token au démarrage…');
      final response = await ApiService().refreshToken(refreshToken: refresh);
      await TokenStorage.instance.saveTokens(response);

      final emailFromToken = _extractEmailFromJwt(response.accessToken);
      if (emailFromToken != null) {
        await _prefs.setString(_emailKey, emailFromToken);
      }
      state = state.copyWith(isAuthenticated: true);
      return true;
    } catch (e) {
      debugPrint('❌ Refresh au démarrage échoué : $e → login');
      await TokenStorage.instance.clear();
      state = const AuthState();
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    await _prefs.remove(_emailKey);
    await _prefs.remove(_telephoneKey);
    await _prefs.remove('user_image_url');
    state = const AuthState();
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs);
});
