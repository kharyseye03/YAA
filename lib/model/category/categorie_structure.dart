import 'package:flutter/material.dart';

class CategorieStructure {
  final int id;
  final String name;
  final String icon;

  const CategorieStructure({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory CategorieStructure.fromJson(Map<String, dynamic> json) {
    return CategorieStructure(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
    );
  }

  IconData get iconData => _iconMap[icon] ?? Icons.category_outlined;

  static const Map<String, IconData> _iconMap = {
    'Icons.restaurant': Icons.restaurant,
    'Icons.medical_services_outlined': Icons.medical_services_outlined,
    'Icons.store_outlined': Icons.store_outlined,
    'Icons.shopping_bag_outlined': Icons.shopping_bag_outlined,
    'Icons.local_pharmacy': Icons.local_pharmacy,
    'Icons.fastfood': Icons.fastfood,
    'Icons.local_grocery_store': Icons.local_grocery_store,
    'Icons.storefront': Icons.storefront,
    'Icons.coffee': Icons.coffee,
    'Icons.local_cafe': Icons.local_cafe,
    'Icons.bakery_dining': Icons.bakery_dining,
    'Icons.category': Icons.category,
    'Icons.category_outlined': Icons.category_outlined,
  };
}
