import '../../../model/category/categorie_produit.dart';
import '../../../model/category/structure.dart';

/// Ordre d'affichage des établissements
enum TriStructures {
  recommande('Recommandé'),
  mieuxNotes('Mieux notés'),
  plusRapides('Plus rapides');

  const TriStructures(this.libelle);
  final String libelle;
}

/// Extrait une durée en minutes d'un libellé du backend.
///
/// « 25 min » → 25 · « 25-40 min » → 40 (on retient le pire cas,
/// c'est ce que l'utilisateur veut plafonner). Renvoie null si le
/// libellé ne contient aucun chiffre.
int? minutesLivraison(String libelle) {
  final nombres = RegExp(r'\d+')
      .allMatches(libelle)
      .map((m) => int.parse(m.group(0)!))
      .toList();
  if (nombres.isEmpty) return null;
  return nombres.reduce((a, b) => a > b ? a : b);
}

/// Critères de filtrage de l'écran Catégorie.
///
/// La catégorie de produit est envoyée au backend (paramètre
/// `specialite`) ; la note, le temps et le tri s'appliquent côté
/// client sur la liste renvoyée — l'API ne les gère pas encore.
class CategoryFilters {
  const CategoryFilters({
    this.categorie,
    this.noteMin = 0,
    this.tempsMax,
    this.tri = TriStructures.recommande,
  });

  /// Catégorie de produit choisie — null signifie « Tous »
  final CategorieProduit? categorie;

  /// Note minimale en étoiles — 0 signifie « toutes »
  final int noteMin;

  /// Temps de livraison maximum en minutes — null signifie « peu importe »
  final int? tempsMax;

  final TriStructures tri;

  /// Nombre de critères actifs **hors catégorie** : celle-ci a déjà
  /// sa puce visible dans la barre, inutile de la compter deux fois.
  /// Alimente la pastille du bouton « Filtres ».
  int get nbCriteres =>
      (noteMin > 0 ? 1 : 0) +
      (tempsMax != null ? 1 : 0) +
      (tri != TriStructures.recommande ? 1 : 0);

  bool get estVierge => categorie == null && nbCriteres == 0;

  /// `copyWith` ne peut pas remettre un champ à null — d'où les
  /// drapeaux `effacer…` pour les critères optionnels.
  CategoryFilters copyWith({
    CategorieProduit? categorie,
    bool effacerCategorie = false,
    int? noteMin,
    int? tempsMax,
    bool effacerTempsMax = false,
    TriStructures? tri,
  }) {
    return CategoryFilters(
      categorie : effacerCategorie ? null : (categorie ?? this.categorie),
      noteMin   : noteMin ?? this.noteMin,
      tempsMax  : effacerTempsMax ? null : (tempsMax ?? this.tempsMax),
      tri       : tri ?? this.tri,
    );
  }

  /// Applique les critères côté client. L'ordre « Recommandé »
  /// préserve celui du serveur, qui place les plus pertinents en tête.
  List<Structure> appliquer(List<Structure> source) {
    final resultat = source.where((s) {
      if (noteMin > 0 && s.nombreEtoile < noteMin) return false;
      if (tempsMax != null) {
        final minutes = minutesLivraison(s.tempsLivraison);
        // Temps inconnu → on garde l'établissement plutôt que de
        // le faire disparaître sur une donnée manquante
        if (minutes != null && minutes > tempsMax!) return false;
      }
      return true;
    }).toList();

    switch (tri) {
      case TriStructures.recommande:
        break;
      case TriStructures.mieuxNotes:
        resultat.sort((a, b) => b.nombreEtoile.compareTo(a.nombreEtoile));
      case TriStructures.plusRapides:
        resultat.sort((a, b) {
          final ma = minutesLivraison(a.tempsLivraison) ?? 9999;
          final mb = minutesLivraison(b.tempsLivraison) ?? 9999;
          return ma.compareTo(mb);
        });
    }
    return resultat;
  }
}
