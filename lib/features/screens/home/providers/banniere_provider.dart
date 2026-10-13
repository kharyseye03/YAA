import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../model/banniere/banniere_model.dart';
import '../../../../service/api/api_service.dart';

/// Bannières du carrousel de l'accueil, groupées par type.
///
/// Un groupe = une carte sur l'accueil, quel que soit le nombre de
/// bannières qu'il contient. Chargées une fois par session ; pour
/// forcer une relecture : `ref.invalidate(bannieresProvider)`.
final bannieresProvider =
    FutureProvider<List<GroupeBannieres>>((ref) async {
  return ApiService().getBannieres();
});
