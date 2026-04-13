import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// Animated dot indicator for page views.
class DotIndicator extends StatelessWidget {
  const DotIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.grey300,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
        );
      }),
    );
  }
}
