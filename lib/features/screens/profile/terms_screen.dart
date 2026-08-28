import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import 'terms_content.dart';

/// Conditions Générales d'Utilisation.
///
/// Le contenu vit dans terms_content.dart : cet écran ne fait que le
/// mettre en forme, ce qui permet de faire relire le texte par un
/// juriste sans toucher au code.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Header(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding, 20,
                  AppDimens.screenPadding, 40),
              children: [
                const _Chapeau(),
                const SizedBox(height: 24),
                const _Resume(),
                const SizedBox(height: 28),
                for (final section in kSections) ...[
                  _Section(section: section),
                  const SizedBox(height: 26),
                ],
                const _PiedDePage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── En-tête ──────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top    : MediaQuery.of(context).padding.top + 12,
        left   : AppDimens.screenPadding,
        right  : AppDimens.screenPadding,
        bottom : 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap    : () => Navigator.of(context).pop(),
            behavior : HitTestBehavior.opaque,
            child: Container(
              width  : 38,
              height : 38,
              decoration: BoxDecoration(
                color        : AppColors.grey100,
                borderRadius : BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.dark, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Conditions d\'utilisation',
            style: AppTextStyles.h3.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chapeau : titre + version ────────────────────────────────
class _Chapeau extends StatelessWidget {
  const _Chapeau();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conditions Générales\nd\'Utilisation',
          style: AppTextStyles.h1.copyWith(
            fontSize   : 26,
            fontWeight : FontWeight.w800,
            color      : AppColors.dark,
            height     : 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Etiquette(texte: 'Version $kVersionCgu'),
            const SizedBox(width: 8),
            _Etiquette(texte: 'Mise à jour : $kDerniereMaj'),
          ],
        ),
      ],
    );
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color        : AppColors.grey100,
        borderRadius : BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(
        texte,
        style: AppTextStyles.caption.copyWith(
          color      : AppColors.grey600,
          fontWeight : FontWeight.w600,
        ),
      ),
    );
  }
}

// ── L'essentiel ──────────────────────────────────────────────
class _Resume extends StatelessWidget {
  const _Resume();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color        : AppColors.primarySurface,
        borderRadius : BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'L\'essentiel',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w800,
                  color      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final point in kResume) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin : const EdgeInsets.only(top: 7, right: 10),
                  width  : 5,
                  height : 5,
                  decoration: const BoxDecoration(
                    color : AppColors.primary,
                    shape : BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: AppTextStyles.bodySmall.copyWith(
                      color  : AppColors.grey700,
                      height : 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Une section ──────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.section});
  final TermsSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre : numéro dans une pastille + intitulé
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width  : 28,
              height : 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color        : AppColors.primary,
                borderRadius : BorderRadius.circular(8),
              ),
              child: Text(
                section.numero,
                style: AppTextStyles.caption.copyWith(
                  color      : Colors.white,
                  fontWeight : FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  section.titre,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize   : 16,
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                    height     : 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final bloc in section.blocs) ...[
          _Bloc(bloc: bloc),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Bloc extends StatelessWidget {
  const _Bloc({required this.bloc});
  final TermsBloc bloc;

  @override
  Widget build(BuildContext context) {
    return switch (bloc) {
      Paragraphe(:final texte) => Text(
          texte,
          textAlign: TextAlign.justify,
          style: AppTextStyles.bodySmall.copyWith(
            color  : AppColors.grey700,
            height : 1.65,
          ),
        ),

      Puces(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin : const EdgeInsets.only(top: 8, right: 10),
                      width  : 5,
                      height : 5,
                      decoration: BoxDecoration(
                        color        : AppColors.grey400,
                        borderRadius : BorderRadius.circular(1),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodySmall.copyWith(
                          color  : AppColors.grey700,
                          height : 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

      // Clause importante : mise en avant pour qu'elle ne se noie
      // pas dans le corps du texte
      Encadre(:final texte) => Container(
          width   : double.infinity,
          padding : const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color        : AppColors.warningLight,
            borderRadius : BorderRadius.circular(12),
            border: const Border(
              left: BorderSide(color: AppColors.warning, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texte,
                  style: AppTextStyles.bodySmall.copyWith(
                    color      : AppColors.grey800,
                    height     : 1.6,
                    fontWeight : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
    };
  }
}

// ── Pied de page ─────────────────────────────────────────────
class _PiedDePage extends StatelessWidget {
  const _PiedDePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.grey200),
        const SizedBox(height: 14),
        Text(
          'YAA — $kEditeur\n$kSiege',
          textAlign : TextAlign.center,
          style     : AppTextStyles.caption.copyWith(
            color  : AppColors.grey400,
            height : 1.6,
          ),
        ),
      ],
    );
  }
}
