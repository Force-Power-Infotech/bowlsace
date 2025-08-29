import 'dart:math';
import 'package:flutter/material.dart';

class ConcentricCircleChart extends StatelessWidget {
  final double value; // Value between 0 and 1
  final double size;
  final Color primaryColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ConcentricCircleChart({
    Key? key,
    required this.value,
    this.size = 120,
    required this.primaryColor,
    required this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: Size(size, size),
        painter: ConcentricCirclePainter(
          value: value,
          primaryColor: primaryColor,
          backgroundColor: backgroundColor,
        ),
        child: Center(
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class ConcentricCirclePainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color backgroundColor;

  ConcentricCirclePainter({
    required this.value,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circles
    for (int i = 3; i >= 0; i--) {
      final paint = Paint()
        ..color = backgroundColor.withOpacity(0.1 * (i + 1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.1;

      canvas.drawCircle(center, radius * (0.4 + (i * 0.15)), paint);
    }

    // Draw progress arc
    final progressPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.7),
      -pi / 2,
      2 * pi * value,
      false,
      progressPaint,
    );

    // Draw center dot
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.1, dotPaint);
  }

  @override
  bool shouldRepaint(ConcentricCirclePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
