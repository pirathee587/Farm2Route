import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Farm2RouteLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final double wheelRotation;

  const Farm2RouteLogo({
    super.key,
    this.size = 120.0,
    this.showWordmark = true,
    this.wheelRotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Concentric Badge (Outer translucent ring + Inner soft mint disc)
        Container(
          width: size * 1.5,
          height: size * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF98E0B3)
                .withValues(alpha: 0.55), // Outer soft mint ring
          ),
          child: Center(
            child: Container(
              width: size * 1.15,
              height: size * 1.15,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD6F3E3), // Inner elevated disc
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: size * 0.95,
                  height: size * 0.70,
                  child: CustomPaint(
                    painter:
                        _EcoTruckBadgePainter(wheelRotation: wheelRotation),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (showWordmark) ...[
          const SizedBox(height: 28),
          // Wordmark matching image: "Farm" (black) + "2" (white)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Farm',
                  style: GoogleFonts.outfit(
                    fontSize: size * 0.44,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF141414), // Bold black
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: '2',
                  style: GoogleFonts.outfit(
                    fontSize: size * 0.44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white, // Crisp White '2'
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Second line: "Route" in bold black
          Text(
            'Route',
            style: GoogleFonts.outfit(
              fontSize: size * 0.44,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414), // Bold black
              letterSpacing: -1.0,
              height: 0.95,
            ),
          ),
        ],
      ],
    );
  }
}

class _EcoTruckBadgePainter extends CustomPainter {
  final double wheelRotation;

  _EcoTruckBadgePainter({required this.wheelRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const greenDark = Color(0xFF1E5E3A); // Cabin & primary green
    const greenMedium = Color(0xFF2E7D32); // Leaves
    const greenLight = Color(0xFF43A047);
    const frameColor = Color(0xFF212121);
    const wheelRim = Color(0xFF1B3826);
    const hubColor = Color(0xFFD6F3E3);

    // =========================================================================
    // 1. CARGO BOX (White Container with dark outline)
    // =========================================================================
    final boxLeft = w * 0.38;
    final boxTop = h * 0.22;
    final boxWidth = w * 0.33;
    final boxHeight = h * 0.42;

    // Cargo White Box
    final boxPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        const Radius.circular(3),
      ),
      boxPaint,
    );

