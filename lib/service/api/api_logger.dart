import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Journal des appels réseau.
///
/// L'objectif est qu'un écran vide soit toujours explicable depuis la
/// console. On y voit l'URL exacte appelée, le statut, la durée, et
/// surtout les réponses « 200 mais vide » : le client HTTP les traite
/// comme un succès, alors que c'est ce que l'utilisateur perçoit
/// comme un bug — un catalogue sans produit, une liste sans résultat.
class ApiLogger {
  ApiLogger._();

  /// Coupé en production : ces traces contiennent des jetons
  /// d'authentification et des données client.
  static bool actif = !kReleaseMode;

  /// Au-delà, le corps est tronqué pour garder la console lisible
  static const _maxCorps = 600;

  static void requete(String methode, Uri url, {Object? corps}) {
    if (!actif) return;
    debugPrint('🌐 $methode ${_chemin(url)}');
    if (corps != null) debugPrint('   ↑ ${_tronquer(_encoder(corps))}');
  }

  static void reponse(
    String methode,
    Uri url,
    int statut,
    String corps,
    Duration duree,
  ) {
    if (!actif) return;

    final succes = statut >= 200 && statut < 300;
    final icone  = succes ? '📡' : '❌';
    final alerte = succes ? _alerteVide(corps) : '';

    debugPrint('$icone $statut · ${duree.inMilliseconds} ms · '
        '$methode ${_chemin(url)}$alerte');
    debugPrint('   ↓ ${_tronquer(corps)}');
  }

  static void erreur(String contexte, Object e) {
    if (!actif) return;
    debugPrint('💥 $contexte → $e');
  }

  /// Trace libre, pour ce qui n'est ni une requête ni une réponse :
  /// renouvellement de jeton, 401 rattrapé, etc.
  static void trace(String message) {
    if (!actif) return;
    debugPrint('🔎 $message');
  }

  /// Avertissement métier : le serveur répond correctement mais
  /// l'écran n'aura rien à afficher.
  static void vide(String contexte, String explication) {
    if (!actif) return;
    debugPrint('⚠️  $contexte — $explication');
  }

  static String _alerteVide(String corps) {
    final c = corps.trim();
    if (c.isEmpty)          return '   ⚠️ CORPS VIDE';
    if (c == '[]')          return '   ⚠️ LISTE VIDE';
    if (c == '{}')          return '   ⚠️ OBJET VIDE';
    if (c.replaceAll(' ', '') == '{"data":[]}') return '   ⚠️ data VIDE';
    return '';
  }

  // L'hôte est le même pour tout le monde : on garde chemin + query,
  // c'est ce qui distingue un appel d'un autre
  static String _chemin(Uri url) =>
      url.hasQuery ? '${url.path}?${url.query}' : url.path;

  static String _encoder(Object corps) {
    try {
      return corps is String ? corps : json.encode(corps);
    } catch (_) {
      return corps.toString();
    }
  }

  static String _tronquer(String texte) {
    final t = texte.replaceAll('\n', ' ');
    if (t.length <= _maxCorps) return t;
    return '${t.substring(0, _maxCorps)}… (${t.length} caractères)';
  }
}
