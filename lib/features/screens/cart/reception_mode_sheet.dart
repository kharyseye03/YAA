import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/cart/cart_structure_model.dart';
import '../../../model/course/estimation_model.dart';
import '../../../model/course/type_vehicule.dart';
import '../../../service/api/api_service.dart';
import '../../../shared/widgets/yaa_button.dart';

/// Comment le client récupère sa commande. Le regroupement des
/// livraisons (GROUPAGE/INDIVIDUEL) n'est plus proposé : il relève
/// de la logistique interne, pas d'un choix client.
enum ModeReception {
  livraison('LIVRAISON'),
  retrait('RETRAIT_CLIENT');

  const ModeReception(this.code);
  final String code;
}

/// Ce que le sheet renvoie au panier, puis au tunnel de paiement.
class ChoixReception {
  const ChoixReception({
    required this.mode,
    this.typeVehicule,
    this.fraisLivraison,
    this.devise,
  });

  final ModeReception mode;

  /// MOTO, CARGO… — nul en retrait, aucun véhicule n'étant mobilisé
  final String? typeVehicule;
  final double? fraisLivraison;
  final String? devise;
}

Future<void> showReceptionModeSheet(
  BuildContext context, {
  required List<CartStructureModel> lignes,
  required double? latitudeClient,
  required double? longitudeClient,
  required ValueChanged<ChoixReception> onConfirm,
}) {
  return showModalBottomSheet(
    context            : context,
    isScrollControlled : true,
    backgroundColor    : Colors.transparent,
    builder            : (_) => _ReceptionModeSheet(
      lignes          : lignes,
      latitudeClient  : latitudeClient,
      longitudeClient : longitudeClient,
      onConfirm       : onConfirm,
    ),
  );
}

class _ReceptionModeSheet extends StatefulWidget {
  const _ReceptionModeSheet({
    required this.lignes,
    required this.latitudeClient,
    required this.longitudeClient,
    required this.onConfirm,
  });

  final List<CartStructureModel>   lignes;
  final double?                    latitudeClient;
  final double?                    longitudeClient;
  final ValueChanged<ChoixReception> onConfirm;

  @override
  State<_ReceptionModeSheet> createState() => _ReceptionModeSheetState();
}

class _ReceptionModeSheetState extends State<_ReceptionModeSheet> {
  ModeReception _mode = ModeReception.livraison;

  List<EstimationModel> _options    = const [];
  EstimationModel?      _choix;
  bool                  _chargement = true;
  String?               _erreur;

  /// Plusieurs établissements dans le panier : la tarification d'une
  /// tournée à plusieurs points de retrait n'est pas arrêtée côté
  /// backend. On n'estime rien et on laisse le simple choix du mode.
  bool get _multi => widget.lignes.length > 1;

  @override
  void initState() {
    super.initState();
    // On n'attend pas que l'utilisateur choisisse : la livraison est
    // le défaut, les tarifs doivent déjà être là quand son œil arrive
    // dessus.
    if (_multi) {
      _chargement = false;
    } else {
      _chargerEstimations();
    }
  }

  Future<void> _chargerEstimations() async {
    setState(() {
      _chargement = true;
      _erreur     = null;
    });

    try {
      final lat = widget.latitudeClient;
      final lng = widget.longitudeClient;
      if (lat == null || lng == null || (lat == 0 && lng == 0)) {
        throw Exception('Adresse de livraison introuvable');
      }

      final api = ApiService();

      // Le panier ne porte pas les coordonnées de l'établissement :
      // il faut aller les chercher pour connaître le point de départ.
      final structure = await api.getStructureById(
        widget.lignes.first.structureId,
      );

      final options = await api.getLivraisonCommandeEstimations(
        latitudeDepart   : structure.latitude,
        longitudeDepart  : structure.longitude,
        latitudeArrivee  : lat,
        longitudeArrivee : lng,
      );

      if (!mounted) return;
      setState(() {
        _options    = options;
        _choix      = options.isEmpty ? null : options.first;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur     = e.toString().replaceAll('Exception: ', '');
        _chargement = false;
      });
    }
  }

  void _confirmer() {
    final livraison = _mode == ModeReception.livraison;
    widget.onConfirm(ChoixReception(
      mode           : _mode,
      typeVehicule   : livraison ? _choix?.typeVehicule : null,
      fraisLivraison : livraison ? _choix?.fraisLivraison : null,
      devise         : livraison ? _choix?.devise : null,
    ));
  }

