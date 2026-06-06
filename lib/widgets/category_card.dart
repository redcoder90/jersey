import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
  });

  final Widget icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active ? AppColors.accent : AppColors.surface;
    final foreground = active ? Colors.white : AppColors.textPrimary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withAlpha(40)
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum CategoryIconType { all, jerseys, socks, boots, accessories }

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.type,
    this.color = AppColors.backgroundDark,
  });

  final CategoryIconType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(painter: _CategoryIconPainter(type, color)),
    );
  }
}

class _CategoryIconPainter extends CustomPainter {
  _CategoryIconPainter(this.type, this.color);

  final CategoryIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case CategoryIconType.all:
        _drawAll(canvas, size, paint);
        break;
      case CategoryIconType.jerseys:
        _drawJersey(canvas, size, paint);
        break;
      case CategoryIconType.socks:
        _drawSocks(canvas, size, paint);
        break;
      case CategoryIconType.boots:
        _drawBoot(canvas, size, paint);
        break;
      case CategoryIconType.accessories:
        _drawAccessory(canvas, size, paint);
        break;
    }
  }

  void _drawAll(Canvas canvas, Size size, Paint paint) {
    final spacing = size.width * 0.08;
    final squareSize = size.width * 0.24;

    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final left = spacing + col * (squareSize + spacing);
        final top = spacing + row * (squareSize + spacing);
        final rect = Rect.fromLTWH(left, top, squareSize, squareSize);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          paint,
        );
      }
    }
  }

  void _drawJersey(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.23)
      ..lineTo(size.width * 0.33, size.height * 0.18)
      ..lineTo(size.width * 0.43, size.height * 0.18)
      ..lineTo(size.width * 0.46, size.height * 0.12)
      ..lineTo(size.width * 0.54, size.height * 0.12)
      ..lineTo(size.width * 0.57, size.height * 0.18)
      ..lineTo(size.width * 0.67, size.height * 0.18)
      ..lineTo(size.width * 0.80, size.height * 0.23)
      ..lineTo(size.width * 0.80, size.height * 0.72)
      ..lineTo(size.width * 0.20, size.height * 0.72)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.38),
      Offset(size.width * 0.66, size.height * 0.38),
      paint,
    );
  }

  void _drawSocks(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.30, size.height * 0.20)
      ..lineTo(size.width * 0.30, size.height * 0.68)
      ..arcToPoint(
        Offset(size.width * 0.70, size.height * 0.72),
        radius: Radius.circular(size.width * 0.16),
      )
      ..lineTo(size.width * 0.70, size.height * 0.60)
      ..lineTo(size.width * 0.58, size.height * 0.56)
      ..lineTo(size.width * 0.58, size.height * 0.24)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawBoot(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.62)
      ..lineTo(size.width * 0.18, size.height * 0.45)
      ..lineTo(size.width * 0.38, size.height * 0.30)
      ..lineTo(size.width * 0.72, size.height * 0.32)
      ..lineTo(size.width * 0.82, size.height * 0.46)
      ..lineTo(size.width * 0.78, size.height * 0.62)
      ..lineTo(size.width * 0.30, size.height * 0.68)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.48),
      Offset(size.width * 0.55, size.height * 0.46),
      paint,
    );
  }

  void _drawAccessory(Canvas canvas, Size size, Paint paint) {
    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.18,
        size.width * 0.22,
        size.height * 0.54,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(bottle, paint);
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.14),
      Offset(size.width * 0.56, size.height * 0.14),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.34),
      Offset(size.width * 0.62, size.height * 0.34),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
