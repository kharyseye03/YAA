import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Useful extensions on [BuildContext].
extension ContextExtensions on BuildContext {
  // ── Theme shortcuts ──────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // ── Media Query shortcuts ────────────────────────────────
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  double get bottomPadding => padding.bottom;
  double get topPadding => padding.top;

  // ── Navigation shortcuts ─────────────────────────────────
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  bool get canPop => Navigator.of(this).canPop();

  // ── Snackbar shortcuts ───────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  void showErrorSnackBar(String message) =>
      showSnackBar(message, isError: true);
}

/// Useful extensions on [String].
extension StringExtensions on String {
  /// Capitalize the first letter.
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Check if the string is a valid email.
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  /// Check if the string is a valid phone number.
  bool get isValidPhone =>
      RegExp(r'^\+?[0-9]{8,15}$').hasMatch(replaceAll(' ', ''));
}

/// Useful extensions on [num] for SizedBox shortcuts.
extension NumSpacing on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}
