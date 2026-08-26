class CommandeModel {
  final int    id;
  final String structureName;
  final String structureAdresse;
  final String structureTelephone;
  final String referenceCommande;
  final String modeLivraison;
  /// LIVRAISON | RETRAIT_CLIENT
  final String modeReceptionCommande;
  final double montantTotal;
  final String description;
  final String adresseLivraison;
  final String telephoneClient;
  final String statut;

  /// MOTO | VEHICULE… Renvoyé par l'API mais absent du modèle
  /// jusqu'ici.
  final String? typeVehicule;

  /// Null tant que le backend n'a pas chiffré la livraison.
  final double? fraisLivraison;

  /// Indispensable pour trier cette liste avec celle des missions.
  final DateTime? createdDate;

  const CommandeModel({
    required this.id,
    required this.structureName,
    required this.structureAdresse,
    required this.structureTelephone,
    required this.referenceCommande,
    required this.modeLivraison,
    this.modeReceptionCommande = 'LIVRAISON',
    required this.montantTotal,
    required this.description,
    required this.adresseLivraison,
    required this.telephoneClient,
    required this.statut,
    this.typeVehicule,
    this.fraisLivraison,
    this.createdDate,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id                 : (json['id']                 as num).toInt(),
      structureName      : json['structureName']       as String? ?? '',
      structureAdresse   : json['structureAdresse']    as String? ?? '',
      structureTelephone : json['structureTelephone']  as String? ?? '',
      referenceCommande  : json['referenceCommande']   as String? ?? '',
      modeLivraison      : json['modeLivraison']       as String? ?? '',
      modeReceptionCommande :
          json['modeReceptionCommande'] as String? ?? 'LIVRAISON',
      montantTotal       : (json['montantTotal']       as num?)?.toDouble() ?? 0.0,
      description        : json['description']         as String? ?? '',
      adresseLivraison   : json['adresseLivraison']    as String? ?? '',
      telephoneClient    : json['telephoneClient']     as String? ?? '',
      statut             : json['statut']              as String? ?? '',
      typeVehicule       : json['typeVehicule']        as String?,
      fraisLivraison     : (json['fraisLivraison']     as num?)?.toDouble(),
      createdDate        :
          DateTime.tryParse(json['createdDate'] as String? ?? ''),
    );
  }

  /// Retourne true si la commande est encore active (pas terminée)
  bool get isEnCours =>
      statut != 'LIVRE' && statut != 'ANNULE' && statut != 'REJETE';
}
