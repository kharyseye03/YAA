import '../../../core/utils/phone_formatter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';
import '../../user/providers/user_notifier.dart';

class EditPersonalInfoScreen extends ConsumerStatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  ConsumerState<EditPersonalInfoScreen> createState() =>
      _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState
    extends ConsumerState<EditPersonalInfoScreen> {
  final _formKey         = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProvider).profile;
    _firstNameController = TextEditingController(text: profile?.firstName ?? '');
    _lastNameController  = TextEditingController(text: profile?.lastName  ?? '');
    _emailController     = TextEditingController(text: profile?.email     ?? '');
    _phoneController     = TextEditingController(text: profile?.telephone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) setState(() => _pickedImage = File(picked.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'channel-error'
          ? 'Caméra non disponible sur ce simulateur. Utilisez un vrai appareil.'
          : 'Impossible d\'accéder à la ${source == ImageSource.camera ? 'caméra' : 'galerie'} : ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w, height: 4.h,
                margin: EdgeInsets.only(bottom: AppDimens.lg),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text('Choisir une photo', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: AppDimens.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Galerie',
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                  ),
                  _buildSourceOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Caméra',
                    onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                  ),
                ],
              ),
              SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64.r, height: 64.r,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28.r),
          ),
          SizedBox(height: AppDimens.sm),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(userProvider.notifier).updateProfile(
      firstName : _firstNameController.text.trim(),
      lastName  : _lastNameController.text.trim(),
      email     : _emailController.text.trim(),
      telephone : _phoneController.text.trim(),
      imagePath : _pickedImage?.path,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(userProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: AppDimens.xxl),

                    // ── Avatar ───────────────────────────────
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          UserAvatar(
                            localFile: _pickedImage,
                            imageUrl: _pickedImage == null
                                ? ref.read(userProvider).profile?.imageUrl
                                : null,
                          ),
                          Positioned(
                            bottom: 0.h, right: 0.w,
                            child: Container(
                              width: 32.r, height: 32.r,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_outlined, color: AppColors.white, size: 16.r),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimens.xxxl),

                    YaaTextField(
                      controller: _firstNameController,
                      label: 'Prénom',
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    SizedBox(height: AppDimens.xl),
                    YaaTextField(
                      controller: _lastNameController,
                      label: 'Nom',
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    SizedBox(height: AppDimens.xl),
                    YaaTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: false,
                    ),
                    SizedBox(height: AppDimens.xl),
                    PhoneTextField(
                      controller      : _phoneController,
                      label           : 'Téléphone',
                      textInputAction : TextInputAction.done,
                      enabled         : false,
                    ),
                    SizedBox(height: AppDimens.xxl),
                  ],
                ),
              ),
            ),
          ),

          // ── Bouton Enregistrer ───────────────────────
          Container(
            padding: EdgeInsets.only(
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              top    : 12.h,
              bottom : MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color  : Colors.white,
              border : Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: YaaButton(
              label     : isLoading ? 'Enregistrement...' : 'Enregistrer',
              onPressed : isLoading ? null : _onSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top    : MediaQuery.of(context).padding.top + 12,
            left   : AppDimens.screenPadding,
            right  : AppDimens.screenPadding,
            bottom : 16.h,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap    : () => Navigator.of(context).pop(),
                behavior : HitTestBehavior.opaque,
                child: Container(
                  width  : 38.r,
                  height : 38.r,
                  decoration: BoxDecoration(
                    color        : AppColors.grey100,
                    borderRadius : BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color : AppColors.dark,
                    size  : 22.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Modifier mes informations',
                style: AppTextStyles.h3.copyWith(
                  fontWeight : FontWeight.w800,
                  color      : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.grey200),
      ],
    );
  }
}
