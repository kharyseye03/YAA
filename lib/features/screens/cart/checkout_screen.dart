import '../../../core/utils/devise.dart';
import '../../../core/utils/phone_formatter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../../../features/cart/providers/delivery_address_provider.dart';
import '../../../features/user/providers/user_notifier.dart';
import '../../../model/course/type_vehicule.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../model/transaction/transaction_model.dart';
import '../../../service/location/location_service.dart';
import '../../../service/api/api_service.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';
import 'delivery_address_sheet.dart';
import 'reception_mode_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.choix});

  /// Mode de réception et, en livraison, le véhicule retenu —
  /// choisis dans le sheet du panier
  final ChoixReception choix;

  bool get isRetrait => choix.mode == ModeReception.retrait;

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
    final profile = ref.read(userProvider).profile;
    _phoneController.text = formatPhone(profile?.telephone ?? '');

    // Pré-remplir l'adresse : celle choisie pour cette commande,
    // sinon l'adresse par défaut du profil
    final adr = ref.read(deliveryAddressProvider)?.adresse
        ?? profile?.address;
    _addressController.text =
        adr != null ? LocationService.cleanAddress(adr) : '';
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
      final cart  = ref.read(cartProvider).cart;
      if (cart == null) throw Exception('Panier introuvable');

      // Coordonnées : adresse choisie pour cette commande,
      // sinon celles de l'adresse par défaut du profil
      final delivery = ref.read(deliveryAddressProvider);
      final profile  = ref.read(userProvider).profile;
      final latitude  = delivery?.latitude  ?? profile?.latitude  ?? 0;
      final longitude = delivery?.longitude ?? profile?.longitude ?? 0;

      // Le payload est identique dans les deux modes : le backend
      // connaît déjà l'adresse du client et celle de la structure.
      final transaction = await ApiService().createTransaction(
        panierId              : cart.id,
        modeReceptionCommande : widget.choix.mode.code,
        typeVehicule          : widget.choix.typeVehicule,
        fraisLivraison        : widget.choix.fraisLivraison,
        adresseLivraison      : _addressController.text.trim(),
        telephoneClient       : unformatPhone(_phoneController.text),
        latitude              : latitude,
        longitude             : longitude,
        description           : _noteController.text.trim(),
      );

      // Infos trajet pour le sheet de recherche de livreur
      // (capturées avant que le panier ne soit vidé)
      final departNom = cart.lignes.length > 1
          ? 'Plusieurs établissements'
          : cart.lignes.first.nomStructure;
      final departAdresse = cart.lignes.length > 1
          ? '${cart.lignes.length} points de retrait'
          : cart.lignes.first.adresseStructure;
      final arriveeAdresse = _addressController.text.trim();

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
          onSuccess   : () {
            Navigator.of(context).pop(); // ferme le sheet paiement
            ref.read(cartProvider.notifier).clearCart(); // vide le panier local
            // L'adresse ponctuelle ne vaut que pour cette commande
            ref.read(deliveryAddressProvider.notifier).state = null;
            _showLivreurSearchSheet(
              transaction,
              departNom      : departNom,
              departAdresse  : departAdresse,
              arriveeAdresse : arriveeAdresse,
            );
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

  void _showLivreurSearchSheet(
    TransactionModel transaction, {
    required String departNom,
    required String departAdresse,
    required String arriveeAdresse,
  }) {
    showModalBottomSheet(
      context            : context,
      isDismissible      : false,
      enableDrag         : false,
      isScrollControlled : true,
      backgroundColor    : Colors.white,
      shape              : const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LivreurSearchSheet(
        transaction    : transaction,
        departNom      : departNom,
        departAdresse  : departAdresse,
        arriveeAdresse : arriveeAdresse,
        isRetrait      : widget.isRetrait,
        onGoHome: () {
          Navigator.of(context).pop();
          context.goNamed(RouteNames.home);
        },
        onTrackOrder: (commandeId) async {
          Navigator.of(context).pop();
          if (!mounted) return;
          context.goNamed(RouteNames.home);
          // L'écran de détail attend une mission de la liste unifiée :
          // on retrouve celle qui porte cette commande.
          try {
            final missions = await ApiService().getMissions();
            final match = missions
                .where((m) => m.commandeStructureId == commandeId)
                .toList();
            if (match.isNotEmpty && mounted) {
              context.pushNamed(RouteNames.orderDetail, extra: match.first);
            }
          } catch (e) {
            debugPrint('⚠️ Suivi commande introuvable : $e');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart  = ref.watch(cartProvider).cart;
    final total = cart?.montantTotal ?? 0.0;
    final count = cart?.totalArticles ?? 0;

    // Met à jour le champ quand l'adresse est changée via le sheet
    ref.listen(deliveryAddressProvider, (_, next) {
      if (next != null) _addressController.text = next.adresse;
    });

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
                    montantLabel(total),
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
                      value : montantLabel(total),
                      bold  : true,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      icon  : widget.isRetrait
                          ? Icons.storefront_outlined
                          : Icons.local_shipping_outlined,
                      label : widget.isRetrait
                          ? 'Retrait sur place'
                          : 'Livraison à domicile',
                      value : '',
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 20),

                    // ── Réception ────────────────────────────
                    _SectionLabel(
                        widget.isRetrait ? 'Retrait' : 'Livraison'),
                    const SizedBox(height: 14),

                    if (widget.isRetrait) ...[
                      // Retrait : pas d'adresse à saisir, on rappelle
                      // simplement où récupérer la commande
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color        : AppColors.primarySurface,
                          borderRadius : BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Retrait sur place',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight : FontWeight.w700,
                                      color      : AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cart != null && cart.lignes.length == 1
                                        ? cart.lignes.first.nomStructure
                                        : 'Vous serez prévenu dès que votre '
                                            'commande sera prête.',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.grey600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      // Lecture seule : l'adresse se choisit via le bottom
                      // sheet (GPS ou autocomplétion) pour garantir que les
                      // coordonnées envoyées correspondent à l'adresse
                      YaaTextField(
                        controller : _addressController,
                        label      : 'Adresse de livraison',
                        hint       : 'Choisir une adresse…',
                        prefixIcon : Icons.location_on_outlined,
                        readOnly   : true,
                        onTap      : () => showDeliveryAddressSheet(context),
                        suffixIcon : const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.grey500),
                        validator  : (v) =>
                            v == null || v.trim().isEmpty ? 'Champ requis' : null,
                      ),

                    const SizedBox(height: AppDimens.lg),
                    PhoneTextField(
                      controller      : _phoneController,
                      label           : 'Téléphone',
                      textInputAction : TextInputAction.next,
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
                  : 'Valider la commande · ${montantLabel(total)}',
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
    required this.onSuccess,
  });

  final TransactionModel transaction;
  final VoidCallback     onSuccess;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  int     _selectedIndex = 0;
  bool    _isPaying      = false;
  String? _error;

  // Seul le paiement en espèces est opérationnel. Les opérateurs
  // mobiles restent visibles mais désactivés : les masquer donnerait
  // l'impression qu'ils n'arriveront jamais.
  static const _methods = [
    _PaymentMethod('Espèces', 'ESPECE', null,
        AppColors.successLight, AppColors.success, disponible: true),
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
            '${montantLabel(tx.montant)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 16),

          // ── Options de paiement ────────────────────────────
          ...List.generate(_methods.length, (i) {
            final m      = _methods[i];
            final active = i == _selectedIndex;
            final ouvert = m.disponible;

            // Un moyen indisponible reste lisible mais éteint :
            // grisé, sans radio, et signalé « Bientôt ».
            final ligne = Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width  : 48,
                    height : 48,
                    decoration: BoxDecoration(
                      color        : ouvert ? m.bgColor : AppColors.grey100,
                      borderRadius : BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: m.imagePath == null
                          ? Icon(Icons.payments_outlined,
                              color: ouvert ? m.accentColor : AppColors.grey400,
                              size: 24)
                          : Image.asset(
                              m.imagePath!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.payment,
                                color: ouvert
                                    ? m.accentColor
                                    : AppColors.grey400,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Nom
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.name,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight : active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize   : 14,
                              color      : ouvert
                                  ? AppColors.dark
                                  : AppColors.grey400,
                            ),
                          ),
                        ),
                        if (!ouvert) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color        : AppColors.grey100,
                              borderRadius : BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Bientôt',
                              style: AppTextStyles.caption.copyWith(
                                color      : AppColors.grey500,
                                fontWeight : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Radio — masqué sur un moyen indisponible
                  if (ouvert)
                    AnimatedContainer(
                      duration  : const Duration(milliseconds: 200),
                      width     : 22,
                      height    : 22,
                      decoration: BoxDecoration(
                        shape  : BoxShape.circle,
                        border : Border.all(
                          color : active ? AppColors.primary : AppColors.grey300,
                          width : active ? 6 : 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            );

            return Column(
              children: [
                if (ouvert)
                  GestureDetector(
                    onTap    : () => setState(() => _selectedIndex = i),
                    behavior : HitTestBehavior.opaque,
                    child    : ligne,
                  )
                else
                  Opacity(opacity: 0.55, child: ligne),
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
            label           : 'Payer · ${montantLabel(tx.montant)}',
            onPressed       : _isPaying ? null : _payer,
            isLoading       : _isPaying,
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
    this.name,
    this.code,
    this.imagePath,
    this.bgColor,
    this.accentColor, {
    this.disponible = false,
  });

  final String name;
  final String code;

  /// Null pour les moyens sans logo — on retombe sur une icône
  final String? imagePath;
  final Color  bgColor;
  final Color  accentColor;

  /// Utilisable dès maintenant. Les autres sont affichés grisés.
  final bool disponible;
}

// ── Bottom sheet de suivi (post-paiement) ────────────────────
// Affiché après un paiement réussi, avec polling du statut.
//   • Livraison → confirmation → préparation → recherche d'un
//     livreur → "Livreur trouvé !"
//   • Retrait   → confirmation → préparation → "Commande prête",
//     aucun coursier n'intervient.
class _LivreurSearchSheet extends StatefulWidget {
  const _LivreurSearchSheet({
    required this.transaction,
    required this.departNom,
    required this.departAdresse,
    required this.arriveeAdresse,
    required this.onGoHome,
    required this.onTrackOrder,
    this.isRetrait = false,
  });

  final TransactionModel    transaction;
  final String              departNom;
  final String              departAdresse;
  final String              arriveeAdresse;
  final VoidCallback        onGoHome;
  final ValueChanged<int>   onTrackOrder;
  final bool                isRetrait;

  @override
  State<_LivreurSearchSheet> createState() => _LivreurSearchSheetState();
}

class _LivreurSearchSheetState extends State<_LivreurSearchSheet>
    with SingleTickerProviderStateMixin {
  // Lent volontairement : donne l'impression d'une vraie recherche
  late final AnimationController _controller = AnimationController(
    vsync    : this,
    duration : const Duration(milliseconds: 4500),
  )..repeat();

  Timer?  _pollTimer;
  String  _statut = 'EN_ATTENTE'; // statut initial après paiement
  int?    _commandeId;
  CommandeDetailModel? _detail; // infos livreur une fois assigné

  /// Le détail de commande n'expose ni la note ni le véhicule du
  /// coursier : on complète depuis la mission correspondante.
  Livreur? _livreur;

  String? get _nomLivreur      => _livreur?.fullName  ?? _detail?.livreurFullName;
  String? get _telLivreur      => _livreur?.telephone ?? _detail?.livreurTelephone;
  String? get _photoLivreur    => _livreur?.photoUrl  ?? _detail?.livreurImageUrl;
  double? get _noteLivreur     => _livreur?.noteMoyenne;
  String? get _vehiculeLivreur => _livreur?.vehicule;

  // En retrait, aucun livreur n'est assigné : le parcours s'achève
  // quand la commande est prête à être récupérée.
  bool get _livreurTrouve =>
      !widget.isRetrait &&
      (_statut == 'LIVREUR_ASSIGNE' || _statut == 'EN_LIVRAISON');
  bool get _commandePrete => widget.isRetrait && _statut == 'PRET';
  bool get _commandeArretee =>
      _statut == 'ANNULE' || _statut == 'REJETE';

  @override
  void initState() {
    super.initState();
    // Polling : on suit l'avancement de la commande créée par cette
    // transaction (même référence) : confirmation → préparation →
    // recherche livreur → livreur assigné
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final commandes =
            await ApiService().getCommandes();
        if (commandes.isEmpty) return;

        // 1. Match par référence (si le backend partage la même
        //    référence entre transaction et commande)
        final matches = commandes.where(
          (c) => c.referenceCommande.toLowerCase() ==
              widget.transaction.reference.toLowerCase(),
        ).toList();

        // 2. Fallback : référence différente → on prend la commande
        //    la plus récente (id max), c'est celle qu'on vient de créer
        final commande = matches.isNotEmpty
            ? matches.first
            : commandes.reduce((a, b) => a.id > b.id ? a : b);

        debugPrint('🔄 Suivi commande #${commande.id} '
            '→ ${commande.statut} (match réf: ${matches.isNotEmpty})');

        _commandeId = commande.id;
        if (commande.statut != _statut && mounted) {
          setState(() => _statut = commande.statut);
        }
        // Plus rien à guetter une fois le livreur trouvé, la commande
        // prête (retrait) ou la commande arrêtée
        if (_livreurTrouve || _commandePrete || _commandeArretee) {
          _pollTimer?.cancel();
          // Détail de la commande pour les infos du livreur
          if (_livreurTrouve) {
            final detail = await ApiService().getCommandeDetail(
              id    : commande.id,
            );
            if (mounted) setState(() => _detail = detail);

            // Photo, note et véhicule ne vivent que sur la mission :
            // on la retrouve par l'identifiant de la commande.
            try {
              final missions = await ApiService().getMissions();
              final match = missions
                  .where((m) => m.commandeStructureId == commande.id)
                  .toList();
              if (match.isNotEmpty && mounted) {
                setState(() => _livreur = match.first.livreur);
              }
            } catch (e) {
              debugPrint('⚠️ Infos livreur enrichies indisponibles : $e');
            }
          }
        }
      } catch (e) {
        // Erreur réseau → on réessaiera au prochain tick
        debugPrint('⚠️ Polling commande: $e');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

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

          const SizedBox(height: 24),

          _livreurTrouve
              ? _buildLivreurTrouve()
              : _commandePrete
                  ? _buildCommandePrete()
                  : _commandeArretee
                      ? _buildCommandeArretee()
                      : _buildEnCours(),
        ],
      ),
    );
  }

  // ── Phase d'avancement selon le statut backend ───────────────
  // EN_ATTENTE → confirmation, CONFIRME/EN_PREPARATION → préparation,
  // PRET/EN_ATTENTE_LIVREUR → recherche livreur
  ({IconData icon, String titre, String message}) get _phase =>
      switch (_statut) {
        'EN_ATTENTE' => (
          icon    : Icons.storefront_rounded,
          titre   : 'En attente de confirmation',
          message : 'Votre commande a été envoyée à l\'établissement, '
                    'il va bientôt la confirmer.',
        ),
        'CONFIRME' || 'EN_PREPARATION' => (
          icon    : Icons.restaurant_rounded,
          titre   : 'Préparation en cours',
          message : 'L\'établissement prépare votre commande.',
        ),
        // En retrait, cette phase n'est jamais atteinte : PRET est
        // un état final traité par _buildCommandePrete().
        'PRET' || 'EN_ATTENTE_LIVREUR' => (
          icon    : Icons.sports_motorsports,
          titre   : 'Recherche d\'un livreur',
          message : 'Nous recherchons un livreur disponible dans votre zone.',
        ),
        _ => (
          icon    : Icons.hourglass_top_rounded,
          titre   : 'Commande en cours de traitement',
          message : 'Votre commande est bien enregistrée.',
        ),
      };

  // ── État : commande en cours (animation par phase) ───────────
  Widget _buildEnCours() {
    final phase = _phase;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                Text(
                  '${phase.titre}${'.' * ((_controller.value * 3).floor() + 1)}',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Scooter qui avance sur une piste pointillée ──
                SizedBox(
                  height: 56,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth = constraints.maxWidth - 48;
                      return Stack(
                        children: [
                          // Piste pointillée
                          Positioned(
                            left  : 0,
                            right : 0,
                            top   : 27,
                            child: Row(
                              children: List.generate(
                                20,
                                (_) => Expanded(
                                  child: Container(
                                    height : 2,
                                    margin : const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    color  : AppColors.grey200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Icône animée (change selon la phase)
                          Positioned(
                            left: trackWidth * _controller.value,
                            top : 4,
                            child: Container(
                              width  : 48,
                              height : 48,
                              decoration: BoxDecoration(
                                color : AppColors.primary,
                                shape : BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius : 12,
                                    offset     : const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(phase.icon,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Message rassurant
        Container(
          width   : double.infinity,
          padding : const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color        : AppColors.grey100,
            borderRadius : BorderRadius.circular(14),
          ),
          child: Text(
            phase.message,
            textAlign : TextAlign.center,
            style     : AppTextStyles.bodySmall.copyWith(
              color  : AppColors.grey600,
              height : 1.5,
            ),
          ),
        ),

        const SizedBox(height: 20),

        _buildTrajet(),

        const SizedBox(height: 12),
        TextButton(
          onPressed : widget.onGoHome,
          child     : Text(
            'Retour à l\'accueil',
            style: AppTextStyles.bodySmall.copyWith(
              color      : AppColors.grey500,
              decoration : TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // ── Détails de la commande : trajet ─────────────────────────
  Widget _buildTrajet() {
    return Container(
      width   : double.infinity,
      padding : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius : BorderRadius.circular(14),
        border       : Border.all(color: AppColors.grey200),
      ),
      // IntrinsicHeight : donne une hauteur finie au Row pour que
      // la colonne dot→pin (avec Expanded) puisse se dimensionner
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colonne dot → pin (le pin et la ligne n'ont de sens
            // qu'en livraison, où il y a un trajet)
            Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width  : 14,
                  height : 14,
                  decoration: BoxDecoration(
                    shape  : BoxShape.circle,
                    border : Border.all(
                        color: AppColors.primary, width: 4),
                  ),
                ),
                if (!widget.isRetrait) ...[
                  Expanded(
                    child: Container(
                      width : 1.5,
                      color : AppColors.grey300,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                  const Icon(Icons.location_on,
                      color: AppColors.secondary, size: 18),
                ],
                const SizedBox(height: 3),
              ],
            ),
            const SizedBox(width: 14),

            // Adresses
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.isRetrait ? 'Point de retrait' : 'Départ',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey400)),
                  const SizedBox(height: 2),
                  Text(
                    widget.departNom,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight : FontWeight.w700,
                      color      : AppColors.dark,
                    ),
                  ),
                  if (widget.departAdresse.isNotEmpty)
                    Text(
                      widget.departAdresse,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // En retrait, il n'y a pas de trajet : le client se
                  // déplace lui-même jusqu'à l'établissement.
                  if (!widget.isRetrait) ...[
                    const SizedBox(height: 16),
                    Text('Livraison',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400)),
                    const SizedBox(height: 2),
                    Text(
                      widget.arriveeAdresse,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight : FontWeight.w600,
                        color      : AppColors.dark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Montant
            Text(
              montantLabel(widget.transaction.montant),
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight : FontWeight.w800,
                color      : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── État : commande prête à retirer (mode retrait) ───────────
  Widget _buildCommandePrete() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width  : 80,
          height : 80,
          decoration: const BoxDecoration(
            shape : BoxShape.circle,
            color : AppColors.successLight,
          ),
          child: const Icon(Icons.shopping_bag_rounded,
              size: 36, color: AppColors.success),
        ),

        const SizedBox(height: 20),

        Text(
          'Commande prête !',
          style: AppTextStyles.h3.copyWith(
            fontWeight : FontWeight.w800,
            color      : AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vous pouvez venir la récupérer.',
          textAlign : TextAlign.center,
          style     : AppTextStyles.bodyMedium.copyWith(
            color  : AppColors.grey500,
            height : 1.5,
          ),
        ),

        const SizedBox(height: 20),

        // Où retirer + montant
        Container(
          width   : double.infinity,
          padding : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius : BorderRadius.circular(14),
            border       : Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Point de retrait',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400)),
                    const SizedBox(height: 2),
                    Text(
                      widget.departNom,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight : FontWeight.w700,
                        color      : AppColors.dark,
                      ),
                    ),
                    if (widget.departAdresse.isNotEmpty)
                      Text(
                        widget.departAdresse,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                montantLabel(widget.transaction.montant),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight : FontWeight.w800,
                  color      : AppColors.dark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        YaaButton(
          label     : 'Voir ma commande',
          onPressed : () => widget.onTrackOrder(_commandeId!),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed : widget.onGoHome,
          child     : Text(
            'Retour à l\'accueil',
            style: AppTextStyles.bodySmall.copyWith(
              color      : AppColors.grey500,
              decoration : TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // ── État : commande annulée / rejetée ────────────────────────
  Widget _buildCommandeArretee() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width  : 80,
          height : 80,
          decoration: const BoxDecoration(
            shape : BoxShape.circle,
            color : AppColors.errorLight,
          ),
          child: const Icon(Icons.close_rounded,
              size: 36, color: AppColors.error),
        ),
        const SizedBox(height: 20),
        Text(
          _statut == 'REJETE' ? 'Commande rejetée' : 'Commande annulée',
          style: AppTextStyles.h3.copyWith(
            fontWeight : FontWeight.w800,
            color      : AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre commande n\'a pas pu être traitée.\nContactez l\'établissement pour plus d\'informations.',
          textAlign : TextAlign.center,
          style     : AppTextStyles.bodyMedium.copyWith(
            color  : AppColors.grey500,
            height : 1.5,
          ),
        ),
        const SizedBox(height: 24),
        YaaButton(
          label     : 'Retour à l\'accueil',
          onPressed : widget.onGoHome,
        ),
      ],
    );
  }

  /// Initiales du livreur pour l'avatar (ex: "Abdoul DIALLO" → "AD")
  String get _livreurInitiales {
    final depuisMission = _livreur?.initiales;
    if (depuisMission != null && depuisMission.isNotEmpty) {
      return depuisMission;
    }
    final prenom = _detail?.livreurName?.trim()     ?? '';
    final nom    = _detail?.livreurLastName?.trim() ?? '';
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty    ? nom[0]    : '';
    return (p + n).toUpperCase();
  }

  /// Avatar fallback : initiales sur fond navy
  Widget _buildInitiales() {
    return Center(
      child: _livreurInitiales.isNotEmpty
          ? Text(
              _livreurInitiales,
              style: const TextStyle(
                fontFamily : 'PlusJakartaSans',
                fontSize   : 30,
                fontWeight : FontWeight.w800,
                color      : Colors.white,
              ),
            )
          : const Icon(Icons.person_rounded,
              color: Colors.white, size: 40),
    );
  }

  Future<void> _appelerLivreur() async {
    final phone = _telLivreur;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── État : livreur trouvé ────────────────────────────────────
  Widget _buildLivreurTrouve() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Livreur trouvé !',
          style: AppTextStyles.h3.copyWith(
            fontWeight : FontWeight.w800,
            color      : AppColors.dark,
          ),
        ),

        const SizedBox(height: 20),

        // ── Photo du livreur (initiales si pas de photo) ──────
        Container(
          width  : 88,
          height : 88,
          decoration: BoxDecoration(
            shape : BoxShape.circle,
            color : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color      : AppColors.primary.withValues(alpha: 0.25),
                blurRadius : 16,
                offset     : const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: _photoLivreur != null
                ? Image.network(
                    _photoLivreur!,
                    width  : 88,
                    height : 88,
                    fit    : BoxFit.cover,
                    errorBuilder: (_, e, __) {
                      debugPrint('❌ photo livreur ($_photoLivreur) : $e');
                      return _buildInitiales();
                    },
                  )
                : _buildInitiales(),
          ),
        ),

        const SizedBox(height: 14),

        // ── Infos du livreur ──────────────────────────────────
        Text(
          _nomLivreur ?? 'Votre livreur',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight : FontWeight.w800,
            fontSize   : 17,
            color      : AppColors.dark,
          ),
        ),

        // Note et véhicule : ce qui rassure avant d'ouvrir sa porte
        if (_noteLivreur != null || _vehiculeLivreur != null) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_noteLivreur != null) ...[
                Icon(Icons.star_rounded,
                    size: 16, color: Colors.amber.shade600),
                const SizedBox(width: 3),
                Text(
                  _noteLivreur!.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize   : 13,
                    fontWeight : FontWeight.w700,
                    color      : AppColors.dark,
                  ),
                ),
              ],
              if (_noteLivreur != null && _vehiculeLivreur != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                      width: 3, height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.grey400,
                        shape: BoxShape.circle,
                      )),
                ),
              if (_vehiculeLivreur != null) ...[
                Icon(
                  TypeVehicule.depuisCode(_vehiculeLivreur)?.icone
                      ?? Icons.local_shipping_outlined,
                  size  : 15,
                  color : AppColors.grey500,
                ),
                const SizedBox(width: 4),
                Text(
                  TypeVehicule.depuisCode(_vehiculeLivreur)?.libelle
                      ?? _vehiculeLivreur!,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize : 13,
                    color    : AppColors.grey500,
                  ),
                ),
              ],
            ],
          ),
        ],

        const SizedBox(height: 4),
        Text(
          'En route vers l\'établissement',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
        ),

        if (_telLivreur != null && _telLivreur!.isNotEmpty) ...[
          const SizedBox(height: 12),
          // Bouton d'appel
          GestureDetector(
            onTap: _appelerLivreur,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color        : AppColors.successLight,
                borderRadius : BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    _telLivreur!,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight : FontWeight.w700,
                      color      : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Itinéraire ────────────────────────────────────────
        _buildTrajet(),

        const SizedBox(height: 16),

        YaaButton(
          label     : 'Suivre ma commande',
          onPressed : () => widget.onTrackOrder(_commandeId!),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed : widget.onGoHome,
          child     : Text(
            'Retour à l\'accueil',
            style: AppTextStyles.bodySmall.copyWith(
              color      : AppColors.grey500,
              decoration : TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
