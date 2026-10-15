import '../../config/api/api_config.dart';

/// Une bannière du carrousel de l'accueil, telle que la renvoie
/// `/bannieres/mobile/groupes`.
class BanniereModel {
  const BanniereModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.cliquable,
    this.imageFileName,
    this.imageFullscreenFileName,
    this.structureId,
  });

  final int     id;
  final String  type;
  final String  titre;
  final String  description;

  /// À false, la bannière n'ouvre pas de fiche. Décidé par le serveur
  /// et suivi tel quel.
  final bool    cliquable;

  /// Visuel large, pour la carte de l'accueil.
  final String? imageFileName;

  /// Visuel vertical, pour la page plein écran.
  ///
  /// Pas encore fourni par le serveur : en son absence on réutilise
  /// [imageFileName], qui est au format paysage et sera donc recadré
  /// en hauteur. Le jour où le champ arrive, il n'y a rien à changer
  /// ici.
  final String? imageFullscreenFileName;

  /// Établissement à ouvrir quand [cliquable] est vrai.
  final int?    structureId;

  String? get imageUrl => _url(imageFileName);

  String? get imageFullscreenUrl =>
      _url(imageFullscreenFileName) ?? _url(imageFileName);

  static String? _url(String? nom) =>
      (nom == null || nom.isEmpty) ? null : ApiConfig.getImageUrl(nom);

  factory BanniereModel.fromJson(Map<String, dynamic> json, String type) {
    return BanniereModel(
      id          : json['id'] as int,
      type        : type,
      titre       : json['title'] as String? ?? '',
      description : json['description'] as String? ?? '',
      // Absent du JSON, la bannière n'est pas cliquable : mieux vaut un
      // toucher sans effet qu'une navigation vers nulle part.
      cliquable   : json['cliquable'] as bool? ?? false,
      imageFileName           : json['imageFileName'] as String?,
      imageFullscreenFileName : json['imageFullscreenFileName'] as String?,
      structureId             : json['structureId'] as int?,
    );
  }
}

/// Les bannières d'un même type, dans l'ordre voulu par le serveur.
///
/// Le groupe est l'unité d'affichage, pas la bannière : l'accueil en
/// montre **une seule carte par type**, celle de [principale], et les
/// autres n'apparaissent qu'en plein écran, à la manière des stories.
/// C'est ce qui permet au backend d'en ajouter autant qu'il veut sans
/// que l'accueil s'allonge.
class GroupeBannieres {
  const GroupeBannieres({required this.type, required this.bannieres});

  final String type;
  final List<BanniereModel> bannieres;

  BanniereModel get principale => bannieres.first;

  /// Vrai dès qu'il y a de quoi faire défiler : c'est ce qui décide
  /// d'afficher la barre segmentée en haut de la page plein écran.
  bool get plusieurs => bannieres.length > 1;

  factory GroupeBannieres.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final liste = (json['bannieres'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((b) => BanniereModel.fromJson(b, type))
        .toList();
    return GroupeBannieres(type: type, bannieres: liste);
  }

  /// Groupes exploitables : un groupe sans aucune bannière n'a rien à
  /// montrer et disparaît du carrousel.
  static List<GroupeBannieres> depuisReponse(List<dynamic> data) => data
      .whereType<Map<String, dynamic>>()
      .map(GroupeBannieres.fromJson)
      .where((g) => g.bannieres.isNotEmpty)
      .toList();
}
