import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';

/// Image distante avec cache disque et attente animée.
///
/// Remplace `Image.network` partout dans l'app, pour deux raisons :
///
/// **Le cache.** Le serveur renvoie les visuels en taille originale —
/// jusqu'à 3 Mo pour un logo affiché dans un rond de 44 px — et sans
/// en-tête `Cache-Control`. Sans cache local, chaque ouverture d'écran
/// les retélécharge intégralement.
///
/// **Le scintillement.** Un cadre vide qui attend donne l'impression
/// que l'app est bloquée. Le dégradé qui balaie annonce qu'il se passe
/// quelque chose, et occupe exactement la place que l'image prendra.
class ImageReseau extends StatelessWidget {
  const ImageReseau({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.shape = BoxShape.rectangle,
    this.fallback,
  });

  /// Null ou vide affiche directement le fallback, sans tentative réseau
  final String? url;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Arrondi appliqué à l'image comme à son attente. Ignoré si
  /// [shape] vaut circle.
  final double? radius;

  final BoxShape shape;

  /// Affiché si l'URL est absente ou si le chargement échoue.
  /// Sans lui, une icône grise neutre.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _repli();

    return CachedNetworkImage(
      imageUrl : url!,
      width    : width,
      height   : height,
      fit      : fit,
      // Le fondu évite l'apparition sèche quand l'image arrive vite
      fadeInDuration : const Duration(milliseconds: 220),
      placeholder    : (_, __) => _attente(),
      errorWidget    : (_, __, ___) => _repli(),
    );
  }

  Widget _attente() {
    return Shimmer.fromColors(
      baseColor      : AppColors.grey200,
      highlightColor : AppColors.grey100,
      period         : const Duration(milliseconds: 1400),
      child: Container(
        width  : width,
        height : height,
        decoration: BoxDecoration(
          color        : AppColors.grey200,
          shape        : shape,
          borderRadius : shape == BoxShape.circle || radius == null
              ? null
              : BorderRadius.circular(radius!),
        ),
      ),
    );
  }

  Widget _repli() {
    if (fallback != null) return fallback!;
    return Container(
      width  : width,
      height : height,
      decoration: BoxDecoration(
        color        : AppColors.grey100,
        shape        : shape,
        borderRadius : shape == BoxShape.circle || radius == null
            ? null
            : BorderRadius.circular(radius!),
      ),
      child: Icon(
        Icons.image_outlined,
        color : AppColors.grey400,
        size  : _tailleIcone,
      ),
    );
  }

  /// L'icône suit la taille du cadre : une icône de 24 px dans une
  /// vignette de 40 px la remplit entièrement.
  double get _tailleIcone {
    final cote = (width ?? height ?? 48);
    return (cote * 0.4).clamp(14.0, 40.0);
  }
}