  String get _libelleBouton {
    if (_mode == ModeReception.retrait) return 'Confirmer et commander';
    final choix = _choix;
    if (choix == null) return 'Confirmer et commander';
    return 'Confirmer · ${choix.prixDevise} de livraison';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final multi     = widget.lignes.length > 1;
    final livraison = _mode == ModeReception.livraison;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color        : AppColors.grey300,
              borderRadius : BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comment récupérer votre commande ?',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight : FontWeight.w800,
                      color      : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Le mode retenu s'affiche en grand, l'autre se
                  // réduit à un lien — on libère la place pour les
                  // tarifs sans jamais enfermer l'utilisateur.
                  AnimatedSize(
                    duration : const Duration(milliseconds: 250),
                    curve    : Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: livraison
                        ? _blocLivraison(multi)
                        : _blocRetrait(multi),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding, 4,
                AppDimens.screenPadding, bottomPad + 16),
            child: YaaButton(
              label           : _libelleBouton,
              onPressed       : _confirmer,
              icon            : Icons.arrow_forward,
              backgroundColor : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mode livraison : carte + tarifs + lien vers le retrait ──────
  Widget _blocLivraison(bool multi) {
    return Column(
      key: const ValueKey('livraison'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeCard(
          selected    : true,
          icon        : Icons.local_shipping_outlined,
          title       : 'Me faire livrer',
          description : 'Un livreur vous apporte votre commande '
              'à l\'adresse de votre choix.',
          onTap       : () {},
        ),
        // Rien à proposer tant que la tournée multi-points n'est pas
        // tarifée : mieux vaut ne rien afficher qu'un prix faux.
        if (!multi) ...[
          const SizedBox(height: 16),
          _blocTarifs(),
        ],
        const SizedBox(height: 16),
        _lienBascule(
          libelle : 'Ou retirer sur place',
          icone   : Icons.storefront_outlined,
          onTap   : () => setState(() => _mode = ModeReception.retrait),
        ),
      ],
    );
  }

  // ── Mode retrait : carte + lien de retour ───────────────────────
  Widget _blocRetrait(bool multi) {
    return Column(
      key: const ValueKey('retrait'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeCard(
          selected    : true,
          icon        : Icons.storefront_outlined,
          title       : 'Retrait sur place',
          description : multi
              ? 'Vous passez récupérer vos commandes dans les '
                  '${widget.lignes.length} établissements.'
              : 'Vous passez récupérer votre commande chez '
                  '${widget.lignes.first.nomStructure}.',
          badge       : multi ? '${widget.lignes.length} points' : null,
          onTap       : () {},
        ),
        const SizedBox(height: 16),
        _lienBascule(
          libelle : 'Ou me faire livrer',
          icone   : Icons.local_shipping_outlined,
          onTap   : () => setState(() => _mode = ModeReception.livraison),
        ),
      ],
    );
  }

  Widget _lienBascule({
    required String libelle,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icone, size: 18, color: AppColors.grey500),
            const SizedBox(width: 10),
            Text(
              libelle,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight : FontWeight.w600,
                color      : AppColors.grey600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  // ── Tarifs par véhicule ─────────────────────────────────────────
  Widget _blocTarifs() {
    if (_chargement) return const _TarifsSquelette();

    if (_erreur != null) {
      return _EncartDiscret(
        icone   : Icons.wifi_off_rounded,
        couleur : AppColors.warning,
        texte   : 'Tarifs indisponibles — $_erreur',
        action  : ('Réessayer', _chargerEstimations),
      );
    }

    if (_options.isEmpty) {
      return const _EncartDiscret(
        icone   : Icons.info_outline_rounded,
        couleur : AppColors.grey500,
        texte   : 'Aucun mode de livraison proposé pour cette adresse.',
      );
    }

    final reference = _choix ?? _options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route_outlined,
                size: 15, color: AppColors.grey500),
            const SizedBox(width: 6),
            Text(
              reference.metaLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color      : AppColors.grey600,
                fontWeight : FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _grilleVehicules(),
      ],
    );
  }

  /// Le backend expose six types de véhicule. Jusqu'à deux options on
  /// occupe toute la largeur ; au-delà on fait défiler, sinon les
  /// cartes deviennent illisibles.
  Widget _grilleVehicules() {
    Widget carte(EstimationModel e) => _VehiculeCard(
          estimation : e,
          selected   : _choix?.typeVehicule == e.typeVehicule,
          onTap      : () => setState(() => _choix = e),
        );

    if (_options.length <= 2) {
      return Row(
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: carte(_options[i])),
          ],
        ],
      );
    }

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection : Axis.horizontal,
        padding         : EdgeInsets.zero,
        itemCount       : _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder     : (_, i) => SizedBox(
          width : 132,
          child : carte(_options[i]),
        ),
      ),
    );
  }
}

