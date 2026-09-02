import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../service/api/api_service.dart';
import '../../../service/location/location_service.dart';
import '../../../shared/utils/map_markers.dart';
import '../order/detail_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPins();
    // Si un coursier est déjà là à l'ouverture (retour sur l'écran)
    if (_coursierTrouve) _refreshMap();
    if (_terminee) {
      // Mission déjà close : rien à suivre, on propose l'avis
      _pulse.stop();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _proposerNotation());
    } else {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadPins() async {
    _pinDepart  = await createPinMarker(
        AppColors.primary, Icons.trip_origin_rounded);
    _pinArrivee = await createPinMarker(
        AppColors.secondary, Icons.location_on_outlined);
    // Le coursier est représenté par son véhicule, sur une pastille
    // blanche. Repli sur un pin classique si l'image manque.
    try {
      _pinLivreur = await createImageMarker('assets/images/moto.png');
    } catch (e) {
      debugPrint('⚠️ marqueur moto indisponible : $e');
      _pinLivreur = await createPinMarker(
          AppColors.dark, Icons.sports_motorsports, scale: 0.8);
    }
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
        debugPrint('🔄 mission #${updated.id} → ${updated.statut} '
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
          _pulse.stop();
          _proposerNotation();
        } else if (_coursierTrouve) {
          _pulse.stop();
        }
      } catch (e) {
        // Réseau instable → on réessaiera au prochain tick
        debugPrint('⚠️ Suivi mission: $e');
      }
    });
  }

  // ── Notation en fin de course ────────────────────────────────
  bool _notationProposee = false;

  /// Affichée une seule fois, quand la mission s'achève normalement.
  /// Une mission annulée n'a rien à noter.
  Future<void> _proposerNotation() async {
    debugPrint('⭐ notation ? statut=${_mission.statut} '
        'déjàProposée=$_notationProposee monté=$mounted');
    if (_notationProposee || !mounted) return;
    if (_mission.statut != 'COURSE_TERMINEE') return;
    _notationProposee = true;
    debugPrint('⭐ ouverture du sheet de notation');

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
      final points = await _locationService.getRoutePolyline(
        departLat  : depuis.latitude,
        departLng  : depuis.longitude,
        arriveeLat : vers.latitude,
        arriveeLng : vers.longitude,
      );
      if (!mounted) return;
      setState(() {
        _routePoints       = points.map((p) => LatLng(p[0], p[1])).toList();
        _posDernierTrace   = depuis;
        _phaseDernierTrace = m.versDestination;
      });
    } catch (e) {
      debugPrint('❌ trajet coursier: $e');
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
      // Marge généreuse en bas : le panneau masque une partie
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Quitter n'annule rien : la recherche continue côté serveur
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _retourAccueil();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Carte ───────────────────────────────────────
            // Gestes désactivés : la caméra reste centrée sur le
            // point de départ, ce qui permet de dessiner les ondes
            // au centre de l'écran de façon parfaitement fluide.
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
              padding: const EdgeInsets.only(bottom: 220),
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
                        width  : 320,
                        height : 320,
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

            // ── Bouton retour ───────────────────────────────
            Positioned(
              top  : MediaQuery.of(context).padding.top + 8,
              left : AppDimens.screenPadding,
              child: GestureDetector(
                onTap    : _retourAccueil,
                behavior : HitTestBehavior.opaque,
                child: Container(
                  width  : 42,
                  height : 42,
                  decoration: BoxDecoration(
                    color : Colors.white,
                    shape : BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color      : Colors.black.withValues(alpha: 0.2),
                        blurRadius : 8,
                        offset     : const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.dark, size: 20),
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
      width  : 22,
      height : 22,
      decoration: BoxDecoration(
        color  : AppColors.secondary,
        shape  : BoxShape.circle,
        border : Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.3),
            blurRadius : 8,
          ),
        ],
      ),
    );
  }

  // ── Panneau : recherche en cours ou coursier trouvé ─────────
  Widget _buildPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color        : AppColors.grey300,
                  borderRadius : BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              if (_coursierTrouve)
                _buildCoursier()
              else
                _buildRecherche(),

              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.grey200),
              const SizedBox(height: 14),

              _buildTrajet(),

              const SizedBox(height: 14),

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
            const SizedBox(height: 4),
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

  /// Même présentation que dans le détail d'une commande : photo
  /// centrée, nom, puis note et appel. Le type de véhicule n'y figure
  /// pas — il n'apprend rien au client, qui verra bien ce qui arrive.
  Widget _buildCoursier() {
    final livreur = _mission.livreur!;
    return CarteCoursier(
      nom       : livreur.fullName,
      telephone : livreur.telephone,
      photoUrl  : livreur.photoUrl,
      note      : livreur.noteMoyenne,
      vehicule  : livreur.vehiculeCoursier,
    );
  }

  Widget _buildTrajet() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 11, height: 11,
                decoration: BoxDecoration(
                  shape  : BoxShape.circle,
                  border : Border.all(color: AppColors.primary, width: 3),
                ),
              ),
              Expanded(
                child: Container(
                  width : 1.5,
                  color : AppColors.grey300,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                ),
              ),
              const Icon(Icons.location_on,
                  color: AppColors.secondary, size: 16),
              const SizedBox(height: 3),
            ],
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 12),
                Text(
                  LocationService.cleanAddress(_mission.adresseArrivee),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _mission.montantLabel,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
