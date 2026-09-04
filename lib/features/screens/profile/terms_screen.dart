import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                SizedBox(height: 24.h),
                const _Resume(),
                SizedBox(height: 28.h),
                for (final section in kSections) ...[
                  _Section(section: section),
                  SizedBox(height: 26.h),
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
        bottom : 14.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap    : () => Navigator.of(context).pop(),
            behavior : HitTestBehavior.opaque,
            child: Container(
              width  : 38.r,
              height : 38.r,
              decoration: BoxDecoration(
                color        : AppColors.grey100,
                borderRadius : BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  color: AppColors.dark, size: 22.r),
            ),
          ),
          SizedBox(width: 12.w),
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
            fontSize   : 26.sp,
            fontWeight : FontWeight.w800,
            color      : AppColors.dark,
            height     : 1.2,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _Etiquette(texte: 'Version $kVersionCgu'),
            SizedBox(width: 8.w),
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
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
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color        : AppColors.primarySurface,
        borderRadius : BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.primary, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                'L\'essentiel',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w800,
                  color      : AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (final point in kResume) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin : EdgeInsets.only(top: 7.h, right: 10.w),
                  width  : 5.r,
                  height : 5.r,
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
            SizedBox(height: 8.h),
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
              width  : 28.r,
              height : 28.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color        : AppColors.primary,
                borderRadius : BorderRadius.circular(8.r),
              ),
              child: Text(
                section.numero,
                style: AppTextStyles.caption.copyWith(
                  color      : Colors.white,
                  fontWeight : FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 3.h),
                child: Text(
                  section.titre,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize   : 16.sp,
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                    height     : 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        for (final bloc in section.blocs) ...[
          _Bloc(bloc: bloc),
          SizedBox(height: 10.h),
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
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin : EdgeInsets.only(top: 8.h, right: 10.w),
                      width  : 5.r,
                      height : 5.r,
                      decoration: BoxDecoration(
                        color        : AppColors.grey400,
                        borderRadius : BorderRadius.circular(1.r),
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
          padding : EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color        : AppColors.warningLight,
            borderRadius : BorderRadius.circular(12.r),
            border: Border(
              left: BorderSide(color: AppColors.warning, width: 3.w),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 17.r),
              SizedBox(width: 10.w),
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
        SizedBox(height: 14.h),
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
