import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/driver_sheet.dart';
import '../../../shared/widgets/phone_number_formatter.dart';
import '../../../shared/widgets/restaurant_sheet.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

/// Order tracking screen — "Itinéraire"
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(context),

          // ── Map + contenu (Stack pour l'effet overlap arrondi) ──
          Expanded(
            child: Stack(
              children: [
                // Image carte en fond
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildMapImage(),
                ),

                // Contenu blanc avec coins arrondis en haut
                Column(
                  children: [
                    // Hauteur de la carte moins l'overlap
                    const SizedBox(height: 200),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.screenPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppDimens.xxl),

                              // ETA + Order ID
                              _buildEtaSection(),

                              const SizedBox(height: AppDimens.xxl),

                              // Timeline
                              _buildTimeline(),

                              const SizedBox(height: AppDimens.xxl),

                              // Adresse de livraison — cliquable
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    _showAddressChoiceSheet(context),
                                child: _buildDeliveryAddress(),
                              ),

                              const SizedBox(height: AppDimens.lg),

                              // Restaurant card
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => showRestaurantSheet(context),
                                child: _buildRestaurantCard(),
                              ),

                              const SizedBox(height: AppDimens.md),

                              // Driver card
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => showDriverSheet(context),
                                child: _buildDriverCard(),
                              ),

                              const SizedBox(height: AppDimens.xxl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Badge "En route" sur la carte
                Positioned(
                  top: 160,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pedal_bike,
                              color: AppColors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'En route',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.md,
        bottom: AppDimens.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1652F0), Color(0xFF08399A)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(Icons.chevron_left,
                  color: AppColors.white, size: 28),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            'Itinéraire',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Map image ──────────────────────────────────────────────────────────

  Widget _buildMapImage() {
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Image.asset(
        'assets/images/itineraire.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.grey200,
          child: const Center(
            child: Icon(Icons.map_outlined,
                size: 60, color: AppColors.grey400),
          ),
        ),
      ),
    );
  }

  // ── ETA ────────────────────────────────────────────────────────────────

  Widget _buildEtaSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heure d\'arrivée estimée',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '14:45 - 15:00',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Text(
            '#CMD-8491',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    final steps = [
      _TimelineStep(
          title: 'Commande acceptée', time: '13:15', isCompleted: true),
      _TimelineStep(
          title: 'En préparation', time: '13:20', isCompleted: true),
      _TimelineStep(
        title: 'Le livreur est en route',
        time: '13:40',
        isCompleted: true,
        isActive: true,
      ),
      _TimelineStep(
          title: 'Livraison à l\'adresse',
          time: '--:--',
          isCompleted: false),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: step.isActive ? 14 : 10,
                    height: step.isActive ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.isCompleted
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: step.isCompleted
                          ? AppColors.primary
                          : AppColors.grey300,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted
                            ? AppColors.dark
                            : AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.time,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
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

  // ── Delivery address ───────────────────────────────────────────────────

  Widget _buildDeliveryAddress() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on_outlined,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Adresse de livraison',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Mermoz, Dakar\nAppartement 4B, Résidence les Flamboyants',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
      ],
    );
  }

  // ── Restaurant card ────────────────────────────────────────────────────

  Widget _buildRestaurantCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: Image.asset(
              'assets/images/resto_tata.jpg',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: AppColors.grey100,
                child: const Icon(Icons.restaurant,
                    color: AppColors.grey500, size: 22),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'les delices de mami',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '★ 4.8 • 20-30 min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.primary, size: 24),
        ],
      ),
    );
  }

  // ── Driver card ────────────────────────────────────────────────────────

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/diallo_livreur.jpg',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.grey200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: AppColors.grey600, size: 22),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mamadou D.',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Moto Yamaha - AB 1234',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.primary, size: 24),
        ],
      ),
    );
  }

  // ── Address choice bottom sheet ────────────────────────────────────────

  void _showAddressChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddressChoiceSheet(
        onUseCurrentLocation: () {
          Navigator.of(context).pop(); // ferme le sheet
        },
        onAddAddress: () {
          Navigator.of(context).pop(); // ferme le choice sheet
          _showAddressFormSheet(context); // ouvre le form
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
          Future.microtask(() => _showAddressSuccessSheet(context));
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

// ── Bottom sheet : choix d'adresse ─────────────────────────────────────────

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
          AppDimens.screenPadding,
          16,
          AppDimens.screenPadding,
          AppDimens.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppDimens.xl),

            // Utiliser ma position actuelle — filled
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
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.md),

// Ajouter une adresse — outlined, même forme
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
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet : formulaire d'adresse ────────────────────────────────────

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
      // Remonte le sheet quand le clavier s'ouvre
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          16,
          AppDimens.screenPadding,
          AppDimens.xxl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.xl),

              Text(
                'Information de l\'adresse',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: AppDimens.xl),

              YaaTextField(
                controller: _addressController,
                label: 'Adresse complète',
                hint: 'Ex: Ouakam cité avion BP 12 Rue 32 Villa 12',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une adresse';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppDimens.lg),

              PhoneTextField(
                controller: _phoneController,
                label: 'Numéro à contacter',
                textInputAction: TextInputAction.done,
              ),

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

// ── Bottom sheet : succès adresse ajoutée ──────────────────────────────────

class _AddressSuccessSheet extends StatelessWidget {
  const _AddressSuccessSheet();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          16,
          AppDimens.screenPadding,
          AppDimens.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimens.xxl),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              'Adresse ajouté',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

// ── Model ───────────────────────────────────────────────────────────────────

class _TimelineStep {
  final String title;
  final String time;
  final bool isCompleted;
  final bool isActive;

  const _TimelineStep({
    required this.title,
    required this.time,
    required this.isCompleted,
    this.isActive = false,
  });
}