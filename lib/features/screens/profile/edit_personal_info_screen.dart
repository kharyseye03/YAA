import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

/// Edit personal info screen — form with avatar, fields, and save button.
class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _firstNameController = TextEditingController(text: 'Addéline');
  final _lastNameController = TextEditingController(text: 'Keita');
  final _emailController = TextEditingController(text: 'akeita@gmail.com');
  final _phoneController = TextEditingController(text: '+221 77 123 45 67');
  final _addressController = TextEditingController(text: 'Ouakam cité avions , Dakar , Sénégal');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
              child: Column(
                children: [
                  const SizedBox(height: AppDimens.xxl),

                  // Avatar with camera icon
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.grey200, border: Border.all(color: AppColors.grey300, width: 2)),
                          child: const Icon(Icons.person, color: AppColors.grey500, size: 48),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.grey300, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, color: AppColors.grey600, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimens.xxxl),

                  YaaTextField(controller: _firstNameController, label: 'Prénom', textInputAction: TextInputAction.next),
                  const SizedBox(height: AppDimens.xl),
                  YaaTextField(controller: _lastNameController, label: 'Nom', textInputAction: TextInputAction.next),
                  const SizedBox(height: AppDimens.xl),
                  YaaTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
                  const SizedBox(height: AppDimens.xl),
                  YaaTextField(controller: _phoneController, label: 'Téléphone', keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
                  const SizedBox(height: AppDimens.xl),
                  YaaTextField(controller: _addressController, label: 'Adresse', textInputAction: TextInputAction.done),
                  const SizedBox(height: AppDimens.xxl),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding, vertical: AppDimens.lg),
            color: AppColors.white,
            child: SafeArea(
              top: false,
              child: YaaButton(
                label: 'Enrehgistrer',
                onPressed: () {
                  // TODO: Save profile
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: AppDimens.screenPadding, right: AppDimens.screenPadding, top: MediaQuery.of(context).padding.top + AppDimens.md, bottom: AppDimens.xl),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1652F0), Color(0xFF3B7BF7)])),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.chevron_left, color: AppColors.white, size: 28)),
        const SizedBox(width: AppDimens.md),
        Text('Informations personnelles', style: AppTextStyles.h4.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}