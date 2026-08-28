import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../features/user/providers/user_notifier.dart';
import '../../../model/course/estimation_model.dart';
import '../../../service/api/api_service.dart';
import '../../../service/location/location_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../../course/models/course_models.dart';

/// Étape 2 de la livraison : prix en haut, puis les coordonnées de
/// l'expéditeur et du destinataire, en bottom sheet sur la carte.
Future<void> showCourseDetailsSheet(
    BuildContext context, CourseFlowArgs args, {EstimationModel? estimation}) {
  return showModalBottomSheet<void>(
    context            : context,
    isScrollControlled : true,
    backgroundColor    : Colors.transparent,
    builder            : (_) =>
        _CourseDetailsSheet(args: args, estimation: estimation),
  );
}

class _CourseDetailsSheet extends ConsumerStatefulWidget {
  const _CourseDetailsSheet({required this.args, this.estimation});

  final CourseFlowArgs   args;
  final EstimationModel? estimation;

  @override
  ConsumerState<_CourseDetailsSheet> createState() =>
      _CourseDetailsSheetState();
}

class _CourseDetailsSheetState extends ConsumerState<_CourseDetailsSheet> {
  final _formKey = GlobalKey<FormState>();

  final _expedTelCtrl     = TextEditingController();
  final _destTelCtrl      = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  bool    _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Téléphone du profil, remis au format guinéen
    _expedTelCtrl.text =
        formatPhone(ref.read(userProvider).profile?.telephone ?? '');
  }

  @override
  void dispose() {
    _expedTelCtrl.dispose();
    _destTelCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _commander() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final depart  = widget.args.depart;
    final arrivee = widget.args.arrivee;
    if (depart == null || arrivee == null) return;

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final mission = await ApiService().createLivraison(
        typeVehicule          : TypeVehicule.moto.code,
        latitudeDepart        : depart.latitude,
        longitudeDepart       : depart.longitude,
        latitudeArrivee       : arrivee.latitude,
        longitudeArrivee      : arrivee.longitude,
        adresseDepart         : depart.adresse,
        adresseArrivee        : arrivee.adresse,
        // L'API attend le numéro sans espaces
        telephoneExpediteur   : unformatPhone(_expedTelCtrl.text),
        telephoneDestinataire : unformatPhone(_destTelCtrl.text),
        instructions          : _instructionsCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(); // ferme le sheet
      // Enchaîne sur l'écran de recherche de coursier
      context.pushReplacementNamed(
        RouteNames.coursierSearch,
        extra: mission,
      );
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
    final depart  = widget.args.depart;
    final arrivee = widget.args.arrivee;
    final estim   = widget.estimation;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding, 12, AppDimens.screenPadding, 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Poignée
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color        : AppColors.grey300,
                      borderRadius : BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Prix bien visible en haut ─────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estim?.prixLabel ?? '—',
                              style: const TextStyle(
                                fontFamily : 'PlusJakartaSans',
                                fontSize   : 30,
                                fontWeight : FontWeight.w800,
                                color      : AppColors.dark,
                              ),
                            ),
                            if (estim != null)
                              Text(
                                estim.metaLabel,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.grey500),
                              ),
                          ],
                        ),
                      ),
                      // Badge moto
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color        : AppColors.primarySurface,
                          borderRadius : BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22, height: 22,
                              child: Image.asset(
                                'assets/images/moto.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.sports_motorsports,
                                    color: AppColors.primary, size: 14),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Moto',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight : FontWeight.w700,
                                color      : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Erreur ────────────────────────────────────
                  if (_error != null) ...[
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
                    const SizedBox(height: 12),
                  ],

                  // ── Expéditeur / Destinataire ─────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _SectionCard(
                            icon    : Icons.trip_origin_rounded,
                            iconBg  : AppColors.primarySurface,
                            iconClr : AppColors.primary,
                            titre   : 'Expéditeur',
                            adresse : depart != null
                                ? LocationService.cleanAddress(depart.adresse)
                                : '—',
                            onEditAddress: () => Navigator.of(context).pop(),
                            child: YaaTextField(
                              controller      : _expedTelCtrl,
                              hint            : kExempleTelephone,
                              prefixIcon      : Icons.phone_outlined,
                              keyboardType    : TextInputType.phone,
                              textInputAction : TextInputAction.next,
                              inputFormatters : [PhoneInputFormatter()],
                              validator       : validatePhone,
                            ),
                          ),

                          const SizedBox(height: 12),

                          _SectionCard(
                            icon    : Icons.location_on_rounded,
                            iconBg  : const Color(0xFFFFF0E9),
                            iconClr : AppColors.secondary,
                            titre   : 'Destinataire',
                            adresse : arrivee != null
                                ? LocationService.cleanAddress(arrivee.adresse)
                                : '—',
                            onEditAddress: () => Navigator.of(context).pop(),
                            child: YaaTextField(
                              controller      : _destTelCtrl,
                              hint            : kExempleTelephone,
                              prefixIcon      : Icons.phone_outlined,
                              keyboardType    : TextInputType.phone,
                              textInputAction : TextInputAction.next,
                              inputFormatters : [PhoneInputFormatter()],
                              validator       : validatePhone,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Instructions (champ unique) ─────────
                          YaaTextField(
                            controller : _instructionsCtrl,
                            hint       : 'Instructions : colis fragile, étage…',
                            prefixIcon : Icons.notes_rounded,
                            maxLines   : 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  YaaButton(
                    label     : 'Commander',
                    isLoading : _isSubmitting,
                    onPressed : _isSubmitting ? null : _commander,
                  ),
                ],
              ),
            ),
          ),
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
    required this.child,
  });

  final IconData     icon;
  final Color        iconBg;
  final Color        iconClr;
  final String       titre;
  final String       adresse;
  final VoidCallback onEditAddress;
  final Widget       child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        border       : Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : icône + titre + adresse (modifiable)
          GestureDetector(
            onTap    : onEditAddress,
            behavior : HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width  : 30,
                  height : 30,
                  decoration: BoxDecoration(
                    color        : iconBg,
                    borderRadius : BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconClr, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400),
                      ),
                      Text(
                        adresse,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight : FontWeight.w700,
                          color      : AppColors.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined,
                    size: 15, color: AppColors.grey500),
              ],
            ),
          ),

          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
