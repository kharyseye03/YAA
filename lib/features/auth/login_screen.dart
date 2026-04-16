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

/// Login screen — "Se connecter"
/// Fields: Numéro de téléphone, Mot de passe
/// Google sign-in, forgot password link, register link.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Handle login
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AuthHeader(
              onBack: () => context.goNamed(RouteNames.register),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimens.lg),

                      // Title
                      Text(
                        'Se connecter',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppDimens.md),

                      // Subtitle
                      Text(
                        'Connectez-vous pour explorer toutes les\nfonctionnalités de l\'application.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: AppDimens.xxl),

                      // Phone
                      PhoneTextField(controller: _phoneController),

                      const SizedBox(height: AppDimens.xl),

                      // Password
                      YaaTextField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        hint: '••••••••••',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.grey500,
                          size: 22,
                        ),
                        onSuffixTap: () {
                          setState(
                                  () => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.xxl),

                      // Login button
                      YaaButton(
                        label: 'Connexion',
                        onPressed: _onLogin,
                        icon: Icons.arrow_forward,
                      ),

                      const SizedBox(height: AppDimens.lg),

                      // Forgot password
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              context.pushNamed(RouteNames.forgotPassword),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimens.xxl),

                      // Divider with "ou"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: AppColors.grey300),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.lg),
                            child: Text(
                              'ou',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: AppColors.grey300),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimens.xxl),

                      // Google button
                      SizedBox(
                        width: double.infinity,
                        height: AppDimens.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Google sign-in
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.grey300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/g-logo.png',
                                width: 40,
                                height: 40,
                              ),
                              Text(
                                'Continuer avec Google',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimens.xxl),

                      // Register link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous n\'avez pas de compte ? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.goNamed(RouteNames.register),
                              child: Text(
                                'S\'inscrire',
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
