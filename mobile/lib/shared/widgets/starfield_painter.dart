import 'dart:math' show Random;
import 'package:flutter/material.dart';

/// Paints a simple starfield background used on the welcome screen.
class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..isAntiAlias = true;

    final random = Random();

    // Generate stars across the canvas
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => false;
}
