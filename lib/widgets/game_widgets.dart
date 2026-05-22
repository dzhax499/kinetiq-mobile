import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated countdown timer widget with visual effects
class CountdownWidget extends StatefulWidget {
  final int seconds;
  final bool isThinking;
  final VoidCallback? onComplete;

  const CountdownWidget({
    super.key,
    required this.seconds,
    this.isThinking = true,
    this.onComplete,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getTimerColor() {
    if (widget.seconds > 5) return AppTheme.accentGreen;
    if (widget.seconds > 3) return AppTheme.accentYellow;
    return AppTheme.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTimerColor();
    final label = widget.isThinking ? 'PIKIRKAN POSE!' : 'MULAI POSE!';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phase label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Countdown number
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.seconds <= 3 ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bgCard.withValues(alpha: 0.8),
                  border: Border.all(color: color, width: 3),
                  boxShadow: AppTheme.neonGlow(color, blur: 15),
                ),
                child: Center(
                  child: Text(
                    '${widget.seconds}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Circular score gauge with animated counting
class ScoreGauge extends StatefulWidget {
  final double score;
  final double size;
  final Duration animationDuration;
  final Color? color;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 160,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.color,
  });

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: 0, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final color = widget.color ?? AppTheme.getScoreColor(currentScore);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugeRingPainter(
                  progress: currentScore / 100,
                  color: color,
                  backgroundColor: AppTheme.bgCardLight,
                ),
              ),
              // Score text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentScore.toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    AppTheme.getScoreLabel(currentScore),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugeRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _GaugeRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugeRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Reference card widget showing the pose to imitate
class ReferenceCard extends StatelessWidget {
  final String poseName;
  final String description;
  final Map<dynamic, List<double>> targetLandmarks;
  final bool compact;

  const ReferenceCard({
    super.key,
    required this.poseName,
    required this.description,
    required this.targetLandmarks,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration(
        borderColor: AppTheme.primaryCyan.withValues(alpha: 0.3),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(
              'TIRUKAN POSE INI!',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryCyan,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Skeleton preview
          SizedBox(
            height: compact ? 100 : 160,
            width: compact ? 100 : 160,
            child: CustomPaint(
              painter: _SimpleSkeletonPainter(
                landmarks: targetLandmarks,
                color: AppTheme.primaryCyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            poseName,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple skeleton painter for reference cards
class _SimpleSkeletonPainter extends CustomPainter {
  final Map<dynamic, List<double>> landmarks;
  final Color color;

  _SimpleSkeletonPainter({
    required this.landmarks,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.height / 6;

    Offset toCanvas(List<double> coords) {
      return Offset(
        centerX + coords[0] * scale,
        centerY + coords[1] * scale * 0.7,
      );
    }

    // Draw head circle
    final neck = Offset(centerX, centerY - 1.3 * scale * 0.7);
    canvas.drawCircle(neck, 8, Paint()..color = color.withValues(alpha: 0.4));
    canvas.drawCircle(
      Offset(neck.dx, neck.dy - 6),
      10,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Simplified connections using string keys
    final connections = [
      ['leftShoulder', 'rightShoulder'],
      ['leftHip', 'rightHip'],
      ['leftShoulder', 'leftHip'],
      ['rightShoulder', 'rightHip'],
      ['leftShoulder', 'leftElbow'],
      ['leftElbow', 'leftWrist'],
      ['rightShoulder', 'rightElbow'],
      ['rightElbow', 'rightWrist'],
      ['leftHip', 'leftKnee'],
      ['leftKnee', 'leftAnkle'],
      ['rightHip', 'rightKnee'],
      ['rightKnee', 'rightAnkle'],
    ];

    // Map string keys to actual landmark keys
    final keyMap = <String, dynamic>{};
    for (final entry in landmarks.entries) {
      final key = entry.key.toString();
      if (key.contains('leftShoulder')) keyMap['leftShoulder'] = entry.key;
      if (key.contains('rightShoulder')) keyMap['rightShoulder'] = entry.key;
      if (key.contains('leftElbow')) keyMap['leftElbow'] = entry.key;
      if (key.contains('rightElbow')) keyMap['rightElbow'] = entry.key;
      if (key.contains('leftWrist')) keyMap['leftWrist'] = entry.key;
      if (key.contains('rightWrist')) keyMap['rightWrist'] = entry.key;
      if (key.contains('leftHip')) keyMap['leftHip'] = entry.key;
      if (key.contains('rightHip')) keyMap['rightHip'] = entry.key;
      if (key.contains('leftKnee')) keyMap['leftKnee'] = entry.key;
      if (key.contains('rightKnee')) keyMap['rightKnee'] = entry.key;
      if (key.contains('leftAnkle')) keyMap['leftAnkle'] = entry.key;
      if (key.contains('rightAnkle')) keyMap['rightAnkle'] = entry.key;
    }

    for (final conn in connections) {
      final fromKey = keyMap[conn[0]];
      final toKey = keyMap[conn[1]];
      if (fromKey != null && toKey != null) {
        final from = landmarks[fromKey];
        final to = landmarks[toKey];
        if (from != null && to != null) {
          canvas.drawLine(toCanvas(from), toCanvas(to), linePaint);
        }
      }
    }

    for (final entry in landmarks.entries) {
      final point = toCanvas(entry.value);
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Particle background animation for home screen
class ParticleBackground extends StatefulWidget {
  final Widget child;

  const ParticleBackground({super.key, required this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.3 + 0.1,
        opacity: _random.nextDouble() * 0.3 + 0.1,
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
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        ),
        // Particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(
                particles: _particles,
                animationValue: _controller.value,
              ),
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + animationValue * particle.speed) % 1.0;
      final paint = Paint()
        ..color = AppTheme.primaryCyan.withValues(alpha: particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
