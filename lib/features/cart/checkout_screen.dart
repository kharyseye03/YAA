import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/phone_number_formatter.dart';
import '../../shared/widgets/yaa_button.dart';
import '../../shared/widgets/yaa_text_field.dart';

/// Checkout / Payment screen — "Paiement"
/// Toggle between "Carte bancaire" and "Mobile money",
/// shows different payment form for each.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isCard = false;
  int _selectedProvider = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(context),

          // ── Content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.lg),

                  // Total card (reused from cart)
                  _buildTotalCard(),

                  const SizedBox(height: AppDimens.xxl),

                  // Informations personnelles
                  Text(
                    'Informations personnelles',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: AppDimens.lg),

                  YaaTextField(
                    controller: _nameController,
                    label: 'Prénom et nom',
                    hint: 'Ex: Birima Diop',
                  ),

                  const SizedBox(height: AppDimens.lg),

                  PhoneTextField(controller: _phoneController),

                  const SizedBox(height: AppDimens.xxl),

                  // Informations de paiement
                  Text(
                    'Informations de paiement',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Payment method toggle
                  _buildPaymentToggle(),

                  const SizedBox(height: AppDimens.md),

                  // Payment form
                  _isCard
                      ? _buildCardForm()
                      : _buildMobileMoneyProviders(),

                  const SizedBox(height: AppDimens.xxl),
                ],
              ),
            ),
          ),

          // ── Bottom buttons ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding,
              vertical: AppDimens.lg,
            ),
            color: AppColors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Annuler
                  Expanded(
                    child: YaaButton(
                      label: 'Annuler',
                      onPressed: () => Navigator.of(context).pop(),
                      isOutlined: true,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  // Payer
                  Expanded(
                    child: YaaButton(
                      label: 'Payer',
                      onPressed: () {
                        // TODO: Process payment
                      },
                      icon: Icons.arrow_forward,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          colors: [
            Color(0xFF1652F0),
            Color(0xFF08399A)
          ],
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
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            'Paiement',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à payer',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '4',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xs),
          const Text(
            '8000F cfa',
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: [
              _buildChip('3 articles'),
              const SizedBox(width: AppDimens.sm),
              _buildChip('Livraison 2000F'),
              const SizedBox(width: AppDimens.sm),
              _buildChip('20-30 min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Payment Toggle ───────────────────────────────────────
  Widget _buildPaymentToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildPaymentTab(
            icon: Icons.credit_card,
            label: 'Carte bancaire',
            isActive: _isCard,
            onTap: () => setState(() => _isCard = true),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: _buildPaymentTab(
            icon: Icons.phone_android,
            label: 'Mobile money',
            isActive: !_isCard,
            onTap: () => setState(() => _isCard = false),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.grey300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color:
                isActive ? AppColors.primary : AppColors.grey600),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color:
                isActive ? AppColors.primary : AppColors.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Money Providers ───────────────────────────────
  Widget _buildMobileMoneyProviders() {
    final providers = [
      {'name': 'Wave', 'image': 'assets/images/wave2.webp'},
      {'name': 'Yas money', 'image': 'assets/images/yas2.webp'},
      {'name': 'Orange money', 'image': 'assets/images/om.webp'},
      {'name': 'Kay pay', 'image': 'assets/images/kpay.webp'},
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.md,
        crossAxisSpacing: AppDimens.md,
        childAspectRatio: 1.6,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final isSelected = _selectedProvider == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedProvider = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.grey300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  provider['image'] as String,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.payment, size: 28, color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  provider['name'] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.dark,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Card Form ────────────────────────────────────────────
  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YaaTextField(
          controller: _cardNameController,
          label: 'Nom sur la carte',
          hint: 'Lamine wade',
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: AppDimens.lg),

        YaaTextField(
          controller: _cardNumberController,
          label: 'Numéro de carte',
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: AppDimens.lg),

        // Expiry + CVV side by side
        Row(
          children: [
            Expanded(
              child: YaaTextField(
                controller: _expiryController,
                label: 'Date d\'expiration',
                hint: 'MM/AA',
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: YaaTextField(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                keyboardType: TextInputType.number,
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
