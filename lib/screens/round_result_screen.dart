import 'package:flutter/material.dart';
import '../core/game_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';

class RoundResultScreen extends StatefulWidget {
  final GameEngine gameEngine;
  final VoidCallback onContinue;

  const RoundResultScreen({
    super.key,
    required this.gameEngine,
    required this.onContinue,
  });

  @override
  State<RoundResultScreen> createState() => _RoundResultScreenState();
}

class _RoundResultScreenState extends State<RoundResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ge = widget.gameEngine;
    final p1Score = ge.player1RoundScore ?? 0;
    final p2Score = ge.player2RoundScore ?? 0;
    final winner = ge.getRoundWinner();
    final challenge = ge.currentChallenge;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _entryController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Round header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentPurple.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'RONDE ${ge.currentRound} SELESAI',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentPurple,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Challenge name
                  if (challenge != null) ...[
                    Text(
                      'Pose: ${challenge.name}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // === Score Comparison ===
                  Expanded(
                    child: Row(
                      children: [
                        // Player 1
                        Expanded(
                          child: _buildPlayerResult(
                            name: ge.player1.name,
                            score: p1Score,
                            color: AppTheme.primaryCyan,
                            isWinner: p1Score > p2Score,
                            capturedImage: ge.player1.capturedImages.isNotEmpty
                                ? ge.player1.capturedImages.last
                                : null,
                            processedImage: ge.player1.processedImages.isNotEmpty
                                ? ge.player1.processedImages.last
                                : null,
                          ),
                        ),

                        // VS divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.bgCard,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'VS',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Player 2
                        Expanded(
                          child: _buildPlayerResult(
                            name: ge.player2.name,
                            score: p2Score,
                            color: AppTheme.secondaryPink,
                            isWinner: p2Score > p1Score,
                            capturedImage: ge.player2.capturedImages.isNotEmpty
                                ? ge.player2.capturedImages.last
                                : null,
                            processedImage: ge.player2.processedImages.isNotEmpty
                                ? ge.player2.processedImages.last
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Winner announcement
                  if (winner != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: winner == 'Seri!'
                            ? null
                            : (p1Score > p2Score
                                ? const LinearGradient(
                                    colors: [Color(0xFF00F5FF), Color(0xFF8B5CF6)])
                                : const LinearGradient(
                                    colors: [Color(0xFFFF006E), Color(0xFFFF6D00)])),
                        color: winner == 'Seri!' ? AppTheme.bgCardLight : null,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: winner != 'Seri!'
                            ? AppTheme.neonGlow(
                                p1Score > p2Score
                                    ? AppTheme.primaryCyan
                                    : AppTheme.secondaryPink,
                                blur: 15,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            winner == 'Seri!'
                                ? Icons.handshake_rounded
                                : Icons.emoji_events_rounded,
                            color: winner == 'Seri!' ? AppTheme.textMuted : AppTheme.bgDark,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            winner == 'Seri!' ? 'SERI!' : '🏆 $winner MENANG!',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: winner == 'Seri!'
                                  ? AppTheme.textMuted
                                  : AppTheme.bgDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Continue button
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
                        onPressed: widget.onContinue,
                        icon: Icon(
                          ge.isLastRound
                              ? Icons.emoji_events_rounded
                              : Icons.arrow_forward_rounded,
                          size: 24,
                        ),
                        label: Text(
                          ge.isLastRound ? 'LIHAT HASIL AKHIR' : 'RONDE BERIKUTNYA',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppTheme.bgDark,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerResult({
    required String name,
    required double score,
    required Color color,
    required bool isWinner,
    dynamic capturedImage,
    dynamic processedImage,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player name
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Winner badge
        if (isWinner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.5),
              ),
            ),
            child: const Text(
              '👑 WINNER',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentGreen,
                letterSpacing: 1,
              ),
            ),
          ),

        // Captured image preview
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.bgCardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWinner ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
              width: isWinner ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: capturedImage != null
              ? Image.memory(capturedImage, fit: BoxFit.cover)
              : const Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.textMuted,
                    size: 32,
                  ),
                ),
        ),

        const SizedBox(height: 8),

        // Thresholded image preview
        if (processedImage != null) ...[
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.memory(processedImage, fit: BoxFit.cover),
          ),
          const SizedBox(height: 4),
          Text(
            'Thresholded',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Score gauge
        ScoreGauge(
          score: score,
          size: 110,
          color: color,
        ),
      ],
    );
  }
}
