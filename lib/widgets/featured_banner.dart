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
          final bannerHeight = isCompact ? 232.0 : 260.0;

          return SizedBox(
            height: bannerHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: _AnimatedJerseyStrip(
                    compact: isCompact,
                    availableWidth: constraints.maxWidth,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.backgroundDeep.withAlpha(240),
                          AppColors.backgroundDeep.withAlpha(150),
                          AppColors.backgroundDeep.withAlpha(40),
                        ],
                        stops: const [0, 0.46, 1],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact
                          ? constraints.maxWidth * 0.78
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
                          'Fresh club and national team looks, moving through the drip wall.',
                          maxLines: isCompact ? 3 : 2,
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
    final gap = widget.compact ? 12.0 : 16.0;
    final itemWidth = (widget.availableWidth * (widget.compact ? 0.34 : 0.2))
        .clamp(96.0, widget.compact ? 138.0 : 172.0);
    final itemHeight = widget.compact ? 178.0 : 210.0;
    final sequenceWidth = (itemWidth + gap) * _assets.length;

    return ClipRect(
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = -sequenceWidth + (_controller.value * sequenceWidth);
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: SizedBox(
            width: sequenceWidth * 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _JerseySequence(
                  assets: _assets,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  gap: gap,
                ),
                _JerseySequence(
                  assets: _assets,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  gap: gap,
                ),
              ],
            ),
          ),
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
