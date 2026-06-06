import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home, label: 'Home'),
      _NavItem(icon: Icons.category, label: 'Categories'),
      _NavItem(icon: Icons.shopping_cart, label: 'Cart'),
      _NavItem(icon: Icons.favorite_border, label: 'Wishlist'),
      _NavItem(icon: Icons.person, label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final active = index == activeIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: active ? AppColors.accent : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 64),
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: active ? AppColors.accent : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
