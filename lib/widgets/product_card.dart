import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.wishlisted,
    required this.onWishlistToggle,
  });

  final String imageUrl;
  final String name;
  final String price;
  final bool wishlisted;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.backgroundLight,
                      child: const Center(
                        child: Icon(
                          Icons.shield,
                          size: 48,
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: InkWell(
                  onTap: onWishlistToggle,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withAlpha(220),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      wishlisted ? Icons.favorite : Icons.favorite_border,
                      color: wishlisted
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 18,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add, color: Colors.white),
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
