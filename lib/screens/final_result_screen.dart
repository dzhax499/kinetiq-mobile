import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';
import 'home_screen.dart';

class FinalResultScreen extends StatefulWidget {
  final GameEngine gameEngine;

  const FinalResultScreen({super.key, required this.gameEngine});

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  final List<_ConfettiParticle> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

    // Generate confetti
    for (int i = 0; i < 50; i++) {
      _confetti.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * -1,
        size: _random.nextDouble() * 8 + 4,
        speed: _random.nextDouble() * 0.4 + 0.2,
        color: [
          AppTheme.primaryCyan,
          AppTheme.secondaryPink,
          AppTheme.accentPurple,
          AppTheme.accentGreen,
          AppTheme.accentYellow,
        ][_random.nextInt(5)],
        rotation: _random.nextDouble() * 360,
      ));
    }

    _entryController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ge = widget.gameEngine;
    final winner = ge.getOverallWinner();
    final roundsWon = ge.getRoundsWon();
    final isTie = winner == 'Seri!';

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          ),

          // Confetti
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: _confetti,
                  progress: _confettiController.value,
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                return Opacity(
                  opacity: _entryController.value.clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Trophy icon
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isTie
                              ? null
                              : AppTheme.primaryGradient,
                          color: isTie ? AppTheme.bgCardLight : null,
                          boxShadow: isTie
                              ? null
                              : AppTheme.neonGlow(AppTheme.primaryCyan, blur: 25),
                        ),
                        child: Icon(
                          isTie
                              ? Icons.handshake_rounded
                              : Icons.emoji_events_rounded,
                          size: 50,
                          color: isTie ? AppTheme.textMuted : AppTheme.bgDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'GAME SELESAI!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => (isTie
                              ? const LinearGradient(
                                  colors: [AppTheme.textMuted, AppTheme.textSecondary])
                              : AppTheme.primaryGradient)
                          .createShader(bounds),
                      child: Text(
                        isTie ? 'SERI!' : '🏆 $winner',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (!isTie)
                      Text(
                        'PEMENANG!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                          letterSpacing: 3,
                        ),
                      ),

                    const SizedBox(height: 32),

                    // === Score Summary ===
                    Container(
                      decoration: AppTheme.glassDecoration(
                        borderColor: AppTheme.primaryCyan.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'SKOR RATA-RATA',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      ge.player1.name,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryCyan,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    ScoreGauge(
                                      score: ge.player1.totalScore,
                                      size: 100,
                                      color: AppTheme.primaryCyan,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${roundsWon[ge.player1.name] ?? 0} ronde menang',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 140,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      ge.player2.name,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.secondaryPink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    ScoreGauge(
                                      score: ge.player2.totalScore,
                                      size: 100,
                                      color: AppTheme.secondaryPink,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${roundsWon[ge.player2.name] ?? 0} ronde menang',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // === Round-by-Round Breakdown ===
                    Container(
                      decoration: AppTheme.glassDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DETAIL PER RONDE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(ge.player1.scores.length, (i) {
                            final p1 = ge.player1.scores[i];
                            final p2 = i < ge.player2.scores.length
                                ? ge.player2.scores[i]
                                : 0.0;
                            final p1Won = p1 > p2;
                            final p2Won = p2 > p1;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  // Round number
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.bgCardLight,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // P1 score bar
                                  Expanded(
                                    child: _buildScoreBar(
                                      p1,
                                      AppTheme.primaryCyan,
                                      p1Won,
                                      alignRight: true,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // P2 score bar
                                  Expanded(
                                    child: _buildScoreBar(
                                      p2,
                                      AppTheme.secondaryPink,
                                      p2Won,
                                      alignRight: false,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // === Buttons ===
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: AppTheme.neonGlow(AppTheme.primaryCyan, blur: 10),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.replay_rounded, size: 24),
                          label: const Text('MAIN LAGI'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppTheme.bgDark,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_rounded, size: 22),
                        label: const Text('KEMBALI KE HOME'),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(double score, Color color, bool isWinner,
      {required bool alignRight}) {
    return Row(
      mainAxisAlignment:
          alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (alignRight) ...[
          Text(
            '${score.toInt()}%',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWinner ? color : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppTheme.bgCardLight,
            ),
            clipBehavior: Clip.hardEdge,
            child: FractionallySizedBox(
              widthFactor: (score / 100).clamp(0.05, 1.0),
              alignment:
                  alignRight ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color.withValues(alpha: isWinner ? 0.8 : 0.4),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (!alignRight) ...[
          const SizedBox(width: 6),
          Text(
            '${score.toInt()}%',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWinner ? color : AppTheme.textMuted,
            ),
          ),
        ],
        if (isWinner) ...[
          const SizedBox(width: 4),
          const Text('👑', style: TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}

class _ConfettiParticle {
  double x, y, size, speed, rotation;
  Color color;
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.rotation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + progress * p.speed * 3) % 1.5 - 0.2;
      final x = p.x + sin(progress * pi * 2 + p.rotation) * 0.05;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(progress * p.rotation * 0.1);

      final paint = Paint()..color = p.color.withValues(alpha: 0.7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
