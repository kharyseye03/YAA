import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../model/category/categorie_structure.dart';
import '../../../../service/api/api_service.dart';

final categoriesProvider = FutureProvider<List<CategorieStructure>>((ref) {
  return ApiService().getCategories();
});
