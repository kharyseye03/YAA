import 'package:flutter/material.dart';

import '../../config/api/api_config.dart';

/// Nature de la mission renvoyée par /livraisons-courses/client
enum TypeServiceMission {
  /// Envoi de colis d'un point A à un point B
  livraison('LIVRAISON', 'Colis', Icons.inventory_2_outlined),

  /// Transport de personne
  course('COURSE', 'Course', Icons.local_taxi_rounded),

  /// Livraison d'une commande passée auprès d'un établissement
  livraisonCommande(
      'LIVRAISON_COMMANDE', 'Commande', Icons.shopping_bag_outlined);

  const TypeServiceMission(this.code, this.label, this.icon);
  final String   code;
  final String   label;
  final IconData icon;

  static TypeServiceMission from(String? code) =>
      TypeServiceMission.values.firstWhere(
        (t) => t.code == code,
        orElse: () => TypeServiceMission.livraison,
      );
}

/// Une entrée de la liste unifiée des livraisons, courses et
/// commandes livrées.
class LivraisonCourseModel {
  final int    id;
  final String code;
  final TypeServiceMission typeService;
  final String typeVehicule;
  final String statut;

  /// Identifiant de la commande d'origine — renseigné uniquement
  /// pour les LIVRAISON_COMMANDE, c'est lui qui permet d'aller
  /// chercher le détail (produits, structure, livreur).
  final int? commandeStructureId;

  final String? livreurFullName;
  final String? livreurTelephone;
  /// Nom de fichier de la photo de profil du coursier
  final String? livreurProfile;
  /// Dernière position connue du coursier (null tant qu'aucun
  /// coursier n'est assigné)
  final double? latitudeLivreur;
  final double? longitudeLivreur;

  final double latitudeDepart;
  final double longitudeDepart;
  final double latitudeArrivee;
  final double longitudeArrivee;
  final String adresseDepart;
  final String adresseArrivee;

  final double distanceMetres;
  final double distanceKm;
  final int    dureeMinutes;

  final double montant;
  final String devise;
  final String instructions;

  final String? telephoneExpediteur;
  final String? telephoneDestinataire;

  final DateTime? createdDate;
  final DateTime? dateAssignation;
  final DateTime? dateRecuperation;
  final DateTime? dateArrivee;
  final DateTime? dateAnnulation;

  const LivraisonCourseModel({
    required this.id,
    required this.code,
    required this.typeService,
    required this.typeVehicule,
    required this.statut,
    this.commandeStructureId,
    this.livreurFullName,
    this.livreurTelephone,
    this.livreurProfile,
    this.latitudeLivreur,
    this.longitudeLivreur,
    this.latitudeDepart   = 0,
    this.longitudeDepart  = 0,
    this.latitudeArrivee  = 0,
    this.longitudeArrivee = 0,
    this.adresseDepart    = '',
    this.adresseArrivee   = '',
    this.distanceMetres   = 0,
    this.distanceKm       = 0,
    this.dureeMinutes     = 0,
    this.montant          = 0,
    this.devise           = 'FCFA',
    this.instructions     = '',
    this.telephoneExpediteur,
    this.telephoneDestinataire,
    this.createdDate,
    this.dateAssignation,
    this.dateRecuperation,
    this.dateArrivee,
    this.dateAnnulation,
  });

