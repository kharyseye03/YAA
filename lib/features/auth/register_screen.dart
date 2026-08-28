import '../../core/utils/phone_formatter.dart';
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
      padding: const EdgeInsets.only(bottom: 6),
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
InputDecoration _inputDeco({String? hint}) => InputDecoration(
      hintText: hint,
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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _emailController     = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Logique inchangée ────────────────────────────────────────
  Future<void> _onConfirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rawPhone = _phoneController.text.replaceAll(' ', '');
    final email    = _emailController.text.trim();

    final success = await ref.read(authProvider.notifier).register(
      firstName : _firstNameController.text.trim(),
      lastName  : _lastNameController.text.trim(),
      email     : email,
      telephone : rawPhone,
    );

    if (!mounted) return;

    if (success) {
      context.pushNamed(RouteNames.verification, extra: email);
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
                // Le titre collait au haut de l'écran : on lui laisse
                // de l'air, la page défile de toute façon
                SizedBox(height: AppDimens.huge),

                // ── Titre ────────────────────────────────────────
                RichText(
                  text: TextSpan(
                    text: 'Créez votre ',
                    style: AppTextStyles.h2,
                    children: [
                      TextSpan(
                        text: 'compte',
                        style: AppTextStyles.h2
                            .copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimens.xs),
                Text(
                  'Renseignez vos informations pour commencer.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),

                SizedBox(height: AppDimens.xxl),

                // ── Prénom + Nom côte à côte ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Prénom'),
                          TextFormField(
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: _inputDeco(hint: 'Abdoul'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requis';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDimens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Nom'),
                          TextFormField(
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: _inputDeco(hint: 'DIALLO'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requis';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppDimens.lg),

                // ── Téléphone ────────────────────────────────────
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
                      return 'Numéro requis';
                    }
                    final digits = value.replaceAll(' ', '');
                    if (digits.length != 9) return '9 chiffres requis';
                    return null;
                  },
                ),

                SizedBox(height: AppDimens.lg),

                // ── Email ────────────────────────────────────────
                const _Label('Adresse email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: _inputDeco(hint: 'exemple@gmail.com'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email requis';
                    }
                    if (!value.trim()._isValidEmail) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),

                SizedBox(height: AppDimens.lg),

                // ── Conditions ───────────────────────────────────
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600),
                    children: [
                      const TextSpan(
                          text: 'En continuant, vous acceptez nos '),
                      TextSpan(
                        text: 'Conditions d\'utilisation',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: ' et notre '),
                      TextSpan(
                        text: 'Politique de confidentialité',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),

                // ── Erreur inline ────────────────────────────────
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
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
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

                SizedBox(height: AppDimens.xxl),

                // ── Bouton confirmer ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _onConfirm,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white),
                          )
                        : const Text('Confirmer'),
                  ),
                ),

                SizedBox(height: AppDimens.lg),

                // ── Lien connexion ───────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous avez déjà un compte ? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey600),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.goNamed(RouteNames.login),
                        child: Text(
                          'Se Connecter',
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


extension _StringValidation on String {
  bool get _isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);
}
