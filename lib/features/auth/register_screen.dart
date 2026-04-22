import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../shared/widgets/auth_header.dart';
import '../../shared/widgets/phone_number_formatter.dart';

/// Registration screen — "Création de compte"
/// Fields: Prénom et nom, Numéro de téléphone, Adresse email
/// Bottom: Terms text + Confirmer button + Se connecter link
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Handle registration logic
      context.pushNamed(RouteNames.verification);
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
            AuthHeader(
              onBack: () => context.goNamed(RouteNames.onboarding),
            ),

            // Scrollable content
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
                        'Création de compte',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppDimens.md),

                      // Subtitle
                      Text(
                        'Créer un compte maintenant et profitez\npleinement de l\'application.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: AppDimens.xxl),

                      // Name field
                      YaaTextField(
                        controller: _nameController,
                        label: 'Prénom et nom',
                        hint: 'Ex: Gérald charo Keita',
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.xl),

                      // Phone field
                      PhoneTextField(controller: _phoneController),

                      const SizedBox(height: AppDimens.xl),

                      // Email field
                      YaaTextField(
                        controller: _emailController,
                        label: 'Adresse email',
                        hint: 'Ex: geraldkeita@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.trim().isValidEmail) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDimens.lg),

                      // Terms text
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey600,
                          ),
                          children: [
                            const TextSpan(
                                text: 'En continuant, vous acceptez nos '),
                            TextSpan(
                              text: 'd\'utilisation Conditions',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: ' et\nnotre '),
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

                      const SizedBox(height: AppDimens.xxl),

                      // Confirm button
                      YaaButton(
                        label: 'Confirmer',
                        onPressed: _onConfirm,
                        icon: Icons.arrow_forward,
                      ),

                      const SizedBox(height: AppDimens.huge),

                      // Login link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous avez déjà un compte ? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.goNamed(RouteNames.login),
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

// Extension for email validation (in case not imported)
extension _StringValidation on String {
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);
}