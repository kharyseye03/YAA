import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/phone_number_formatter.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _paymentTab = 0; // 0 = Mobile money · 1 = Carte
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
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header blanc ──────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top: top + 12,
              left: AppDimens.screenPadding,
              right: AppDimens.screenPadding,
              bottom: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: AppColors.dark),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Paiement',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    '8 000 F',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // ── Contenu ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Récapitulatif ─────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Récapitulatif'),
                        const SizedBox(height: 16),
                        _PriceRow(label: 'Sous-total', value: '6 000 F'),
                        const SizedBox(height: 10),
                        _PriceRow(label: 'Frais de livraison', value: '2 000 F'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Divider(
                              height: 1, color: AppColors.grey200),
                        ),
                        _PriceRow(
                            label: 'Total', value: '8 000 F', isTotal: true),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.grey200),

                  // ── Infos personnelles ────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Informations personnelles'),
                        const SizedBox(height: 16),
                        YaaTextField(
                          controller: _nameController,
                          label: 'Prénom et nom',
                          hint: 'Ex: Birima Diop',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppDimens.lg),
                        PhoneTextField(
                          controller: _phoneController,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.grey200),

                  // ── Mode de paiement ──────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 0),
                    child: _SectionLabel('Mode de paiement'),
                  ),

                  // Tabs Mobile money / Carte
                  _PaymentTabs(
                    current: _paymentTab,
                    onTap: (i) => setState(() => _paymentTab = i),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, 20,
                        AppDimens.screenPadding, 24),
                    child: _paymentTab == 0
                        ? _MobileMoneyList(
                            selected: _selectedProvider,
                            onSelect: (i) =>
                                setState(() => _selectedProvider = i),
                          )
                        : _CardForm(
                            nameCtrl: _cardNameController,
                            numberCtrl: _cardNumberController,
                            expiryCtrl: _expiryController,
                            cvvCtrl: _cvvController,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bouton Payer fixe ─────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: AppDimens.screenPadding,
              right: AppDimens.screenPadding,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: YaaButton(
              label: 'Payer · 8 000 F',
              onPressed: _showSuccessSheet,
              icon: Icons.lock_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OrderSuccessSheet(
        onContinue: () {
          Navigator.of(context).pop();
          context.goNamed(RouteNames.home);
        },
      ),
    );
  }
}

// ── Label de section ──────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.grey500,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Ligne prix ────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.dark,
                )
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey500,
                  fontSize: 13,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.dark,
                )
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.dark,
                  fontSize: 13,
                ),
        ),
      ],
    );
  }
}

// ── Tabs Mobile money / Carte ─────────────────────────────
class _PaymentTabs extends StatelessWidget {
  const _PaymentTabs({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mobile Money', 'Carte bancaire'];
    const icons = [Icons.phone_android_outlined, Icons.credit_card_outlined];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(2, (i) {
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[i],
                        size: 16,
                        color: active
                            ? AppColors.dark
                            : AppColors.grey400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labels[i],
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppColors.dark
                              : AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        Stack(
          children: [
            Container(height: 1, color: AppColors.grey200),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: current == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 2, color: AppColors.dark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Liste Mobile Money ────────────────────────────────────
class _MobileMoneyList extends StatelessWidget {
  const _MobileMoneyList({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  static const _providers = [
    ('Wave', 'assets/images/wave2.webp'),
    ('Yas Money', 'assets/images/yas2.webp'),
    ('Orange Money', 'assets/images/om.webp'),
    ('Kay Pay', 'assets/images/kpay.webp'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_providers.length, (i) {
        final (name, img) = _providers[i];
        final active = i == selected;
        return Column(
          children: [
            GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          img,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.payment,
                              color: AppColors.grey400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? AppColors.dark
                              : AppColors.grey300,
                          width: active ? 6 : 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _providers.length - 1)
              const Divider(height: 1, color: AppColors.grey200),
          ],
        );
      }),
    );
  }
}

// ── Formulaire carte ──────────────────────────────────────
class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.nameCtrl,
    required this.numberCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
  });
  final TextEditingController nameCtrl;
  final TextEditingController numberCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        YaaTextField(
          controller: nameCtrl,
          label: 'Nom sur la carte',
          hint: 'Lamine Wade',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppDimens.lg),
        YaaTextField(
          controller: numberCtrl,
          label: 'Numéro de carte',
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card_outlined,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppDimens.lg),
        Row(
          children: [
            Expanded(
              child: YaaTextField(
                controller: expiryCtrl,
                label: 'Expiration',
                hint: 'MM/AA',
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: YaaTextField(
                controller: cvvCtrl,
                label: 'CVV',
                hint: '···',
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

// ── Bottom sheet succès ───────────────────────────────────
class _OrderSuccessSheet extends StatefulWidget {
  const _OrderSuccessSheet({required this.onContinue});
  final VoidCallback onContinue;

  @override
  State<_OrderSuccessSheet> createState() => _OrderSuccessSheetState();
}

class _OrderSuccessSheetState extends State<_OrderSuccessSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 16, AppDimens.screenPadding, AppDimens.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2)),
          ),

          const SizedBox(height: AppDimens.xxl),

          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.primarySurface),
            child: const Icon(Icons.check_rounded,
                size: 40, color: AppColors.primary),
          ),

          const SizedBox(height: AppDimens.xl),

          Text(
            'Commande enregistrée !',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Votre commande a bien été reçue.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey500,
            ),
          ),

          const SizedBox(height: AppDimens.xxl),
          const Divider(color: AppColors.grey200, height: 1),
          const SizedBox(height: AppDimens.lg),

          Text(
            'Notez votre expérience',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey500,
            ),
          ),

          const SizedBox(height: AppDimens.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () {
                  setState(() => _rating = i + 1);
                  Future.delayed(
                    const Duration(milliseconds: 600),
                    widget.onContinue,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 38,
                    color: i < _rating
                        ? const Color(0xFFFFC107)
                        : AppColors.grey300,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: AppDimens.xl),
        ],
      ),
    );
  }
}
