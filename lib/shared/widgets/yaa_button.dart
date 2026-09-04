import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/constants.dart';

/// Primary CTA button used across the app.
/// Supports loading state, disabled state, and icon prefix.
class YaaButton extends StatelessWidget {
  const YaaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? AppDimens.buttonHeight;
    // Pilule par défaut, comme sur yaagn.com
    final effectiveRadius = borderRadius ?? AppDimens.radiusFull;

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: effectiveHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: backgroundColor ?? AppColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
            ),
          ),
          child: _buildChild(foregroundColor ?? AppColors.primary),
        ),
      );
    }

    final fond = backgroundColor ?? AppColors.primary;

    return Container(
      width  : width ?? double.infinity,
      height : effectiveHeight,
      // Lueur teintée sous le bouton — la signature du site. Elle
      // disparaît quand le bouton est inactif, pour ne pas suggérer
      // une action possible.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        boxShadow: (onPressed == null || isLoading)
            ? null
            : [
                BoxShadow(
                  color      : fond.withValues(alpha: 0.20),
                  blurRadius : 26.r,
                  offset     : const Offset(0, 12),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor : fond,
          foregroundColor : foregroundColor ?? AppColors.white,
          elevation       : 0,
          shadowColor     : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
        ),
        child: _buildChild(foregroundColor ?? AppColors.white),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22.r,
        height: 22.r,
        child: CircularProgressIndicator(
          strokeWidth: 2.5.r,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.button.copyWith(color: color)),
          SizedBox(width: AppDimens.sm),
          Icon(icon, size: AppDimens.iconMd),
        ],
      );
    }

    return Text(label, style: AppTextStyles.button.copyWith(color: color));
  }
}
