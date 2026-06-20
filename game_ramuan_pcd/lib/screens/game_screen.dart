import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/potion.dart';
import '../models/pcd_filter.dart';
import '../utils/constants.dart';
import '../widgets/potion_card.dart';
import '../widgets/filter_button.dart';
import '../widgets/image_preview.dart';
import '../widgets/particle_effect.dart';
import '../widgets/camera_overlay.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gameState;
  Timer? _timer;

  // Arrange phase state
  List<Potion> _shuffledPotions = [];
  int? _selectedSwapIndex;
  List<bool> _revealedPositions = [];

  // Filter phase state
  List<PCDFilter> _availableFilters = [];
  List<PCDFilter> _selectedFilters = [];

  // Animation controllers
  late AnimationController _phaseTransitionController;
  late AnimationController _timerPulseController;
  late Animation<double> _phaseTransitionAnimation;

  // Feedback
  bool _showCorrectFeedback = false;
  bool _showWrongFeedback = false;
  bool _showParticles = false;

  // Countdown before game
  int _countdown = 3;
  bool _showCountdown = true;

  // ML Kit Virtual Cursor
  List<GlobalKey> _potionKeys = [];
  List<GlobalKey> _filterKeys = [];
  final GlobalKey _submitButtonKey = GlobalKey();
  bool _wasHolding = false;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();

    _phaseTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _phaseTransitionAnimation = CurvedAnimation(
      parent: _phaseTransitionController,
      curve: Curves.easeOutCubic,
    );

    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 3;
    _showCountdown = true;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _showCountdown = false;
          _gameState.startGame();
          _startMemorizePhase();
        }
      });
    });
  }

  void _startMemorizePhase() {
    _phaseTransitionController.forward(from: 0);
    _gameState.setPhase(GamePhase.memorize);

    final level = _gameState.currentLevel;
    final totalMs = level.memorizeTime.inMilliseconds;
    _gameState.setTimeRemaining(totalMs / 1000.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _gameState.timeRemaining - 0.05;
      if (remaining <= 0) {
        timer.cancel();
        _startArrangePhase();
      } else {
        _gameState.setTimeRemaining(remaining);
        // Pulse when time is low
        if (remaining <= 2 && !_timerPulseController.isAnimating) {
          _timerPulseController.repeat(reverse: true);
        }
        setState(() {});
      }
    });
  }

  void _startArrangePhase() {
    _timerPulseController.stop();
    _phaseTransitionController.forward(from: 0);
    _gameState.setPhase(GamePhase.arrange);

    _shuffledPotions = List<Potion>.from(_gameState.currentLevel.potionSequence);
    do {
      _shuffledPotions.shuffle();
    } while (_listEquals(_shuffledPotions, _gameState.currentLevel.potionSequence));

    _potionKeys = List.generate(_shuffledPotions.length, (_) => GlobalKey());
    _selectedSwapIndex = null;
    _revealedPositions =
        List<bool>.filled(_shuffledPotions.length, false);

    final totalMs = _gameState.currentLevel.arrangeTimeLimit.inMilliseconds;
    _gameState.setTimeRemaining(totalMs / 1000.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _gameState.timeRemaining - 0.05;
      if (remaining <= 0) {
        timer.cancel();
        _checkArrangement(timedOut: true);
      } else {
        _gameState.setTimeRemaining(remaining);
        if (remaining <= 5 && !_timerPulseController.isAnimating) {
          _timerPulseController.repeat(reverse: true);
        }
        setState(() {});
      }
    });
  }

  void _onPotionTap(int index) {
    if (_gameState.phase != GamePhase.arrange) return;

    setState(() {
      if (_selectedSwapIndex == null) {
        _selectedSwapIndex = index;
      } else if (_selectedSwapIndex == index) {
        _selectedSwapIndex = null;
      } else {
        // Swap
        final temp = _shuffledPotions[_selectedSwapIndex!];
        _shuffledPotions[_selectedSwapIndex!] = _shuffledPotions[index];
        _shuffledPotions[index] = temp;
        _selectedSwapIndex = null;

        // Auto check after swap
        _gameState.setPlayerArrangement(_shuffledPotions);
        if (_gameState.checkArrangement()) {
          _checkArrangement();
        }
      }
    });
  }

  void _checkArrangement({bool timedOut = false}) {
    _timer?.cancel();
    _timerPulseController.stop();

    _gameState.setPlayerArrangement(_shuffledPotions);
    final isCorrect = _gameState.checkArrangement();

    // Show position feedback
    _revealedPositions = List.generate(
      _shuffledPotions.length,
      (i) => true,
    );

    setState(() {
      if (isCorrect) {
        _showCorrectFeedback = true;
        _showParticles = true;
      } else {
        _showWrongFeedback = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _showCorrectFeedback = false;
        _showWrongFeedback = false;
        _showParticles = false;
      });

      if (isCorrect || timedOut) {
        _startFilterPhase();
      } else {
        _startFilterPhase();
      }
    });
  }

  void _startFilterPhase() {
    _phaseTransitionController.forward(from: 0);
    _gameState.setPhase(GamePhase.filter);

    // Prepare available filters (correct + distractors)
    final correct = _gameState.currentLevel.correctFilterSequence;
    final allFilters = List<PCDFilter>.from(PCDFilter.allFilters);
    allFilters.shuffle();

    _availableFilters = [...correct];
    // Add some distractors
    for (final f in allFilters) {
      if (!_availableFilters.any((af) => af.id == f.id)) {
        _availableFilters.add(f);
        if (_availableFilters.length >= correct.length + 3) break;
      }
    }
    _availableFilters.shuffle();
    _filterKeys = List.generate(_availableFilters.length, (_) => GlobalKey());
    _selectedFilters = [];

    final totalMs = _gameState.currentLevel.filterTimeLimit.inMilliseconds;
    _gameState.setTimeRemaining(totalMs / 1000.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _gameState.timeRemaining - 0.05;
      if (remaining <= 0) {
        timer.cancel();
        _checkFilters(timedOut: true);
      } else {
        _gameState.setTimeRemaining(remaining);
        if (remaining <= 5 && !_timerPulseController.isAnimating) {
          _timerPulseController.repeat(reverse: true);
        }
        setState(() {});
      }
    });
  }

  void _onFilterTap(PCDFilter filter) {
    if (_gameState.phase != GamePhase.filter) return;

    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else if (_selectedFilters.length <
          _gameState.currentLevel.correctFilterSequence.length) {
        _selectedFilters.add(filter);

        // Auto check if all selected
        if (_selectedFilters.length ==
            _gameState.currentLevel.correctFilterSequence.length) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _checkFilters();
          });
        }
      }
    });
  }

  void _checkFilters({bool timedOut = false}) {
    _timer?.cancel();
    _timerPulseController.stop();

    _gameState.clearFilters();
    for (final f in _selectedFilters) {
      _gameState.addFilterToSequence(f);
    }
    final isCorrect = _gameState.checkFilterSequence();

    setState(() {
      if (isCorrect) {
        _showCorrectFeedback = true;
        _showParticles = true;
      } else {
        _showWrongFeedback = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _showCorrectFeedback = false;
        _showWrongFeedback = false;
        _showParticles = false;
      });
      _showResult();
    });
  }

  void _showResult() {
    final arrangePerfect = _gameState.arrangeCorrect;
    final filterPerfect = _gameState.filterCorrect;
    final timeLeft = _gameState.timeRemaining;

    _gameState.calculateLevelScore(timeLeft, arrangePerfect, filterPerfect);

    if (!arrangePerfect || !filterPerfect) {
      final alive = _gameState.loseLife();
      if (!alive) {
        // Game over
        _navigateToResult();
        return;
      }
    }

    _gameState.setPhase(GamePhase.result);
    _phaseTransitionController.forward(from: 0);
    setState(() {});

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final hasNext = _gameState.nextLevel();
      if (hasNext) {
        _startMemorizePhase();
      } else {
        _navigateToResult();
      }
    });
  }

  void _navigateToResult() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
          totalScore: _gameState.totalScore,
          levelsCompleted: _gameState.currentLevelIndex,
          highScore: _gameState.highScore,
        ),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onCursorUpdate(Offset cursorPosition, bool isHolding) {
    if (isHolding && !_wasHolding) {
      // Trigger tap logic
      if (_gameState.phase == GamePhase.arrange) {
        for (int i = 0; i < _shuffledPotions.length; i++) {
          if (_checkCollision(_potionKeys[i], cursorPosition)) {
            _onPotionTap(i);
            break;
          }
        }
        if (_checkCollision(_submitButtonKey, cursorPosition)) {
          _checkArrangement();
        }
      } else if (_gameState.phase == GamePhase.filter) {
        for (int i = 0; i < _availableFilters.length; i++) {
          if (_checkCollision(_filterKeys[i], cursorPosition)) {
            _onFilterTap(_availableFilters[i]);
            break;
          }
        }
      }
    }
    _wasHolding = isHolding;
  }

  bool _checkCollision(GlobalKey key, Offset pos) {
    if (key.currentContext == null) return false;
    final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    final Offset localPos = box.globalToLocal(pos);
    return box.paintBounds.contains(localPos);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseTransitionController.dispose();
    _timerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraOverlay(
        isActive: !_showCountdown,
        onCursorUpdate: _onCursorUpdate,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgDarkTop,
                AppColors.bgDarkMid,
                AppColors.bgDarkBot,
              ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _showCountdown
                          ? _buildCountdownUI()
                          : _buildPhaseContent(),
                    ),
                  ],
                ),
              ),
              // Feedback overlays
              if (_showCorrectFeedback) _buildFeedbackOverlay(true),
              if (_showWrongFeedback) _buildFeedbackOverlay(false),
              // Particles
              ParticleEffect(
                isActive: _showParticles,
                type: ParticleType.confetti,
                particleCount: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => _showQuitDialog(),
          ),
          // Level info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Level ${_gameState.currentLevelIndex}',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Difficulty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _getDifficultyColor().withValues(alpha: 0.2),
            ),
            child: Text(
              _gameState.currentLevel.difficulty,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getDifficultyColor(),
              ),
            ),
          ),
          const Spacer(),
          // Lives
          Row(
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  i < _gameState.livesRemaining
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: i < _gameState.livesRemaining
                      ? AppColors.error
                      : AppColors.textMuted,
                  size: 20,
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_gameState.totalScore}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (_gameState.currentLevel.difficulty) {
      case 'Mudah':
        return AppColors.success;
      case 'Sedang':
        return AppColors.warning;
      case 'Sulit':
        return AppColors.potionOrange;
      case 'Ahli':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildCountdownUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _countdown > 0 ? '$_countdown' : 'GO!',
            style: GoogleFonts.cinzel(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: _countdown > 0 ? AppColors.accent : AppColors.success,
              shadows: [
                Shadow(
                  color: (_countdown > 0 ? AppColors.accent : AppColors.success)
                      .withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bersiap...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_gameState.phase) {
      case GamePhase.memorize:
        return _buildMemorizePhase();
      case GamePhase.arrange:
        return _buildArrangePhase();
      case GamePhase.filter:
        return _buildFilterPhase();
      case GamePhase.result:
        return _buildResultPhase();
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  // ─── MEMORIZE PHASE ──────────────────────────────────────────
  Widget _buildMemorizePhase() {
    return FadeTransition(
      opacity: _phaseTransitionAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          children: [
            _buildPhaseHeader(
              '🧠',
              'Hafalkan Urutan Ramuan!',
              'Ingat urutan bahan-bahan berikut',
            ),
            _buildTimerBar(),
            const SizedBox(height: 24),
            // Potion sequence
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    _gameState.currentLevel.potionSequence.length,
                    (index) {
                      final potion =
                          _gameState.currentLevel.potionSequence[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Order number
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: potion.color.withValues(alpha: 0.3),
                              border: Border.all(
                                color: potion.color.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: potion.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          PotionCard(
                            potion: potion,
                            isRevealed: true,
                            size: 95,
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

  // ─── ARRANGE PHASE ──────────────────────────────────────────
  Widget _buildArrangePhase() {
    return FadeTransition(
      opacity: _phaseTransitionAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          children: [
            _buildPhaseHeader(
              '🔀',
              'Susun Ulang Ramuan!',
              'Tap dua ramuan untuk menukar posisi',
            ),
            _buildTimerBar(),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    _shuffledPotions.length,
                    (index) {
                      final potion = _shuffledPotions[index];
                      final isSelected = _selectedSwapIndex == index;
                      final isCorrectPos = _revealedPositions.isNotEmpty &&
                          index < _revealedPositions.length &&
                          _revealedPositions[index] &&
                          _gameState.currentLevel.potionSequence[index].id ==
                              potion.id;
                      final isWrongPos = _revealedPositions.isNotEmpty &&
                          index < _revealedPositions.length &&
                          _revealedPositions[index] &&
                          _gameState.currentLevel.potionSequence[index].id !=
                              potion.id;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.5)
                                  : AppColors.surface,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.cardBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            key: _potionKeys[index],
                            onTap: () => _onPotionTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.diagonal3Values(isSelected ? 1.1 : 1.0, isSelected ? 1.1 : 1.0, 1.0),
                              transformAlignment: Alignment.center,
                              child: PotionCard(
                                potion: potion,
                                isRevealed: true,
                                isCorrectPosition: isCorrectPos,
                                isWrongPosition: isWrongPos,
                                isDragging: isSelected,
                                size: 95,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Submit button
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
              child: SizedBox(
                key: _submitButtonKey,
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _checkArrangement(),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    'Cek Urutan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusLg),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTER PHASE ──────────────────────────────────────────
  Widget _buildFilterPhase() {
    return FadeTransition(
      opacity: _phaseTransitionAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          children: [
            _buildPhaseHeader(
              '🖼️',
              'Terapkan Filter PCD!',
              'Pilih ${_gameState.currentLevel.correctFilterSequence.length} filter dalam urutan yang benar',
            ),
            _buildTimerBar(),
            const SizedBox(height: 16),
            // Image Preview
            ImagePreview(
              appliedFilters: _selectedFilters,
              seed: _gameState.currentLevelIndex * 7,
              width: MediaQuery.of(context).size.width - 64,
              height: 180,
            ),
            const SizedBox(height: 12),
            // Selected filters display
            if (_selectedFilters.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      'Urutan: ',
                      style: GoogleFonts.poppins(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: List.generate(_selectedFilters.length, (i) {
                          return Chip(
                            label: Text(
                              '${i + 1}. ${_selectedFilters[i].name}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: _selectedFilters[i]
                                .color
                                .withValues(alpha: 0.2),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setState(() {
                                _selectedFilters.removeAt(i);
                              });
                            },
                            side: BorderSide(
                              color: _selectedFilters[i]
                                  .color
                                  .withValues(alpha: 0.5),
                            ),
                            labelStyle: TextStyle(
                              color: _selectedFilters[i].color,
                              fontWeight: FontWeight.w500,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          );
                        }),
                      ),
                    ),
                    if (_selectedFilters.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.restart_alt, size: 20),
                        color: AppColors.textMuted,
                        onPressed: () {
                          setState(() => _selectedFilters.clear());
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Available filters
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _availableFilters.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final filter = _availableFilters[index];
                  final isSelected = _selectedFilters.contains(filter);
                  final orderNum = isSelected
                      ? _selectedFilters.indexOf(filter) + 1
                      : null;

                  return GestureDetector(
                    key: _filterKeys[index],
                    onTap: () => _onFilterTap(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.diagonal3Values(
                        isSelected ? 1.05 : 1.0, isSelected ? 1.05 : 1.0, 1.0),
                      transformAlignment: Alignment.center,
                      child: FilterButton(
                        filter: filter,
                        isSelected: isSelected,
                        orderNumber: orderNum,
                        isDisabled: !isSelected &&
                            _selectedFilters.length >=
                                _gameState.currentLevel.correctFilterSequence.length,
                        onTap: () => _onFilterTap(filter),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESULT PHASE ──────────────────────────────────────────
  Widget _buildResultPhase() {
    return FadeTransition(
      opacity: _phaseTransitionAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _gameState.arrangeCorrect && _gameState.filterCorrect
                    ? '🎉'
                    : '😅',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                _gameState.arrangeCorrect && _gameState.filterCorrect
                    ? 'Level Berhasil!'
                    : 'Belum Sempurna',
                style: GoogleFonts.cinzel(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _gameState.arrangeCorrect && _gameState.filterCorrect
                      ? AppColors.accent
                      : AppColors.warning,
                ),
              ),
              const SizedBox(height: 24),
              // Score breakdown
              _buildScoreRow(
                'Urutan Ramuan',
                _gameState.arrangeCorrect,
                _gameState.arrangeCorrect ? 500 : 0,
              ),
              const SizedBox(height: 8),
              _buildScoreRow(
                'Filter PCD',
                _gameState.filterCorrect,
                _gameState.filterCorrect ? 500 : 0,
              ),
              const SizedBox(height: 8),
              _buildScoreRow(
                'Bonus Waktu',
                true,
                (_gameState.timeRemaining * 50).toInt(),
              ),
              const Divider(color: AppColors.cardBorder, height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Skor Level: ',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${_gameState.score}',
                    style: GoogleFonts.cinzel(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              if (_gameState.streak > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '🔥 Streak x${_gameState.streak}!',
                    style: GoogleFonts.poppins(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Level berikutnya dimulai...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, bool success, int points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          success ? Icons.check_circle : Icons.cancel,
          color: success ? AppColors.success : AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '+$points',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: success ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ─── COMMON WIDGETS ──────────────────────────────────────────
  Widget _buildPhaseHeader(String emoji, String title, String subtitle) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTimerBar() {
    final totalTime = _gameState.phase == GamePhase.memorize
        ? _gameState.currentLevel.memorizeTime.inSeconds.toDouble()
        : _gameState.phase == GamePhase.arrange
            ? _gameState.currentLevel.arrangeTimeLimit.inSeconds.toDouble()
            : _gameState.currentLevel.filterTimeLimit.inSeconds.toDouble();

    final progress =
        (_gameState.timeRemaining / totalTime).clamp(0.0, 1.0);

    final isLow = _gameState.timeRemaining <= 5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '⏱️ ${_gameState.timeRemaining.toStringAsFixed(0)}s',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLow ? AppColors.error : AppColors.textSecondary,
              ),
            ),
            Text(
              _getPhaseLabel(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              isLow
                  ? AppColors.error
                  : Color.lerp(
                          AppColors.accent, AppColors.success, progress) ??
                      AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  String _getPhaseLabel() {
    switch (_gameState.phase) {
      case GamePhase.memorize:
        return 'Fase Menghafal';
      case GamePhase.arrange:
        return 'Fase Menyusun';
      case GamePhase.filter:
        return 'Fase Filter PCD';
      default:
        return '';
    }
  }

  Widget _buildFeedbackOverlay(bool isCorrect) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: isCorrect
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.error.withValues(alpha: 0.2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? 'BENAR!' : 'SALAH!',
                style: GoogleFonts.cinzel(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppColors.success : AppColors.error,
                  shadows: [
                    Shadow(
                      color: (isCorrect ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Keluar Game?',
          style: GoogleFonts.cinzel(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Progress kamu akan hilang. Yakin ingin keluar?',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tidak',
              style: GoogleFonts.poppins(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Ya, Keluar',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
