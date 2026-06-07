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
          final bannerHeight = isCompact ? 260.0 : 260.0;

          return SizedBox(
            height: bannerHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: isCompact ? 0 : constraints.maxWidth * 0.42,
                  right: 0,
                  bottom: isCompact ? AppSpacing.xs : AppSpacing.sm,
                  height: isCompact ? 92 : 208,
                  child: _AnimatedJerseyStrip(
                    compact: isCompact,
                    availableWidth: isCompact
                        ? constraints.maxWidth
                        : constraints.maxWidth * 0.58,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.backgroundDeep.withAlpha(240),
                          AppColors.backgroundDeep.withAlpha(118),
                          AppColors.backgroundDeep.withAlpha(0),
                        ],
                        stops: const [0, 0.54, 1],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: isCompact ? AppSpacing.sm : null,
                  bottom: isCompact ? null : 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact
                          ? constraints.maxWidth * 0.82
                          : constraints.maxWidth * 0.46,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW SEASON JERSEYS',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: Colors.white,
                            fontSize: isCompact ? 24 : 28,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Discover the latest club and national team kits',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedJerseyStrip extends StatefulWidget {
  const _AnimatedJerseyStrip({
    required this.compact,
    required this.availableWidth,
  });

  final bool compact;
  final double availableWidth;

  @override
  State<_AnimatedJerseyStrip> createState() => _AnimatedJerseyStripState();
}

class _AnimatedJerseyStripState extends State<_AnimatedJerseyStrip>
    with SingleTickerProviderStateMixin {
  static const _assets = [
    'product_images/animations/argentina.jpeg',
    'product_images/animations/belgium.jpeg',
    'product_images/animations/germany.jpeg',
    'product_images/animations/japan.jpeg',
    'product_images/animations/mexico.jpeg',
    'product_images/animations/seven.jpeg',
    'product_images/animations/spain.jpeg',
    'product_images/animations/spain2.jpeg',
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.compact ? 10.0 : 16.0;
    final itemWidth = (widget.availableWidth * (widget.compact ? 0.24 : 0.25))
        .clamp(68.0, widget.compact ? 86.0 : 154.0);
    final itemHeight = widget.compact ? 88.0 : 188.0;
    final sequenceWidth = (itemWidth + gap) * _assets.length;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: sequenceWidth * 2,
        maxWidth: sequenceWidth * 2,
        minHeight: itemHeight,
        maxHeight: itemHeight,
        child: AnimatedBuilder(
          animation: _controller,
          child: SizedBox(
            width: sequenceWidth * 2,
            height: itemHeight,
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  _JerseySequence(
                    assets: _assets,
                    itemWidth: itemWidth,
                    itemHeight: itemHeight,
                    gap: gap,
                  ),
              ],
            ),
          ),
          builder: (context, child) {
            final offset = -_controller.value * sequenceWidth;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
        ),
      ),
    );
  }
}

class _JerseySequence extends StatelessWidget {
  const _JerseySequence({
    required this.assets,
    required this.itemWidth,
    required this.itemHeight,
    required this.gap,
  });

  final List<String> assets;
  final double itemWidth;
  final double itemHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final asset in assets) ...[
          _JerseyFrame(asset: asset, width: itemWidth, height: itemHeight),
          SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _JerseyFrame extends StatelessWidget {
  const _JerseyFrame({
    required this.asset,
    required this.width,
    required this.height,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(46)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.sports_soccer,
                color: Colors.white.withAlpha(150),
                size: 34,
              );
            },
          ),
        ),
      ),
    );
  }
}
