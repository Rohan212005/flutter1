import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    // Dark matte gray background (previous color used)
    paint.color = Color(0xFF212121); // Dark gray (matte gray)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Optional Curved Shape (if you want a subtle curve at the bottom)
    paint.color = Color(0xFF212121).withOpacity(0.9); // Slightly transparent gray
    Path path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

