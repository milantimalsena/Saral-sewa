import 'package:flutter/material.dart';

class AppTheme {
  // Nepal-inspired colors
  static const Color crimsonRed = Color(0xFFDC143C);
  static const Color deepBlue = Color(0xFF003893);
  static const Color offWhite = Color(0xFFF8F6F2);
  static const Color lightGrey = Color(0xFFE8E6E2);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: crimsonRed,
        onPrimary: Colors.white,
        secondary: deepBlue,
        onSecondary: Colors.white,
        error: Colors.red.shade700,
        onError: Colors.white,
        surface: offWhite,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: offWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: crimsonRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepBlue,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: crimsonRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 16),
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      ),
    );
  }
}

/// Mountain-inspired header painter
class MountainHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.crimsonRed,
          AppTheme.crimsonRed.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // Mountain peaks
    final Paint mountainPaint1 = Paint()
      ..color = AppTheme.deepBlue.withValues(alpha: 0.3);

    final Paint mountainPaint2 = Paint()
      ..color = AppTheme.deepBlue.withValues(alpha: 0.2);

    final Paint snowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);

    // Back mountain range
    Path backMountain = Path();
    backMountain.moveTo(0, size.height);
    backMountain.lineTo(0, size.height * 0.7);
    backMountain.lineTo(size.width * 0.15, size.height * 0.5);
    backMountain.lineTo(size.width * 0.3, size.height * 0.65);
    backMountain.lineTo(size.width * 0.45, size.height * 0.35);
    backMountain.lineTo(size.width * 0.55, size.height * 0.5);
    backMountain.lineTo(size.width * 0.7, size.height * 0.3);
    backMountain.lineTo(size.width * 0.85, size.height * 0.55);
    backMountain.lineTo(size.width, size.height * 0.4);
    backMountain.lineTo(size.width, size.height);
    backMountain.close();
    canvas.drawPath(backMountain, mountainPaint2);

    // Front mountain range
    Path frontMountain = Path();
    frontMountain.moveTo(0, size.height);
    frontMountain.lineTo(0, size.height * 0.8);
    frontMountain.lineTo(size.width * 0.2, size.height * 0.55);
    frontMountain.lineTo(size.width * 0.35, size.height * 0.7);
    frontMountain.lineTo(size.width * 0.5, size.height * 0.45);
    frontMountain.lineTo(size.width * 0.65, size.height * 0.6);
    frontMountain.lineTo(size.width * 0.8, size.height * 0.5);
    frontMountain.lineTo(size.width, size.height * 0.65);
    frontMountain.lineTo(size.width, size.height);
    frontMountain.close();
    canvas.drawPath(frontMountain, mountainPaint1);

    // Snow caps
    Path snowCaps = Path();
    snowCaps.moveTo(size.width * 0.45, size.height * 0.35);
    snowCaps.lineTo(size.width * 0.42, size.height * 0.42);
    snowCaps.lineTo(size.width * 0.48, size.height * 0.42);
    snowCaps.close();

    snowCaps.moveTo(size.width * 0.7, size.height * 0.3);
    snowCaps.lineTo(size.width * 0.67, size.height * 0.38);
    snowCaps.lineTo(size.width * 0.73, size.height * 0.38);
    snowCaps.close();

    canvas.drawPath(snowCaps, snowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle mandala watermark painter
class MandalaWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.deepBlue.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;

    // Draw concentric circles
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(center, maxRadius * (i / 6), paint);
    }

    // Draw radial lines
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * 3.14159 / 180;
      final startX = center.dx + (maxRadius * 0.2) * cos(angle);
      final startY = center.dy + (maxRadius * 0.2) * sin(angle);
      final endX = center.dx + maxRadius * cos(angle);
      final endY = center.dy + maxRadius * sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw petal shapes
    final Paint petalPaint = Paint()
      ..color = AppTheme.crimsonRed.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * 3.14159 / 180;
      Path petal = Path();
      final petalRadius = maxRadius * 0.5;
      final petalX = center.dx + petalRadius * cos(angle);
      final petalY = center.dy + petalRadius * sin(angle);
      petal.addOval(
        Rect.fromCenter(
          center: Offset(petalX, petalY),
          width: maxRadius * 0.25,
          height: maxRadius * 0.12,
        ),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  double _cos(double radians) {
    return cosine(radians);
  }

  double _sin(double radians) {
    return sine(radians);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple trigonometric functions
double cosine(double radians) {
  // Taylor series approximation
  radians = radians % (2 * 3.14159265359);
  double result = 1.0;
  double term = 1.0;
  for (int i = 1; i <= 10; i++) {
    term *= -radians * radians / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

double sine(double radians) {
  // Taylor series approximation
  radians = radians % (2 * 3.14159265359);
  double result = radians;
  double term = radians;
  for (int i = 1; i <= 10; i++) {
    term *= -radians * radians / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}
