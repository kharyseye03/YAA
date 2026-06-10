import '../../config/api/api_config.dart';

class CommandeProduit {
  final int    produitId;
  final String nom;
  final String? image;
  final int    quantite;
  final double prixUnitaire;
  final double prixTotal;

  const CommandeProduit({
    required this.produitId,
    required this.nom,
    this.image,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixTotal,
  });

  String? get imageUrl =>
      image != null ? ApiConfig.getImageUrl(image!) : null;

  factory CommandeProduit.fromJson(Map<String, dynamic> json) {
    return CommandeProduit(
      produitId    : (json['produitId']    as num).toInt(),
      nom          : json['nom']           as String? ?? '',
      image        : json['image']         as String?,
      quantite     : (json['quantite']     as num?)?.toInt()    ?? 1,
      prixUnitaire : (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
      prixTotal    : (json['prixTotal']    as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CommandeDetailModel {
  final int    id;
  final String structureName;
  final String structureAdresse;
  final String structureTelephone;
  final String referenceCommande;
  final String modeLivraison;
  final double montantTotal;
  final String description;
  final String? livreurName;
  final String? livreurLastName;
  final String? livreurTelephone;
  final String statut;
  final List<CommandeProduit> commandeProduits;

  const CommandeDetailModel({
    required this.id,
    required this.structureName,
    required this.structureAdresse,
    required this.structureTelephone,
    required this.referenceCommande,
    required this.modeLivraison,
    required this.montantTotal,
    required this.description,
    this.livreurName,
    this.livreurLastName,
    this.livreurTelephone,
    required this.statut,
    required this.commandeProduits,
  });

  /// Nom complet du livreur
  String? get livreurFullName {
    if (livreurName == null) return null;
    final last = livreurLastName ?? '';
    return '$livreurName $last'.trim();
  }

  bool get hasLivreur => livreurName != null && livreurName!.isNotEmpty;

  factory CommandeDetailModel.fromJson(Map<String, dynamic> json) {
    final produits = json['commandeProduits'] as List<dynamic>? ?? [];
    return CommandeDetailModel(
      id                : (json['id'] as num).toInt(),
      structureName     : json['structureName']      as String? ?? '',
      structureAdresse  : json['structureAdresse']   as String? ?? '',
      structureTelephone: json['structureTelephone'] as String? ?? '',
      referenceCommande : json['referenceCommande']  as String? ?? '',
      modeLivraison     : json['modeLivraison']      as String? ?? '',
      montantTotal      : (json['montantTotal']      as num?)?.toDouble() ?? 0.0,
      description       : json['description']        as String? ?? '',
      livreurName       : json['livreurName']        as String?,
      livreurLastName   : json['livreurLastName']    as String?,
      livreurTelephone  : json['livreurTelephone']   as String?,
      statut            : json['statut']             as String? ?? '',
      commandeProduits  : produits
          .map((e) => CommandeProduit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
