import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';

/// OTP verification screen — "Vérifiez votre numéro"
/// Shows 4 OTP input boxes, custom numeric keypad, resend timer.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<String> _code = ['', '', '', ''];
  int _activeIndex = 0;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onKeyTap(String value) {
    if (_activeIndex < 4) {
      setState(() {
        _code[_activeIndex] = value;
        _activeIndex++;
      });
    }
  }

  void _onBackspace() {
    if (_activeIndex > 0) {
      setState(() {
        _activeIndex--;
        _code[_activeIndex] = '';
      });
    }
  }

  void _onVerify() {
    final otp = _code.join();
    if (otp.length == 4) {
      // TODO: Verify OTP
      context.pushNamed(RouteNames.password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const AuthHeader(),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimens.lg),

                    // Title
                    Text(
                      'Vérifiez votre numéro',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    // Subtitle with phone number
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text:
                            'Veuillez saisir le code à 4 chiffres envoyé\npar SMS au ',
                          ),
                          TextSpan(
                            text: '+221 78 123 45 67',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.xxxl),

                    // OTP Code boxes
                    _buildOtpBoxes(),

                    const SizedBox(height: AppDimens.xxl),

                    // Resend text
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Vous n\'avez pas reçu de code ?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: AppDimens.sm),
                          _resendSeconds > 0
                              ? Text(
                            'Renvoyer le code dans $_resendSeconds',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                              : GestureDetector(
                            onTap: _startResendTimer,
                            child: Text(
                              'Renvoyer le code',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimens.xxl),

                    // Number pad
                    _buildNumberPad(),

                    const Spacer(),

                    // Verify button
                    YaaButton(
                      label: 'Vérifier',
                      onPressed: _code.every((c) => c.isNotEmpty)
                          ? _onVerify
                          : null,
                    ),

                    const SizedBox(height: AppDimens.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── OTP Boxes ────────────────────────────────────────────
  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = _code[index].isNotEmpty;
        final isActive = index == _activeIndex;

        return Container(
          width: 64,
          height: 64,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primarySurface
                : AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : isFilled
                  ? AppColors.grey300
                  : Colors.transparent,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              _code[index],
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Number Pad ───────────────────────────────────────────
  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: AppDimens.md),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: AppDimens.md),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: AppDimens.md),
        _buildKeyRow(['', '0', 'back']),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 90, height: 56);
        }
        return _buildKey(key);
      }).toList(),
    );
  }

  Widget _buildKey(String value) {
    final isBackspace = value == 'back';

    return GestureDetector(
      onTap: () => isBackspace ? _onBackspace() : _onKeyTap(value),
      child: Container(
        width: 90,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Center(
          child: isBackspace
              ? Icon(
            Icons.backspace_outlined,
            color: AppColors.grey700,
            size: 22,
          )
              : Text(
            value,
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      ),
    );
  }
}