  factory LivraisonCourseModel.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final raw = json[key] as String?;
      return raw == null ? null : DateTime.tryParse(raw);
    }

    return LivraisonCourseModel(
      id                    : (json['id'] as num).toInt(),
      code                  : json['code'] as String? ?? '',
      typeService           : TypeServiceMission.from(
                                  json['typeService'] as String?),
      typeVehicule          : json['typeVehicule'] as String? ?? '',
      statut                : json['statut'] as String? ?? '',
      commandeStructureId   : (json['commandeStructureId'] as num?)?.toInt(),
      livreurFullName       : json['livreurFullName']  as String?,
      livreurTelephone      : json['livreurTelephone'] as String?,
      livreurProfile        : json['livreurProfile']   as String?,
      latitudeLivreur       : (json['latitudeLivreur']  as num?)?.toDouble(),
      longitudeLivreur      : (json['longitudeLivreur'] as num?)?.toDouble(),
      latitudeDepart        : (json['latitudeDepart']   as num?)?.toDouble() ?? 0,
      longitudeDepart       : (json['longitudeDepart']  as num?)?.toDouble() ?? 0,
      latitudeArrivee       : (json['latitudeArrivee']  as num?)?.toDouble() ?? 0,
      longitudeArrivee      : (json['longitudeArrivee'] as num?)?.toDouble() ?? 0,
      adresseDepart         : json['adresseDepart']  as String? ?? '',
      adresseArrivee        : json['adresseArrivee'] as String? ?? '',
      distanceMetres        : (json['distanceMetres'] as num?)?.toDouble() ?? 0,
      distanceKm            : (json['distanceKm']     as num?)?.toDouble() ?? 0,
      dureeMinutes          : (json['dureeMinutes']   as num?)?.toInt() ?? 0,
      montant               : (json['montant']        as num?)?.toDouble() ?? 0,
      devise                : json['devise'] as String? ?? 'FCFA',
      instructions          : json['instructions'] as String? ?? '',
      telephoneExpediteur   : json['telephoneExpediteur']   as String?,
      telephoneDestinataire : json['telephoneDestinataire'] as String?,
      // La liste expose `createdDate`, la création `dateCreationMission`
      createdDate           : date('createdDate')
                              ?? date('dateCreationMission'),
      dateAssignation       : date('dateAssignation'),
      dateRecuperation      : date('dateRecuperation'),
      dateArrivee           : date('dateArrivee'),
      dateAnnulation        : date('dateAnnulation'),
    );
  }

  /// Seules les commandes passées auprès d'un établissement ont un
  /// détail enrichi (produits, structure…) à aller chercher.
  bool get hasDetail =>
      typeService == TypeServiceMission.livraisonCommande &&
      commandeStructureId != null;

  bool get hasLivreur =>
      livreurFullName != null && livreurFullName!.isNotEmpty;

  /// URL complète de la photo du coursier
  String? get livreurPhotoUrl {
    final f = livreurProfile;
    if (f == null || f.isEmpty) return null;
    return f.startsWith('http') ? f : ApiConfig.getImageUrl(f);
  }

  bool get hasLivreurPosition =>
      latitudeLivreur != null && longitudeLivreur != null;

  /// Le coursier a récupéré le colis : il file vers la destination.
  /// Avant ça, il se dirige vers le point de retrait.
  bool get versDestination => const {
        'PRISE_EN_CHARGE_EFFECTUEE',
        'COURSE_EN_COURS',
        'EN_LIVRAISON',
      }.contains(statut);

  /// Statuts terminaux : la mission ne bougera plus, elle bascule
  /// dans l'historique. Les cinq statuts intermédiaires
  /// (RECHERCHE_COURSIER, COURSIER_ASSIGNE, COURSIER_EN_ROUTE_VERS_DEPART,
  /// COURSIER_ARRIVE_AU_DEPART, PRISE_EN_CHARGE_EFFECTUEE,
  /// COURSE_EN_COURS) restent « en cours ».
  static const _statutsFinaux = {
    'COURSE_TERMINEE', 'ANNULE',   // missions
    'LIVRE', 'REJETE',             // commandes d'établissement
  };

  bool get isEnCours => !_statutsFinaux.contains(statut);

  /// "6.9 km · 16 min"
  String get metaLabel {
    final d = distanceKm > 0 ? '${distanceKm.toStringAsFixed(1)} km' : null;
    final t = dureeMinutes > 0 ? '$dureeMinutes min' : null;
    return [d, t].where((e) => e != null).join(' · ');
  }

  String get montantLabel => '${montant.toStringAsFixed(0)} $devise';
}
