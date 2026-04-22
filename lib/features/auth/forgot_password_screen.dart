import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_router.dart';
import '../../shared/widgets/auth_header.dart';
import '../../shared/widgets/phone_number_formatter.dart';
import '../../shared/widgets/yaa_button.dart';
import '../../shared/widgets/yaa_text_field.dart';
import 'package:flutter/services.dart';


/// Forgot password screen — "Mot de passe oublié"
/// Toggle between phone and email input, then send OTP.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _isPhone = true;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    // TODO: Send OTP to phone or email
    context.pushNamed(RouteNames.forgotVerification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AuthHeader(
              onBack: () => context.goNamed(RouteNames.login),
            ),
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
                      'Mot de passe oublié',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    // Subtitle
                    Text(
                      'Entrer votre numéro de téléphone ou votre\nadresse email pour recevoir un OTP',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppDimens.xxl),

                    // Toggle tabs: Téléphone / Email
                    _buildToggleTabs(),

                    const SizedBox(height: AppDimens.xxl),

                    // Input field based on selected tab
                    if (_isPhone)
                    PhoneTextField(controller: _phoneController)
                    else
                      YaaTextField(
                        controller: _emailController,
                        label: 'Adresse email',
                        hint: 'Ex: geraldkeita@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),

                    const Spacer(),

                    // Submit button
                    YaaButton(
                      label: 'Connexion',
                      onPressed: _onSubmit,
                      icon: Icons.arrow_forward,
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

  Widget _buildToggleTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        children: [
          // Phone tab
          Expanded(
            child: _buildTab(
              isActive: _isPhone,
              icon: Icons.phone,
              label: 'Téléphone',
              onTap: () => setState(() => _isPhone = true),
            ),
          ),
          // Email tab
          Expanded(
            child: _buildTab(
              isActive: !_isPhone,
              icon: Icons.mail,
              label: 'Email',
              onTap: () => setState(() => _isPhone = false),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTab({
    required bool isActive,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.grey600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isActive ? AppColors.primary : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}