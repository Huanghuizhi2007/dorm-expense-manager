import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/analytics.dart';
import '../../core/app_constants.dart';

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.entries,
    this.size = 132,
  });

  final List<CategorySummary> entries;
  final double size;

  @override
  Widget build(BuildContext context) {
    final totalCents = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.amountCents,
    );
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(entries),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '总消费',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                money(totalCents / 100),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.entries);

  final List<CategorySummary> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final totalCents = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.amountCents,
    );
    if (totalCents == 0) return;

    const strokeWidth = 16.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    var startAngle = -pi / 2;

    for (final entry in entries) {
      final sweepAngle = (entry.amountCents / totalCents) * 2 * pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = categoryStyle(entry.category).color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

