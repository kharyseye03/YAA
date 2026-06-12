import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../service/location/location_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';
import 'providers/auth_notifier.dart';

/// Location permission screen — "Où livrer vos commande ?"
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _locationService   = LocationService();
  final _adresseController = TextEditingController();

  Timer?                _debounce;
  List<PlaceSuggestion> _suggestions      = [];
  LocationResult?       _selectedLocation;
  bool                  _isLoadingGps     = false;
  bool                  _isLoadingPlace   = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _adresseController.dispose();
    super.dispose();
  }

  // ── Position actuelle (GPS) ───────────────────────────────────
  Future<void> _onUseLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _selectedLocation        = result;
        _adresseController.text  = result.adresse;
        _suggestions             = [];
        _isLoadingGps            = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGps = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Autocomplétion pendant la saisie ──────────────────────────
  void _onAdresseChanged(String value) {
    // L'utilisateur modifie l'adresse → on invalide la sélection
    _selectedLocation = null;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length < 3) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      try {
        final suggestions = await _locationService.autocomplete(value);
        if (mounted) setState(() => _suggestions = suggestions);
      } catch (e) {
        debugPrint('❌ autocomplete: $e');
      }
    });
  }

  // ── Sélection d'une suggestion ────────────────────────────────
  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _adresseController.text = suggestion.description;
      _suggestions            = [];
      _isLoadingPlace         = true;
    });
    try {
      final result = await _locationService.getPlaceDetails(suggestion);
      if (!mounted) return;
      setState(() {
        _selectedLocation = result;
        _isLoadingPlace   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPlace = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Enregistrement de l'adresse (PUT set-adresse) ─────────────
  Future<void> _onContinue() async {
    final location = _selectedLocation;
    if (location == null) return;

    final success = await ref.read(authProvider.notifier).setAdresse(
      adresse   : location.adresse,
      latitude  : location.latitude,
      longitude : location.longitude,
    );

    if (!mounted) return;

    if (success) {
      await _showLocationSuccessSheet();
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) _showError(error);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content         : Text(message),
        backgroundColor : AppColors.error,
        behavior        : SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showLocationSuccessSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      // Transparent pour laisser le Container gérer son propre style
      backgroundColor: Colors.transparent,
      // Permet au sheet de dépasser 50% de hauteur si besoin
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _LocationSuccessSheet(
        onLogin: () {
          Navigator.of(context).pop();
          context.goNamed(RouteNames.login);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            const AuthHeader(),

            // ── Scrollable content ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.lg),

                    Text(
                      'Où livrer vos\ncommande ?',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    Text(
                      'Autorisez l\'accès à votre position pour voir les\nboutiques et restaurants proches de vous.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppDimens.xl),

                    // ── Champ adresse avec autocomplétion ────────────
                    YaaTextField(
                      controller : _adresseController,
                      hint       : 'Saisissez votre adresse…',
                      prefixIcon : Icons.search_rounded,
                      onChanged  : _onAdresseChanged,
                      suffixIcon : _isLoadingPlace
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _selectedLocation != null
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.check_circle_rounded,
                                      color: AppColors.success, size: 22),
                                )
                              : null,
                    ),

                    // ── Suggestions ──────────────────────────────────
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.sm),
                      Container(
                        decoration: BoxDecoration(
                          color        : AppColors.white,
                          borderRadius : BorderRadius.circular(AppDimens.radiusMd),
                          border       : Border.all(color: AppColors.grey200),
                          boxShadow    : [
                            BoxShadow(
                              color      : Colors.black.withValues(alpha: 0.06),
                              blurRadius : 12,
                              offset     : const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _suggestions
                              .map((s) => PlaceSuggestionTile(
                                    suggestion: s,
                                    onTap: () => _onSuggestionTap(s),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Location icon — double cercle centré
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySurface,
                        ),
                        child: Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Buttons anchored at bottom ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                0,
                AppDimens.screenPadding,
                AppDimens.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton de validation — visible quand une adresse est choisie
                  if (_selectedLocation != null) ...[
                    YaaButton(
                      label     : 'Continuer',
                      onPressed : _onContinue,
                      isLoading : ref.watch(authProvider).isLoading,
                    ),
                    const SizedBox(height: AppDimens.md),
                  ],
                  YaaButton(
                    label      : 'Utiliser ma position actuelle',
                    onPressed  : _onUseLocation,
                    isLoading  : _isLoadingGps,
                    isOutlined : _selectedLocation != null,
                    icon       : Icons.location_on,
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

// ---------------------------------------------------------------------------
// Success bottom sheet — flottant avec marges et coins arrondis partout
// ---------------------------------------------------------------------------

class _LocationSuccessSheet extends StatelessWidget {
  const _LocationSuccessSheet({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    // Padding sur les côtés et en bas pour l'effet "flottant"
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          // Coins arrondis sur les 4 côtés
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          16,
          AppDimens.screenPadding,
          AppDimens.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppDimens.xl),

            // Success icon — double cercle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.lg),

            // Title
            Text(
              'Position ajoutée',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: AppDimens.sm),

            // Subtitle
            Text(
              'Connectez-vous pour accéder à votre espace.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppDimens.xl),

            // CTA
            YaaButton(
              label: 'Se connecter',
              onPressed: onLogin,
            ),
          ],
        ),
      ),
    );
  }
}
