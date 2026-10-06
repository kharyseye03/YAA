import '../../core/utils/journal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/auth/login_response.dart';

/// Stockage des jetons Keycloak, chiffré par le système.
///
/// Garde l'access token, le refresh token et la **date d'expiration
/// calculée** au moment de l'enregistrement (`now + expires_in`), ce qui
/// permet de savoir si le token est encore utilisable sans le décoder.
///
/// **Pourquoi pas SharedPreferences.** C'est là qu'ils étaient, et
/// SharedPreferences écrit un fichier XML en clair. Deux fuites en
/// découlaient : sur un appareil rooté n'importe quelle application
/// pouvait les lire, et surtout la sauvegarde automatique d'Android
/// les emportait dans le Google Drive de l'utilisateur, d'où ils
/// étaient restaurés sur tout nouvel appareil. Le refresh token vaut
/// dix jours et ouvre l'accès sans mot de passe : il pèse plus lourd
/// qu'un identifiant volé.
///
/// `FlutterSecureStorage` s'appuie sur le Keystore Android et sur la
/// Keychain iOS — le contenu n'est déchiffrable que par cette app, sur
/// cet appareil, et ne part dans aucune sauvegarde.
///
///  `clear()` ne doit JAMAIS être appelé depuis la couche HTTP : un
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

  static const _coffre = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // EncryptedSharedPreferences : chiffrement AES adossé au
      // Keystore Android. Sans cette option, la v9 retombe sur du
      // stockage en clair — c'est-à-dire exactement le problème que
      // ce fichier corrige.
      encryptedSharedPreferences: true,

      // Couvre un vrai cas de panne : la clé du Keystore peut être
      // invalidée par le système, après une restauration d'appareil
      // ou un changement de verrouillage d'écran. Les jetons
      // deviennent alors illisibles ; sans ceci, chaque lecture
      // lèverait et l'app resterait bloquée au démarrage. On efface
      // et on redemande une connexion.
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      // Lisible seulement quand l'appareil a été déverrouillé au moins
      // une fois depuis son démarrage, et jamais copié sur un autre
      // appareil lors d'une restauration de sauvegarde.
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Enregistre les deux tokens et calcule la date d'expiration.
  /// Keycloak peut invalider l'ancien refresh token après usage : il
  /// faut donc bien enregistrer le nouveau à chaque renouvellement.
  Future<void> saveTokens(LoginResponse response) async {
    final expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));

    await _coffre.write(key: _accessKey,  value: response.accessToken);
    await _coffre.write(key: _refreshKey, value: response.refreshToken);
    await _coffre.write(
        key: _expiresAtKey, value: expiresAt.toIso8601String());
  }

  Future<String?> getAccessToken()  => _coffre.read(key: _accessKey);
  Future<String?> getRefreshToken() => _coffre.read(key: _refreshKey);

  /// `true` si un access token est présent et encore valide au moins
  /// [_safetyMargin] de plus.
  Future<bool> hasValidToken() async {
    final token = await _coffre.read(key: _accessKey);
    if (token == null || token.isEmpty) return false;

    final raw = await _coffre.read(key: _expiresAtKey);
    if (raw == null) return false;

    final expiresAt = DateTime.tryParse(raw);
    if (expiresAt == null) return false;

    return DateTime.now().add(_safetyMargin).isBefore(expiresAt);
  }

  /// Efface les tokens — déconnexion ou session définitivement morte.
  Future<void> clear() async {
    await _coffre.delete(key: _accessKey);
    await _coffre.delete(key: _refreshKey);
    await _coffre.delete(key: _expiresAtKey);
  }

  /// Efface les jetons laissés en clair par les versions précédentes.
  ///
  /// Les déplacer serait inutile et dangereux : ils resteraient
  /// lisibles dans l'ancienne sauvegarde. On les supprime, quitte à
  /// demander une reconnexion — le prix d'une seule fois.
  ///
  /// À appeler une fois au démarrage. Sans effet une fois le ménage
  /// fait, donc sans risque à laisser en place.
  static Future<void> purgerAncienStockage(SharedPreferences prefs) async {
    const anciennes = [_accessKey, _refreshKey, _expiresAtKey];
    if (!anciennes.any(prefs.containsKey)) return;
    for (final cle in anciennes) {
      await prefs.remove(cle);
    }
    journal('🔐 Anciens jetons en clair effacés');
  }
}
