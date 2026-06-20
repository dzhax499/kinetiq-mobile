import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'tutorial_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double> _titleScale;
  late Animation<double> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _buttonsSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
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
              Color(0xFF1A1333),
              Color(0xFF12081F),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            _AnimatedBackground(controller: _bgController),
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXl,
                    vertical: AppSizes.paddingLg,
                  ),
                  child: AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo & Title
                          Transform.scale(
                            scale: _titleScale.value,
                            child: _buildTitle(),
                          ),
                          SizedBox(height: 50 * _entryController.value),
                          // Menu Buttons
                          Transform.translate(
                            offset: Offset(0, _buttonsSlide.value),
                            child: Opacity(
                              opacity: _entryController.value.clamp(0, 1),
                              child: _buildMenuButtons(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // Potion icon with glow
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF9B6EF3),
                Color(0xFF6C3FC5),
                Color(0xFF3E1A8A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text('⚗️', style: TextStyle(fontSize: 56)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'GAME RAMUAN',
          style: GoogleFonts.cinzel(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 15,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'PENGOLAHAN CITRA DIGITAL',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        _MenuButton(
          label: 'MULAI GAME',
          icon: Icons.play_arrow_rounded,
          color: AppColors.accent,
          onTap: () => _navigateTo(const GameScreen()),
        ),
        const SizedBox(height: 16),
        _MenuButton(
          label: 'TUTORIAL',
          icon: Icons.school_rounded,
          color: AppColors.primary,
          onTap: () => _navigateTo(const TutorialScreen()),
        ),
        const SizedBox(height: 16),
        _MenuButton(
          label: 'TENTANG',
          icon: Icons.info_outline_rounded,
          color: AppColors.info,
          onTap: () => _showAboutDialog(),
        ),
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Tentang Game',
          style: GoogleFonts.cinzel(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Game Ramuan PCD adalah game puzzle yang menggabungkan '
          'memori dan pengolahan citra digital.\n\n'
          'Hafal urutan ramuan, susun dengan benar, lalu '
          'terapkan filter PCD pada gambar secara berurutan!\n\n'
          '© 2026 KinetiQFun Team',
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _hoverController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _hoverController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _hoverController.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 280,
        height: 60,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.95 : 1.0, _isPressed ? 0.95 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.color.withValues(alpha: 0.25),
              widget.color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isPressed ? 0.3 : 0.15),
              blurRadius: _isPressed ? 20 : 10,
              spreadRadius: _isPressed ? 2 : 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.color, size: 28),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _MenuBgPainter(progress: controller.value),
        );
      },
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}

class _MenuBgPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(99);

  _MenuBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Floating orbs
    for (int i = 0; i < 6; i++) {
      final baseX = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final radius = 50.0 + _random.nextDouble() * 100;
      final phase = _random.nextDouble() * 2 * pi;

      final x = baseX + cos(progress * 2 * pi + phase) * 30;
      final y = baseY + sin(progress * 2 * pi + phase * 1.5) * 20;

      final paint = Paint()
        ..color = Color.lerp(
          AppColors.primary.withValues(alpha: 0.04),
          AppColors.accent.withValues(alpha: 0.06),
          _random.nextDouble(),
        )!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Small particles
    for (int i = 0; i < 30; i++) {
      final baseX = _random.nextDouble() * size.width;
      final speed = 0.2 + _random.nextDouble() * 0.5;

      final y = size.height -
          ((progress * speed + _random.nextDouble()) % 1.0) * size.height * 1.2;
      final x = baseX + sin(progress * 2 * pi + i) * 10;

      final opacity = ((1.0 - (y / size.height).abs()) * 0.2).clamp(0.0, 0.2);
      final particleSize = 1.0 + _random.nextDouble() * 3;

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()
          ..color = (_random.nextBool() ? AppColors.primary : AppColors.accent)
              .withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBgPainter old) => true;
}
