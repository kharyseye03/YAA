import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.dark),
          decoration: InputDecoration(
            hintText: 'Rechercher un produit, restaurant…',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey400,
            ),
            border: InputBorder.none,
            prefixIcon: PhosphorIcon(
              PhosphorIcons.magnifyingGlass(),
              color: AppColors.grey400,
              size: 20,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: _controller.text.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherches populaires',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Burger', 'Pizza', 'Pharmacie', 'Boutique', 'Épicerie',
                    ].map((tag) => GestureDetector(
                      onTap: () {
                        _controller.text = tag;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.dark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              )
            : Center(
                child: Text(
                  'Aucun résultat pour "${_controller.text}"',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey400,
                  ),
                ),
              ),
      ),
    );
  }
}
