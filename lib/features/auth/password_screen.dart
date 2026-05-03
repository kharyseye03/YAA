
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';
import 'providers/auth_notifier.dart';

class PasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const PasswordScreen({super.key, required this.email});

  @override
  ConsumerState<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends ConsumerState<PasswordScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  bool _obscurePassword     = true;
  bool _obscureConfirm      = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authProvider.notifier).createPassword(
      email      : widget.email,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.pushNamed(RouteNames.location);
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const AuthHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimens.lg),

                      Text(
                        'Créez votre mot de\npasse',
                        style: AppTextStyles.h1.copyWith(
                          fontSize   : 28,
                          fontWeight : FontWeight.w800,
                          color      : AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppDimens.md),

                      Text(
                        'Choisissez un mot de passe sécurisé pour\nprotéger votre compte.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color  : AppColors.grey600,
                          height : 1.5,
                        ),
                      ),

                      const SizedBox(height: AppDimens.xxxl),

                      YaaTextField(
                        controller      : _passwordController,
                        label           : 'Nouveau mot de passe',
                        hint            : '••••••••••',
                        obscureText     : _obscurePassword,
                        textInputAction : TextInputAction.next,
                        suffixIcon      : Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color : AppColors.grey500,
                          size  : 22,
                        ),
                        onSuffixTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Minimum 6 caractères';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.xl),

                      YaaTextField(
                        controller      : _confirmController,
                        label           : 'Confirmation de mot de passe',
                        hint            : '••••••••••',
                        obscureText     : _obscureConfirm,
                        textInputAction : TextInputAction.done,
                        onSubmitted     : (_) => _onConfirm(),
                        suffixIcon      : Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color : AppColors.grey500,
                          size  : 22,
                        ),
                        onSuffixTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer le mot de passe';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.xxxl),
                    ],
                  ),
                ),
              ),

              // Bouton ancré en bas
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.screenPadding,
                  0,
                  AppDimens.screenPadding,
                  AppDimens.xxl,
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final isLoading = ref.watch(authProvider).isLoading;
                    return YaaButton(
                      label     : isLoading ? 'Chargement...' : 'Confirmer',
                      onPressed : isLoading ? null : _onConfirm,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}