import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../base_pose_screen.dart';
import '../game_engine.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../core/camera/pose_evaluator.dart';

class TiruGayaPage extends BasePoseScreen {
  final int playerCount;
  const TiruGayaPage({super.key, this.playerCount = 2});

  @override
  State<TiruGayaPage> createState() => _TiruGayaPageState();
}

class _TiruGayaPageState extends BasePoseScreenState<TiruGayaPage> {
  int _currentRound = 1;
  int _p1Score = 0;
  int _p2Score = 0;
  final int _totalRounds = 4;
  
  bool _isTutorialFinished = false;
  bool _isModelLoaded = false;
  bool _isWaitingForPlayers = false;
  bool _isGameStarted = false;
  bool _isFlash = false;
  
  int _roundTimer = 5;
  Timer? _timer;
  
  final List<String> _targetPoses = [
    'assets/images/posebuaya.png',
    'assets/images/poserocket.png',
    'assets/images/posekucing.png',
    'assets/images/posedino.png'
  ];
  
  final List<double> _p1SimScore = [0, 0, 0, 0, 0, 0, 0, 0];
  final List<double> _p2SimScore = [0, 0, 0, 0, 0, 0, 0, 0];
  
  int _currentTargetIndex = 0;
  String _roundStatus = "";
  bool _showSnapshot = false;

  Pose? _lastP1Pose;
  Pose? _lastP2Pose;
  
  DateTime? _lastP1DetectTime;
  DateTime? _lastP2DetectTime;
  Timer? _lobbyCheckTimer;

  VideoPlayerController? _tutorialVideoController;
  int _tutorialCountdown = 0;
  Timer? _tutorialCountdownTimer;

  ui.Image? _capturedImage;
  final Map<String, List<double>> _targetFeaturesMap = {};

  @override
  void initState() {
    super.initState();
    engine.setGameMode(GameMode.tiruGaya);
    _targetPoses.shuffle();
    
    // Pause ML Kit pose processing during tutorial to prevent lag
    canProcess = false;
    
    // Only play tutorial first — all heavy work deferred until tutorial finishes
    _playTutorial();
  }

