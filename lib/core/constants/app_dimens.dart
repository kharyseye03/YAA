import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Espacements, tailles et rayons de l'application.
///
/// Toutes les valeurs passent par ScreenUtil : elles sont exprimées
/// dans la taille de référence déclarée au démarrage (375 × 812) puis
/// mises à l'échelle selon l'écran réel. Un padding de 20 devient donc
/// plus serré sur un petit téléphone et plus large sur une tablette.
///
/// ⚠️ Ce sont des **getters**, plus des constantes : leur valeur
/// dépend de l'écran, elle ne peut pas être connue à la compilation.
/// D'où l'absence de `const` devant les widgets qui les utilisent.
///
/// Le suffixe choisi compte :
/// - `.r` pour tout ce qui doit rester proportionné dans les deux sens
///   (espacements, rayons, icônes) — évite les formes déformées ;
/// - `.h` pour les hauteurs qui doivent suivre la verticale ;
/// - `.sp` réservé au texte, dans AppTextStyles.
abstract final class AppDimens {
  // ── Espacements ──────────────────────────────────────────
  static double get xs   => 4.r;
  static double get sm   => 8.r;
  static double get md   => 12.r;
  static double get lg   => 16.r;
  static double get xl   => 20.r;
  static double get xxl  => 24.r;
  static double get xxxl => 32.r;
  static double get huge => 48.r;

  // ── Marges intérieures ───────────────────────────────────
  static double get screenPadding   => 20.r;
  static double get cardPadding     => 16.r;
  static double get listItemPadding => 12.r;

  // ── Rayons ───────────────────────────────────────────────
  // Échelle reprise de yaagn.com (--radius-sm/md/lg). Le site est
  // volontairement peu arrondi : c'est ce qui lui donne son côté net.
  static double get radiusSm => 6.r;
  static double get radiusMd => 8.r;
  static double get radiusLg => 12.r;

  /// Cartes mises en avant et bottom sheets — l'exception assumée
  static double get radiusXl => 24.r;

  /// Pilule : la forme de tous les boutons du site. Volontairement
  /// non mis à l'échelle — au-delà de la moitié de la hauteur, la
  /// forme ne change plus, autant garder une valeur stable.
  static const double radiusFull = 999.0;

  // ── Tailles d'icônes ─────────────────────────────────────
  static double get iconSm => 16.r;
  static double get iconMd => 20.r;
  static double get iconLg => 24.r;
  static double get iconXl => 32.r;

  // ── Hauteurs de bouton ───────────────────────────────────
  static double get buttonHeight   => 52.h;
  static double get buttonHeightSm => 40.h;

  // ── Tailles d'avatar ─────────────────────────────────────
  static double get avatarSm => 32.r;
  static double get avatarMd => 48.r;
  static double get avatarLg => 64.r;
  static double get avatarXl => 80.r;

  // ── Barre de navigation ──────────────────────────────────
  static double get bottomNavHeight => 72.h;

  // ── Divers ───────────────────────────────────────────────
  // Une bordure d'un pixel doit rester d'un pixel : la mettre à
  // l'échelle la ferait disparaître ou doubler selon l'écran.
  static const double dividerThickness = 1.0;
  static const double cardElevation    = 2.0;
}
