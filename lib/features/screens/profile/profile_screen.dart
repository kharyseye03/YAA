import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_contacts.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../service/location/location_service.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../cart/providers/delivery_address_provider.dart';
import '../../user/providers/user_notifier.dart';
import '../cart/delivery_address_sheet.dart';
import 'suppression_compte_sheet.dart';

/// Profil du client.
///
/// Les lignes sont groupées en cartes posées sur un fond gris, plutôt
/// qu'alignées à plat. La liste précédente séparait ses blocs par deux
/// styles de filets mélangés — certains pleine largeur, d'autres
/// indentés — ce qui créait des groupes sans jamais dire lesquels.
///
/// Chaque ligne porte aussi la **valeur du moment** en sous-titre :
/// « Informations personnelles / Mame Khary · 622 12 34 56 ». Une
/// ligne qui renseigne vaut mieux qu'une ligne qui pointe ailleurs, et
/// ça supprime la ligne « Téléphone », qui menait au même écran.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Ouvre un lien externe sans jamais laisser l'appui sans effet.
  ///
  /// Sur Android 11+, `canLaunchUrl` renvoie false pour un schéma que
  /// le manifeste ne déclare pas — le bouton semble alors cassé. Les
  /// schémas tel, mailto et https sont déclarés dans `<queries>` ; si
  /// l'appareil n'a malgré tout aucune application pour l'ouvrir, on
  /// 
  /// le dit au lieu de ne rien faire.
  Future<void> _ouvrir(Uri uri, String siImpossible) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(siImpossible)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top     = MediaQuery.of(context).padding.top;
    final user    = ref.watch(userProvider);
    final profile = user.profile;

    // L'adresse retenue pour la prochaine commande, sinon celle du
    // profil. Même règle que dans le panier, pour que les deux écrans
    // ne montrent jamais deux adresses différentes.
    final adresse = ref.watch(deliveryAddressProvider)?.adresse
        ?? profile?.address;

    final telephone = profile?.telephone == null
        ? null
        : formatPhone(telephoneLocal(profile!.telephone));

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: top + AppDimens.xl),

            // ── Identité ──────────────────────────────────
            _enTete(user, profile),

            SizedBox(height: AppDimens.xl),

            // ── Compte ────────────────────────────────────
            _Carte(children: [
              _Ligne(
                icon     : Icons.person_outline_rounded,
                label    : 'Informations personnelles',
                // Le nom et le numéro rendent la ligne utile sans
                // avoir à l'ouvrir. C'est aussi ce qui remplace
                // l'ancienne ligne « Téléphone », qui menait ici.
                subtitle : [profile?.fullName, telephone]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(' · '),
                onTap    : () => context.pushNamed(RouteNames.personalInfo),
              ),
              _Ligne(
                icon     : Icons.location_on_outlined,
                label    : 'Adresse de livraison',
                subtitle : adresse == null
                    ? 'Non renseignée'
                    : LocationService.cleanAddress(adresse),
                // Même feuille que depuis le panier : l'adresse se
                // choisit d'un seul endroit dans l'application.
                onTap    : () => showDeliveryAddressSheet(context),
              ),
            ]),

            SizedBox(height: AppDimens.lg),

            _Carte(children: [
              _Ligne(
                icon     : Icons.receipt_long_outlined,
                label    : 'Historique des commandes',
                subtitle : 'Vos commandes terminées',
                onTap    : () => context.pushNamed(RouteNames.orderHistory),
              ),
            ]),

            SizedBox(height: AppDimens.lg),

            // ── Recrutement ───────────────────────────────
            _CarteCoursier(
              onTap: () => _ouvrir(
                Uri.parse(AppContacts.lienDevenirCoursier),
                'Aucun navigateur disponible',
              ),
            ),

            SizedBox(height: AppDimens.lg),

            // ── Aide ──────────────────────────────────────
            _Carte(children: [
              _Ligne(
                icon     : Icons.headset_mic_outlined,
                label    : 'Support',
                subtitle : 'Nous joindre par téléphone ou e-mail',
                onTap    : _ouvrirSupport,
              ),
              _Ligne(
                icon     : Icons.description_outlined,
                label    : 'Conditions d\'utilisation',
                onTap    : () => context.pushNamed(RouteNames.terms),
              ),
            ]),

            SizedBox(height: AppDimens.lg),

            // ── Fin de session ────────────────────────────
            // Les deux seules actions de l'écran qui ne mènent nulle
            // part mais agissent sur le compte, isolées du reste.
            _Carte(children: [
              _Ligne(
                icon      : Icons.logout_rounded,
                label     : 'Se déconnecter',
                onTap     : _confirmerDeconnexion,
                couleur   : AppColors.error,
                chevron   : false,
              ),
            ]),

            SizedBox(height: AppDimens.lg),

            // Séparée de la déconnexion, et non voisine dans la même
            // carte : l'une est quotidienne, l'autre irréversible.
            // Côte à côte, un doigt pressé confond les deux.
            //
            // Sa présence est une exigence de Google Play, qui impose
            // depuis avril 2024 un chemin de suppression dans l'app.
            _Carte(children: [
              _Ligne(
                icon      : Icons.delete_outline_rounded,
                label     : 'Supprimer mon compte',
                subtitle  : 'Action définitive',
                onTap     : _supprimerCompte,
                couleur   : AppColors.error,
              ),
            ]),

            SizedBox(height: AppDimens.lg),

            Text(
              'YAA · version 1.0.0',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),

            SizedBox(height: 90.h),
          ],
        ),
      ),
    );
  }

  Widget _enTete(dynamic user, dynamic profile) {
    return Column(
      children: [
        Stack(
          children: [
            user.isLoading
                ? Container(
                    width  : 88.r,
                    height : 88.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.grey200,
                    ),
                    child: Center(
                      child: SizedBox(
                        width : 20.r,
                        height: 20.r,
                        child : CircularProgressIndicator(
                            strokeWidth: 2.r, color: AppColors.primary),
                      ),
                    ),
                  )
                : UserAvatar(imageUrl: profile?.imageUrl),
            Positioned(
              bottom: 0,
              right : 0,
              child: GestureDetector(
                onTap: () => context.pushNamed(RouteNames.editPersonalInfo),
                child: Container(
                  width  : 28.r,
                  height : 28.r,
                  decoration: BoxDecoration(
                    color : AppColors.primary,
                    shape : BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Icon(Icons.edit_rounded,
                      color: Colors.white, size: 13.r),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimens.md),
        Text(
          profile?.fullName ?? '—',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w800,
            color     : AppColors.dark,
          ),
        ),
        SizedBox(height: AppDimens.xs),
        Text(
          profile?.email ?? '—',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  /// Feuille de contact du support.
  ///
  /// Deux lignes du profil pour un seul besoin — « joindre YAA » —
  /// c'était une ligne de trop. Le choix du canal est une décision
  /// secondaire : elle appartient à la feuille, pas à l'écran.
  void _ouvrirSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupportSheet(
        onAppeler: () => _ouvrir(
          Uri(scheme: 'tel', path: AppContacts.telephoneSupport),
          'Aucune application téléphone',
        ),
        onEcrire: () => _ouvrir(
          Uri(scheme: 'mailto', path: AppContacts.emailSupport),
          'Aucune application e-mail',
        ),
      ),
    );
  }

  /// Ouvre la feuille de suppression, et nettoie la session si le
  /// compte a réellement été supprimé.
  ///
  /// Le `logout` est indispensable : sans lui, les jetons resteraient
  /// dans le coffre et l'application tenterait de restaurer une
  /// session dont le compte n'existe plus.
  Future<void> _supprimerCompte() async {
    final supprime = await showSuppressionCompteSheet(context);
    if (!supprime || !mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre compte a été supprimé.')),
    );
    context.goNamed(RouteNames.login);
  }

  Future<void> _confirmerDeconnexion() async {
    {
      {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Se déconnecter',
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Êtes-vous sûr de vouloir vous déconnecter ?',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSoft),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Annuler',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSoft)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Se déconnecter',
                  style: AppTextStyles.bodySmall.copyWith(
                    color     : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        await ref.read(authProvider.notifier).logout();
        // `mounted` de l'État, et non `context.mounted` : c'est bien
        // ce widget qui doit être encore là pour naviguer.
        if (!mounted) return;
        context.goNamed(RouteNames.login);
      }
    }
  }
}

// ── Feuille de contact du support ─────────────────────────────
class _SupportSheet extends StatelessWidget {
  const _SupportSheet({required this.onAppeler, required this.onEcrire});

  final VoidCallback onAppeler;
  final VoidCallback onEcrire;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color        : AppColors.surface,
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppDimens.md, AppDimens.lg, AppDimens.md, AppDimens.sm),
              child: Column(
                children: [
                  Text(
                    'Contacter le support',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color     : AppColors.dark,
                    ),
                  ),
                  SizedBox(height: AppDimens.xs),
                  Text(
                    'Nous répondons du lundi au samedi',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.grey100),
            _Ligne(
              icon     : Icons.phone_outlined,
              label    : 'Appeler',
              subtitle : AppContacts.telephoneSupport,
              // La feuille se ferme avant d'ouvrir l'application
              // externe : au retour, l'utilisateur retrouve le profil
              // et non une feuille restée ouverte derrière.
              onTap    : () {
                Navigator.of(context).pop();
                onAppeler();
              },
            ),
            Padding(
              padding: EdgeInsets.only(left: 52.w),
              child: const Divider(height: 1, color: AppColors.grey100),
            ),
            _Ligne(
              icon     : Icons.mail_outline_rounded,
              label    : 'Écrire',
              subtitle : AppContacts.emailSupport,
              onTap    : () {
                Navigator.of(context).pop();
                onEcrire();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte groupée ─────────────────────────────────────────────
class _Carte extends StatelessWidget {
  const _Carte({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      decoration: BoxDecoration(
        color        : AppColors.surface,
        borderRadius : BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            // Filet entre deux lignes seulement, jamais après la
            // dernière : le bord de la carte fait déjà la séparation.
            if (i < children.length - 1)
              Padding(
                padding: EdgeInsets.only(left: 52.w),
                child: const Divider(height: 1, color: AppColors.grey100),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Ligne de carte ────────────────────────────────────────────
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.couleur,
    this.chevron = true,
  });

  final IconData     icon;
  final String       label;
  final String?      subtitle;
  final VoidCallback onTap;

  /// Teinte l'icône et le libellé. Réservé à la déconnexion : c'est
  /// la seule ligne qui ne mène pas à un écran mais agit sur la
  /// session, et le rouge la distingue au premier coup d'œil.
  final Color? couleur;

  /// Le chevron annonce « ceci ouvre autre chose ». Une action qui
  /// s'exécute sur place n'en a pas.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final sousTitre = subtitle;
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical  : AppDimens.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: couleur ?? AppColors.textSoft),
            SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize  : 14.sp,
                      fontWeight: couleur == null
                          ? FontWeight.w600
                          : FontWeight.w700,
                      color     : couleur ?? AppColors.dark,
                    ),
                  ),
                  if (sousTitre != null && sousTitre.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      sousTitre,
                      maxLines : 1,
                      overflow : TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (chevron)
              Icon(Icons.chevron_right,
                  size: 18.r, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

// ── Carte « Devenir coursier » ────────────────────────────────
/// Seule carte sombre de l'écran, et seul endroit de l'application
/// client où YAA peut recruter ses coursiers. Le contraste attire
/// l'œil sans avoir besoin de crier.
class _CarteCoursier extends StatelessWidget {
  const _CarteCoursier({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: Container(
        margin : EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical  : AppDimens.lg,
        ),
        decoration: BoxDecoration(
          color        : AppColors.primary,
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width  : 36.r,
              height : 36.r,
              decoration: BoxDecoration(
                color : AppColors.secondary,
                shape : BoxShape.circle,
              ),
              // Le casque, comme sur la carte Livraison de l'accueil
              // et le marqueur du coursier : c'est déjà le signe du
              // métier dans l'application.
              child: Icon(Icons.sports_motorsports,
                  color: Colors.white, size: 20.r),
            ),
            SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devenir coursier YAA',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize  : 14.sp,
                      fontWeight: FontWeight.w700,
                      color     : Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Roulez, livrez, gagnez',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18.r, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}
