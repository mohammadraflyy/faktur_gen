import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

/// Programmatic app logo — a stylized document icon with "F" letter.
/// Used in splash screen, about dialogs, etc.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.invoiceBlueSoft : AppColors.invoiceBlue;
    final secondary = isDark ? AppColors.strukGreenSoft : AppColors.strukGreen;
    final radius = size * 0.22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background rounded rectangle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, secondary],
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
          ),
          // Document fold corner
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size * 0.28, size * 0.28),
              painter: _FoldPainter(
                color: Colors.white.withValues(alpha: 0.15),
                radius: radius,
              ),
            ),
          ),
          // "F" letter
          Center(
            child: Text(
              'F',
              style: GoogleFonts.inter(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          // Small receipt lines at bottom
          Positioned(
            bottom: size * 0.15,
            left: size * 0.22,
            right: size * 0.22,
            child: Column(
              children: [
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                SizedBox(height: size * 0.04),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoldPainter extends CustomPainter {
  final Color color;
  final double radius;

  _FoldPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, radius)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, radius);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
