import '../../core/utils/phone_formatter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

// ── Label avec astérisque (style YAA_PRO) ───────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: RichText(
        text: TextSpan(
          text: text,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey800),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(
                  color: AppColors.secondary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── InputDecoration uniforme ─────────────────────────────────────
InputDecoration _inputDeco({String? hint, Widget? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.lg, vertical: AppDimens.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.white,
    );

/// Login screen — "Se connecter"
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _phoneController  = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Logique inchangée ────────────────────────────────────────
  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawPhone = _phoneController.text.replaceAll(' ', '');
    final success = await ref.read(authProvider.notifier).login(
      username: rawPhone,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ────────────────────────────────────────
                // Logo large (ratio ~2.9:1) : on ne contraint que la
                // largeur, la hauteur suit le ratio naturel.
                SizedBox(height: AppDimens.huge),
                Center(
                  child: Image.asset(
                    'assets/images/logo_off.png',
                    width: 150.w,
                  ),
                ),
                SizedBox(height: AppDimens.xxxl),

                // ── Titre ────────────────────────────────────────
                RichText(
                  text: TextSpan(
                    text: 'Bon retour ',
                    style: AppTextStyles.h2,
                    children: [
                      TextSpan(
                        text: 'chez vous ',
                        style: AppTextStyles.h2
                            .copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimens.xs),
                Text(
                  'Connectez-vous pour accéder à votre espace.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),

                SizedBox(height: AppDimens.xxl),

                // ── Téléphone ───────────────────────────────────
                const _Label('Numéro de téléphone'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    ...phoneInputFormatters,
                                    ],
                  decoration: _inputDeco(hint: kExempleTelephone),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre numéro';
                    }
                    final digits = value.replaceAll(' ', '');
                    if (digits.length != 9) {
                      return 'Le numéro doit contenir 9 chiffres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppDimens.lg),

                // ── Mot de passe ────────────────────────────────
                const _Label('Mot de passe'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDeco(
                    hint: '••••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey500,
                        size: 20.r,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppDimens.md),

                // ── Mot de passe oublié ─────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        context.pushNamed(RouteNames.forgotPassword),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),

                // ── Erreur inline ───────────────────────────────
                if (state.error != null) ...[
                  SizedBox(height: AppDimens.lg),
                  Container(
                    padding: EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18.r),
                        SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: AppDimens.xxxl),

                // ── Bouton connexion ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _onLogin,
                    child: state.isLoading
                        ? SizedBox(
                            height: 22.h,
                            width: 22.w,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5.r,
                                color: AppColors.white),
                          )
                        : const Text('Se connecter'),
                  ),
                ),

                SizedBox(height: AppDimens.lg),

                // ── Lien inscription ────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous n\'avez pas de compte ? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey600),
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed(RouteNames.register),
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

                SizedBox(height: AppDimens.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

