import 'package:flutter/material.dart';

/// Gradient sky with softly drifting clouds (painter-based, no assets).
class CloudSkyBackground extends StatefulWidget {
  final Animation<double>? drift;

  const CloudSkyBackground({super.key, this.drift});

  @override
  State<CloudSkyBackground> createState() => _CloudSkyBackgroundState();
}

class _CloudSkyBackgroundState extends State<CloudSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drift = widget.drift ?? _controller;
    return AnimatedBuilder(
      animation: drift,
      builder: (context, _) => CustomPaint(
        painter: _SkyCloudPainter(drift.value),
        size: Size.infinite,
      ),
    );
  }
}

class _SkyCloudPainter extends CustomPainter {
  final double t;

  _SkyCloudPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF1E6FD9),
        Color(0xFF4DA3F0),
        Color(0xFF87CEEB),
        Color(0xFFB8E4FF),
        Color(0xFFE8F6FF),
        Color(0xFFF0FAFF),
      ],
      stops: const [0.0, 0.22, 0.45, 0.65, 0.85, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = sky.createShader(rect));

    // Soft sun glow
    final sunCenter = Offset(size.width * 0.78, size.height * 0.14);
    final sunGlow = RadialGradient(
      colors: [
        const Color(0xFFFFF9E6).withValues(alpha: 0.55),
        const Color(0xFFFFF9E6).withValues(alpha: 0.0),
      ],
    );
    canvas.drawCircle(
      sunCenter,
      size.width * 0.22,
      Paint()..shader = sunGlow.createShader(Rect.fromCircle(center: sunCenter, radius: size.width * 0.22)),
    );

    void drawCloud({
      required double baseX,
      required double baseY,
      required double scale,
      required double opacity,
      required double speed,
    }) {
      final dx = ((baseX + t * speed) % (size.width + 200)) - 100;
      final center = Offset(dx, baseY);
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      final w = 80.0 * scale;
      final h = 36.0 * scale;
      canvas.drawOval(Rect.fromCenter(center: center.translate(-w * 0.35, 0), width: w * 0.9, height: h), paint);
      canvas.drawOval(Rect.fromCenter(center: center, width: w * 1.1, height: h * 1.05), paint);
      canvas.drawOval(Rect.fromCenter(center: center.translate(w * 0.32, h * 0.05), width: w * 0.85, height: h * 0.95), paint);
    }

    drawCloud(baseX: size.width * 0.1, baseY: size.height * 0.18, scale: 1.4, opacity: 0.92, speed: 12);
    drawCloud(baseX: size.width * 0.55, baseY: size.height * 0.12, scale: 1.0, opacity: 0.78, speed: 8);
    drawCloud(baseX: size.width * 0.25, baseY: size.height * 0.32, scale: 1.8, opacity: 0.88, speed: 6);
    drawCloud(baseX: size.width * 0.7, baseY: size.height * 0.28, scale: 1.2, opacity: 0.72, speed: 10);
    drawCloud(baseX: size.width * 0.0, baseY: size.height * 0.42, scale: 2.0, opacity: 0.65, speed: 5);
    drawCloud(baseX: size.width * 0.45, baseY: size.height * 0.48, scale: 1.5, opacity: 0.8, speed: 7);

    // Subtle horizon haze
    final haze = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        const Color(0xFF0D9488).withValues(alpha: 0.06),
        const Color(0xFF0D9488).withValues(alpha: 0.12),
      ],
      stops: const [0.55, 0.82, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
      Paint()..shader = haze.createShader(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5)),
    );
  }

  @override
  bool shouldRepaint(covariant _SkyCloudPainter old) => old.t != t;
}
