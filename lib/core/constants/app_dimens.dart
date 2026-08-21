/// Centralized spacing, sizing, and dimension constants.
abstract final class AppDimens {
  // ── Spacing ──────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // ── Padding ──────────────────────────────────────────────
  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double listItemPadding = 12.0;

  // ── Border Radius ────────────────────────────────────────
  // Échelle reprise de yaagn.com (--radius-sm/md/lg). Le site est
  // volontairement peu arrondi : c'est ce qui lui donne son côté net.
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  /// Cartes mises en avant et bottom sheets — l'exception assumée
  static const double radiusXl = 24.0;
  /// Pilule : la forme de tous les boutons du site
  static const double radiusFull = 999.0;

  // ── Icon Sizes ───────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // ── Button Heights ───────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;

  // ── Image Sizes ──────────────────────────────────────────
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 80.0;

  // ── Bottom Nav ───────────────────────────────────────────
  static const double bottomNavHeight = 72.0;

  // ── Misc ─────────────────────────────────────────────────
  static const double dividerThickness = 1.0;
  static const double cardElevation = 2.0;
}
