import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';
import 'providers/auth_notifier.dart';

/// OTP verification screen — "Vérifiez votre numéro"
class VerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<String> _code = ['', '', '', '', '', ''];
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
    if (_activeIndex < 6) {
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

  Future<void> _onVerify() async {
    final otp = _code.join();
    if (otp.length != 6) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(
      email: widget.email,
      otp: otp,
    );

    if (!mounted) return;

    if (success) {
      context.pushNamed(RouteNames.password, extra: widget.email);
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _onResendCode() async {
    final success = await ref.read(authProvider.notifier).resendCode(
      email: widget.email,
    );

    if (!mounted) return;

    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code renvoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
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
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppDimens.lg),

                    // Title
                    Text(
                      'Vérifiez votre numéro',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),

                    SizedBox(height: AppDimens.md),

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
                            'Veuillez saisir le code à 6 chiffres envoyé\npar E-mail  ',
                          ),
                          TextSpan(
                            text: widget.email,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimens.xxxl),

                    // OTP Code boxes
                    _buildOtpBoxes(),

                    SizedBox(height: AppDimens.xxl),

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
                          SizedBox(height: AppDimens.sm),
                          _resendSeconds > 0
                              ? Text(
                            'Renvoyer le code dans $_resendSeconds',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                              : GestureDetector(
                            onTap: _onResendCode,
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

                    SizedBox(height: AppDimens.xxl),

                    // Number pad
                    _buildNumberPad(),

                    const Spacer(),

                    // Verify button
                    Consumer(
                      builder: (context, ref, _) {
                        final isLoading = ref.watch(authProvider).isLoading;
                        return YaaButton(
                          label     : isLoading ? 'Vérification...' : 'Vérifier',
                          onPressed : isLoading
                              ? null
                              : _code.every((c) => c.isNotEmpty) ? _onVerify : null,
                        );
                      },
                    ),

                    SizedBox(height: AppDimens.xxl),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final totalMargin = 5 * 2 * 6;        // margin horizontale × 6 boîtes
    final totalPadding = AppDimens.screenPadding * 2;
    final boxSize = (screenWidth - totalPadding - totalMargin) / 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = _code[index].isNotEmpty;
        final isActive = index == _activeIndex;

        return Container(
          width: boxSize,
          height: boxSize,
          margin: EdgeInsets.symmetric(horizontal: 5.w),
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
                fontFamily: 'PlusJakartaSans',
                fontSize: 24.sp,
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
        SizedBox(height: AppDimens.md),
        _buildKeyRow(['4', '5', '6']),
        SizedBox(height: AppDimens.md),
        _buildKeyRow(['7', '8', '9']),
        SizedBox(height: AppDimens.md),
        _buildKeyRow(['', '0', 'back']),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return SizedBox(width: 90.w, height: 56.h);
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
        width: 90.w,
        height: 56.h,
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Center(
          child: isBackspace
              ? Icon(
            Icons.backspace_outlined,
            color: AppColors.grey700,
            size: 22.r,
          )
              : Text(
            value,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      ),
    );
  }
}