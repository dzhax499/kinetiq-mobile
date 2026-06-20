import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/particle_effect.dart';
import 'menu_screen.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  final int totalScore;
  final int levelsCompleted;
  final int highScore;

  const ResultScreen({
    super.key,
    required this.totalScore,
    required this.levelsCompleted,
    required this.highScore,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _scoreCountController;
  late AnimationController _starsController;
  late Animation<double> _entryAnimation;
  late Animation<int> _scoreAnimation;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scoreCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _scoreAnimation = IntTween(begin: 0, end: widget.totalScore).animate(
      CurvedAnimation(
        parent: _scoreCountController,
        curve: Curves.easeOutCubic,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _entryController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _scoreCountController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _showParticles = true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scoreCountController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  int get _starCount {
    if (widget.levelsCompleted >= 10) return 3;
    if (widget.levelsCompleted >= 5) return 2;
    if (widget.levelsCompleted >= 1) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0B1A),
              Color(0xFF1A0D33),
              Color(0xFF12081F),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            _AnimatedStarsBg(controller: _starsController),
            // Content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _entryAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(_entryAnimation),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingXl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Trophy
                          Text(
                            widget.levelsCompleted >= 10 ? '🏆' : '⚗️',
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            widget.levelsCompleted >= 10
                                ? 'LUAR BIASA!'
                                : 'PERMAINAN SELESAI',
                            style: GoogleFonts.cinzel(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Stars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              final filled = i < _starCount;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: AnimatedScale(
                                  scale: filled ? 1.0 : 0.7,
                                  duration: Duration(
                                      milliseconds: 300 + i * 200),
                                  child: Icon(
                                    filled ? Icons.star : Icons.star_border,
                                    color: filled
                                        ? AppColors.accent
                                        : AppColors.textMuted,
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 32),
                          // Score card
                          Container(
                            width: 280,
                            padding: const EdgeInsets.all(AppSizes.paddingLg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusLg),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'TOTAL SKOR',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedBuilder(
                                  animation: _scoreAnimation,
                                  builder: (context, _) {
                                    return Text(
                                      '${_scoreAnimation.value}',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                        shadows: [
                                          Shadow(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.5),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: AppColors.cardBorder),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  Icons.layers_rounded,
                                  'Level Selesai',
                                  '${widget.levelsCompleted} / 10',
                                ),
                                const SizedBox(height: 8),
                                _buildStatRow(
                                  Icons.emoji_events_rounded,
                                  'Skor Tertinggi',
                                  '${widget.highScore}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Buttons
                          SizedBox(
                            width: 250,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const GameScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.replay_rounded),
                              label: Text(
                                'Main Lagi',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.borderRadiusLg),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 250,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MenuScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.home_rounded, size: 20),
                              label: Text(
                                'Kembali ke Menu',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(
                                  color: AppColors.cardBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.borderRadiusLg),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Particles
            ParticleEffect(
              isActive: _showParticles,
              type: ParticleType.sparkle,
              particleCount: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}

class _AnimatedStarsBg extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedStarsBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _StarsBgPainter(progress: controller.value),
        );
      },
    );
  }
}

class _StarsBgPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(77);

  _StarsBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 40; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final twinkle =
          (sin(progress * 2 * pi + _random.nextDouble() * 2 * pi) + 1) / 2;
      final opacity = 0.1 + twinkle * 0.4;
      final starSize = 1.0 + _random.nextDouble() * 2;

      canvas.drawCircle(
        Offset(x, y),
        starSize,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsBgPainter old) => true;
}
