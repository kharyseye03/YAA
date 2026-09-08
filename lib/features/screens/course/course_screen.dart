import '../../../shared/utils/map_markers.dart';
import '../../../core/utils/journal.dart';
import '../../../core/errors/messages_erreur.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Préfixé : MapsConfig déclare son propre LatLng (un record), qui
// entrerait en conflit avec la classe LatLng de google_maps_flutter.
import '../../../config/maps/maps_config.dart' as config;
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
  /// Centre de repli tant que le GPS n'a pas répondu. Vient de
  /// MapsConfig pour rester cohérent avec le pays auquel
  /// l'autocomplétion est restreinte.
  static const _villeParDefaut = LatLng(
    config.MapsConfig.villeLat,
    config.MapsConfig.villeLng,
  );

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
  LatLng        _myPosition = _villeParDefaut;
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

  /// Les marqueurs dépendent de la densité de l'écran, qui se lit
  /// dans MediaQuery — interdit depuis initState. D'où ce garde-fou :
  /// didChangeDependencies peut être rappelé, le chargement non.
  bool _iconesChargees = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iconesChargees) return;
    _iconesChargees = true;
    _loadMarkerIcons(MediaQuery.devicePixelRatioOf(context));
  }

  @override
  void initState() {
    super.initState();
    _initPosition();
  }

  // Génère les marqueurs (cercle coloré + anneau blanc + pointe +
  // icône pin) directement en Dart, aux couleurs de la marque.
  Future<void> _loadMarkerIcons(double densite) async {
    _departIcon = await createPinMarker(
        AppColors.primary, Icons.location_on_outlined,
        densite: densite); // bleu
    _arriveeIcon = await createPinMarker(
        AppColors.secondary, Icons.location_on_outlined,
        densite: densite); // orange
    if (mounted) setState(() {});
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
      journal('❌ estimation: $e');
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
      journal('❌ route: $e');
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
        journal('❌ autocomplete: $e');
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
            padding: EdgeInsets.only(bottom: 280.h),
          ),

          // ── Bouton retour ───────────────────────────────────
          Positioned(
            top   : MediaQuery.of(context).padding.top + 8,
            left  : AppDimens.screenPadding,
            child: GestureDetector(
              onTap    : () => Navigator.of(context).pop(),
              behavior : HitTestBehavior.opaque,
              child: Container(
                width  : 42.r,
                height : 42.r,
                decoration: BoxDecoration(
                  color : Colors.white,
                  shape : BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color      : Colors.black.withValues(alpha: 0.12),
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
    // La feuille grandit pendant la recherche : à 62 % on ne voit que
    // deux suggestions, ce qui oblige à scroller dans un espace déjà
    // réduit par le clavier.
    //
    // Au repos, 70 % : les deux véhicules empilés ne tenaient pas dans
    // 62 %. Le plafond reste une proportion de l'écran — il n'y a rien
    // à mettre à l'échelle ici, la carte garde toujours sa part.
    return AnimatedContainer(
      duration : const Duration(milliseconds: 220),
      curve    : Curves.easeOutCubic,
      width    : double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            (_isSearching ? 0.88 : 0.70),
      ),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow    : [
          BoxShadow(color: Colors.black26, blurRadius: 20.r),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppDimens.screenPadding, 12, AppDimens.screenPadding, 12),
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
              SizedBox(height: 16.h),

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
              SizedBox(height: 16.h),

              // ── Champs A → B ────────────────────────────────
              _buildAddressFields(),

              // ── Contenu dynamique ───────────────────────────
              // Les deux branches sont Flexible : sous une hauteur
              // plafonnée, un enfant non flexible reçoit une contrainte
              // infinie et déborde au lieu de s'adapter.
              if (_isSearching)
                _buildSuggestions()
              else
                Flexible(child: _buildConfirm()),
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
              SizedBox(height: 20.h),
              Container(
                width: 12.r, height: 12.r,
                decoration: BoxDecoration(
                  shape  : BoxShape.circle,
                  border : Border.all(color: AppColors.primary, width: 3.5.w),
                ),
              ),
              Expanded(
                child: Container(
                  width : 1.5,
                  color : AppColors.grey300,
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                ),
              ),
              Icon(Icons.location_on,
                  color: AppColors.secondary, size: 18.r),
              SizedBox(height: 20.h),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              children: [
                YaaTextField(
                  controller : _departCtrl,
                  hint       : 'Point de départ',
                  onChanged  : (v) => _onChanged(v, isDepart: true),
                  onTap      : () => _editingDepart = true,
                ),
                SizedBox(height: 10.h),
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
          ? Padding(
              padding: EdgeInsets.all(24.r),
              child: CircularProgressIndicator(),
            )
          : ListView(
              shrinkWrap : true,
              padding    : EdgeInsets.only(top: 8.h),
              children   : [
                for (var i = 0; i < _suggestions.length; i++)
                  PlaceSuggestionTile(
                    suggestion  : _suggestions[i],
                    onTap       : () => _onSuggestionTap(_suggestions[i]),
                    showDivider : i < _suggestions.length - 1,
                  ),
              ],
            ),
    );
  }

  Widget _buildConfirm() {
    // Le bouton reste posé en bas, hors du défilement : c'est l'action
    // de l'écran, elle ne doit jamais demander de scroller pour être
    // atteinte. Seul le choix du véhicule glisse, et uniquement sur les
    // écrans trop courts pour l'afficher entier.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16.h),

                // Course → trajet + choix véhicule ; Livraison → moto
                if (_isCourse) ...[
                  // Distance seule : la durée est désormais portée par
                  // chaque tuile véhicule, la répéter ici la ferait
                  // apparaître trois fois sur le même écran.
                  if (_estimation != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color        : AppColors.grey100,
                        borderRadius : BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route_rounded,
                              size: 15.r, color: AppColors.grey500),
                          SizedBox(width: 6.w),
                          Text(
                            _estimation!.distanceText,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight : FontWeight.w700,
                              color      : AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  // Aligné à gauche comme les champs d'adresse au-dessus :
                  // un titre de section démarre là où le contenu démarre.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choisir un moyen de transport',
                      textAlign: TextAlign.left,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight : FontWeight.w700,
                        fontSize   : 15.sp,
                        color      : AppColors.dark,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimens.md),

                  // Empilées plutôt que côte à côte : les prix s'alignent
                  // dans une colonne, et c'est eux qu'on compare.
                  for (final v in [TypeVehicule.moto, TypeVehicule.vehicule])
                    ...[
                    _VehiclePick(
                      vehicule : v,
                      selected : v == _vehicule,
                      loading  : _loadingEstim,
                      // Chaque véhicule affiche son propre prix
                      estimation : _estimations[v],
                      // Les 2 estimations sont déjà chargées :
                      // changer de véhicule n'appelle plus l'API
                      onTap    : () => setState(() => _vehicule = v),
                    ),
                    if (v != TypeVehicule.vehicule)
                      SizedBox(height: AppDimens.sm),
                  ],
                ] else ...[
                  _buildMotoCard(),
                  SizedBox(height: 10.h),
                  _buildOptionsRow(),
                ],
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

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
          content         : Text(MessagesErreur.depuisException(e)),
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

  /// Raccourci vers l'étape détails du colis.
  ///
  /// Mène volontairement au même endroit que le bouton principal :
  /// deux entrées visuelles, un seul chemin. Il suit donc la même
  /// règle d'activation, sinon on ouvrirait l'étape détails sans
  /// trajet renseigné.
  Widget _buildOptionsRow() {
    final actif = _bothSet && !_isSubmitting;

    return InkWell(
      onTap        : actif ? _onConfirm : null,
      borderRadius : BorderRadius.circular(14.r),
      child: Opacity(
        opacity: actif ? 1 : 0.45,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius : BorderRadius.circular(14.r),
            border       : Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 20.r, color: AppColors.primary),
              SizedBox(width: 10.w),
              Text(
                'Options de livraison',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight : FontWeight.w600,
                  color      : AppColors.dark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Laisser un colis, notes…',
                  textAlign : TextAlign.right,
                  maxLines  : 1,
                  overflow  : TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey500),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  size: 20.r, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  /// Bloc gris traversé par un reflet, à la place d'une valeur pas
  /// encore connue.
  ///
  /// Volontairement appliqué valeur par valeur, et non à la carte
  /// entière : le véhicule et son libellé sont connus d'avance, les
  /// masquer ne donnait qu'une bande grise sans rapport avec ce qui
  /// allait s'afficher.
  Widget _shimmerBloc(double w, double h) => Shimmer.fromColors(
        baseColor      : AppColors.grey200,
        highlightColor : AppColors.grey100,
        child: Container(
          width  : w,
          height : h,
          decoration: BoxDecoration(
            color        : AppColors.grey200,
            borderRadius : BorderRadius.circular(4.r),
          ),
        ),
      );

  // ── Carte moto (livraison) — inspirée des cartes livreur ─────
  Widget _buildMotoCard() {
    final pret = _estimation != null;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.circular(16.r),
        border       : Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color      : Colors.black.withValues(alpha: 0.05),
            blurRadius : 12.r,
            offset     : const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image moto (sans fond) — toujours visible, y compris
          // pendant l'attente de l'estimation.
          SizedBox(
            width  : 68.r,
            height : 68.r,
            child: Image.asset(
              TypeVehicule.moto.asset!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                  TypeVehicule.moto.icone,
                  color: AppColors.primary, size: 32.r),
            ),
          ),
          SizedBox(width: 12.w),

          // Titre + métadonnées (distance · durée)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livraison par moto',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight : FontWeight.w800,
                    fontSize   : 15.sp,
                    color      : AppColors.dark,
                  ),
                ),
                SizedBox(height: 3.h),
                if (pret)
                  Row(
                    children: [
                      Icon(Icons.route_rounded,
                          size: 13.r, color: AppColors.grey400),
                      SizedBox(width: 3.w),
                      // distance · durée (depuis l'estimation)
                      Text(
                        _estimation!.metaLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: _shimmerBloc(104, 11),
                  ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          // Prix bien visible à droite
          if (!pret)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _shimmerBloc(58, 18),
                SizedBox(height: 6.h),
                _shimmerBloc(32, 9),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _estimation!.fraisLivraison.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily : 'PlusJakartaSans',
                    fontWeight : FontWeight.w800,
                    fontSize   : 20.sp,
                    color      : AppColors.dark,
                  ),
                ),
                Text(
                  _estimation!.devise,
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
/// Une ligne du sélecteur de véhicule.
///
/// Disposition horizontale plutôt qu'en tuiles carrées : le visuel à
/// gauche, le libellé au centre, le prix à droite. Chaque ligne se lit
/// d'un balayage vertical, et les prix s'alignent dans une colonne —
/// ce qui est précisément ce qu'on compare.
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

  /// Visuel du véhicule, avec repli sur l'icône quand aucune image
  /// n'est définie pour ce type ou que le fichier manque.
  Widget _visuel() {
    final icone = Icon(
      vehicule.icone,
      size  : 30.r,
      color : selected ? AppColors.primary : AppColors.grey500,
    );
    final asset = vehicule.asset;
    if (asset == null) return icone;

    return Image.asset(
      asset,
      height       : 44.h,
      width        : 62.w,
      fit          : BoxFit.contain,
      errorBuilder : (_, __, ___) => icone,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le squelette ne couvre que la zone prix : le véhicule et son
    // libellé sont connus d'avance, les masquer empêcherait de
    // comparer les options pendant le calcul.
    final pret = estimation != null && !loading;

    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration : const Duration(milliseconds: 180),
        padding  : EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color        : selected ? AppColors.primarySurface : Colors.white,
          borderRadius : BorderRadius.circular(14.r),
          border: Border.all(
            color : selected ? AppColors.primary : AppColors.grey200,
            width : selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 62.w, child: Center(child: _visuel())),
            SizedBox(width: 12.w),

            // Libellé et argument, à gauche
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicule.libelle,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize   : 15.sp,
                      fontWeight : FontWeight.w700,
                      color      : selected
                          ? AppColors.primary
                          : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    vehicule.description,
                    maxLines : 1,
                    overflow : TextOverflow.ellipsis,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSoft),
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            // Prix et durée, à droite — alignés d'une ligne à l'autre
            if (pret)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${estimation!.fraisLivraison.toStringAsFixed(0)}'
                    ' ${estimation!.devise}',
                    style: TextStyle(
                      fontFamily : 'PlusJakartaSans',
                      fontSize   : 17.sp,
                      fontWeight : FontWeight.w800,
                      color      : selected
                          ? AppColors.dark
                          : AppColors.grey600,
                    ),
                  ),
                  Text(
                    estimation!.dureeText,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              )
            else
              Shimmer.fromColors(
                baseColor      : AppColors.grey200,
                highlightColor : AppColors.grey100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _barre(72, 15),
                    SizedBox(height: 5.h),
                    _barre(42, 9),
                  ],
                ),
              ),

            // Pastille de sélection en bout de ligne
            SizedBox(width: 10.w),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity : selected ? 1 : 0,
              child: Container(
                width  : 20.r,
                height : 20.r,
                decoration: const BoxDecoration(
                  color : AppColors.primary,
                  shape : BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 13.r, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _barre(double w, double h) => Container(
        width  : w,
        height : h,
        decoration: BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.circular(4.r),
        ),
      );
}
