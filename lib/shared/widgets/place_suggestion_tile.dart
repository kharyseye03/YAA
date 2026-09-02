import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../service/location/location_service.dart';

/// Suggestion d'autocomplétion Google Places.
///
/// Widget unique de l'app pour ce motif : l'écran course, la feuille
/// d'adresse de livraison et l'écran de localisation à l'inscription
/// s'appuient tous dessus. Toute retouche ici se propage aux trois —
/// c'est le but, ne pas dupliquer la mise en forme sur chaque écran.
class PlaceSuggestionTile extends StatelessWidget {
  const PlaceSuggestionTile({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.showDivider = true,
  });

  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

  /// Filet de séparation sous la ligne. À passer à false sur le
  /// dernier élément d'une liste.
  final bool showDivider;

  /// Icône selon le type Google Places du lieu
  static IconData iconForTypes(List<String> types) {
    for (final type in types) {
      switch (type) {
        case 'restaurant' || 'food' || 'cafe' || 'bar' || 'bakery'
            || 'meal_takeaway' || 'meal_delivery':
          return Icons.restaurant_rounded;
        case 'pharmacy' || 'drugstore':
          return Icons.local_pharmacy_rounded;
        case 'hospital' || 'doctor' || 'health' || 'dentist':
          return Icons.local_hospital_rounded;
        case 'school' || 'university' || 'primary_school'
            || 'secondary_school':
          return Icons.school_rounded;
        case 'supermarket' || 'grocery_or_supermarket'
            || 'convenience_store':
          return Icons.shopping_cart_rounded;
        case 'shopping_mall' || 'store' || 'clothing_store'
            || 'electronics_store' || 'shoe_store':
          return Icons.storefront_rounded;
        case 'bank' || 'atm' || 'finance':
          return Icons.account_balance_rounded;
        case 'gas_station':
          return Icons.local_gas_station_rounded;
        case 'airport':
          return Icons.flight_rounded;
        case 'bus_station' || 'transit_station' || 'train_station'
            || 'taxi_stand':
          return Icons.directions_bus_rounded;
        case 'mosque' || 'church' || 'place_of_worship':
          return Icons.mosque_rounded;
        case 'lodging':
          return Icons.hotel_rounded;
        case 'gym':
          return Icons.fitness_center_rounded;
        case 'park' || 'stadium':
          return Icons.park_rounded;
        case 'route' || 'street_address':
          return Icons.signpost_rounded;
        case 'neighborhood' || 'sublocality' || 'locality'
            || 'sublocality_level_1':
          return Icons.location_city_rounded;
      }
    }
    // Type inconnu → pin générique
    return Icons.location_on_rounded;
  }

  /// Teinte unique de la liste.
  ///
  /// Trois couleurs selon la famille du lieu donnaient une liste
  /// bariolée où l'œil cherchait un sens qui n'existait pas : la
  /// couleur ne disait rien que l'icône ne disait déjà. Le navy de
  /// marque laisse le libellé porter l'information.
  static const Color accent = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final icon = iconForTypes(suggestion.types);
    // Fallback sur description si structured_formatting absent
    final mainText = suggestion.mainText.isNotEmpty
        ? suggestion.mainText
        : suggestion.description;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              )
            : null,
        child: Row(
          children: [
            // Pastille teintée : c'est elle qui donne du relief à la
            // liste, une icône nue se perd dans le texte.
            Container(
              width  : 38,
              height : 38,
              decoration: BoxDecoration(
                color        : accent.withValues(alpha: 0.10),
                borderRadius : BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 12),

            // Nom du lieu + adresse
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color      : AppColors.dark,
                      fontWeight : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.secondaryText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Distance à droite : elle sert à départager deux lieux
            // au nom voisin, pas à estimer un trajet.
            if (suggestion.distanceLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                suggestion.distanceLabel,
                style: AppTextStyles.caption.copyWith(
                  color      : AppColors.textSoft,
                  fontWeight : FontWeight.w700,
                ),
              ),
            ],

            // Flèche de report : indique que le tap remplit le champ
            // plutôt que de naviguer ailleurs.
            const SizedBox(width: 8),
            const Icon(Icons.north_west_rounded,
                size: 17, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
