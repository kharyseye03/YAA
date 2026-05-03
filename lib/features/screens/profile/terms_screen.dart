import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

/// Terms and conditions screen — "Conditions d'utilisations"
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.lg),

                  Text(
                    'Conditions Générales d\'Utilisation de YAA',
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: AppDimens.lg),

                  _buildParagraph(
                    'Les présentes Conditions Générales d\'Utilisation (CGU) ont pour objet de définir les modalités d\'accès et d\'utilisation de l\'application YAA, plateforme digitale de commande et livraison de produits (restaurants, pharmacies, boutiques, supermarchés). L\'utilisation de l\'application implique l\'acceptation pleine et entière des présentes CGU.',
                  ),

                  const SizedBox(height: AppDimens.xxl),

                  _buildSectionTitle('1. Présentation de YAA'),

                  const SizedBox(height: AppDimens.md),

                  _buildParagraph('YAA permet aux utilisateurs de :'),

                  const SizedBox(height: AppDimens.md),

                  _buildBullet('Commander des produits depuis des restaurants, pharmacies, boutiques et supermarchés'),
                  _buildBullet('Suivre les commandes en temps réel'),
                  _buildBullet('Gérer les paiements et transactions'),
                  _buildBullet('Contacter les livreurs et les commerces'),
                  _buildBullet('Consulter l\'historique des commandes'),

                  const SizedBox(height: AppDimens.lg),

                  _buildParagraph('Les services peuvent évoluer à tout moment pour améliorer l\'expérience utilisateur.'),

                  const SizedBox(height: AppDimens.md),

                  _buildParagraph('Pour utiliser YAA, l\'utilisateur doit :'),

                  const SizedBox(height: AppDimens.md),

                  _buildBullet('Être âgé d\'au moins 18 ans'),
                  _buildBullet('Fournir des informations exactes et à jour'),
                  _buildBullet('Créer un compte sécurisé (email + mot de passe)'),

                  const SizedBox(height: AppDimens.lg),

                  _buildParagraph('L\'utilisateur est responsable de la confidentialité de ses identifiants et des actions effectuées sur son compte.'),

                  const SizedBox(height: AppDimens.xxl),

                  _buildSectionTitle('2. Protection des données'),

                  const SizedBox(height: AppDimens.md),

                  _buildParagraph('YAA s\'engage à protéger les données personnelles des utilisateurs conformément aux lois en vigueur. Les données collectées sont utilisées uniquement pour le bon fonctionnement du service.'),

                  const SizedBox(height: AppDimens.xxl),

                  _buildSectionTitle('3. Responsabilité'),

                  const SizedBox(height: AppDimens.md),

                  _buildParagraph('YAA s\'efforce d\'assurer la disponibilité continue de ses services mais ne saurait être tenu responsable en cas d\'interruption temporaire pour maintenance ou mise à jour.'),

                  const SizedBox(height: AppDimens.huge),
                ],
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
        Text('Conditions d\'utilisations', style: AppTextStyles.h4.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700, height: 1.7),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.lg, bottom: AppDimens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 5, height: 5,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.grey700),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700, height: 1.7))),
        ],
      ),
    );
  }
}