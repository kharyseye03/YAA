import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/driver_sheet.dart';
import '../../../shared/widgets/phone_number_formatter.dart';
import '../../../shared/widgets/restaurant_sheet.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // ── Carte en fond plein écran ──────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/itineraire.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.grey100,
                child: const Center(
                  child: Icon(Icons.map_outlined,
                      size: 60, color: AppColors.grey300),
                ),
              ),
            ),
          ),

          // ── Bouton retour flottant ─────────────────────
          Positioned(
            top: top + 12,
            left: AppDimens.screenPadding,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.dark),
              ),
            ),
          ),

          // ── Panneau blanc qui monte depuis le bas ──────
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.62,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.screenPadding,
                    24,
                    AppDimens.screenPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Drag handle ──────────────────
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── ETA ──────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arrivée estimée',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.grey500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '14:45 – 15:00',
                                style: TextStyle(
                                  fontFamily: 'Archivo',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusFull),
                            ),
                            child: Text(
                              '#CMD-8491',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.grey600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Timeline ─────────────────────
                      _Timeline(),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.grey200, height: 1),
                      const SizedBox(height: 20),

                      // ── Adresse ──────────────────────
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showAddressChoiceSheet(context),
                        child: _InfoRow(
                          icon: Icons.location_on_outlined,
                          title: 'Mermoz, Dakar',
                          subtitle:
                              'Appt 4B, Résidence les Flamboyants',
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.grey400),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppColors.grey200, height: 1),
                      const SizedBox(height: 16),

                      // ── Restaurant ───────────────────
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showRestaurantSheet(context),
                        child: _InfoRow(
                          imageUrl: 'assets/images/resto_tata.jpg',
                          isAsset: true,
                          title: 'Les délices de Mami',
                          subtitle: '★ 4.8 · 20-30 min',
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.grey400),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppColors.grey200, height: 1),
                      const SizedBox(height: 16),

                      // ── Livreur ──────────────────────
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showDriverSheet(context),
                        child: _InfoRow(
                          imageUrl: 'assets/images/diallo_livreur.jpg',
                          isAsset: true,
                          isCircle: true,
                          title: 'Mamadou D.',
                          subtitle: 'Moto Yamaha · AB 1234',
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.grey400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Badge statut sur la carte ──────────────────
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.62 - 18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'En route · ~15 min',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddressChoiceSheet(
        onUseCurrentLocation: () => Navigator.of(context).pop(),
        onAddAddress: () {
          Navigator.of(context).pop();
          _showAddressFormSheet(context);
        },
      ),
    );
  }

  void _showAddressFormSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (innerContext) => _AddressFormSheet(
        onConfirm: () {
          Navigator.of(innerContext).pop();
          _showAddressSuccessSheet(innerContext);
        },
      ),
    );
  }

  void _showAddressSuccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: AppColors.white,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddressSuccessSheet(),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────
class _Timeline extends StatelessWidget {
  final _steps = const [
    ('Commande acceptée', '13:15', true),
    ('En préparation', '13:20', true),
    ('Livreur en route', '13:40', true),
    ('Livraison à l\'adresse', '--:--', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final (title, time, done) = _steps[i];
        final isLast = i == _steps.length - 1;
        final isActive = i == _steps.indexWhere((s) => !s.$3);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + ligne
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: isActive ? 12 : 8,
                    height: isActive ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.dark
                          : AppColors.grey200,
                    ),
                    child: done && !isActive
                        ? const Icon(Icons.check,
                            size: 6, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 32,
                      color: done
                          ? AppColors.dark
                          : AppColors.grey200,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 20, top: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: done
                            ? AppColors.dark
                            : AppColors.grey400,
                      ),
                    ),
                    Text(
                      time,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: done
                            ? AppColors.grey500
                            : AppColors.grey300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Ligne info réutilisable ───────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    this.icon,
    this.imageUrl,
    this.isAsset = false,
    this.isCircle = false,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData? icon;
  final String? imageUrl;
  final bool isAsset;
  final bool isCircle;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (imageUrl != null) {
      final img = isAsset
          ? Image.asset(imageUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback())
          : Image.network(imageUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback());
      avatar = isCircle
          ? ClipOval(child: SizedBox(width: 44, height: 44, child: img))
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 44, height: 44, child: img));
    } else {
      avatar = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _fallback() => Container(
        width: 44,
        height: 44,
        color: AppColors.grey100,
        child: const Icon(Icons.storefront_outlined,
            color: AppColors.grey400, size: 20),
      );
}

// ── Bottom sheets (inchangés) ─────────────────────────────
class _AddressChoiceSheet extends StatelessWidget {
  const _AddressChoiceSheet({
    required this.onUseCurrentLocation,
    required this.onAddAddress,
  });
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding, 16, AppDimens.screenPadding, AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: AppDimens.xl),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: onUseCurrentLocation,
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('Utiliser ma position actuelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusFull)),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: onAddAddress,
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('Ajouter une adresse de livraison'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusFull)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(AppDimens.screenPadding, 16,
            AppDimens.screenPadding, AppDimens.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              Text('Information de l\'adresse',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppDimens.xl),
              YaaTextField(
                controller: _addressController,
                label: 'Adresse complète',
                hint: 'Ex: Ouakam cité avion BP 12 Rue 32 Villa 12',
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Veuillez entrer une adresse' : null,
              ),
              const SizedBox(height: AppDimens.lg),
              PhoneTextField(
                  controller: _phoneController,
                  label: 'Numéro à contacter',
                  textInputAction: TextInputAction.done),
              const SizedBox(height: AppDimens.xxl),
              YaaButton(
                label: 'Confirmer →',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onConfirm();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSuccessSheet extends StatelessWidget {
  const _AddressSuccessSheet();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding, 16, AppDimens.screenPadding, AppDimens.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: AppDimens.xxl),
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.primarySurface),
              child: Center(
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12)),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      size: 32, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text('Adresse ajoutée',
                style: AppTextStyles.h3
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.dark)),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}