// ── Carte d'un type de véhicule ───────────────────────────────────
class _VehiculeCard extends StatelessWidget {
  const _VehiculeCard({
    required this.estimation,
    required this.selected,
    required this.onTap,
  });

  final EstimationModel estimation;
  final bool            selected;
  final VoidCallback    onTap;

  /// Un code inconnu s'affiche tel quel plutôt que de disparaître de
  /// la liste : mieux vaut une option mal nommée qu'une option perdue.
  static ({String libelle, IconData icone}) _info(String? code) {
    final type = TypeVehicule.depuisCode(code);
    if (type != null) return (libelle: type.libelle, icone: type.icone);
    return (
      libelle: code ?? 'Véhicule',
      icone  : Icons.local_shipping_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info(estimation.typeVehicule);

    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration  : const Duration(milliseconds: 200),
        padding   : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color        : selected
              ? AppColors.secondary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius : BorderRadius.circular(14),
          border       : Border.all(
            color : selected ? AppColors.secondary : AppColors.grey200,
            width : selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  info.icone,
                  size  : 22,
                  color : selected ? AppColors.secondary : AppColors.grey600,
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity : selected ? 1 : 0,
                  child   : const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              info.libelle,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight : FontWeight.w600,
                color      : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              estimation.prixDevise,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight : FontWeight.w800,
                fontSize   : 15,
                color      : AppColors.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              estimation.dureeText,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Squelette de chargement ───────────────────────────────────────
class _TarifsSquelette extends StatelessWidget {
  const _TarifsSquelette();

  @override
  Widget build(BuildContext context) {
    Widget bloc({required double hauteur, double? largeur}) => Container(
          height : hauteur,
          width  : largeur,
          decoration: BoxDecoration(
            color        : AppColors.grey100,
            borderRadius : BorderRadius.circular(6),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bloc(hauteur: 12, largeur: 120),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: bloc(hauteur: 104)),
            const SizedBox(width: 10),
            Expanded(child: bloc(hauteur: 104)),
          ],
        ),
      ],
    );
  }
}

// ── Encart d'information discret ──────────────────────────────────
class _EncartDiscret extends StatelessWidget {
  const _EncartDiscret({
    required this.icone,
    required this.couleur,
    required this.texte,
    this.action,
  });

  final IconData icone;
  final Color    couleur;
  final String   texte;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color        : couleur.withValues(alpha: 0.06),
        borderRadius : BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, size: 18, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: AppTextStyles.bodySmall.copyWith(
                color  : AppColors.grey700,
                height : 1.35,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action!.$2,
              style: TextButton.styleFrom(
                padding        : const EdgeInsets.symmetric(horizontal: 8),
                minimumSize    : Size.zero,
                tapTargetSize  : MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!.$1,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight : FontWeight.w700,
                  color      : couleur,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Carte option de mode ──────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final bool         selected;
  final IconData     icon;
  final String       title;
  final String       description;
  final String?      badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration  : const Duration(milliseconds: 200),
        padding   : const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color        : selected
              ? AppColors.secondary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius : BorderRadius.circular(14),
          border       : Border.all(
            color : selected ? AppColors.secondary : AppColors.grey200,
            width : selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width  : 42,
              height : 42,
              decoration: BoxDecoration(
                color        : selected
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.grey100,
                borderRadius : BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size  : 20,
                color : selected ? AppColors.secondary : AppColors.grey600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight : FontWeight.w700,
                          color      : AppColors.dark,
                          fontSize   : 14,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color        : AppColors.grey100,
                            borderRadius : BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: AppTextStyles.caption.copyWith(
                              color      : AppColors.grey600,
                              fontWeight : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color  : AppColors.grey500,
                      height : 1.4,
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
