import 'dart:convert';
import '../../../core/utils/journal.dart';
import '../../../core/errors/messages_erreur.dart';
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
      journal('JWT decode error: $e');
      return null;
    }
  }

  static String? _extractEmailFromJwt(String token) =>
      decodeJwtPayload(token)?['email'] as String?;

  /// Rôle attendu dans `realm_access.roles` pour utiliser cette app.
  ///
  /// Keycloak est commun au client et à YAA PRO : le même serveur
  /// délivre un jeton valide à un coursier, qui pouvait donc entrer
  /// ici. Ce n'est pas une faille — le backend refusera ses appels
  /// sur les routes client — mais l'app lui ouvrait une interface qui
  /// ne le concerne pas, et échouait ensuite sans rien expliquer.
  static const String _roleRequis = 'CLIENT';

  /// Vrai si le jeton porte le rôle client.
  ///
  /// **Ce n'est pas une barrière de sécurité** : la vérification est
  /// locale, un binaire modifié la contournerait. C'est un aiguillage,
  /// pour que chacun atterrisse dans la bonne application. La règle
  /// qui protège vraiment reste celle du serveur.
  static bool estCompteClient(String token) {
    final realm = decodeJwtPayload(token)?['realm_access'];
    if (realm is! Map) return false;
    final roles = realm['roles'];
    if (roles is! List) return false;
    return roles.contains(_roleRequis);
  }

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

      // Contrôle avant d'enregistrer quoi que ce soit : un jeton de
      // coursier stocké ici le reconnecterait automatiquement au
      // prochain lancement, sans repasser par cet écran.
      if (!estCompteClient(response.accessToken)) {
        journal('⛔ connexion refusée : jeton sans rôle $_roleRequis');
        state = state.copyWith(
          isLoading : false,
          error     : MessagesErreur.compteNonClient,
        );
        return false;
      }

      // Enregistre les deux tokens + la date d'expiration calculée
      await TokenStorage.instance.saveTokens(response);

      // Extraire et sauvegarder l'email depuis le JWT Keycloak
      final emailFromToken = _extractEmailFromJwt(response.accessToken);
      if (emailFromToken != null) {
        await _prefs.setString(_emailKey, emailFromToken);
        journal('✅ Email extrait du token: $emailFromToken');
      } else {
        journal('⚠️ Email absent du token JWT');
      }

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: MessagesErreur.depuisException(e),
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
        error: MessagesErreur.depuisException(e),
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
        error: MessagesErreur.depuisException(e),
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
        error: MessagesErreur.depuisException(e),
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
        error: MessagesErreur.depuisException(e),
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
        error: MessagesErreur.depuisException(e),
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
        error: MessagesErreur.depuisException(e),
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
      // Le rôle est revérifié ici, pas seulement à la connexion : un
      // coursier entré avant que ce contrôle existe a son jeton en
      // mémoire, et serait reconnecté sans jamais repasser par le
      // formulaire. On le déconnecte proprement.
      final token = await TokenStorage.instance.getAccessToken();
      if (token != null && !estCompteClient(token)) {
        journal('⛔ session refusée : jeton sans rôle $_roleRequis');
        await TokenStorage.instance.clear();
        state = const AuthState();
        return false;
      }
      journal('🔐 Session restaurée (token encore valide)');
      state = state.copyWith(isAuthenticated: true);
      return true;
    }

    final refresh = await TokenStorage.instance.getRefreshToken();
    if (refresh == null) return false;

    try {
      journal('🔄 Renouvellement du token au démarrage…');
      final response = await ApiService().refreshToken(refreshToken: refresh);

      // Même contrôle après renouvellement : le rôle pourrait avoir
      // changé côté Keycloak depuis la dernière connexion.
      if (!estCompteClient(response.accessToken)) {
        journal('⛔ session refusée après refresh : rôle $_roleRequis absent');
        await TokenStorage.instance.clear();
        state = const AuthState();
        return false;
      }

      await TokenStorage.instance.saveTokens(response);

      final emailFromToken = _extractEmailFromJwt(response.accessToken);
      if (emailFromToken != null) {
        await _prefs.setString(_emailKey, emailFromToken);
      }
      state = state.copyWith(isAuthenticated: true);
      return true;
    } catch (e) {
      journal('❌ Refresh au démarrage échoué : $e → login');
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
