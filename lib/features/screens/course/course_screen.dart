import '../../../core/utils/devise.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/course/estimation_model.dart';
import '../../../service/api/api_service.dart';
import '../../../service/location/location_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../../course/models/course_models.dart';
import 'course_details_sheet.dart';

/// Écran unique du flow course/livraison, façon Yango :
/// carte Google Maps en fond + bottom sheet qui évolue
/// (saisie A→B → choix véhicule/prix → commander).
class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key, required this.typeService});

  final TypeService typeService;

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  static const _dakar = LatLng(14.6928, -17.4467);

  final _locationService = LocationService();
  final _departCtrl      = TextEditingController();
  final _arriveeCtrl     = TextEditingController();

  GoogleMapController? _mapController;
  Timer?                _debounce;
  List<PlaceSuggestion> _suggestions   = [];
  bool                  _editingDepart = false;
  bool                  _loadingPlace  = false;

  CoursePoint?  _depart;
  CoursePoint?  _arrivee;
  LatLng        _myPosition = _dakar;
  TypeVehicule  _vehicule   = TypeVehicule.moto;

  // Tracé du trajet + marqueurs personnalisés
  List<LatLng>       _routePoints = [];
  BitmapDescriptor?  _departIcon;
  BitmapDescriptor?  _arriveeIcon;

  // Estimation par véhicule (prix, distance, durée)
  Map<TypeVehicule, EstimationModel> _estimations = {};
  bool _loadingEstim = false;
  bool _isSubmitting = false;

  /// Estimation du véhicule actuellement retenu
  EstimationModel? get _estimation =>
      _estimations[_isCourse ? _vehicule : TypeVehicule.moto];

  bool get _isCourse   => widget.typeService == TypeService.course;
  bool get _bothSet    => _depart != null && _arrivee != null;
  bool get _isSearching => _suggestions.isNotEmpty || _loadingPlace;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _initPosition();
  }

  // Génère les marqueurs (cercle coloré + anneau blanc + pointe +
  // icône pin) directement en Dart, aux couleurs de la marque.
  Future<void> _loadMarkerIcons() async {
    _departIcon = await _createMarker(
        AppColors.primary, Icons.location_on_outlined); // bleu
    _arriveeIcon = await _createMarker(
        AppColors.secondary, Icons.location_on_outlined);       // orange
    if (mounted) setState(() {});
  }

  /// Dessine un marqueur type "pin arrondi" et le convertit en
  /// BitmapDescriptor utilisable par Google Maps.
  Future<BitmapDescriptor> _createMarker(Color color, IconData icon) async {
    const double w = 78, circleR = 29, stemH = 14;
    final center = Offset(w / 2, circleR + 5);
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);

    // Ombre douce
    canvas.drawCircle(
      center.translate(0, 2),
      circleR + 4,
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );
    // Anneau blanc
    canvas.drawCircle(center, circleR + 4, Paint()..color = Colors.white);
    // Cercle coloré
    final fill = Paint()..color = color;
    canvas.drawCircle(center, circleR, fill);
    // Pointe (triangle vers le bas)
    final stem = Path()
      ..moveTo(center.dx - 9, center.dy + circleR - 4)
      ..lineTo(center.dx + 9, center.dy + circleR - 4)
      ..lineTo(center.dx, center.dy + circleR + stemH)
      ..close();
    canvas.drawPath(stem, fill);
    // Icône pin blanche au centre
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize    : 30,
          fontFamily  : icon.fontFamily,
          package     : icon.fontPackage,
          color       : Colors.white,
        ),
      )
      ..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    final img = await recorder
        .endRecording()
        .toImage(w.toInt(), (circleR + 5 + circleR + stemH + 4).toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  // Estimation automatique dès que le trajet est complet.
  // Course   → 1 seul appel qui renvoie les tarifs MOTO et VEHICULE.
  // Livraison → estimation moto uniquement.
  Future<void> _loadEstimation() async {
    if (_depart == null || _arrivee == null) return;
    setState(() => _loadingEstim = true);

    try {
      final Map<TypeVehicule, EstimationModel> result = {};

      if (_isCourse) {
        final estimations = await ApiService().getCourseEstimations(
          latitudeDepart   : _depart!.latitude,
          longitudeDepart  : _depart!.longitude,
          latitudeArrivee  : _arrivee!.latitude,
          longitudeArrivee : _arrivee!.longitude,
        );
        // Range chaque tarif selon son typeVehicule (MOTO / VEHICULE).
        // Si le type est inconnu on ignore, pour ne pas écraser un
        // tarif déjà rangé.
        for (final e in estimations) {
          for (final v in TypeVehicule.values) {
            if (v.code == e.typeVehicule) {
              result[v] = e;
              break;
            }
          }
        }
      } else {
        result[TypeVehicule.moto] = await ApiService().getEstimation(
          typeService      : widget.typeService.code,
          typeVehicule     : TypeVehicule.moto.code,
          latitudeDepart   : _depart!.latitude,
          longitudeDepart  : _depart!.longitude,
          latitudeArrivee  : _arrivee!.latitude,
          longitudeArrivee : _arrivee!.longitude,
        );
      }

      if (!mounted) return;
      setState(() {
        _estimations  = result;
        _loadingEstim = false;
      });
    } catch (e) {
      debugPrint('❌ estimation: $e');
      if (mounted) setState(() => _loadingEstim = false);
    }
  }

  // Récupère et dessine le trajet routier A → B
  Future<void> _loadRoute() async {
    if (_depart == null || _arrivee == null) return;
    try {
      final points = await _locationService.getRoutePolyline(
        departLat  : _depart!.latitude,
        departLng  : _depart!.longitude,
        arriveeLat : _arrivee!.latitude,
        arriveeLng : _arrivee!.longitude,
      );
      if (!mounted) return;
      setState(() {
        _routePoints =
            points.map((p) => LatLng(p[0], p[1])).toList();
      });
    } catch (e) {
      debugPrint('❌ route: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _departCtrl.dispose();
    _arriveeCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Position actuelle → point de départ + centrage carte ─────
  Future<void> _initPosition() async {
    try {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _myPosition      = LatLng(result.latitude, result.longitude);
        _depart          = CoursePoint(
          adresse   : result.adresse,
          latitude  : result.latitude,
          longitude : result.longitude,
        );
        _departCtrl.text = result.adresse;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_myPosition, 15),
      );
    } catch (_) {
      // GPS indisponible → on reste sur Dakar
    }
  }

  // ── Autocomplétion ───────────────────────────────────────────
  void _onChanged(String value, {required bool isDepart}) {
    _editingDepart = isDepart;
    if (isDepart) {
      _depart = null;
    } else {
      _arrivee = null;
    }
    // Adresse modifiée → tracé et estimations ne sont plus valables
    _routePoints = [];
    _estimations = {};
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length < 3) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      try {
        final s = await _locationService.autocomplete(value);
        if (mounted) setState(() => _suggestions = s);
      } catch (e) {
        debugPrint('❌ autocomplete: $e');
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions  = [];
      _loadingPlace = true;
    });
    try {
      final result = await _locationService.getPlaceDetails(suggestion);
      if (!mounted) return;
      final point = CoursePoint(
        adresse   : result.adresse,
        latitude  : result.latitude,
        longitude : result.longitude,
      );
      setState(() {
        if (_editingDepart) {
          _depart          = point;
          _departCtrl.text = result.adresse;
        } else {
          _arrivee          = point;
          _arriveeCtrl.text = result.adresse;
        }
        _loadingPlace = false;
      });
      _fitMap();
      if (_bothSet) {
        _loadRoute();
        _loadEstimation();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPlace = false);
    }
  }

  // ── Ajuste la carte pour montrer A et B (ou juste le point) ──
  void _fitMap() {
    final ctrl = _mapController;
    if (ctrl == null) return;

    if (_depart != null && _arrivee != null) {
      final a = LatLng(_depart!.latitude, _depart!.longitude);
      final b = LatLng(_arrivee!.latitude, _arrivee!.longitude);
      final bounds = LatLngBounds(
        southwest: LatLng(
          a.latitude  < b.latitude  ? a.latitude  : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude,
        ),
        northeast: LatLng(
          a.latitude  > b.latitude  ? a.latitude  : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude,
        ),
      );
      ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else {
      final p = _arrivee ?? _depart;
      if (p != null) {
        ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 15),
        );
      }
    }
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_depart != null) {
      markers.add(Marker(
        markerId : const MarkerId('depart'),
        position : LatLng(_depart!.latitude, _depart!.longitude),
        icon     : _departIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (_arrivee != null) {
      markers.add(Marker(
        markerId : const MarkerId('arrivee'),
        position : LatLng(_arrivee!.latitude, _arrivee!.longitude),
        icon     : _arriveeIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    if (_routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId : const PolylineId('trajet'),
        points     : _routePoints,
        color      : AppColors.primary,
        width      : 5,
        startCap   : Cap.roundCap,
        endCap     : Cap.roundCap,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Carte en fond ───────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _myPosition,
              zoom  : 14,
            ),
            onMapCreated: (c) {
              _mapController = c;
              _fitMap();
            },
            myLocationEnabled        : true,
            myLocationButtonEnabled  : false,
            zoomControlsEnabled      : false,
            markers                  : _markers,
            polylines                : _polylines,
            padding: const EdgeInsets.only(bottom: 280),
          ),

          // ── Bouton retour ───────────────────────────────────
          Positioned(
            top   : MediaQuery.of(context).padding.top + 8,
            left  : AppDimens.screenPadding,
            child: GestureDetector(
              onTap    : () => Navigator.of(context).pop(),
              behavior : HitTestBehavior.opaque,
              child: Container(
                width  : 42,
                height : 42,
                decoration: BoxDecoration(
                  color : Colors.white,
                  shape : BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color      : Colors.black.withValues(alpha: 0.12),
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

          // ── Bottom sheet ────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildSheet() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      decoration: const BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow    : [
          BoxShadow(color: Colors.black26, blurRadius: 20),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding, 12, AppDimens.screenPadding, 12),
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
              const SizedBox(height: 16),

              // ── Titre ───────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isCourse ? 'Où allez-vous ?' : 'Envoyer un colis',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isCourse
                      ? 'Renseignez votre trajet'
                      : 'Un coursier récupère et livre votre colis',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ),
              const SizedBox(height: 16),

              // ── Champs A → B ────────────────────────────────
              _buildAddressFields(),

              // ── Contenu dynamique ───────────────────────────
              if (_isSearching)
                _buildSuggestions()
              else
                _buildConfirm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressFields() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape  : BoxShape.circle,
                  border : Border.all(color: AppColors.primary, width: 3.5),
                ),
              ),
              Expanded(
                child: Container(
                  width : 1.5,
                  color : AppColors.grey300,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              const Icon(Icons.location_on,
                  color: AppColors.secondary, size: 18),
              const SizedBox(height: 20),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                YaaTextField(
                  controller : _departCtrl,
                  hint       : 'Point de départ',
                  onChanged  : (v) => _onChanged(v, isDepart: true),
                  onTap      : () => _editingDepart = true,
                ),
                const SizedBox(height: 10),
                YaaTextField(
                  controller : _arriveeCtrl,
                  hint       : 'Où allez-vous ?',
                  onChanged  : (v) => _onChanged(v, isDepart: false),
                  onTap      : () => _editingDepart = false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Flexible(
      child: _loadingPlace
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          : ListView(
              shrinkWrap : true,
              padding    : const EdgeInsets.only(top: 8),
              children   : _suggestions
                  .map((s) => PlaceSuggestionTile(
                        suggestion : s,
                        onTap      : () => _onSuggestionTap(s),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildConfirm() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Course → infos trajet + choix véhicule ; Livraison → carte moto
        if (_isCourse) ...[
          // Distance et durée : identiques pour les 2 véhicules,
          // donc affichées une seule fois au-dessus
          if (_estimation != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color        : AppColors.grey100,
                borderRadius : BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route_rounded,
                      size: 15, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text(
                    _estimation!.distanceText,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight : FontWeight.w700,
                      color      : AppColors.dark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.schedule_rounded,
                      size: 15, color: AppColors.grey500),
                  const SizedBox(width: 6),
                  Text(
                    _estimation!.dureeText,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight : FontWeight.w700,
                      color      : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [TypeVehicule.moto, TypeVehicule.vehicule]
                .map((v) => Expanded(
                      child: _VehiclePick(
                        vehicule : v,
                        selected : v == _vehicule,
                        loading  : _loadingEstim,
                        // Chaque véhicule affiche son propre prix
                        estimation : _estimations[v],
                        // Les 2 estimations sont déjà chargées :
                        // changer de véhicule n'appelle plus l'API
                        onTap    : () => setState(() => _vehicule = v),
                      ),
                    ))
                .toList(),
          ),
        ] else
          _buildMotoCard(),

        const SizedBox(height: 16),

        // Bouton toujours visible, grisé tant que A→B incomplet
        SizedBox(
          width: double.infinity,
          child: YaaButton(
            label     : _isCourse ? 'Commander' : 'Continuer',
            isLoading : _isSubmitting,
            onPressed : (_bothSet && !_isSubmitting) ? _onConfirm : null,
          ),
        ),
      ],
    );
  }

  void _onConfirm() {
    if (_isCourse) {
      _commanderCourse();
      return;
    }
    // Livraison → étape détails expéditeur/destinataire (bottom sheet)
    _showLivraisonSheet();
  }

  // ── Commander une course ─────────────────────────────────────
  Future<void> _commanderCourse() async {
    if (_depart == null || _arrivee == null) return;
    setState(() => _isSubmitting = true);
    try {
      final mission = await ApiService().createCourse(
        typeVehicule     : _vehicule.code,
        latitudeDepart   : _depart!.latitude,
        longitudeDepart  : _depart!.longitude,
        latitudeArrivee  : _arrivee!.latitude,
        longitudeArrivee : _arrivee!.longitude,
        adresseDepart    : _depart!.adresse,
        adresseArrivee   : _arrivee!.adresse,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // Enchaîne sur l'écran de recherche de coursier
      context.pushReplacementNamed(
        RouteNames.coursierSearch,
        extra: mission,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content         : Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor : AppColors.error,
          behavior        : SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLivraisonSheet() {
    showCourseDetailsSheet(
      context,
      CourseFlowArgs(
        typeService : widget.typeService,
        depart      : _depart,
        arrivee     : _arrivee,
      ),
      estimation: _estimation,
    );
  }

  // ── Carte moto (livraison) — inspirée des cartes livreur ─────
  Widget _buildMotoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16),
        border       : Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.05),
            blurRadius : 12,
            offset     : const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image moto (sans fond)
          SizedBox(
            width  : 68,
            height : 68,
            child: Image.asset(
              'assets/images/moto.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_motorsports,
                  color: AppColors.primary, size: 32),
            ),
          ),
          const SizedBox(width: 12),

          // Titre + métadonnées (distance · durée)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livraison par moto',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight : FontWeight.w800,
                    fontSize   : 15,
                    color      : AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.route_rounded,
                        size: 13, color: AppColors.grey400),
                    const SizedBox(width: 3),
                    // distance · durée (depuis l'estimation)
                    Text(
                      _estimation?.metaLabel ?? '— km · — min',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Prix bien visible à droite
          if (_loadingEstim)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _estimation != null
                      ? _estimation!.fraisLivraison.toStringAsFixed(0)
                      : '—',
                  style: const TextStyle(
                    fontFamily : 'PlusJakartaSans',
                    fontWeight : FontWeight.w800,
                    fontSize   : 20,
                    color      : AppColors.dark,
                  ),
                ),
                Text(
                  _estimation?.devise ?? kDevise,
                  style: AppTextStyles.caption.copyWith(
                    color      : AppColors.grey400,
                    fontWeight : FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Choix véhicule compact (course) ──────────────────────────
class _VehiclePick extends StatelessWidget {
  const _VehiclePick({
    required this.vehicule,
    required this.selected,
    required this.loading,
    required this.estimation,
    required this.onTap,
  });

  final TypeVehicule     vehicule;
  final bool             selected;
  final bool             loading;
  final EstimationModel? estimation;
  final VoidCallback     onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration : const Duration(milliseconds: 180),
        margin   : const EdgeInsets.symmetric(horizontal: 4),
        padding  : const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color        : selected ? AppColors.primarySurface : Colors.white,
          borderRadius : BorderRadius.circular(16),
          border: Border.all(
            color : selected ? AppColors.primary : AppColors.grey200,
            width : selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Icône + nom du véhicule
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  vehicule.icone,
                  color : selected ? AppColors.primary : AppColors.grey500,
                  size  : 20,
                ),
                const SizedBox(width: 6),
                Text(
                  vehicule.libelle,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight : FontWeight.w700,
                    color      : selected ? AppColors.primary : AppColors.dark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Prix bien visible
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    estimation != null
                        ? estimation!.fraisLivraison.toStringAsFixed(0)
                        : '—',
                    style: TextStyle(
                      fontFamily : 'PlusJakartaSans',
                      fontSize   : 22,
                      fontWeight : FontWeight.w800,
                      color      : selected ? AppColors.dark : AppColors.grey600,
                    ),
                  ),
                  Text(
                    estimation?.devise ?? kDevise,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight : FontWeight.w600,
                      color      : AppColors.grey400,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
