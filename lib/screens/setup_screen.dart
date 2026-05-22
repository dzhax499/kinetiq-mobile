import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _player1Controller = TextEditingController(text: 'Player 1');
  final _player2Controller = TextEditingController(text: 'Player 2');
  int _totalRounds = 5;
  PoseCategory _category = PoseCategory.campur;
  Difficulty _difficulty = Difficulty.sedang;

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    final config = GameConfig(
      totalRounds: _totalRounds,
      category: _category,
      difficulty: _difficulty,
      player1Name: _player1Controller.text.trim().isEmpty
          ? 'Player 1'
          : _player1Controller.text.trim(),
      player2Name: _player2Controller.text.trim().isEmpty
          ? 'Player 2'
          : _player2Controller.text.trim(),
    );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GameScreen(config: config),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppTheme.textPrimary,
                    ),
                    const Expanded(
                      child: Text(
                        'SETUP GAME',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // === Player Names ===
                      _buildSectionTitle('👥 Nama Pemain'),
                      const SizedBox(height: 12),
                      _buildPlayerInput(
                        controller: _player1Controller,
                        label: 'Player 1',
                        color: AppTheme.primaryCyan,
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildPlayerInput(
                        controller: _player2Controller,
                        label: 'Player 2',
                        color: AppTheme.secondaryPink,
                        icon: Icons.person_rounded,
                      ),

                      const SizedBox(height: 28),

                      // === Rounds ===
                      _buildSectionTitle('🔄 Jumlah Ronde'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: AppTheme.glassDecoration(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_totalRounds Ronde',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryCyan,
                                  ),
                                ),
                                Row(
                                  children: [3, 5, 7].map((n) {
                                    final isSelected = _totalRounds == n;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _totalRounds = n),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.primaryCyan
                                                : AppTheme.bgCardLight,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.primaryCyan
                                                  : Colors.white.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$n',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? AppTheme.bgDark
                                                    : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // === Category ===
                      _buildSectionTitle('📂 Kategori Pose'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PoseCategory.values.map((cat) {
                          final isSelected = _category == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _category = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryCyan.withValues(alpha: 0.15)
                                    : AppTheme.bgCard.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryCyan
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? AppTheme.neonGlow(AppTheme.primaryCyan, blur: 8)
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    cat.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.primaryCyan
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // === Difficulty ===
                      _buildSectionTitle('⚡ Tingkat Kesulitan'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: AppTheme.glassDecoration(),
                        child: Column(
                          children: Difficulty.values.map((diff) {
                            final isSelected = _difficulty == diff;
                            return GestureDetector(
                              onTap: () => setState(() => _difficulty = diff),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryCyan.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: diff != Difficulty.sulit
                                        ? BorderSide(
                                            color: Colors.white.withValues(alpha: 0.05),
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryCyan
                                              : AppTheme.textMuted,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? AppTheme.primaryCyan
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: AppTheme.bgDark,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            diff.label,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppTheme.primaryCyan
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Mikir ${diff.thinkingSeconds}s + Pose ${diff.posingSeconds}s',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Difficulty indicator
                                    Row(
                                      children: List.generate(3, (i) {
                                        final filled = i < Difficulty.values.indexOf(diff) + 1;
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: filled
                                                ? (diff == Difficulty.mudah
                                                    ? AppTheme.accentGreen
                                                    : diff == Difficulty.sedang
                                                        ? AppTheme.accentYellow
                                                        : AppTheme.scoreLow)
                                                : AppTheme.bgCardLight,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // === Start Button ===
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.neonGlow(AppTheme.primaryCyan, blur: 12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.sports_esports_rounded, size: 24),
                      label: const Text('MULAI!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppTheme.bgDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildPlayerInput({
    required TextEditingController controller,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: AppTheme.glassDecoration(borderColor: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color, size: 22),
          hintText: label,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          filled: false,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