    // Frame Outline
    final outlinePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        const Radius.circular(3),
      ),
      outlinePaint,
    );

    // Green Harvest / Plant Motif inside the white container
    final plantPaint = Paint()
      ..color = greenMedium
      ..style = PaintingStyle.fill;

    // Central leaf
    final leafCenter = Path();
    leafCenter.moveTo(boxLeft + boxWidth * 0.50, boxTop + boxHeight * 0.72);
    leafCenter.quadraticBezierTo(
      boxLeft + boxWidth * 0.38,
      boxTop + boxHeight * 0.42,
      boxLeft + boxWidth * 0.50,
      boxTop + boxHeight * 0.24,
    );
    leafCenter.quadraticBezierTo(
      boxLeft + boxWidth * 0.62,
      boxTop + boxHeight * 0.42,
      boxLeft + boxWidth * 0.50,
      boxTop + boxHeight * 0.72,
    );
    canvas.drawPath(leafCenter, plantPaint);

    // Left leaf
    final leafL = Path();
    leafL.moveTo(boxLeft + boxWidth * 0.46, boxTop + boxHeight * 0.56);
    leafL.quadraticBezierTo(
      boxLeft + boxWidth * 0.30,
      boxTop + boxHeight * 0.42,
      boxLeft + boxWidth * 0.26,
      boxTop + boxHeight * 0.30,
    );
    leafL.quadraticBezierTo(
      boxLeft + boxWidth * 0.44,
      boxTop + boxHeight * 0.36,
      boxLeft + boxWidth * 0.46,
      boxTop + boxHeight * 0.56,
    );
    canvas.drawPath(leafL, plantPaint);

    // Right leaf
    final leafR = Path();
    leafR.moveTo(boxLeft + boxWidth * 0.54, boxTop + boxHeight * 0.56);
    leafR.quadraticBezierTo(
      boxLeft + boxWidth * 0.70,
      boxTop + boxHeight * 0.42,
      boxLeft + boxWidth * 0.74,
      boxTop + boxHeight * 0.30,
    );
    leafR.quadraticBezierTo(
      boxLeft + boxWidth * 0.56,
      boxTop + boxHeight * 0.36,
      boxLeft + boxWidth * 0.54,
      boxTop + boxHeight * 0.56,
    );
    canvas.drawPath(leafR, plantPaint);

    // Stem dots / grains
    canvas.drawCircle(
        Offset(boxLeft + boxWidth * 0.36, boxTop + boxHeight * 0.62),
        2.2,
        plantPaint);
    canvas.drawCircle(
        Offset(boxLeft + boxWidth * 0.64, boxTop + boxHeight * 0.62),
        2.2,
        plantPaint);

    // Under-chassis bar
    final chassisPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
          boxLeft - 2, boxTop + boxHeight, boxWidth + w * 0.08, h * 0.08),
      chassisPaint,
    );

    // =========================================================================
    // 2. GREEN TRUCK CABIN
    // =========================================================================
    final cabLeft = boxLeft + boxWidth + 2;
    final cabTop = h * 0.32;
    final cabWidth = w * 0.17;
    final cabHeight = h * 0.36;

    final cabPath = Path();
    cabPath.moveTo(cabLeft, cabTop);
    cabPath.lineTo(cabLeft + cabWidth * 0.50, cabTop);
    cabPath.quadraticBezierTo(
      cabLeft + cabWidth,
      cabTop + cabHeight * 0.20,
      cabLeft + cabWidth,
      cabTop + cabHeight * 0.80,
    );
    cabPath.lineTo(cabLeft + cabWidth, cabTop + cabHeight);
    cabPath.lineTo(cabLeft, cabTop + cabHeight);
    cabPath.close();

    final cabPaint = Paint()..color = greenDark;
    canvas.drawPath(cabPath, cabPaint);

    // Window (White curved)
    final winLeft = cabLeft + cabWidth * 0.18;
    final winTop = cabTop + cabHeight * 0.12;
    final winWidth = cabWidth * 0.70;
    final winHeight = cabHeight * 0.44;

    final winPath = Path();
    winPath.moveTo(winLeft, winTop);
    winPath.lineTo(winLeft + winWidth * 0.45, winTop);
    winPath.quadraticBezierTo(
      winLeft + winWidth,
      winTop + winHeight * 0.18,
      winLeft + winWidth,
      winTop + winHeight,
    );
    winPath.lineTo(winLeft, winTop + winHeight);
    winPath.close();

    final winPaint = Paint()..color = Colors.white;
    canvas.drawPath(winPath, winPaint);

    // Door line accent
    final doorPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(winLeft, winTop + winHeight + 3),
      Offset(winLeft + winWidth * 0.4, winTop + winHeight + 3),
      doorPaint,
    );

    // =========================================================================
    // 3. WHEELS (2 Rear, 1 Front)
    // =========================================================================
    final wheelRadius = h * 0.085;
    final wheelY = boxTop + boxHeight + h * 0.09;

    _drawWheel(canvas, w * 0.44, wheelY, wheelRadius, wheelRim, hubColor);
    _drawWheel(canvas, w * 0.54, wheelY, wheelRadius, wheelRim, hubColor);
    _drawWheel(canvas, w * 0.77, wheelY, wheelRadius, wheelRim, hubColor);

    // =========================================================================
    // 4. SWIRLING LEAF TRAILS (Sweeping gracefully from the rear)
    // =========================================================================
    final swirlPaint = Paint()
      ..color = greenMedium
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    // Lower sweeping trail
    final swirl1 = Path();
    swirl1.moveTo(boxLeft + w * 0.04, boxTop + boxHeight * 0.85);
    swirl1.cubicTo(
      w * 0.30,
      h * 0.70,
      w * 0.22,
      h * 0.65,
      w * 0.28,
      h * 0.48,
    );
    canvas.drawPath(swirl1, swirlPaint);

    // Upper sweeping trail
    final swirl2 = Path();
    swirl2.moveTo(boxLeft - 2, boxTop + boxHeight * 0.75);
    swirl2.cubicTo(
      w * 0.24,
      h * 0.55,
      w * 0.26,
      h * 0.42,
      w * 0.34,
      h * 0.32,
    );
    canvas.drawPath(swirl2, swirlPaint);

    // Trailing organic leaves
    _drawLeaf(canvas, Offset(w * 0.27, h * 0.46), Offset(w * 0.20, h * 0.40),
        greenLight);
    _drawLeaf(canvas, Offset(w * 0.24, h * 0.56), Offset(w * 0.16, h * 0.52),
        greenMedium);
    _drawLeaf(canvas, Offset(w * 0.32, h * 0.34), Offset(w * 0.28, h * 0.25),
        greenDark);
    _drawLeaf(canvas, Offset(w * 0.36, h * 0.28), Offset(w * 0.33, h * 0.20),
        greenLight);
  }

  void _drawLeaf(Canvas canvas, Offset base, Offset tip, Color color) {
    final path = Path();
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(
      (base.dx + tip.dx) / 2 + 5,
      (base.dy + tip.dy) / 2 - 6,
      tip.dx,
      tip.dy,
    );
    path.quadraticBezierTo(
      (base.dx + tip.dx) / 2 - 5,
      (base.dy + tip.dy) / 2 + 6,
      base.dx,
      base.dy,
    );
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawWheel(Canvas canvas, double cx, double cy, double radius, Color rim,
      Color hub) {
    // Outer tire
    final tirePaint = Paint()..color = rim;
    canvas.drawCircle(Offset(cx, cy), radius, tirePaint);

    // White ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(cx, cy), radius * 0.65, ringPaint);

    // Inner hub
    final hubPaint = Paint()..color = hub;
    canvas.drawCircle(Offset(cx, cy), radius * 0.42, hubPaint);

    // Animated Wheel Spoke / Lug dot
    if (wheelRotation != 0.0) {
      final spokePaint = Paint()
        ..color = rim
        ..style = PaintingStyle.fill;
      final spokeX = cx + math.cos(wheelRotation) * (radius * 0.26);
      final spokeY = cy + math.sin(wheelRotation) * (radius * 0.26);
      canvas.drawCircle(Offset(spokeX, spokeY), 1.2, spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EcoTruckBadgePainter oldDelegate) =>
      oldDelegate.wheelRotation != wheelRotation;
}
