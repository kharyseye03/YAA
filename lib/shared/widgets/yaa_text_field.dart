import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';

/// Styled text field used across the app.
/// Supports prefix/suffix icons, validation, obscure text, etc.
class YaaTextField extends StatelessWidget {
  const YaaTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofillHints,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimens.sm),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.dark),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: AppDimens.iconLg, color: AppColors.grey500)
                : null,
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixTap,
                    child: suffixIcon,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
