import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../service/location/location_service.dart';

/// Suggestion d'autocomplétion Google Places — icône adaptée au type
/// de lieu (navy blue), nom en gras + adresse en gris dessous.
class PlaceSuggestionTile extends StatelessWidget {
  const PlaceSuggestionTile({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    final icon = iconForTypes(suggestion.types);
    // Fallback sur description si structured_formatting absent
    final mainText = suggestion.mainText.isNotEmpty
        ? suggestion.mainText
        : suggestion.description;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
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
                    const SizedBox(height: 1),
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
          ],
        ),
      ),
    );
  }
}
