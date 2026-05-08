import 'package:flutter/material.dart';

class OnboardingPageData {
  final String image;
  final String title;
  final String badge;
  final Alignment imageAlignment;

  const OnboardingPageData({
    required this.image,
    required this.title,
    required this.badge,
    this.imageAlignment = Alignment.center,
  });
}
