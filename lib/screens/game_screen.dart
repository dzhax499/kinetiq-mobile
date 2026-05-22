import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../core/game_engine.dart';
import '../core/pose_comparator.dart';
import '../core/pose_detector_service.dart';
import '../core/image_processor.dart';
import '../data/pose_library.dart';
import '../models/game_config.dart';
import '../models/pose_challenge.dart';
import '../theme/app_theme.dart';
import '../widgets/game_widgets.dart';
import '../widgets/pose_painter.dart';
import 'round_result_screen.dart';
import 'final_result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;

  const GameScreen({super.key, required this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  // Pose detection
  final PoseDetectorService _poseService = PoseDetectorService();
  List<Pose> _currentPoses = [];
  Size _imageSize = const Size(480, 640);
  bool _isProcessingCameraImage = false;

  // Game engine
  final GameEngine _gameEngine = GameEngine();
  List<PoseChallenge> _challenges = [];

  // Capture
  bool _showFlash = false;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  // Loading state
  bool _isLoading = true;
  String _loadingMessage = 'Mempersiapkan kamera...';

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _gameEngine.initializeGame(widget.config);
    _gameEngine.addListener(_onGameStateChanged);
    _gameEngine.onCaptureTrigger = _handleCapture;

    _challenges = PoseLibrary.getGameChallenges(
      widget.config.category,
      widget.config.totalRounds,
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _loadingMessage = 'Tidak ada kamera yang tersedia';
        });
        return;
      }

      // Use front camera
      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      // Initialize pose detector
      _poseService.initialize();

      // Start image stream for pose detection
      _isProcessingCameraImage = false;
      await _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isLoading = false;
        });

        // Start first round
        _startNextRound();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = 'Error: $e';
        });
      }
    }
  }

  void _processCameraImage(CameraImage image) {
    if (!mounted || _isProcessingCameraImage) return;
    _isProcessingCameraImage = true;
    _processCameraImageAsync(image);
  }

  Future<void> _processCameraImageAsync(CameraImage image) async {
    try {
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      final poses = await _poseService.processImage(image, camera);
      
      if (mounted) {
        setState(() {
          _currentPoses = poses;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isProcessingCameraImage = false;
    }
  }

  void _startNextRound() {
    if (_gameEngine.currentRound < _challenges.length) {
      _gameEngine.startRound(_challenges[_gameEngine.currentRound]);
    }
  }

  void _onGameStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    // Show flash effect
    setState(() => _showFlash = true);
    _flashController.forward().then((_) {
      _flashController.reverse().then((_) {
        if (mounted) setState(() => _showFlash = false);
      });
    });

    try {
      // Stop image stream temporarily
      await _cameraController!.stopImageStream();

      // Take picture
      final xFile = await _cameraController!.takePicture();
      final imageBytes = await xFile.readAsBytes();

      // Skip heavy Dart image processing (grayscale/blur/otsu) which causes OOM on high-res photos
      // Just use the raw image for both captured and processed display
      final processedBytes = imageBytes;

      // Calculate score
      double score = 0;
      final challenge = _gameEngine.currentChallenge;
      if (challenge != null && _currentPoses.isNotEmpty) {
        final landmarks = _currentPoses.first.landmarks;
        score = PoseComparator.comparePoses(
          detectedLandmarks: landmarks,
          targetLandmarks: challenge.targetLandmarks,
        );
      }

      // Submit score
      _gameEngine.submitPlayerScore(
        score,
        capturedImage: imageBytes,
        processedImage: processedBytes,
      );

      // Restart image stream if game continues
      if (_gameEngine.state != GameState.showingRoundResult &&
          _gameEngine.state != GameState.showingFinalResult) {
        _isProcessingCameraImage = false;
        await _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      _gameEngine.submitPlayerScore(0);
    }

    // Navigate based on state
    if (_gameEngine.state == GameState.showingRoundResult) {
      _navigateToRoundResult();
    }
  }

  void _navigateToRoundResult() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RoundResultScreen(
          gameEngine: _gameEngine,
          onContinue: () async {
            Navigator.pop(context);
            if (_gameEngine.isLastRound) {
              _gameEngine.proceedAfterRoundResult();
              _navigateToFinalResult();
            } else {
              _gameEngine.proceedAfterRoundResult();
              // Restart camera stream
              if (_cameraController != null) {
                try {
                  _isProcessingCameraImage = false;
                  await _cameraController!.startImageStream(_processCameraImage);
                } catch (_) {}
              }
              _startNextRound();
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToFinalResult() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FinalResultScreen(gameEngine: _gameEngine),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _gameEngine.removeListener(_onGameStateChanged);
    _gameEngine.dispose();
    _cameraController?.dispose();
    _poseService.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryCyan),
                const SizedBox(height: 24),
                Text(
                  _loadingMessage,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // === Top Bar: Round info + Player indicator ===
              _buildTopBar(),

              // === Reference Pose Card ===
              if (_gameEngine.currentChallenge != null) _buildReferenceSection(),

              // === Camera Preview with Skeleton Overlay ===
              Expanded(child: _buildCameraSection()),

              // === Bottom: Timer ===
              if (_gameEngine.state == GameState.thinkingTime ||
                  _gameEngine.state == GameState.posingTime)
                _buildTimerSection(),

              if (_gameEngine.state == GameState.capturing)
                _buildCapturingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Round indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              'Ronde ${_gameEngine.currentRound}/${_gameEngine.totalRounds}',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          // Current player indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: (_gameEngine.isPlayer1Turn
                      ? AppTheme.primaryCyan
                      : AppTheme.secondaryPink)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _gameEngine.isPlayer1Turn
                    ? AppTheme.primaryCyan
                    : AppTheme.secondaryPink,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: _gameEngine.isPlayer1Turn
                      ? AppTheme.primaryCyan
                      : AppTheme.secondaryPink,
                ),
                const SizedBox(width: 6),
                Text(
                  _gameEngine.currentPlayerName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _gameEngine.isPlayer1Turn
                        ? AppTheme.primaryCyan
                        : AppTheme.secondaryPink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceSection() {
    final challenge = _gameEngine.currentChallenge!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ReferenceCard(
        poseName: challenge.name,
        description: challenge.description,
        targetLandmarks: challenge.targetLandmarks,
        compact: true,
      ),
    );
  }

  Widget _buildCameraSection() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(),
        child: const Center(
          child: Text(
            'Kamera tidak tersedia',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: (_gameEngine.isPlayer1Turn
                  ? AppTheme.primaryCyan
                  : AppTheme.secondaryPink)
              .withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: AppTheme.neonGlow(
          _gameEngine.isPlayer1Turn
              ? AppTheme.primaryCyan
              : AppTheme.secondaryPink,
          blur: 10,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double scale = 1.0;
          if (_cameraController != null && _cameraController!.value.isInitialized) {
            double actualRatio = _cameraController!.value.aspectRatio;
            if (MediaQuery.of(context).orientation == Orientation.portrait && actualRatio > 1.0) {
               actualRatio = 1.0 / actualRatio;
            }
            final double containerRatio = constraints.maxWidth / constraints.maxHeight;
            if (actualRatio > containerRatio) {
              scale = actualRatio / containerRatio;
            } else {
              scale = containerRatio / actualRatio;
            }
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera and Skeleton scaled to cover
              Transform.scale(
                scale: scale,
                child: Center(
                  child: Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      if (_currentPoses.isNotEmpty)
                        Positioned.fill(
                          child: Builder(
                            builder: (context) {
                              InputImageRotation rotation = InputImageRotation.rotation270deg;
                              final sensorOrientation = _cameraController!.description.sensorOrientation;
                              if (sensorOrientation == 90) rotation = InputImageRotation.rotation90deg;
                              else if (sensorOrientation == 0) rotation = InputImageRotation.rotation0deg;
                              else if (sensorOrientation == 180) rotation = InputImageRotation.rotation180deg;

                              return CustomPaint(
                                painter: PosePainter(
                                  poses: _currentPoses,
                                  imageSize: _imageSize,
                                  rotation: rotation,
                                  isFrontCamera: _cameraController!.description.lensDirection == CameraLensDirection.front,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Flash effect
          if (_showFlash)
            AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.white.withValues(alpha: _flashAnimation.value * 0.8),
                );
              },
            ),

          // "Showing Reference" overlay
          if (_gameEngine.state == GameState.showingReference)
            Container(
              color: AppTheme.bgDark.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      size: 48,
                      color: AppTheme.primaryCyan.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Perhatikan pose di atas!',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giliran: ${_gameEngine.currentPlayerName}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: _gameEngine.isPlayer1Turn
                            ? AppTheme.primaryCyan
                            : AppTheme.secondaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CountdownWidget(
        seconds: _gameEngine.remainingSeconds,
        isThinking: _gameEngine.isThinkingPhase,
      ),
    );
  }

  Widget _buildCapturingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryPink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.secondaryPink.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded,
                    color: AppTheme.secondaryPink, size: 24),
                SizedBox(width: 10),
                Text(
                  '📸 CKREK!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondaryPink,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
