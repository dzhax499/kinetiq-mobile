import 'dart:math';
import 'package:flutter/material.dart';

/// Particle effect system for celebrations and feedback
class ParticleEffect extends StatefulWidget {
  final bool isActive;
  final Color? primaryColor;
  final ParticleType type;
  final int particleCount;

  const ParticleEffect({
    super.key,
    this.isActive = false,
    this.primaryColor,
    this.type = ParticleType.confetti,
    this.particleCount = 50,
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

enum ParticleType { confetti, sparkle, burst, rain }

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant ParticleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _spawnParticles();
      _controller.forward(from: 0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.3,
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: _random.nextDouble() * 0.015 + 0.005,
        size: _random.nextDouble() * 8 + 3,
        color: widget.primaryColor ??
            Color.fromRGBO(
              _random.nextInt(256),
              _random.nextInt(256),
              _random.nextInt(256),
              1.0,
            ),
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        opacity: 1.0,
        delay: _random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ParticlePainter(
          particles: _particles,
          progress: _controller.value,
          type: widget.type,
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, rotation, rotationSpeed, opacity, delay;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.delay,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final ParticleType type;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final adjustedProgress = (progress - p.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final currentX = (p.x + p.vx * adjustedProgress * 60) * size.width;
      final currentY =
          (p.y + p.vy * adjustedProgress * 60 + adjustedProgress * adjustedProgress * 0.5) *
              size.height;
      final currentOpacity =
          (1.0 - adjustedProgress).clamp(0.0, 1.0) * p.opacity;

      if (currentOpacity <= 0 || currentY > size.height) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: currentOpacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + p.rotationSpeed * adjustedProgress * 20);

      switch (type) {
        case ParticleType.confetti:
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.6),
            paint,
          );
          break;
        case ParticleType.sparkle:
          _drawStar(canvas, p.size, paint);
          break;
        case ParticleType.burst:
          canvas.drawCircle(Offset.zero, p.size * (1 - adjustedProgress), paint);
          break;
        case ParticleType.rain:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: p.size * 0.3,
                  height: p.size * 1.5),
              Radius.circular(p.size * 0.15),
            ),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * pi / 5) - pi / 2;
      final innerAngle = outerAngle + 2 * pi / 5;
      if (i == 0) {
        path.moveTo(cos(outerAngle) * size, sin(outerAngle) * size);
      } else {
        path.lineTo(cos(outerAngle) * size, sin(outerAngle) * size);
      }
      path.lineTo(
          cos(innerAngle) * size * 0.4, sin(innerAngle) * size * 0.4);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) {
    return old.progress != progress;
  }
}
