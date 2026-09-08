import 'dart:async';
import '../../../core/utils/journal.dart';
import '../../../core/errors/messages_erreur.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/cart/providers/delivery_address_provider.dart';
import '../../../service/location/location_service.dart';
import '../../../shared/widgets/widgets.dart';

/// Ouvre le bottom sheet de changement d'adresse de livraison.
/// L'adresse choisie est stockée dans [deliveryAddressProvider]
/// (valable uniquement pour la commande en cours).
Future<void> showDeliveryAddressSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context            : context,
    isScrollControlled : true,
    backgroundColor    : Colors.transparent,
    builder            : (_) => const _DeliveryAddressSheet(),
  );
}

class _DeliveryAddressSheet extends ConsumerStatefulWidget {
  const _DeliveryAddressSheet();

  @override
  ConsumerState<_DeliveryAddressSheet> createState() =>
      _DeliveryAddressSheetState();
}

class _DeliveryAddressSheetState
    extends ConsumerState<_DeliveryAddressSheet> {
  final _locationService = LocationService();
  final _controller      = TextEditingController();

  Timer?                _debounce;
  List<PlaceSuggestion> _suggestions    = [];
  bool                  _isLoadingGps   = false;
  bool                  _isLoadingPlace = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Position actuelle (GPS) ──────────────────────────────────
  Future<void> _onUseLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final result = await _locationService.getCurrentLocation();
      if (!mounted) return;
      _select(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGps = false);
      _showError(MessagesErreur.depuisException(e));
    }
  }

  // ── Sélection d'une suggestion → coordonnées via Place Details ─
  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    setState(() => _isLoadingPlace = true);
    try {
      final result = await _locationService.getPlaceDetails(suggestion);
      if (!mounted) return;
      _select(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPlace = false);
      _showError(MessagesErreur.depuisException(e));
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

  // ── Autocomplétion pendant la saisie ─────────────────────────
  void _onChanged(String value) {
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
        journal('❌ autocomplete: $e');
      }
    });
  }

  /// Valide l'adresse (avec coordonnées) pour cette commande
  /// et ferme le sheet
  void _select(LocationResult result) {
    ref.read(deliveryAddressProvider.notifier).state = result;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Remonte le sheet quand le clavier s'ouvre
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 12,
          AppDimens.screenPadding,
          MediaQuery.of(context).padding.bottom + 20,
        ),
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

            SizedBox(height: 20.h),

            Text(
              'Adresse de livraison',
              style: AppTextStyles.h3.copyWith(
                fontWeight : FontWeight.w800,
                color      : AppColors.dark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Valable uniquement pour cette commande',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
            ),

            SizedBox(height: 20.h),

            // ── Bouton position actuelle ──────────────────────
            YaaButton(
              label      : 'Utiliser ma position actuelle',
              onPressed  : _onUseLocation,
              isLoading  : _isLoadingGps,
              isOutlined : true,
              icon       : Icons.my_location_rounded,
            ),

            SizedBox(height: 16.h),

            // ── Séparateur "ou" ───────────────────────────────
            Row(
              children: [
                const Expanded(
                    child: Divider(height: 1, color: AppColors.grey200)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    'ou',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey400),
                  ),
                ),
                const Expanded(
                    child: Divider(height: 1, color: AppColors.grey200)),
              ],
            ),

            SizedBox(height: 16.h),

            // ── Champ avec autocomplétion ─────────────────────
            YaaTextField(
              controller : _controller,
              hint       : 'Saisissez une adresse…',
              prefixIcon : Icons.search_rounded,
              onChanged  : _onChanged,
            ),

            // ── Suggestions ───────────────────────────────────
            if (_isLoadingPlace) ...[
              SizedBox(height: 16.h),
              Center(
                child: SizedBox(
                  width: 22.r, height: 22.r,
                  child: CircularProgressIndicator(strokeWidth: 2.5.r),
                ),
              ),
            ] else if (_suggestions.isNotEmpty) ...[
              SizedBox(height: AppDimens.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Container(
                  decoration: BoxDecoration(
                    color        : Colors.white,
                    borderRadius : BorderRadius.circular(AppDimens.radiusMd),
                    border       : Border.all(color: AppColors.grey200),
                  ),
                  child: ListView(
                    shrinkWrap : true,
                    padding    : EdgeInsets.zero,
                    children   : [
                      for (var i = 0; i < _suggestions.length; i++)
                        PlaceSuggestionTile(
                          suggestion  : _suggestions[i],
                          onTap       : () =>
                              _onSuggestionTap(_suggestions[i]),
                          showDivider : i < _suggestions.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
