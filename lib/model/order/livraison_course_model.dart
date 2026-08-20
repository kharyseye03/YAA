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

/// Le coursier assigné à une mission.
///
/// Nul tant que le statut est RECHERCHE_COURSIER. Présent sur les
/// trois types de service dès qu'un coursier prend la mission.
class Livreur {
  const Livreur({
    required this.id,
    required this.fullName,
    this.telephone,
    this.imageFileName,
    this.latitude,
    this.longitude,
    this.vehicule,
    this.noteMoyenne,
  });

  /// Usage interne uniquement — cet identifiant ne doit jamais
  /// apparaître à l'écran.
  final int id;

  final String  fullName;
  final String? telephone;
  final String? imageFileName;

  /// Position **actuelle** du coursier, pas celle qu'il occupait
  /// pendant la mission : le serveur renvoie la même sur toutes ses
  /// missions, y compris celles déjà terminées.
  final double? latitude;
  final double? longitude;

  /// Véhicule réellement utilisé — peut différer de celui demandé
  final String? vehicule;
  final double? noteMoyenne;

  factory Livreur.fromJson(Map<String, dynamic> json) => Livreur(
        id            : (json['id'] as num?)?.toInt() ?? 0,
        fullName      : json['fullName'] as String? ?? '',
        telephone     : json['telephone'] as String?,
        imageFileName : json['imageFileName'] as String?,
        latitude      : (json['latitude']  as num?)?.toDouble(),
        longitude     : (json['longitude'] as num?)?.toDouble(),
        vehicule      : json['vehicule'] as String?,
        noteMoyenne   : (json['noteMoyenne'] as num?)?.toDouble(),
      );

  String? get photoUrl {
    final f = imageFileName;
    if (f == null || f.isEmpty) return null;
    return f.startsWith('http') ? f : ApiConfig.getImageUrl(f);
  }

  bool get hasPosition => latitude != null && longitude != null;

  /// "AK" — repli quand la photo est absente ou ne charge pas
  String get initiales => fullName
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((m) => m.isNotEmpty ? m[0] : '')
      .join()
      .toUpperCase();
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

  /// Le coursier assigné — null tant qu'aucun n'a pris la mission
  final Livreur? livreur;

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
    this.livreur,
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

    // Le coursier est arrivé sous forme d'objet imbriqué ; certaines
    // réponses plus anciennes l'exposent encore à plat. On accepte
    // les deux plutôt que de perdre l'information.
    final brut = json['livreur'] as Map<String, dynamic>?;
    final livreur = brut != null
        ? Livreur.fromJson(brut)
        : (json['livreurFullName'] as String?)?.isNotEmpty == true
            ? Livreur(
                id            : 0,
                fullName      : json['livreurFullName'] as String,
                telephone     : json['livreurTelephone'] as String?,
                imageFileName : json['livreurProfile'] as String?
                                ?? json['livreurImage'] as String?,
                latitude      : (json['latitudeLivreur']  as num?)?.toDouble(),
                longitude     : (json['longitudeLivreur'] as num?)?.toDouble(),
              )
            : null;

    return LivraisonCourseModel(
      id                    : (json['id'] as num).toInt(),
      code                  : json['code'] as String? ?? '',
      typeService           : TypeServiceMission.from(
                                  json['typeService'] as String?),
      typeVehicule          : json['typeVehicule'] as String? ?? '',
      statut                : json['statut'] as String? ?? '',
      commandeStructureId   : (json['commandeStructureId'] as num?)?.toInt(),
      livreur               : livreur,
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
      livreur != null && livreur!.fullName.isNotEmpty;

  // ── Accès à plat, pour les écrans ────────────────────────────
  String? get livreurFullName  => livreur?.fullName;
  String? get livreurTelephone => livreur?.telephone;
  String? get livreurPhotoUrl  => livreur?.photoUrl;
  String? get livreurVehicule  => livreur?.vehicule;
  double? get livreurNote      => livreur?.noteMoyenne;
  double? get latitudeLivreur  => livreur?.latitude;
  double? get longitudeLivreur => livreur?.longitude;

  /// Le serveur renvoie la position **courante** du coursier sur
  /// toutes ses missions, terminées comprises. La placer sur une
  /// carte n'a de sens que tant que la mission est en cours.
  bool get hasLivreurPosition =>
      isEnCours && (livreur?.hasPosition ?? false);

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
