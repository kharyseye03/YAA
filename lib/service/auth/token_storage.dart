import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/auth/login_response.dart';

/// Stockage des tokens Keycloak.
///
/// Garde l'access token, le refresh token et la **date d'expiration
/// calculée** au moment de l'enregistrement (`now + expires_in`), ce qui
/// permet de savoir si le token est encore utilisable sans le décoder.
///
/// ⚠️ `clear()` ne doit JAMAIS être appelé depuis la couche HTTP : un
/// appel resté en vol pendant que l'utilisateur se reconnecte effacerait
/// les tokens juste après que le login les ait enregistrés. Le nettoyage
/// se fait uniquement à la déconnexion et au démarrage.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _accessKey    = 'access_token';
  static const _refreshKey   = 'refresh_token';
  static const _expiresAtKey = 'token_expires_at';

  /// Marge de sécurité : un token qui expire dans moins de 30 s est
  /// considéré comme invalide, sinon la requête part et échoue en vol.
  static const _safetyMargin = Duration(seconds: 30);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Enregistre les deux tokens et calcule la date d'expiration.
  /// Keycloak peut invalider l'ancien refresh token après usage : il
  /// faut donc bien enregistrer le nouveau à chaque renouvellement.
  Future<void> saveTokens(LoginResponse response) async {
    final prefs     = await _prefs;
    final expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));

    await prefs.setString(_accessKey, response.accessToken);
    await prefs.setString(_refreshKey, response.refreshToken);
    await prefs.setString(_expiresAtKey, expiresAt.toIso8601String());

    debugPrint('🔐 Tokens enregistrés — expire à $expiresAt');
  }

  Future<String?> getAccessToken() async =>
      (await _prefs).getString(_accessKey);

  Future<String?> getRefreshToken() async =>
      (await _prefs).getString(_refreshKey);

  /// `true` si un access token est présent et encore valide au moins
  /// [_safetyMargin] de plus.
  Future<bool> hasValidToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(_accessKey);
    if (token == null || token.isEmpty) return false;

    final raw = prefs.getString(_expiresAtKey);
    if (raw == null) return false;

    final expiresAt = DateTime.tryParse(raw);
    if (expiresAt == null) return false;

    return DateTime.now().add(_safetyMargin).isBefore(expiresAt);
  }

  /// Efface les tokens — déconnexion ou session définitivement morte.
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_expiresAtKey);
    debugPrint('🔐 Tokens effacés');
  }
}
