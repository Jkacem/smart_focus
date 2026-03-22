import 'package:flutter/material.dart';

/// Custom painter that draws the robot graphic used on several screens.
class RobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Head
    paint.color = const Color(0xFFE8D5F2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 20, 120, 100),
        const Radius.circular(20),
      ),
      paint,
    );

    // Head stroke
    strokePaint.color = const Color(0xFFB8A5D2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40, 20, 120, 100),
        const Radius.circular(20),
      ),
      strokePaint,
    );

    // Eyes
    paint.color = const Color(0xFF2A1F4D);
    canvas.drawCircle(const Offset(70, 55), 15, paint);
    canvas.drawCircle(const Offset(130, 55), 15, paint);

    // Eye highlights
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(73, 52), 6, paint);
    canvas.drawCircle(const Offset(133, 52), 6, paint);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF2A1F4D)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(80, 80);
    path.quadraticBezierTo(100, 90, 120, 80);
    canvas.drawPath(path, mouthPaint);

    // Headphone left
    paint.color = const Color(0xFFB8A5D2);
    canvas.drawCircle(const Offset(35, 45), 8, paint);

    strokePaint.color = const Color(0xFF8A7AA5);
    canvas.drawCircle(const Offset(35, 45), 8, strokePaint);

    final linePaint = Paint()
      ..color = const Color(0xFF8A7AA5)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(35, 35), const Offset(35, 20), linePaint);

    // Headphone right
    paint.color = const Color(0xFFB8A5D2);
    canvas.drawCircle(const Offset(165, 45), 8, paint);

    strokePaint.color = const Color(0xFF8A7AA5);
    canvas.drawCircle(const Offset(165, 45), 8, strokePaint);

    canvas.drawLine(const Offset(165, 35), const Offset(165, 20), linePaint);

    // Body
    paint.color = const Color(0xFFD4E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, 110, 140, 120),
        const Radius.circular(15),
      ),
      paint,
    );

    strokePaint.color = const Color(0xFFA8C5D5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, 110, 140, 120),
        const Radius.circular(15),
      ),
      strokePaint,
    );

    // AI Logo circle
    paint.color = const Color(0xFF2A1F4D);
    canvas.drawCircle(const Offset(100, 160), 20, paint);

    // AI Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(100 - 12, 160 - 12));

    // Left arm
    paint.color = const Color(0xFFD4E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 140, 20, 60),
        const Radius.circular(10),
      ),
      paint,
    );

    // Left hand
    paint.color = const Color(0xFFB8A5D2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 195, 25, 30),
        const Radius.circular(8),
      ),
      paint,
    );

    // Right arm
    paint.color = const Color(0xFFD4E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(170, 140, 20, 60),
        const Radius.circular(10),
      ),
      paint,
    );

    // Right hand
    paint.color = const Color(0xFFB8A5D2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(167, 195, 25, 30),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(RobotPainter oldDelegate) => false;
}
