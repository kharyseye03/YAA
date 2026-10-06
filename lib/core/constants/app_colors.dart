import 'dart:ui';

/// Palette de YAA, alignée sur les variables CSS de yaagn.com.
///
/// Les valeurs viennent du site, pas d'un relevé à l'œil : l'app et le
/// site doivent afficher exactement les mêmes couleurs, sinon l'écart
/// se perçoit sans qu'on sache le nommer.
abstract final class AppColors {
  // ── Marque ───────────────────────────────────────────────
  /// --brand-navy — relevé sur le logo officiel, plus saturé que la
  /// valeur du site (#102033) qui ne correspondait pas au lettrage.
  static const Color primary = Color(0xFF001553);
  /// --brand-navy-2
  static const Color primaryLight = Color(0xFF123457);
  /// --blue-deep
  static const Color primaryDark = Color(0xFF07111F);
  /// --blue-soft
  static const Color primarySurface = Color(0xFFEEF3F8);

  /// --brand-orange
  static const Color secondary = Color(0xFFFF6608);
  /// --brand-orange-hover
  static const Color secondaryDark = Color(0xFFDD6808);
  /// Fin du dégradé des cartes de service : plus profond que
  /// secondaryDark, pour que le blanc du texte tienne jusqu'en bas.
  static const Color secondaryDeep = Color(0xFFCC4400);
  /// --brand-orange-soft
  static const Color secondaryLight = Color(0xFFFFF3E8);

  // ── Texte ────────────────────────────────────────────────
  /// --ink — titres et texte principal
  static const Color dark = Color(0xFF101B2D);
  /// --ink-soft — texte courant
  static const Color textSoft = Color(0xFF4D5F73);
  /// --ink-muted — mentions discrètes
  static const Color textMuted = Color(0xFF8290A3);

  // ── Neutres ──────────────────────────────────────────────
  // Conservés pour les écrans pas encore repris ; préférer
  // dark / textSoft / textMuted et border pour tout nouveau code.
  static const Color black = Color(0xFF000000);
  static const Color grey900 = Color(0xFF101B2D);
  static const Color grey800 = Color(0xFF2A3A4F);
  static const Color grey700 = Color(0xFF3D4E62);
  static const Color grey600 = Color(0xFF4D5F73);
  static const Color grey500 = Color(0xFF8290A3);
  static const Color grey400 = Color(0xFFB9C8D9);
  static const Color grey300 = Color(0xFFDBE4EF);
  static const Color grey200 = Color(0xFFE5EAF1);
  static const Color grey100 = Color(0xFFF4F7FB);
  static const Color white = Color(0xFFFFFFFF);

  // ── Fonds et bordures ────────────────────────────────────
  /// --surface-page
  static const Color background = Color(0xFFF4F7FB);
  /// --surface-card
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffold = Color(0xFFF4F7FB);
  /// --surface-soft
  static const Color surfaceSoft = Color(0xFFFBFCFF);
  /// --border
  static const Color border = Color(0xFFDBE4EF);
  /// --border-strong
  static const Color borderStrong = Color(0xFFB9C8D9);

  // ── Sémantique ───────────────────────────────────────────
  /// --success
  static const Color success = Color(0xFF168043);
  /// --success-soft
  static const Color successLight = Color(0xFFE9F8EE);
  /// --warning
  static const Color warning = Color(0xFFC76800);
  /// --brand-orange-soft, réutilisé comme fond d'avertissement
  static const Color warningLight = Color(0xFFFFF3E8);
  /// --danger
  static const Color error = Color(0xFF9B1C1C);
  /// --danger-soft
  static const Color errorLight = Color(0xFFFFF0F0);
  static const Color info = primary;
  static const Color infoLight = primarySurface;

  /// Cœur d'un favori actif. Volontairement distincte de [error] :
  /// un favori est une marque d'attachement, pas un avertissement.
  static const Color favori = Color(0xFFFF4D6D);

  // ── Couleurs de catégorie ────────────────────────────────
  // Alias, jamais de littéral : ces couleurs reprennent la palette de
  // marque. Dupliquer la valeur hexa ferait diverger les écrans dès
  // qu'on retouche une teinte.
  static const Color restaurant  = secondary;
  static const Color pharmacy    = success;
  static const Color boutique    = primaryLight;
  static const Color supermarket = primary;

  static const Color catRestaurant   = restaurant;
  static const Color catPharmacie    = pharmacy;
  static const Color catBoutique     = boutique;
  static const Color catSupermarche  = supermarket;
}
