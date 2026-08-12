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
  final double structureLatitude;
  final double structureLongitude;
  final String referenceCommande;
  final String modeLivraison;
  /// LIVRAISON | RETRAIT_CLIENT
  final String modeReceptionCommande;
  final double montantTotal;
  final String description;
  final String? livreurName;
  final String? livreurLastName;
  final String? livreurTelephone;
  final String? livreurImage;
  final String statut;
  final String adresseLivraison;
  final double latitudeLivraison;
  final double longitudeLivraison;
  final String telephoneClient;
  final List<CommandeProduit> commandeProduits;

  const CommandeDetailModel({
    required this.id,
    required this.structureName,
    required this.structureAdresse,
    required this.structureTelephone,
    this.structureLatitude  = 0,
    this.structureLongitude = 0,
    required this.referenceCommande,
    required this.modeLivraison,
    this.modeReceptionCommande = 'LIVRAISON',
    required this.montantTotal,
    required this.description,
    this.livreurName,
    this.livreurLastName,
    this.livreurTelephone,
    this.livreurImage,
    required this.statut,
    this.adresseLivraison   = '',
    this.latitudeLivraison  = 0,
    this.longitudeLivraison = 0,
    this.telephoneClient    = '',
    required this.commandeProduits,
  });

  /// Nom complet du livreur
  String? get livreurFullName {
    if (livreurName == null) return null;
    final last = livreurLastName ?? '';
    return '$livreurName $last'.trim();
  }

  bool get hasLivreur => livreurName != null && livreurName!.isNotEmpty;

  /// URL complète de la photo du livreur (null si pas de photo)
  String? get livreurImageUrl {
    final img = livreurImage;
    if (img == null || img.isEmpty) return null;
    return img.startsWith('http') ? img : ApiConfig.getImageUrl(img);
  }

  factory CommandeDetailModel.fromJson(Map<String, dynamic> json) {
    final produits = json['commandeProduits'] as List<dynamic>? ?? [];
    return CommandeDetailModel(
      id                : (json['id'] as num).toInt(),
      structureName     : json['structureName']      as String? ?? '',
      structureAdresse  : json['structureAdresse']   as String? ?? '',
      structureTelephone: json['structureTelephone'] as String? ?? '',
      structureLatitude : (json['structurelatitude']  as num?)?.toDouble() ?? 0,
      structureLongitude: (json['structurelongitude'] as num?)?.toDouble() ?? 0,
      referenceCommande : json['referenceCommande']  as String? ?? '',
      modeLivraison     : json['modeLivraison']      as String? ?? '',
      modeReceptionCommande :
          json['modeReceptionCommande'] as String? ?? 'LIVRAISON',
      montantTotal      : (json['montantTotal']      as num?)?.toDouble() ?? 0.0,
      description       : json['description']        as String? ?? '',
      livreurName       : json['livreurName']        as String?,
      livreurLastName   : json['livreurLastName']    as String?,
      livreurTelephone  : json['livreurTelephone']   as String?,
      livreurImage      : json['livreurImage']       as String?,
      statut            : json['statut']             as String? ?? '',
      adresseLivraison  : json['adresseLivraison']   as String? ?? '',
      latitudeLivraison : (json['latitudeLivraison']  as num?)?.toDouble() ?? 0,
      longitudeLivraison: (json['longitudeLivraison'] as num?)?.toDouble() ?? 0,
      telephoneClient   : json['telephoneClient']    as String? ?? '',
      commandeProduits  : produits
          .map((e) => CommandeProduit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
