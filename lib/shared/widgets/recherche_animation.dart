import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// Attente animée : un véhicule qui avance sur une piste pointillée,
/// sous un titre dont les points de suspension défilent.
///
/// Extrait du suivi post-paiement pour être partagé : le détail d'une
/// mission affiche la même chose pendant `RECHERCHE_COURSIER`. Deux
/// copies auraient fini par diverger.
class RechercheAnimation extends StatefulWidget {
  const RechercheAnimation({
    super.key,
    required this.titre,
    required this.message,
    this.icone = Icons.sports_motorsports,
  });

  /// Sans point final : ils sont ajoutés et animés
  final String titre;

  /// Phrase rassurante sous l'animation. Vide pour ne rien afficher.
  final String message;

  final IconData icone;

  @override
  State<RechercheAnimation> createState() => _RechercheAnimationState();
}

class _RechercheAnimationState extends State<RechercheAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync    : this,
    duration : const Duration(milliseconds: 4500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                Text(
                  '${widget.titre}'
                  '${'.' * ((_controller.value * 3).floor() + 1)}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
                SizedBox(height: AppDimens.xxl),
                SizedBox(
                  height: 56,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final piste = constraints.maxWidth - 48;
                      return Stack(
                        children: [
                          // Piste pointillée
                          Positioned(
                            left  : 0,
                            right : 0,
                            top   : 27,
                            child: Row(
                              children: List.generate(
                                20,
                                (_) => Expanded(
                                  child: Container(
                                    height : 2,
                                    margin : const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    color  : AppColors.grey200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Le véhicule qui avance
                          Positioned(
                            left : piste * _controller.value,
                            top  : 4,
                            child: Container(
                              width  : 48,
                              height : 48,
                              decoration: BoxDecoration(
                                color : AppColors.primary,
                                shape : BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius : 12,
                                    offset     : const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(widget.icone,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        if (widget.message.isNotEmpty) ...[
          SizedBox(height: AppDimens.xl),
          Container(
            width   : double.infinity,
            padding : const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color        : AppColors.grey100,
              borderRadius : BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Text(
              widget.message,
              textAlign : TextAlign.center,
              style     : AppTextStyles.bodySmall.copyWith(
                color  : AppColors.textSoft,
                height : 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
