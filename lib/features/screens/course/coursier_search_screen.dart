import 'dart:async';
import '../../../core/utils/journal.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../service/api/api_service.dart';
import '../../../service/location/location_service.dart';
import '../../../model/course/type_vehicule.dart';
import '../../../shared/utils/map_markers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_contacts.dart';
import '../../../core/errors/messages_erreur.dart';
import '../../../core/utils/devise.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../order/confirmation_annulation.dart';
import 'rating_sheet.dart';

/// Écran affiché juste après la création d'une livraison ou d'une
/// course : la carte reste visible mais assombrie, et des ondes
/// partent du point de départ tant qu'aucun coursier n'a accepté.
///
/// Dès qu'un coursier est assigné, le panneau du bas se transforme
/// en fiche coursier (nom, téléphone, appel).
class CoursierSearchScreen extends StatefulWidget {
  const CoursierSearchScreen({super.key, required this.mission});

  final LivraisonCourseModel mission;

  @override
  State<CoursierSearchScreen> createState() => _CoursierSearchScreenState();
}

class _CoursierSearchScreenState extends State<CoursierSearchScreen>
    with SingleTickerProviderStateMixin {
  // Une seule boucle d'animation ; les ondes sont décalées entre elles
  late final AnimationController _pulse = AnimationController(
    vsync    : this,
    duration : const Duration(milliseconds: 2600),
  )..repeat();

  late LivraisonCourseModel _mission = widget.mission;
  Timer? _pollTimer;

  /// Vrai pendant l'appel d'annulation : le lien se verrouille, un
  /// double toucher enverrait deux requêtes.
  bool _enAnnulation = false;

  /// Délai au bout duquel on prévient que la recherche traîne.
  ///
  /// Quatre minutes : assez pour qu'un coursier se libère aux heures
  /// creuses de Conakry, assez court pour qu'on ne laisse personne
  /// devant une animation sans fin. Le serveur, lui, continue de
  /// chercher — il n'expire pas les missions, c'est une limite connue.
  static const _delaiRechercheLongue = Duration(minutes: 4);

  Timer? _alerteTimer;

  /// Vrai une fois le délai écoulé sans coursier.
  bool _rechercheLongue = false;

  /// Durée du trajet restant, telle que Google la calcule au moment du
  /// tracé. Null tant qu'aucun itinéraire n'a été obtenu : on n'affiche
  /// alors aucune estimation, plutôt qu'un chiffre inventé.
  int? _dureeMinutes;

  GoogleMapController? _mapController;
  final _locationService = LocationService();

  // Marqueurs générés une fois, réutilisés à chaque rafraîchissement
  BitmapDescriptor? _pinDepart;
  BitmapDescriptor? _pinArrivee;
  BitmapDescriptor? _pinLivreur;

  List<LatLng> _routePoints = [];

  // Le tracé vient de Google Directions, facturé à l'appel. On ne le
  // recalcule donc pas à chaque rafraîchissement : le marqueur du
  // coursier, lui, bouge à chaque fois — visuellement c'est identique.
  static const double _seuilRecalculMetres = 50;
  LatLng? _posDernierTrace;
  bool?   _phaseDernierTrace;

  /// Un coursier a accepté : la recherche est terminée
  bool get _coursierTrouve => _mission.hasLivreur;

  /// La mission est arrêtée (terminée ou annulée)
  bool get _terminee => !_mission.isEnCours;

  LatLng get _depart =>
      LatLng(_mission.latitudeDepart, _mission.longitudeDepart);

  LatLng get _arrivee =>
      LatLng(_mission.latitudeArrivee, _mission.longitudeArrivee);

  /// Les pins dépendent de la densité de l'écran, qui se lit dans
  /// MediaQuery — interdit depuis initState. D'où ce garde-fou :
  /// didChangeDependencies peut être rappelé, le chargement non.
  bool _pinsCharges = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pinsCharges) return;
    _pinsCharges = true;
    _loadPins(MediaQuery.devicePixelRatioOf(context));
  }

  @override
  void initState() {
    super.initState();
    // Si un coursier est déjà là à l'ouverture (retour sur l'écran)
    if (_coursierTrouve) _refreshMap();
    if (_terminee) {
      // Mission déjà close : rien à suivre, on propose l'avis
      _pulse.stop();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _proposerNotation());
    } else {
      _startPolling();
      _armerAlerteRecherche();
    }
  }

  /// Au bout de [_delaiRechercheLongue] sans coursier, remplace
  /// l'animation de recherche par un message d'attente, qui renvoie au
  /// lien d'annulation juste en dessous.
  ///
  /// Le minuteur ne s'arme que si la recherche est en cours : rouvrir
  /// l'écran d'une mission déjà acceptée ne doit pas déclencher
  /// l'alerte quatre minutes plus tard.
  void _armerAlerteRecherche() {
    _alerteTimer = Timer(_delaiRechercheLongue, () {
      if (mounted && !_coursierTrouve && !_terminee) {
        setState(() => _rechercheLongue = true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _alerteTimer?.cancel();
    _mapController?.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadPins(double densite) async {
    _pinDepart  = await createPinMarker(
        AppColors.primary, Icons.trip_origin_rounded, densite: densite);
    _pinArrivee = await createPinMarker(
        AppColors.secondary, Icons.location_on_outlined, densite: densite);
    // Le coursier est représenté par son véhicule vu de dessus, posé
    // nu sur la carte.
    //
    // Le visuel suit le véhicule réellement utilisé, que le coursier
    // renseigne, et retombe sur celui demandé à la commande. La moto
    // était auparavant codée en dur : un client qui commandait une
    // voiture voyait une moto approcher, et `suivi_voiture.png` ne
    // servait à rien.
    final type = TypeVehicule.depuisCode(_mission.livreur?.vehicule)
        ?? TypeVehicule.depuisCode(_mission.typeVehicule);
    final asset = type?.assetSuivi;

    if (asset != null) {
      try {
        _pinLivreur = await createImageMarker(asset, densite: densite);
      } catch (e) {
        journal('⚠️ marqueur $asset indisponible : $e');
      }
    }

    _pinLivreur ??= await createPinMarker(
        AppColors.dark, type?.icone ?? Icons.sports_motorsports,
        scale: 0.8, densite: densite);
    if (mounted) setState(() {});
  }

  // ── Suivi : on guette l'assignation d'un coursier ────────────
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final missions = await ApiService().getMissions();
        final match =
            missions.where((m) => m.id == _mission.id).toList();
        if (match.isEmpty || !mounted) return;

        final updated  = match.first;
        journal('🔄 mission #${updated.id} → ${updated.statut} '
            '(enCours: ${updated.isEnCours})');
        final aChange  = updated.statut != _mission.statut ||
            updated.livreurFullName  != _mission.livreurFullName ||
            updated.latitudeLivreur  != _mission.latitudeLivreur ||
            updated.longitudeLivreur != _mission.longitudeLivreur;

        if (aChange) {
          setState(() => _mission = updated);
          if (_coursierTrouve) _refreshMap();
        }
        // Mission close → plus rien à guetter. Tant qu'elle est en
        // cours on continue, même après l'assignation : la position
        // du coursier évolue.
        if (_terminee) {
          _pollTimer?.cancel();
          _alerteTimer?.cancel();
          _pulse.stop();
          _proposerNotation();
        } else if (_coursierTrouve) {
          _pulse.stop();
          // Un coursier a répondu : l'alerte d'attente n'a plus lieu
          // d'être, qu'elle soit déjà affichée ou encore à venir.
          _alerteTimer?.cancel();
          if (_rechercheLongue) {
            setState(() => _rechercheLongue = false);
          }
        }
      } catch (e) {
        // Réseau instable → on réessaiera au prochain tick
        journal('⚠️ Suivi mission: $e');
      }
    });
  }

  // ── Notation en fin de course ────────────────────────────────
  bool _notationProposee = false;

  /// Affichée une seule fois, quand la mission s'achève normalement.
  /// Une mission annulée n'a rien à noter.
  Future<void> _proposerNotation() async {
    journal('⭐ notation ? statut=${_mission.statut} '
        'déjàProposée=$_notationProposee monté=$mounted');
    if (_notationProposee || !mounted) return;
    if (_mission.statut != 'COURSE_TERMINEE') return;
    _notationProposee = true;
    journal('⭐ ouverture du sheet de notation');

    await showRatingSheet(context, _mission);
    if (mounted) _retourAccueil();
  }

  // ── Carte : trajet du coursier + cadrage ─────────────────────
  /// Trace le chemin depuis le coursier jusqu'à sa cible du moment :
  /// le point de retrait tant qu'il n'a pas récupéré le colis, la
  /// destination ensuite. Sans position connue, on trace A → B.
  Future<void> _refreshMap() async {
    final m = _mission;
    final depuis = m.hasLivreurPosition
        ? LatLng(m.latitudeLivreur!, m.longitudeLivreur!)
        : _depart;
    final vers = (m.hasLivreurPosition && !m.versDestination)
        ? _depart
        : _arrivee;

    // Recalcul seulement si le coursier a franchi le seuil, ou s'il
    // vient de récupérer le colis (la cible du tracé change alors).
    if (_routePoints.isNotEmpty &&
        _posDernierTrace != null &&
        _phaseDernierTrace == m.versDestination) {
      final metres = Geolocator.distanceBetween(
        _posDernierTrace!.latitude, _posDernierTrace!.longitude,
        depuis.latitude,           depuis.longitude,
      );
      if (metres < _seuilRecalculMetres) return;
    }

    try {
      final route = await _locationService.getRoute(
        departLat  : depuis.latitude,
        departLng  : depuis.longitude,
        arriveeLat : vers.latitude,
        arriveeLng : vers.longitude,
      );
      final points = route.points;
      if (!mounted) return;
      setState(() {
        _dureeMinutes      = route.dureeMinutes;
        _routePoints       = points.map((p) => LatLng(p[0], p[1])).toList();
        _posDernierTrace   = depuis;
        _phaseDernierTrace = m.versDestination;
      });
    } catch (e) {
      journal('❌ trajet coursier: $e');
    }
    _fitCamera();
  }

  /// Cadre la carte sur tous les points utiles
  void _fitCamera() {
    final ctrl = _mapController;
    if (ctrl == null) return;

    final points = <LatLng>[
      _depart,
      _arrivee,
      if (_mission.hasLivreurPosition)
        LatLng(_mission.latitudeLivreur!, _mission.longitudeLivreur!),
    ];

    var minLat = points.first.latitude,  maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      90,
    ));
  }

  Set<Marker> get _markers {
    if (!_coursierTrouve) return {};
    final m = _mission;
    return {
      if (_pinDepart != null)
        Marker(
          markerId : const MarkerId('depart'),
          position : _depart,
          icon     : _pinDepart!,
        ),
      if (_pinArrivee != null)
        Marker(
          markerId : const MarkerId('arrivee'),
          position : _arrivee,
          icon     : _pinArrivee!,
        ),
      if (m.hasLivreurPosition && _pinLivreur != null)
        Marker(
          markerId : const MarkerId('livreur'),
          position : LatLng(m.latitudeLivreur!, m.longitudeLivreur!),
          icon     : _pinLivreur!,
        ),
    };
  }

  Set<Polyline> get _polylines {
    if (!_coursierTrouve || _routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId : const PolylineId('trajet'),
        points     : _routePoints,
        color      : AppColors.secondary,
        width      : 5,
        startCap   : Cap.roundCap,
        endCap     : Cap.roundCap,
      ),
    };
  }

  void _retourAccueil() => context.goNamed(RouteNames.home);

  /// Annule la mission depuis l'écran d'attente.
  ///
  /// Le lien n'apparaît que sur les statuts annulables, mais c'est le
  /// serveur qui tranche : cet écran interroge l'API toutes les
  /// quelques secondes, et un coursier peut arriver au point de
  /// départ entre l'affichage et le toucher. Son refus est affiché
  /// tel quel.
  ///
  /// Après l'annulation, retour à l'accueil : il n'y a plus rien à
  /// suivre sur cette carte.
  Future<void> _annuler() async {
    final livraison = _mission.typeService == TypeServiceMission.livraison;
    final confirme = await confirmerAnnulation(
      context,
      titre   : livraison
          ? 'Annuler cette livraison ?'
          : 'Annuler cette course ?',
      message : _mission.hasLivreur
          ? 'Un coursier a déjà accepté et se dirige vers le point de '
              'départ. Il en sera informé. Vous ne pourrez pas revenir '
              'en arrière.'
          : 'La recherche d\'un coursier s\'arrêtera. Vous ne pourrez '
              'pas revenir en arrière.',
      libelleGarder  : livraison
          ? 'Garder ma livraison'
          : 'Garder ma course',
      libelleAnnuler : livraison
          ? 'Annuler la livraison'
          : 'Annuler la course',
    );
    if (confirme != true || !mounted) return;

    setState(() => _enAnnulation = true);
    try {
      await ApiService().annulerMission(_mission.id);
      if (!mounted) return;
      _pollTimer?.cancel();
      _retourAccueil();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enAnnulation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MessagesErreur.depuisException(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _retourAccueil();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _depart, zoom: 15.5),
              onMapCreated: (c) {
                _mapController = c;
                if (_coursierTrouve) _fitCamera();
              },
              markers                 : _markers,
              polylines               : _polylines,
              zoomControlsEnabled     : false,
              myLocationButtonEnabled : false,
              // Carte figée pendant la recherche (les ondes sont
              // dessinées au centre) ; manipulable une fois le
              // coursier trouvé, pour suivre son trajet.
              scrollGesturesEnabled   : _coursierTrouve,
              zoomGesturesEnabled     : _coursierTrouve,
              rotateGesturesEnabled   : false,
              tiltGesturesEnabled     : false,
              padding: EdgeInsets.only(bottom: 220.h),
            ),

            // ── Voile sombre (uniquement pendant la recherche) ──
            if (!_coursierTrouve)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),

            // ── Ondes + point de départ ─────────────────────
            if (!_coursierTrouve && !_terminee)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => SizedBox(
                        width  : 320.r,
                        height : 320.r,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Trois ondes décalées d'un tiers de cycle
                            for (var i = 0; i < 3; i++)
                              _onde((_pulse.value + i / 3) % 1.0),
                            _pointDepart(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Bandeau d'état, au-dessus de la carte ───────
            //
            // Reprend la lecture du panneau mais en un coup d'œil :
            // quand on suit un point qui avance, on ne veut pas
            // baisser les yeux pour savoir ce qui se passe.
            if (_coursierTrouve)
              Positioned(
                top   : MediaQuery.of(context).padding.top + 14,
                // Centré et libre de sa largeur : la pastille ne fait
                // que la taille de son texte, au lieu de barrer
                // l'écran d'un bord à l'autre.
                left  : 62.w,
                right : 16.w,
                child : Align(
                  alignment : Alignment.centerRight,
                  child     : _bandeauEtat(),
                ),
              ),

            // ── Bouton retour ───────────────────────────────
            Positioned(
              top  : MediaQuery.of(context).padding.top + 8,
              left : AppDimens.screenPadding,
              child: GestureDetector(
                onTap    : _retourAccueil,
                behavior : HitTestBehavior.opaque,
                child: Container(
                  width  : 42.r,
                  height : 42.r,
                  decoration: BoxDecoration(
                    color : Colors.white,
                    shape : BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color      : Colors.black.withValues(alpha: 0.2),
                        blurRadius : 8.r,
                        offset     : const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.dark, size: 20.r),
                ),
              ),
            ),

            // ── Panneau du bas ──────────────────────────────
            Align(
              alignment : Alignment.bottomCenter,
              child     : _buildPanel(),
            ),
          ],
        ),
      ),
    );
  }

  /// Onde : grandit et s'estompe au fil du cycle [t] (0 → 1)
  Widget _onde(double t) {
    final size    = 70 + t * 240;
    final opacity = (1 - t) * 0.5;
    return Container(
      width  : size,
      height : size,
      decoration: BoxDecoration(
        shape  : BoxShape.circle,
        color  : AppColors.secondary.withValues(alpha: opacity * 0.25),
        border : Border.all(
          color : AppColors.secondary.withValues(alpha: opacity),
          width : 2,
        ),
      ),
    );
  }

  Widget _pointDepart() {
    return Container(
      width  : 22.r,
      height : 22.r,
      decoration: BoxDecoration(
        color  : AppColors.secondary,
        shape  : BoxShape.circle,
        border : Border.all(color: Colors.white, width: 4.w),
        boxShadow: [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.3),
            blurRadius : 8.r,
          ),
        ],
      ),
    );
  }

  // ── Panneau : recherche en cours ou coursier trouvé ─────────
  Widget _buildPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppDimens.screenPadding, 14, AppDimens.screenPadding, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée
              Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(
                  color        : AppColors.grey300,
                  borderRadius : BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 18.h),

              if (_coursierTrouve) ...[
                _buildCoursier(),
                SizedBox(height: 14.h),
                _boutonAppeler(),
                SizedBox(height: 14.h),
                _carteTrajet(),
                SizedBox(height: 10.h),
                _carteStatut(),
                SizedBox(height: 14.h),
              ] else ...[
                _buildRecherche(),
                SizedBox(height: 16.h),
                const Divider(height: 1, color: AppColors.grey200),
                SizedBox(height: 14.h),
                _buildTrajet(),
                SizedBox(height: 14.h),
              ],

              // L'annulation se décide ici, pendant l'attente : c'est
              // l'écran où l'on est quand on change d'avis, bien avant
              // d'aller la chercher dans le détail de la commande.
              // Elle disparaît dès que le coursier arrive au point de
              // départ, comme le veut le serveur.
              if (_mission.peutEtreAnnulee) ...[
                LienAnnuler(
                  libelle : _mission.typeService ==
                          TypeServiceMission.livraison
                      ? 'Annuler la livraison'
                      : 'Annuler la course',
                  enCours : _enAnnulation,
                  onTap   : _annuler,
                ),
                SizedBox(height: 4.h),
              ],

              TextButton(
                onPressed : _retourAccueil,
                child     : Text(
                  'Retour à l\'accueil',
                  style: AppTextStyles.bodySmall.copyWith(
                    color      : AppColors.grey500,
                    decoration : TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecherche() {
    // Passé ce délai, on cesse de faire patienter en silence.
    //
    // La recherche continue côté serveur — l'app ne peut pas
    // l'arrêter, seul le backend le pourrait. Ce qu'elle peut faire,
    // c'est dire la vérité et offrir une sortie : sans ce message,
    // l'animation tourne indéfiniment et laisse croire que quelque
    // chose avance.
    if (_rechercheLongue) {
      return Column(
        children: [
          Icon(Icons.schedule_rounded, size: 30.r, color: AppColors.grey400),
          SizedBox(height: 10.h),
          Text(
            'La recherche prend plus de temps que prévu',
            textAlign : TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
              fontSize   : 16.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Aucun coursier ne s\'est encore libéré dans votre zone. '
            'Vous pouvez patienter encore un peu ou annuler.',
            textAlign : TextAlign.center,
            style     : AppTextStyles.bodySmall
                .copyWith(color: AppColors.grey500, height: 1.45),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final dots = '.' * ((_pulse.value * 3).floor() + 1);
        return Column(
          children: [
            Text(
              'Recherche d\'un coursier$dots',
              style: AppTextStyles.h3.copyWith(
                fontWeight : FontWeight.w800,
                color      : AppColors.dark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Nous prévenons les coursiers disponibles autour de vous.',
              textAlign : TextAlign.center,
              style     : AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey500),
            ),
          ],
        );
      },
    );
  }

  /// Le coursier, en ligne : portrait à gauche, identité au centre,
  /// plaque à droite.
  ///
  /// Remplace la présentation centrée empruntée au détail d'une
  /// commande. Sur cet écran on suit quelqu'un qui arrive : on veut
  /// reconnaître la personne et son véhicule d'un coup d'œil, pas lire
  /// une fiche. D'où le véhicule et la plaque mis en avant — ce sont
  /// eux qu'on cherche dans la rue.
  Widget _buildCoursier() {
    final livreur  = _mission.livreur!;
    final vehicule = livreur.vehiculeCoursier;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        UserAvatar(imageUrl: livreur.photoUrl, size: 56.r),
        SizedBox(width: 12.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                livreur.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(
                  fontWeight : FontWeight.w800,
                  color      : AppColors.dark,
                  fontSize   : 17.sp,
                ),
              ),
              if (livreur.noteMoyenne != null) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 15.r, color: AppColors.warning),
                    SizedBox(width: 3.w),
                    Text(
                      livreur.noteMoyenne!.toStringAsFixed(1),
                      style: AppTextStyles.bodySmall.copyWith(
                        color      : AppColors.dark,
                        fontWeight : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              if (vehicule != null && vehicule.description.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  vehicule.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ],
          ),
        ),

        // La plaque, encadrée : c'est l'information qu'on relit en
        // levant les yeux vers la rue.
        if (vehicule?.immatriculation != null &&
            vehicule!.immatriculation!.isNotEmpty) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color        : AppColors.primarySurface,
              borderRadius : BorderRadius.circular(8.r),
            ),
            child: Text(
              vehicule.immatriculation!,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight    : FontWeight.w800,
                color         : AppColors.primary,
                letterSpacing : 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Bouton d'appel, pleine largeur.
  ///
  /// Seul moyen de joindre le coursier : l'app n'a pas de messagerie,
  /// et promettre un bouton « Message » qui n'existe pas serait pire
  /// que de ne rien proposer.
  Widget _boutonAppeler() {
    final numero = _mission.livreur?.telephone;

    return Row(
      children: [
        if (numero != null && numero.isNotEmpty) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed : () => _appeler(numero),
              icon      : Icon(Icons.phone_rounded, size: 17.r),
              label     : const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor : AppColors.success,
                foregroundColor : Colors.white,
                elevation       : 0,
                padding         : EdgeInsets.symmetric(vertical: 7.h),
                minimumSize   : Size(0, 38.h),
                tapTargetSize : MaterialTapTargetSize.shrinkWrap,
                textStyle: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
        ],

        // Support, et non « Message » : l'app n'a pas de messagerie.
        // Il joint le support de YAA par téléphone, ce qui est utile
        // tout de suite ; la destination définitive reste à décider.
        Expanded(
          child: OutlinedButton.icon(
            onPressed : () => _appeler(AppContacts.telephoneSupport),
            icon      : Icon(Icons.headset_mic_outlined, size: 17.r),
            label     : const Text('Support'),
            style: OutlinedButton.styleFrom(
              foregroundColor : AppColors.primary,
              backgroundColor : AppColors.primarySurface,
              side            : BorderSide.none,
              padding         : EdgeInsets.symmetric(vertical: 7.h),
              minimumSize     : Size(0, 38.h),
              tapTargetSize   : MaterialTapTargetSize.shrinkWrap,
              textStyle: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _appeler(String numero) async {
    final uri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune application téléphone.')),
    );
  }

  /// Départ et arrivée dans un bloc gris, avec le prix à droite.
  ///
  /// Chaque adresse porte son rôle en sous-titre — « Point de départ »,
  /// « Votre adresse de livraison » — parce que deux lignes d'adresses
  /// se ressemblent et qu'on ne sait plus laquelle est laquelle.
  Widget _carteTrajet() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color        : AppColors.background,
        borderRadius : BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTrajet(avecRoles: true)),
          SizedBox(width: 10.w),
          Text(
            montantLabel(_mission.montant, devise: _mission.devise),
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  /// Où en est la mission, en une phrase.
  ///
  /// Le texte suit **deux** variables : le service et l'avancement.
  /// Une course transporte une personne, une livraison transporte un
  /// colis — « votre commande est en route » n'a aucun sens quand
  /// c'est le client lui-même qui monte dans le véhicule. Et tant que
  /// le coursier n'a pas pris en charge, rien n'est « en route » :
  /// c'est lui qui vient.
  ({String titre, String detail, IconData icone}) _statutLisible() {
    final course     = _mission.typeService == TypeServiceMission.course;
    final enApproche = !_mission.versDestination;

    if (enApproche) {
      return course
          ? (
              titre  : 'Votre chauffeur est en route',
              detail : 'Il se dirige vers votre point de départ.',
              icone  : Icons.directions_car_rounded,
            )
          : (
              titre  : 'Le coursier vient récupérer votre colis',
              detail : 'Il se dirige vers le point de départ.',
              icone  : Icons.two_wheeler_rounded,
            );
    }

    return course
        ? (
            titre  : 'Course en cours',
            detail : 'Vous êtes en route vers votre destination.',
            icone  : Icons.navigation_rounded,
          )
        : (
            titre  : 'Votre commande est en route',
            detail : 'Le coursier a récupéré votre colis. Il arrive bientôt.',
            icone  : Icons.inventory_2_outlined,
          );
  }

  /// Pastille sombre posée sur la carte : état et temps d'arrivée.
  ///
  /// La durée vient de Google Directions, recalculée à chaque fois que
  /// le tracé l'est. Absente, la seconde ligne disparaît plutôt que
  /// d'afficher une estimation inventée — c'est le genre de chiffre
  /// qu'un client retient et reproche.
  Widget _bandeauEtat() {
    final course = _mission.typeService == TypeServiceMission.course;
    final titre  = _mission.versDestination
        ? (course ? 'Course en cours' : 'Livraison en cours')
        : (course ? 'Chauffeur en route' : 'Coursier en route');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
      decoration: BoxDecoration(
        color        : AppColors.primary,
        borderRadius : BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.22),
            blurRadius : 10.r,
            offset     : const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(course ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
              size: 15.r, color: Colors.white),
          SizedBox(width: 7.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color      : Colors.white,
                    fontWeight : FontWeight.w700,
                    fontSize   : 12.sp,
                  ),
                ),
                if (_dureeMinutes != null)
                  Text(
                    '~ $_dureeMinutes min',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color    : Colors.white.withValues(alpha: 0.85),
                      fontSize : 10.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteStatut() {
    final statut = _statutLisible();

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color        : AppColors.background,
        borderRadius : BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        children: [
          Icon(statut.icone, size: 22.r, color: AppColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statut.titre,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight : FontWeight.w700,
                    color      : AppColors.dark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  statut.detail,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrajet({bool avecRoles = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              SizedBox(height: 3.h),
              Container(
                width: 11.r, height: 11.r,
                decoration: BoxDecoration(
                  shape  : BoxShape.circle,
                  border : Border.all(color: AppColors.primary, width: 3.w),
                ),
              ),
              Expanded(
                child: Container(
                  width : 1.5,
                  color : AppColors.grey300,
                  margin: EdgeInsets.symmetric(vertical: 3.h),
                ),
              ),
              Icon(Icons.location_on,
                  color: AppColors.secondary, size: 16.r),
              SizedBox(height: 3.h),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocationService.cleanAddress(_mission.adresseDepart),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (avecRoles)
                  Text(
                    'Point de départ',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                SizedBox(height: 12.h),
                Text(
                  LocationService.cleanAddress(_mission.adresseArrivee),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (avecRoles)
                  Text(
                    _mission.typeService == TypeServiceMission.livraison
                        ? 'Votre adresse de livraison'
                        : 'Destination',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          // Le prix n'est montré ici que dans l'ancienne disposition ;
          // la carte grise l'affiche elle-même, aligné en haut.
          if (!avecRoles) ...[
            SizedBox(width: 10.w),
            Text(
              _mission.montantLabel,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight : FontWeight.w800,
                color      : AppColors.dark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
