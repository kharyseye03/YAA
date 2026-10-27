import 'dart:convert';

import '../../core/utils/journal.dart';

/// Une notification de l'historique, telle que la renvoie
/// `GET /notifications`.
///
/// À ne pas confondre avec la notification push, qui est une livraison
/// et ne se stocke nulle part. Celle-ci est sa trace : elle survit à
/// l'affichage et se consulte plus tard.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.lue,
    required this.donnees,
    this.creeLe,
  });

  final int    id;
  final String titre;
  final String message;

  /// `COMMANDE_STATUT`, et d'autres à venir. Sert à choisir l'icône.
  final String type;

  final bool lue;

  /// Contenu de `data`, décodé.
  ///
  /// Le serveur l'envoie comme **une chaîne contenant du JSON**, pas
  /// comme un objet — héritage de Firebase, où toute valeur de `data`
  /// doit être une chaîne. D'où ce second décodage, fait ici une fois
  /// pour toutes plutôt qu'à chaque lecture.
  final Map<String, dynamic> donnees;

  final DateTime? creeLe;

  /// Commande concernée, si la notification en désigne une.
  ///
  /// Le serveur envoie l'identifiant en texte : on le convertit ici,
  /// sinon chaque appelant devrait y penser.
  int? get commandeId => _entier(donnees['commandeId']);

  int? get commandeStructureId => _entier(donnees['commandeStructureId']);

  /// Statut porté par la notification — `EN_PREPARATION`, `CONFIRME`…
  String? get statut => donnees['statut'] as String?;

  static int? _entier(dynamic valeur) => switch (valeur) {
        int v    => v,
        String v => int.tryParse(v),
        num v    => v.toInt(),
        _        => null,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id      : (json['id'] as num).toInt(),
      titre   : json['title'] as String? ?? '',
      message : json['body']  as String? ?? '',
      type    : json['type']  as String? ?? '',
      lue     : json['lue']   as bool?   ?? false,
      donnees : _decoderDonnees(json['data']),
      creeLe  : DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  /// Accepte la chaîne JSON du serveur, un objet déjà décodé, ou rien.
  ///
  /// Un `data` illisible ne doit pas faire disparaître la
  /// notification : on garde le titre et le message, qui sont
  /// l'essentiel, et on perd seulement la destination au toucher.
  static Map<String, dynamic> _decoderDonnees(dynamic brut) {
    if (brut == null) return const {};
    if (brut is Map<String, dynamic>) return brut;
    if (brut is String && brut.isNotEmpty) {
      try {
        final decode = json.decode(brut);
        if (decode is Map<String, dynamic>) return decode;
      } catch (e) {
        journal('⚠️ data de notification illisible : $e');
      }
    }
    return const {};
  }

  NotificationModel copyWith({bool? lue}) => NotificationModel(
        id      : id,
        titre   : titre,
        message : message,
        type    : type,
        lue     : lue ?? this.lue,
        donnees : donnees,
        creeLe  : creeLe,
      );
}
