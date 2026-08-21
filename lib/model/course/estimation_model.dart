import '../../core/utils/devise.dart';

/// Réponse de POST /livraisons-courses/estimation
class EstimationModel {
  final int    distanceMetres;
  final double distanceKm;
  final String distanceText;   // ex: "6.9 km"
  final int    dureeSecondes;
  final int    dureeMinutes;
  final String dureeText;      // ex: "16 mins"
  final String estimation;     // ex: "16 mins (6.9 km)"
  final double fraisLivraison;
  final String devise;         // ex: "FCFA"
  /// Présent sur l'estimation d'une course : MOTO | VEHICULE
  final String? typeVehicule;

  const EstimationModel({
    required this.distanceMetres,
    required this.distanceKm,
    required this.distanceText,
    required this.dureeSecondes,
    required this.dureeMinutes,
    required this.dureeText,
    required this.estimation,
    required this.fraisLivraison,
    required this.devise,
    this.typeVehicule,
  });

  factory EstimationModel.fromJson(Map<String, dynamic> json) {
    return EstimationModel(
      distanceMetres : (json['distanceMetres'] as num?)?.toInt()    ?? 0,
      distanceKm     : (json['distanceKm']     as num?)?.toDouble() ?? 0,
      distanceText   : json['distanceText']    as String? ?? '',
      dureeSecondes  : (json['dureeSecondes']  as num?)?.toInt()    ?? 0,
      dureeMinutes   : (json['dureeMinutes']   as num?)?.toInt()    ?? 0,
      dureeText      : json['dureeText']       as String? ?? '',
      estimation     : json['estimation']      as String? ?? '',
      fraisLivraison : (json['fraisLivraison'] as num?)?.toDouble() ?? 0,
      devise         : json['devise']          as String? ?? kDevise,
      // Le backend a renommé ce champ : on accepte les deux noms
      typeVehicule   : json['typeVehicule'] as String?
                       ?? json['typeVehiculeTarification'] as String?,
    );
  }

  /// Prix formaté : "2 500 F"
  String get prixLabel => montantLabel(fraisLivraison);

  /// Prix avec la devise renvoyée par le serveur : "2 500 FCFA".
  /// On affiche celle qu'il envoie plutôt qu'un symbole codé en dur —
  /// c'est aussi ce qui rend visibles ses incohérences.
  String get prixDevise => '${formaterMontant(fraisLivraison)} $devise';

  /// Métadonnées : "6.9 km · 16 mins"
  String get metaLabel => '$distanceText · $dureeText';
}

