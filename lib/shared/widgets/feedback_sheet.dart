import 'package:flutter/material.dart';
import 'package:yaa/shared/widgets/yaa_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// Shows the feedback bottom sheet.
/// Call this from any screen:
/// ```dart
/// showFeedbackSheet(context, shopName: 'TATA Food');
/// ```
void showFeedbackSheet(BuildContext context, {required String shopName}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeedbackSheet(shopName: shopName),
  );
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.shopName});
  final String shopName;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final Set<String> _selectedTags = {};

  final _tags = [
    {'icon': Icons.access_time, 'label': 'Ponctuel'},
    {'icon': Icons.workspace_premium, 'label': 'Professionnel'},
    {'icon': Icons.sentiment_satisfied_alt, 'label': 'Sympathique'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: AppDimens.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Close button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(
                  right: AppDimens.screenPadding, top: AppDimens.sm),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close,
                    color: AppColors.grey500, size: 24),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.md),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDimens.lg),

          // Title
          Text(
            'Course terminé',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppDimens.sm),

          // Subtitle
          Text(
            'Merci pour votre confiance chez',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.grey600),
          ),
          Text(
            widget.shopName,
            style: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppDimens.xxl),

          // Divider
          const Divider(color: AppColors.grey200),

          const SizedBox(height: AppDimens.xxl),

          // Rating section
          Text(
            'Notez votre expérience',
            style: AppTextStyles.labelLarge
                .copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppDimens.lg),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 40,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: AppDimens.xxl),

          // Divider
          const Divider(color: AppColors.grey200),

          const SizedBox(height: AppDimens.xxl),

          // Appreciation tags
          Text(
            'Qu\'avez-vous particulièrement apprécié ?',
            style: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppDimens.lg),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _tags.map((tag) {
                final label = tag['label'] as String;
                final icon = tag['icon'] as IconData;
                final isSelected = _selectedTags.contains(label);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(label);
                        } else {
                          _selectedTags.add(label);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primarySurface
                            : AppColors.white,
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            size: 24,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.grey600,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppDimens.xxxl),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: YaaButton(
              label: 'Envoyer la note',
              onPressed: () {
                // TODO: Submit review
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}