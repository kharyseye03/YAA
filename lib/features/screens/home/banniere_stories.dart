import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/banniere/banniere_model.dart';
import '../../../shared/widgets/image_reseau.dart';

/// Les bannières d'un type, en plein écran, à la manière des stories.
///
/// L'accueil ne montre qu'une carte par type ; les bannières suivantes
/// du même groupe vivent ici. Le backend peut donc en publier autant
/// qu'il veut sans que la page d'accueil s'allonge — c'est tout
/// l'intérêt du procédé.
///
/// Geste attendu de tous : la moitié droite avance, la gauche recule,
/// un doigt maintenu met en pause, et chaque page défile seule au bout
/// de [_duree]. La barre du haut, segmentée, dit d'un coup d'œil
/// combien il en reste.
Future<void> showBanniereStories(
  BuildContext context,
  GroupeBannieres groupe,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque          : false,
      barrierColor    : Colors.black,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder     : (_, __, ___) => _Stories(groupe: groupe),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Durée d'affichage d'une bannière avant de passer à la suivante.
const _duree = Duration(seconds: 6);

class _Stories extends StatefulWidget {
  const _Stories({required this.groupe});

  final GroupeBannieres groupe;

  @override
  State<_Stories> createState() => _StoriesState();
}

class _StoriesState extends State<_Stories>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progression;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _progression = AnimationController(vsync: this, duration: _duree)
      ..addStatusListener((statut) {
        if (statut == AnimationStatus.completed) _suivante();
      });
    _demarrer();
  }

  @override
  void dispose() {
    _progression.dispose();
    super.dispose();
  }

  void _demarrer() => _progression
    ..reset()
    ..forward();

  void _suivante() {
    if (_index >= widget.groupe.bannieres.length - 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _index++);
    _demarrer();
  }

  void _precedente() {
    // Sur la première, on redémarre plutôt que de fermer : un retour
    // en arrière ne doit jamais faire sortir.
    if (_index == 0) {
      _demarrer();
      return;
    }
    setState(() => _index--);
    _demarrer();
  }

  @override
  Widget build(BuildContext context) {
    final banniere = widget.groupe.bannieres[_index];
    final largeur  = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Pause tant que le doigt touche l'écran : on lit un texte
        // sans courir après le minuteur.
        onTapDown   : (_) => _progression.stop(),
        onTapCancel : () => _progression.forward(),
        onTapUp: (details) {
          if (details.globalPosition.dx < largeur / 3) {
            _precedente();
          } else {
            _suivante();
          }
        },
        // Balayage vers le bas pour fermer, comme partout ailleurs.
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) {
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Visuel ────────────────────────────────────────
            ImageReseau(
              url      : banniere.imageFullscreenUrl,
              fit      : BoxFit.cover,
              fallback : Container(color: AppColors.primary),
            ),

            // Dégradé : le texte blanc doit rester lisible quelle que
            // soit l'image, claire ou sombre.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin : Alignment.topCenter,
                  end   : Alignment.bottomCenter,
                  colors: [
                    Color(0xB3000000),
                    Color(0x33000000),
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),

            // ── Barre segmentée ───────────────────────────────
            Positioned(
              top   : MediaQuery.of(context).padding.top + 10,
              left  : AppDimens.screenPadding,
              right : AppDimens.screenPadding,
              child: _BarreSegments(
                total       : widget.groupe.bannieres.length,
                index       : _index,
                progression : _progression,
              ),
            ),

            // ── Fermer ────────────────────────────────────────
            Positioned(
              top   : MediaQuery.of(context).padding.top + 28,
              right : AppDimens.screenPadding - 4,
              child: IconButton(
                onPressed : () => Navigator.of(context).maybePop(),
                icon      : const Icon(Icons.close_rounded,
                    color: Colors.white, size: 26),
                tooltip   : 'Fermer',
              ),
            ),

            // ── Texte ─────────────────────────────────────────
            Positioned(
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              bottom : MediaQuery.of(context).padding.bottom + 48.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banniere.titre.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2.copyWith(
                      color      : Colors.white,
                      fontWeight : FontWeight.w800,
                      height     : 1.15,
                      fontSize   : 26.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    banniere.description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color  : Colors.white.withValues(alpha: 0.92),
                      height : 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les segments du haut : un par bannière, rempli pour celles déjà
/// vues, en cours de remplissage pour la courante, vide pour la suite.
class _BarreSegments extends StatelessWidget {
  const _BarreSegments({
    required this.total,
    required this.index,
    required this.progression,
  });

  final int total;
  final int index;
  final Animation<double> progression;

  @override
  Widget build(BuildContext context) {
    // Un seul segment n'apprend rien : on le masque plutôt que
    // d'afficher une barre pleine largeur qui ne bouge pas.
    if (total < 2) return const SizedBox.shrink();

    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            height : 2.5,
            margin : EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color        : Colors.white.withValues(alpha: 0.35),
              borderRadius : BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: i < index
                  ? const _Rempli(1)
                  : i > index
                      ? const SizedBox.shrink()
                      : AnimatedBuilder(
                          animation: progression,
                          builder: (_, __) => _Rempli(progression.value),
                        ),
            ),
          ),
        );
      }),
    );
  }
}

class _Rempli extends StatelessWidget {
  const _Rempli(this.fraction);

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: fraction.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.circular(2),
        ),
      ),
    );
  }
}
