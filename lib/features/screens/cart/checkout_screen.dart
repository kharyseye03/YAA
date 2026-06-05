import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../../../features/user/providers/user_notifier.dart';
import '../../../model/transaction/transaction_model.dart';
import '../../../service/api/api_service.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.modeLivraison = 'GROUPAGE'});

  /// 'GROUPAGE' ou 'INDIVIDUEL' — transmis depuis le panier
  final String modeLivraison;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController   = TextEditingController();
  final _noteController    = TextEditingController();

  bool    _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pré-remplir le téléphone depuis le profil
    final phone = ref.read(userProvider).profile?.telephone ?? '';
    _phoneController.text = phone;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _validerCommande() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() { _isSubmitting = true; _error = null; });

    try {
      final token = ref.read(authProvider.notifier).token;
      final cart  = ref.read(cartProvider).cart;
      if (cart == null) throw Exception('Panier introuvable');

      final transaction = await ApiService().createTransaction(
        panierId         : cart.id,
        modeLivraison    : widget.modeLivraison,
        adresseLivraison : _addressController.text.trim(),
        telephoneClient  : _phoneController.text.trim(),
        description      : _noteController.text.trim(),
        token            : token,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      // Afficher le bottom sheet de paiement
      showModalBottomSheet(
        context            : context,
        isScrollControlled : true,
        isDismissible      : false,
        backgroundColor    : Colors.transparent,
        builder            : (_) => _PaymentSheet(
          transaction : transaction,
          token       : token,
          onSuccess   : () {
            Navigator.of(context).pop(); // ferme le sheet paiement
            ref.read(cartProvider.notifier).clearCart(); // vide le panier local
            _showSuccessSheet();
          },
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context         : context,
      isDismissible   : false,
      backgroundColor : Colors.white,
      shape           : const RoundedRectangleBorder(
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

  @override
  Widget build(BuildContext context) {
    final cart  = ref.watch(cartProvider).cart;
    final total = cart?.montantTotal ?? 0.0;
    final count = cart?.totalArticles ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top    : MediaQuery.of(context).padding.top + 12,
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              bottom : 16,
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
                  'Commander',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
                const Spacer(),
                // Badge total
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color        : AppColors.grey100,
                    borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    '${total.toStringAsFixed(0)} F',
                    style: AppTextStyles.labelSmall.copyWith(
                      color      : AppColors.dark,
                      fontWeight : FontWeight.w700,
                      fontSize   : 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // ── Erreur ──────────────────────────────────────────
          if (_error != null)
            Container(
              width   : double.infinity,
              padding : const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding, vertical: 10),
              color   : AppColors.errorLight,
              child   : Row(
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

          // ── Contenu ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding, 20,
                AppDimens.screenPadding, 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Récapitulatif ────────────────────────
                    _SectionLabel('Récapitulatif'),
                    const SizedBox(height: 14),
                    _SummaryRow(
                      icon  : Icons.shopping_bag_outlined,
                      label : '$count article${count > 1 ? 's' : ''}',
                      value : '${total.toStringAsFixed(0)} F',
                      bold  : true,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      icon  : Icons.local_shipping_outlined,
                      label : widget.modeLivraison == 'GROUPAGE'
                          ? 'Livraison groupée'
                          : 'Livraison individuelle',
                      value : '',
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 20),

                    // ── Livraison ────────────────────────────
                    _SectionLabel('Livraison'),
                    const SizedBox(height: 14),
                    YaaTextField(
                      controller      : _addressController,
                      label           : 'Adresse de livraison',
                      hint            : 'Ex: 15 Rue de la Paix, Dakar',
                      prefixIcon      : Icons.location_on_outlined,
                      textInputAction : TextInputAction.next,
                      validator       : (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: AppDimens.lg),
                    YaaTextField(
                      controller      : _phoneController,
                      label           : 'Téléphone',
                      hint            : 'Ex: 77 123 45 67',
                      prefixIcon      : Icons.phone_outlined,
                      keyboardType    : TextInputType.phone,
                      textInputAction : TextInputAction.next,
                      validator       : (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 20),

                    // ── Note de commande ─────────────────────
                    _SectionLabel('Note de commande'),
                    const SizedBox(height: 14),
                    YaaTextField(
                      controller : _noteController,
                      hint       : 'Instructions spéciales, allergies…',
                      maxLines   : 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bouton Valider fixe ──────────────────────────────
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
            child: YaaButton(
              label           : _isSubmitting
                  ? 'Validation...'
                  : 'Valider la commande · ${total.toStringAsFixed(0)} F',
              onPressed       : _isSubmitting ? null : _validerCommande,
              icon            : _isSubmitting ? null : Icons.lock_outline_rounded,
              backgroundColor : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Label de section ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color         : AppColors.grey500,
        fontSize      : 11,
        letterSpacing : 0.8,
        fontWeight    : FontWeight.w700,
      ),
    );
  }
}

// ── Ligne récap ───────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final bool     bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width  : 34,
          height : 34,
          decoration: BoxDecoration(
            color        : AppColors.grey100,
            borderRadius : BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.grey600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color      : AppColors.grey700,
              fontWeight : bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
      ],
    );
  }
}

// ── Bottom sheet paiement ─────────────────────────────────────
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.transaction,
    required this.token,
    required this.onSuccess,
  });

  final TransactionModel transaction;
  final String?          token;
  final VoidCallback     onSuccess;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  int     _selectedIndex = 0;
  bool    _isPaying      = false;
  String? _error;

  static const _methods = [
    _PaymentMethod('Orange Money', 'ORANGE_MONEY', 'assets/images/om.webp',
        Color(0xFFFFF0E6), Color(0xFFFF7900)),
    _PaymentMethod('Wave',         'WAVE',         'assets/images/wave2.webp',
        Color(0xFFE8F4FF), Color(0xFF1B9AFF)),
    _PaymentMethod('MTN Money',    'MTN_MONEY',    'assets/images/mtn.jpg',
        Color(0xFFFFFBE6), Color(0xFFFFCC00)),
  ];

  Future<void> _payer() async {
    setState(() { _isPaying = true; _error = null; });
    try {
      await ApiService().payTransaction(
        id           : widget.transaction.id,
        reference    : widget.transaction.reference,
        modePaiement : _methods[_selectedIndex].code,
        token        : widget.token,
      );
      widget.onSuccess();
    } catch (e) {
      setState(() {
        _isPaying = false;
        _error    = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final tx        = widget.transaction;

    return Container(
      decoration: const BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 0,
          AppDimens.screenPadding, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color        : AppColors.grey300,
              borderRadius : BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Titre + référence ──────────────────────────────
          Text(
            'Choisir le mode de paiement',
            style: AppTextStyles.h3.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Réf : ${tx.reference.substring(0, 8).toUpperCase()}  ·  '
            '${tx.montant.toStringAsFixed(0)} F',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 16),

          // ── Options de paiement ────────────────────────────
          ...List.generate(_methods.length, (i) {
            final m      = _methods[i];
            final active = i == _selectedIndex;
            return Column(
              children: [
                GestureDetector(
                  onTap    : () => setState(() => _selectedIndex = i),
                  behavior : HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width  : 48,
                          height : 48,
                          decoration: BoxDecoration(
                            color        : m.bgColor,
                            borderRadius : BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              m.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.payment,
                                color: m.accentColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Nom
                        Expanded(
                          child: Text(
                            m.name,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight : active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize   : 14,
                              color      : AppColors.dark,
                            ),
                          ),
                        ),
                        // Radio
                        AnimatedContainer(
                          duration  : const Duration(milliseconds: 200),
                          width     : 22,
                          height    : 22,
                          decoration: BoxDecoration(
                            shape  : BoxShape.circle,
                            border : Border.all(
                              color : active ? AppColors.dark : AppColors.grey300,
                              width : active ? 6 : 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < _methods.length - 1)
                  const Divider(height: 1, color: AppColors.grey200),
              ],
            );
          }),

          // ── Erreur ────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width   : double.infinity,
              padding : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color        : AppColors.errorLight,
                borderRadius : BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Bouton Payer ───────────────────────────────────
          YaaButton(
            label           : _isPaying
                ? 'Paiement en cours...'
                : 'Payer · ${tx.montant.toStringAsFixed(0)} F',
            onPressed       : _isPaying ? null : _payer,
            icon            : _isPaying ? null : Icons.lock_outline_rounded,
            backgroundColor : AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

// ── Modèle de méthode de paiement ────────────────────────────
class _PaymentMethod {
  const _PaymentMethod(
      this.name, this.code, this.imagePath, this.bgColor, this.accentColor);
  final String name;
  final String code;
  final String imagePath;
  final Color  bgColor;
  final Color  accentColor;
}

// ── Bottom sheet succès ───────────────────────────────────────
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
      padding: EdgeInsets.fromLTRB(
        AppDimens.screenPadding, 16,
        AppDimens.screenPadding,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color        : AppColors.grey300,
              borderRadius : BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 28),

          // Icône succès
          Container(
            width  : 80,
            height : 80,
            decoration: const BoxDecoration(
              shape : BoxShape.circle,
              color : AppColors.successLight,
            ),
            child: const Icon(Icons.check_rounded,
                size: 40, color: AppColors.success),
          ),

          const SizedBox(height: 20),

          Text(
            'Commande enregistrée !',
            style: AppTextStyles.h3.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre paiement a bien été traité.\nVous pouvez suivre votre commande.',
            textAlign : TextAlign.center,
            style     : AppTextStyles.bodyMedium.copyWith(
              color  : AppColors.grey500,
              height : 1.5,
            ),
          ),

          const SizedBox(height: 28),
          const Divider(color: AppColors.grey200, height: 1),
          const SizedBox(height: 16),

          Text(
            'Notez votre expérience',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 12),

          // Étoiles
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
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size  : 38,
                    color : i < _rating
                        ? const Color(0xFFFFC107)
                        : AppColors.grey300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Ou ',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
          TextButton(
            onPressed : widget.onContinue,
            child     : Text(
              'Passer',
              style: AppTextStyles.bodySmall.copyWith(
                color      : AppColors.grey500,
                decoration : TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