  Future<void> _loadTargetPoses() async {
    final detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.base,
      ),
    );
    
    int loadedCount = 0;
    
    for (var assetPath in _targetPoses) {
      try {
        final byteData = await rootBundle.load(assetPath);
        final tempDir = await getTemporaryDirectory();
        final fileName = assetPath.split('/').last;
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.create(recursive: true);
        await tempFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        
        final inputImage = InputImage.fromFilePath(tempFile.path);
        final poses = await detector.processImage(inputImage);
        
        if (poses.isNotEmpty) {
          final features = PoseEvaluator.extractFeatures(poses.first);
          if (features != null) {
            _targetFeaturesMap[assetPath] = features;
          } else {
            _targetFeaturesMap[assetPath] = List.filled(8, 0.0);
          }
        } else {
          _targetFeaturesMap[assetPath] = List.filled(8, 0.0);
        }
      } catch (e) {
        debugPrint("Error loading target pose $assetPath: $e");
        _targetFeaturesMap[assetPath] = List.filled(8, 0.0);
      } finally {
        loadedCount++;
        if (loadedCount == _targetPoses.length) {
          detector.close();
          if (mounted) {
            setState(() {
              _isModelLoaded = true;
              _checkStartGame();
            });
          }
        }
      }
    }
  }

  void _playTutorial() {
    _tutorialVideoController = VideoPlayerController.asset('assets/video/tutorial_tiru_gaya.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _tutorialCountdown = _tutorialVideoController!.value.duration.inSeconds;
        });
        _tutorialVideoController!.play();
        
        _tutorialCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            if (_tutorialCountdown > 0) {
              _tutorialCountdown--;
            } else {
              timer.cancel();
            }
          });
        });
      });

    _tutorialVideoController!.addListener(() {
      if (_tutorialVideoController!.value.isInitialized &&
          !_tutorialVideoController!.value.isPlaying &&
          _tutorialVideoController!.value.duration == _tutorialVideoController!.value.position) {
        _finishTutorial();
      }
    });
  }

  void _finishTutorial() {
    if (_isTutorialFinished) return;
    _tutorialCountdownTimer?.cancel();
    
    // Fully dispose the video controller to free resources
    _tutorialVideoController?.pause();
    _tutorialVideoController?.dispose();
    _tutorialVideoController = null;
    
    setState(() {
      _isTutorialFinished = true;
    });
    
    // NOW start heavy work: resume ML Kit, BGM, and load target poses
    canProcess = true;
    SoundManager().playBgm('audio/tiru_gaya.mp3');
    _loadTargetPoses();
  }

  void _checkStartGame() {
    if (_isTutorialFinished && _isModelLoaded) {
      _startWaitingForPlayers();
    }
  }
  
  void _startWaitingForPlayers() {
    setState(() {
      _isWaitingForPlayers = true;
    });
    
    _lobbyCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      
      final now = DateTime.now();
      final p1Detected = _lastP1DetectTime != null && now.difference(_lastP1DetectTime!).inMilliseconds < 1500;
      final p2Detected = _lastP2DetectTime != null && now.difference(_lastP2DetectTime!).inMilliseconds < 1500;
      
      bool ready = widget.playerCount == 1 ? p1Detected : (p1Detected && p2Detected);
      
      if (ready) {
        timer.cancel();
        setState(() {
          _isWaitingForPlayers = false;
        });
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _currentRound = 1;
      _p1Score = 0;
      _p2Score = 0;
      _startRound();
    });
  }

  void _startRound() {
    if (!mounted) return;
    setState(() {
      _showSnapshot = false;
      _capturedImage = null;
      _roundTimer = 5;
      _isGameStarted = true;
      _roundStatus = "Round $_currentRound";
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_roundTimer > 1) {
          SoundManager().playClick();
        }
        _roundTimer--;
        if (_roundTimer <= 0) {
          timer.cancel();
          _captureAndEvaluate();
        }
      });
    });
  }
  
  void _captureAndEvaluate() async {
    if (!mounted) return;
    
    // Play capture SFX
    SoundManager().playCapture();
    
    setState(() {
      _isGameStarted = false;
      _isFlash = true;
    });

    // Capture screenshot of camera preview
    ui.Image? snapshot;
    try {
      snapshot = await cameraViewController.capture();
    } catch (e) {
      debugPrint("Failed to capture snapshot: $e");
    }

    // Evaluate features
    final targetPath = _targetPoses[_currentTargetIndex];
    final targetFeatures = _targetFeaturesMap[targetPath] ?? List.filled(8, 0.0);
    
    double p1Sim = 0.0;
    double p2Sim = 0.0;
    
    final now = DateTime.now();
    final p1Valid = _lastP1Pose != null && _lastP1DetectTime != null && now.difference(_lastP1DetectTime!).inMilliseconds < 1500;
    final p2Valid = _lastP2Pose != null && _lastP2DetectTime != null && now.difference(_lastP2DetectTime!).inMilliseconds < 1500;
    
    if (p1Valid) {
      final p1Features = PoseEvaluator.extractFeatures(_lastP1Pose!);
      if (p1Features != null) {
        p1Sim = PoseEvaluator.compareFeatures(targetFeatures, p1Features);
      }
    }
    
    if (p2Valid) {
      final p2Features = PoseEvaluator.extractFeatures(_lastP2Pose!);
      if (p2Features != null) {
        p2Sim = PoseEvaluator.compareFeatures(targetFeatures, p2Features);
      }
    }
    
    _p1SimScore[_currentRound - 1] = p1Sim;
    _p2SimScore[_currentRound - 1] = p2Sim;
    
    String status = "";
    if (widget.playerCount == 1) {
      if (p1Sim >= 60.0) { // Minimal kemiripan 60%
        _p1Score++;
        status = "GAYA MANTAP!";
      } else {
        status = "COBA LAGI!";
      }
    } else {
      if (p1Sim > p2Sim) {
        _p1Score++;
        status = "P1 LEBIH MANTAP!";
      } else if (p2Sim > p1Sim) {
        _p2Score++;
        status = "P2 LEBIH MANTAP!";
      } else {
        status = "GAYA SEIMBANG!";
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    
    setState(() {
      _isFlash = false;
      _capturedImage = snapshot;
      _showSnapshot = true;
      _roundStatus = status;
    });
    
    // Wait 5 seconds, then next round
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_currentRound < _totalRounds) {
        setState(() {
          _currentRound++;
          _currentTargetIndex = (_currentTargetIndex + 1) % _targetPoses.length;
          _startRound();
        });
      } else if (_currentRound == _totalRounds && _p1Score == _p2Score) {
        // Sudden death
        setState(() {
          _currentRound++;
          _currentTargetIndex = (_currentTargetIndex + 1) % _targetPoses.length;
          _startRound();
        });
      } else {
        _showFinalWinner();
      }
    });
  }

  void _showFinalWinner() {
    if (!mounted) return;
    
    setState(() {
      _showSnapshot = false;
    });

    final size = MediaQuery.of(context).size;
    final winnerName = _p1Score > _p2Score ? engine.nameP1 : engine.nameP2;
    engine.setWinner(winnerName, size.width, size.height);
    SoundManager().playVictory();
  }

  @override
  void onPoseDetected(List<Pose> poses, Size imageSize) {
    if (poses.isEmpty) return;
    
    final now = DateTime.now();
    for (var pose in poses) {
      if (PoseEvaluator.isLikelyHuman(pose)) {
        if (widget.playerCount == 1) {
          _lastP1Pose = pose;
          _lastP1DetectTime = now;
          break; // Cukup 1 pemain
        } else {
          final nose = pose.landmarks[PoseLandmarkType.nose];
          if (nose != null) {
            if (nose.x > (imageSize.width / 2)) {
              _lastP1Pose = pose; // P1 on left side of mirrored screen (so right side of image)
              _lastP1DetectTime = now;
            } else {
              _lastP2Pose = pose;
              _lastP2DetectTime = now;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lobbyCheckTimer?.cancel();
    _tutorialCountdownTimer?.cancel();
    _tutorialVideoController?.dispose();
    super.dispose();
  }

  @override
  Widget buildGameUI(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 1. Tutorial Overlay
    if (!_isTutorialFinished) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (_tutorialVideoController != null && _tutorialVideoController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _tutorialVideoController!.value.size.width,
                  height: _tutorialVideoController!.value.size.height,
                  child: VideoPlayer(_tutorialVideoController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.yellowAccent),
            ),
          
          // Tutorial Countdown (Top Right)
          Positioned(
            top: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _tutorialCountdown.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontFamily: 'game_font',
                  fontSize: 28,
                  color: Colors.yellowAccent,
                ),
              ),
            ),
          ),

          // Skip Button (Bottom Right)
          Positioned(
            bottom: 32,
            right: 32,
            child: ElevatedButton(
              onPressed: () {
                SoundManager().playClick();
                _finishTutorial();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'SKIP',
                style: TextStyle(fontFamily: 'game_font', fontSize: 20),
              ),
            ),
          ),
        ],
      );
    }



    // 4. Standard Game HUD
    return Stack(
      children: [
        // ROUND X/Y Top Center
        if (_isGameStarted && !_showSnapshot)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                'ROUND $_currentRound/$_totalRounds',
                style: const TextStyle(
                  fontFamily: 'game_font',
                  fontSize: 40,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          ),
          
        // Global Scores Top Corners
        Positioned(
          top: 16,
          left: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'P1: $_p1Score',
                style: const TextStyle(
                  fontFamily: 'game_font',
                  fontSize: 20,
                  color: Color(0xFFFFDD00),
                  shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                ),
              ),
              Text(
                'P1 SKOR: $_p1Score',
                style: const TextStyle(
                  fontFamily: 'game_font',
                  fontSize: 32,
                  color: Color(0xFFFFDD00),
                  shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                ),
              ),
            ],
          ),
        ),
        if (widget.playerCount == 2)
          Positioned(
            top: 16,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'P2: $_p2Score',
                  style: const TextStyle(
                    fontFamily: 'game_font',
                    fontSize: 20,
                    color: Color(0xFFFFDD00),
                    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                ),
                Text(
                  '$_p2Score :SKOR P2',
                  style: const TextStyle(
                    fontFamily: 'game_font',
                    fontSize: 32,
                    color: Color(0xFFFFDD00),
                    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                ),
              ],
            ),
          ),

        // Center Target Image
        if (_isGameStarted && !_showSnapshot && !_isWaitingForPlayers)
          Align(
            alignment: const Alignment(0, 0.4),
            child: Image.asset(
              _targetPoses[_currentTargetIndex],
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          
        // 3. Waiting for Players Lobby Overlay
        if (_isWaitingForPlayers)
          Center(
            child: Container(
              width: size.width * 0.85,
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: Colors.black.withValues(alpha: 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'WARNING...',
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'game_font',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PLEASE PROP THE DEVICE UPRIGHT ON A STABLE SURFACE.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'game_font',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.playerCount == 1 
                        ? 'MAKE SURE 1 PLAYER IS STANDING IN THE FRAME.' 
                        : 'MAKE SURE 2 PLAYERS ARE STANDING IN THE FRAME.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'game_font',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Timer Text Center
        if (_isGameStarted && !_showSnapshot)
          Center(
            child: Text(
              '$_roundTimer',
              style: const TextStyle(
                fontFamily: 'game_font',
                fontSize: 180,
                color: Color(0xFFFFDD00),
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 15, offset: Offset(5, 5)),
                ],
              ),
            ),
          ),
          
        // Flash overlay
        if (_isFlash)
          Container(color: Colors.white),
          
        // Snapshot / Round Result (Polaroid Layout)
        if (_showSnapshot)
          Stack(
            children: [
              Container(color: const Color(0x99000000)),
              
              // P1 Polaroid (Left or Center)
              Align(
                alignment: widget.playerCount == 1 ? const Alignment(0, 0.1) : const Alignment(-0.6, 0.1),
                child: Transform.rotate(
                  angle: widget.playerCount == 1 ? 0 : (-8 * 3.1415926535 / 180),
                  child: Card(
                    color: Colors.white,
                    elevation: 16,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.black,
                            child: _capturedImage != null
                                ? ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.5,
                                      child: RawImage(
                                        image: _capturedImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_p1SimScore[_currentRound - 1].toInt()}% MIRIP',
                            style: const TextStyle(
                              fontFamily: 'game_font',
                              fontSize: 28,
                              color: Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (widget.playerCount == 2)
                // P2 Polaroid (Right)
                Align(
                  alignment: const Alignment(0.6, 0.1),
                child: Transform.rotate(
                  angle: 8 * 3.1415926535 / 180,
                  child: Card(
                    color: Colors.white,
                    elevation: 16,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.black,
                            child: _capturedImage != null
                                ? ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      widthFactor: 0.5,
                                      child: RawImage(
                                        image: _capturedImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_p2SimScore[_currentRound - 1].toInt()}% MIRIP',
                            style: const TextStyle(
                              fontFamily: 'game_font',
                              fontSize: 28,
                              color: Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Winner Text
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 64),
                  child: Text(
                    _roundStatus,
                    style: TextStyle(
                      fontFamily: 'game_font',
                      fontSize: 48,
                      color: _roundStatus.contains('GAYA') ? Colors.white : const Color(0xFFFFDD00),
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 10, offset: Offset(3, 3)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
