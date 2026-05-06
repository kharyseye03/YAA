import 'package:flutter/material.dart';

class OnboardingPageData {
  final String imageUrl;
  final String title;
  final String badge;
  final Color fallbackColor;

  const OnboardingPageData({
    required this.imageUrl,
    required this.title,
    required this.badge,
    this.fallbackColor = const Color(0xFF2D3748),
  });
}
