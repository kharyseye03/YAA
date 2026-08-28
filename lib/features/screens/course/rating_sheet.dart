import '../../../service/storage/notation_storage.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../service/api/api_service.dart';
import '../../../shared/widgets/widgets.dart';

/// Ouvre la notation du coursier à la fin d'une mission.
///
/// Le sheet ne se ferme ni au geste ni au bouton retour : on veut
/// que l'avis soit vu. Un « Plus tard » discret reste disponible pour
/// ne pas piéger l'utilisateur si l'envoi échoue.
Future<void> showRatingSheet(
    BuildContext context, LivraisonCourseModel mission) {
  return showModalBottomSheet<void>(
    context            : context,
    isScrollControlled : true,
    isDismissible      : false,
    enableDrag         : false,
    backgroundColor    : Colors.transparent,
    builder            : (_) => PopScope(
      canPop: false,
      child : _RatingSheet(mission: mission),
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.mission});
  final LivraisonCourseModel mission;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int  _note = 0;
  final Set<String> _tags = {};
  bool    _isSubmitting = false;
  String? _error;

  /// Libellé associé à la note choisie
  static const _libelles = {
    1: 'Très déçu',
    2: 'Décevant',
    3: 'Correct',
    4: 'Bien',
    5: 'Excellent',
  };

  /// Les propositions changent selon que l'expérience a été bonne
  /// ou mauvaise — inutile de proposer « Ponctuel » à 1 étoile.
  List<String> get _propositions => _note >= 4
      ? const ['Ponctuel', 'Aimable', 'Soigneux', 'Bonne communication',
               'Colis intact']
      : const ['En retard', 'Peu aimable', 'Colis abîmé',
               'Difficile à joindre', 'Mauvais itinéraire'];

  Future<void> _envoyer() async {
    if (_note == 0) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await ApiService().noterCoursier(
        livraisonCourseId : widget.mission.id,
        note              : _note,
      );
      // Retenu localement pour ne pas redemander le même avis depuis
      // le détail de la mission
      await NotationStorage.instance.marquerNotee(widget.mission.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error        = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m     = widget.mission;
    final photo = m.livreurPhotoUrl;

    return Container(
      decoration: const BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding, 20, AppDimens.screenPadding, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Avatar du coursier ────────────────────────
              Container(
                width  : 78,
                height : 78,
                decoration: BoxDecoration(
                  color : AppColors.primary,
                  shape : BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color      : AppColors.primary.withValues(alpha: 0.25),
                      blurRadius : 18,
                      offset     : const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photo != null
                      ? Image.network(photo,
                          width: 78, height: 78, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initiales())
                      : _initiales(),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Votre livraison est terminée',
                style: AppTextStyles.h3.copyWith(
                  fontWeight : FontWeight.w800,
                  color      : AppColors.dark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                m.hasLivreur
                    ? 'Comment s\'est passée votre course avec ${m.livreurFullName} ?'
                    : 'Comment s\'est passée votre course ?',
                textAlign : TextAlign.center,
                style     : AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey500, height: 1.4),
              ),

              const SizedBox(height: 22),

              // ── Étoiles ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valeur = i + 1;
                  final active = valeur <= _note;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _note = valeur;
                      // Les propositions changent de registre :
                      // on repart d'une sélection vierge
                      _tags.clear();
                    }),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration : const Duration(milliseconds: 150),
                      padding  : EdgeInsets.symmetric(
                          horizontal: 6, vertical: active ? 0 : 3),
                      child: Icon(
                        active ? Icons.star_rounded : Icons.star_outline_rounded,
                        size  : active ? 46 : 40,
                        color : active
                            ? const Color(0xFFFFC107)
                            : AppColors.grey300,
                      ),
                    ),
                  );
                }),
              ),

              // ── Libellé de la note ────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _note == 0
                    ? const SizedBox(height: 22)
                    : SizedBox(
                        key    : ValueKey(_note),
                        height : 22,
                        child  : Center(
                          child: Text(
                            _libelles[_note]!,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight : FontWeight.w700,
                              color      : AppColors.dark,
                            ),
                          ),
                        ),
                      ),
              ),

              // ── Propositions rapides ──────────────────────
              if (_note > 0) ...[
                const SizedBox(height: 14),
                Wrap(
                  alignment : WrapAlignment.center,
                  spacing   : 8,
                  runSpacing: 8,
                  children: _propositions.map((tag) {
                    final choisi = _tags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() {
                        choisi ? _tags.remove(tag) : _tags.add(tag);
                      }),
                      child: AnimatedContainer(
                        duration : const Duration(milliseconds: 150),
                        padding  : const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color : choisi
                              ? AppColors.primarySurface
                              : Colors.white,
                          borderRadius : BorderRadius.circular(
                              AppDimens.radiusFull),
                          border: Border.all(
                            color : choisi
                                ? AppColors.primary
                                : AppColors.grey200,
                            width : choisi ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.bodySmall.copyWith(
                            color      : choisi
                                ? AppColors.primary
                                : AppColors.grey600,
                            fontWeight : choisi
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // ── Erreur ────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width   : double.infinity,
                  padding : const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color        : AppColors.errorLight,
                    borderRadius : BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              YaaButton(
                label     : 'Envoyer mon avis',
                isLoading : _isSubmitting,
                onPressed : (_note == 0 || _isSubmitting) ? null : _envoyer,
              ),

              TextButton(
                onPressed : _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(
                  'Plus tard',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initiales() {
    final nom = widget.mission.livreurFullName ?? '';
    final ini = nom
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((m) => m.isNotEmpty ? m[0] : '')
        .join()
        .toUpperCase();
    return Container(
      color     : AppColors.primary,
      alignment : Alignment.center,
      child: ini.isEmpty
          ? const Icon(Icons.person_rounded, color: Colors.white, size: 34)
          : Text(
              ini,
              style: const TextStyle(
                fontFamily : 'PlusJakartaSans',
                fontSize   : 26,
                fontWeight : FontWeight.w800,
                color      : Colors.white,
              ),
            ),
    );
  }
}
