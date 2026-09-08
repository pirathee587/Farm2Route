import 'package:flutter/material.dart';

class TopographyBackground extends StatelessWidget {
  final Widget child;
  final Color strokeColor;

  const TopographyBackground({
    super.key,
    required this.child,
    this.strokeColor = const Color(0x121E5E3A), // Faint organic green contour
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TopographyPainter(strokeColor: strokeColor),
      child: child,
    );
  }
}

class _TopographyPainter extends CustomPainter {
  final Color strokeColor;

  _TopographyPainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw wavy organic contour lines matching Agrizel banner artwork
    final path1 = Path();
    path1.moveTo(0, size.height * 0.15);
    path1.cubicTo(
      size.width * 0.3,
      size.height * 0.08,
      size.width * 0.7,
      size.height * 0.22,
      size.width,
      size.height * 0.12,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.25);
    path2.cubicTo(
      size.width * 0.25,
      size.height * 0.18,
      size.width * 0.65,
      size.height * 0.32,
      size.width,
      size.height * 0.20,
    );
    canvas.drawPath(path2, paint);

    final path3 = Path();
    path3.moveTo(0, size.height * 0.38);
    path3.cubicTo(
      size.width * 0.35,
      size.height * 0.28,
      size.width * 0.75,
      size.height * 0.45,
      size.width,
      size.height * 0.32,
    );
    canvas.drawPath(path3, paint);

    final path4 = Path();
    path4.moveTo(-size.width * 0.1, size.height * 0.85);
    path4.cubicTo(
      size.width * 0.4,
      size.height * 0.75,
      size.width * 0.6,
      size.height * 0.95,
      size.width * 1.1,
      size.height * 0.82,
    );
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant _TopographyPainter oldDelegate) => false;
}
