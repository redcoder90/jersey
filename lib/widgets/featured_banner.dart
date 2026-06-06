import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class FeaturedBanner extends StatelessWidget {
  const FeaturedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.backgroundDeep, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;

          return Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.loose,
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW SEASON JERSEYS',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Discover the latest club and national team kits',
                      style: AppTextStyles.body.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.backgroundDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Shop Now'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: isCompact ? AppSpacing.lg : 0,
                width: isCompact ? 0 : AppSpacing.lg,
              ),
              Flexible(
                fit: FlexFit.loose,
                flex: 2,
                child: Align(
                  alignment: isCompact
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? constraints.maxWidth * 0.82 : 220,
                      maxHeight: isCompact ? 240 : 260,
                    ),
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Image.network(
                        'https://images.pexels.com/photos/4171652/pexels-photo-4171652.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shield,
                              color: Colors.white70,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
