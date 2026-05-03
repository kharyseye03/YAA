import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Affiche la photo de profil : URL réseau, fichier local, ou icône par défaut.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.localFile,
    this.size = 100,
  });

  final String? imageUrl;
  final File? localFile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey200,
        border: Border.all(color: AppColors.grey300, width: 2),
      ),
      child: ClipOval(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (localFile != null) {
      return Image.file(localFile!, fit: BoxFit.cover);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, error, stack) {
          debugPrint('❌ Image.network erreur : $error\nURL: $imageUrl');
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => const Icon(Icons.person, color: AppColors.grey500, size: 48);
}
