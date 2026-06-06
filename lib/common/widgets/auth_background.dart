import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundDark, AppColors.backgroundDeep],
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -56,
            child: _DecorativeCircle(
              diameter: 220,
              color: AppColors.accent.withAlpha((0.08 * 255).round()),
            ),
          ),
          Positioned(
            top: 80,
            right: -36,
            child: _DecorativeCircle(
              diameter: 140,
              color: Colors.white.withAlpha((0.04 * 255).round()),
            ),
          ),
          Positioned(
            bottom: -64,
            left: -48,
            child: _DecorativeCircle(
              diameter: 180,
              color: Colors.white.withAlpha((0.06 * 255).round()),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -72,
            child: _DecorativeCircle(
              diameter: 260,
              color: AppColors.accent.withAlpha((0.06 * 255).round()),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
