import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/user/providers/user_notifier.dart';
import '../../../service/location/location_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../../course/models/course_models.dart';

/// Ouvre l'étape 2 de la livraison (détails expéditeur/destinataire)
/// en bottom sheet par-dessus la carte, façon Yango.
Future<void> showCourseDetailsSheet(
    BuildContext context, CourseFlowArgs args) {
  return showModalBottomSheet<void>(
    context            : context,
    isScrollControlled : true,
    backgroundColor    : Colors.transparent,
    builder            : (_) => _CourseDetailsSheet(args: args),
  );
}

class _CourseDetailsSheet extends ConsumerStatefulWidget {
  const _CourseDetailsSheet({required this.args});

  final CourseFlowArgs args;

  @override
  ConsumerState<_CourseDetailsSheet> createState() =>
      _CourseDetailsSheetState();
}

class _CourseDetailsSheetState extends ConsumerState<_CourseDetailsSheet> {
  final _formKey = GlobalKey<FormState>();

  final _expedTelCtrl  = TextEditingController();
  final _expedNoteCtrl = TextEditingController();
  final _destNomCtrl   = TextEditingController();
  final _destTelCtrl   = TextEditingController();
  final _destNoteCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expedTelCtrl.text = ref.read(userProvider).profile?.telephone ?? '';
  }

  @override
  void dispose() {
    _expedTelCtrl.dispose();
    _expedNoteCtrl.dispose();
    _destNomCtrl.dispose();
    _destTelCtrl.dispose();
    _destNoteCtrl.dispose();
    super.dispose();
  }

  void _commander() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: estimation + création livraison + recherche de coursier
  }

  @override
  Widget build(BuildContext context) {
    final depart  = widget.args.depart;
    final arrivee = widget.args.arrivee;

    return Padding(
      // Remonte le sheet quand le clavier s'ouvre
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Poignée
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color        : AppColors.grey300,
                borderRadius : BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // ── En-tête ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding),
              child: Row(
                children: [
                  Text(
                    'Détails de la livraison',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight : FontWeight.w800,
                      color      : AppColors.dark,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap    : () => Navigator.of(context).pop(),
                    behavior : HitTestBehavior.opaque,
                    child: Container(
                      width  : 32,
                      height : 32,
                      decoration: const BoxDecoration(
                        color : AppColors.grey100,
                        shape : BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.grey200),

            // ── Contenu ─────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadding, 18,
                      AppDimens.screenPadding, 20),
                  children: [
                    // Bandeau moto
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color        : AppColors.primarySurface,
                        borderRadius : BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width  : 40,
                            height : 40,
                            child: Image.asset(
                              'assets/images/moto.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.sports_motorsports,
                                  color: AppColors.primary, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Livraison par moto',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight : FontWeight.w700,
                                color      : AppColors.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Carte Expéditeur ────────────────────────
                    _SectionCard(
                      icon    : Icons.trip_origin_rounded,
                      iconBg  : AppColors.primarySurface,
                      iconClr : AppColors.primary,
                      titre   : 'Expéditeur',
                      adresse : depart != null
                          ? LocationService.cleanAddress(depart.adresse)
                          : '—',
                      onEditAddress: () => Navigator.of(context).pop(),
                      children: [
                        YaaTextField(
                          controller      : _expedTelCtrl,
                          label           : 'Téléphone de l\'expéditeur',
                          hint            : 'Ex: 77 123 45 67',
                          prefixIcon      : Icons.phone_outlined,
                          keyboardType    : TextInputType.phone,
                          textInputAction : TextInputAction.next,
                          validator       : (v) => v == null || v.trim().isEmpty
                              ? 'Champ requis'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        YaaTextField(
                          controller : _expedNoteCtrl,
                          label      : 'Précisions (facultatif)',
                          hint       : 'Étage, code, point de repère…',
                          maxLines   : 2,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Carte Destinataire ──────────────────────
                    _SectionCard(
                      icon    : Icons.location_on_rounded,
                      iconBg  : const Color(0xFFFFF0E9),
                      iconClr : AppColors.secondary,
                      titre   : 'Destinataire',
                      adresse : arrivee != null
                          ? LocationService.cleanAddress(arrivee.adresse)
                          : '—',
                      onEditAddress: () => Navigator.of(context).pop(),
                      children: [
                        YaaTextField(
                          controller      : _destNomCtrl,
                          label           : 'Nom du destinataire',
                          hint            : 'Ex: Awa Ndiaye',
                          prefixIcon      : Icons.person_outline_rounded,
                          textInputAction : TextInputAction.next,
                          validator       : (v) => v == null || v.trim().isEmpty
                              ? 'Champ requis'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        YaaTextField(
                          controller      : _destTelCtrl,
                          label           : 'Téléphone du destinataire',
                          hint            : 'Ex: 77 123 45 67',
                          prefixIcon      : Icons.phone_outlined,
                          keyboardType    : TextInputType.phone,
                          textInputAction : TextInputAction.next,
                          validator       : (v) => v == null || v.trim().isEmpty
                              ? 'Champ requis'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        YaaTextField(
                          controller : _destNoteCtrl,
                          label      : 'Précisions (facultatif)',
                          hint       : 'Étage, code, point de repère…',
                          maxLines   : 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Barre du bas : total + commander ────────────
            Container(
              padding: EdgeInsets.only(
                left   : AppDimens.screenPadding,
                right  : AppDimens.screenPadding,
                top    : 12,
                bottom : MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color  : Colors.white,
                border : Border(top: BorderSide(color: AppColors.grey200)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.grey400)),
                      Text(
                        '—',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight : FontWeight.w800,
                          color      : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: YaaButton(
                      label     : 'Commander',
                      onPressed : _commander,
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

// ── Carte de section (Expéditeur / Destinataire) ─────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconBg,
    required this.iconClr,
    required this.titre,
    required this.adresse,
    required this.onEditAddress,
    required this.children,
  });

  final IconData     icon;
  final Color        iconBg;
  final Color        iconClr;
  final String       titre;
  final String       adresse;
  final VoidCallback onEditAddress;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        border       : Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width  : 32,
                height : 32,
                decoration: BoxDecoration(
                  color        : iconBg,
                  borderRadius : BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconClr, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                titre,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w800,
                  fontSize   : 15,
                  color      : AppColors.dark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap    : onEditAddress,
            behavior : HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color        : AppColors.grey100,
                borderRadius : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      adresse,
                      style: AppTextStyles.bodySmall.copyWith(
                        color      : AppColors.dark,
                        fontWeight : FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.grey500),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
