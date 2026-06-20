import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';
import '../base_pose_screen.dart';
import '../game_engine.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../core/utils/tooltip_helper.dart';

class KesatriaPage extends BasePoseScreen {
  final int playerCount;

  const KesatriaPage({super.key, this.playerCount = 2});

  @override
  State<KesatriaPage> createState() => _KesatriaPageState();
}

class _KesatriaPageState extends BasePoseScreenState<KesatriaPage> {
  // ── Video tutorial ──────────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoFinished = false;

  // ── Game state ───────────────────────────────────────────────────────────────
  bool isGameStarted = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  final Map<int, double> _lastHandYL = {};
  final Map<int, double> _lastHandYR = {};

  int _p1DestroyedCount = 0;
  int _p2DestroyedCount = 0;
  final int _totalRocksGoal = 3;

  bool get _isSolo => widget.playerCount == 1;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    engine.setGameMode(GameMode.kesatria);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/video/tutorial_kesatriapcd.mp4');
    await _videoController!.initialize();
    _videoController!.addListener(_onVideoListener);
    if (mounted) {
      setState(() {});
      _videoController!.play();
    }
  }

  void _onVideoListener() {
    if (_videoController == null) return;
    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;
    if (!_videoFinished && dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      _onVideoEnd();
    }
  }

  void _onVideoEnd() {
    if (_videoFinished) return;
    _videoFinished = true;
    _videoController?.pause();
    _startGame();
  }

  void _startGame() {
    SoundManager().playBgm('audio/kesatria_pcd_background_music.mp3');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRocks();
      _startCountdown();
      _showTooltips();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _videoController?.removeListener(_onVideoListener);
    _videoController?.dispose();
    super.dispose();
  }

  // ── Game Logic ────────────────────────────────────────────────────────────────
  void _initRocks() {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    engine.rocks.clear();
    int nextId = 0;

    if (_isSolo) {
      // Main sendiri: 3 batu P1 tersebar di seluruh layar
      for (int i = 0; i < 3; i++) {
        _spawnRockSolo(width, height, i, nextId++);
      }
    } else {
      // Main berdua: masing-masing 3 batu di area separuh layar
      for (int i = 0; i < 3; i++) {
        _spawnRock(1, width, height, i, nextId++);
        _spawnRock(2, width, height, i, nextId++);
      }
    }
  }

  /// Spawn batu untuk mode solo — tersebar di seluruh lebar layar
  void _spawnRockSolo(double screenWidth, double screenHeight, int index, int id) {
    final rockWidth = screenWidth / 8.0;
    final rockHeight = rockWidth;

    final slotMultipliers = [0.15, 0.5, 0.85];
    final slot = slotMultipliers[index % 3];

    final x = screenWidth * slot - rockWidth / 2.0;
    final startY = screenHeight - rockHeight - 50.0;

    engine.rocks.add(Rock(
      id: id,
      ownerId: 1,
      rect: Rect.fromLTWH(x, startY, rockWidth, rockHeight),
    ));
  }

  /// Spawn batu untuk mode duo — tiap pemain di area separuh layar
  void _spawnRock(int playerId, double screenWidth, double screenHeight, int index, int id) {
    final rockWidth = screenWidth / 10.0;
    final rockHeight = rockWidth;

    final areaWidth = screenWidth / 2.0;
    final startX = playerId == 1 ? 0.0 : areaWidth;

    final slotMultipliers = [0.2, 0.5, 0.8];
    final slot = slotMultipliers[index % 3];

    final x = startX + (areaWidth * slot) - (rockWidth / 2.0);
    final startY = screenHeight - rockHeight - 50.0;

    engine.rocks.add(Rock(
      id: id,
      ownerId: playerId,
      rect: Rect.fromLTWH(x, startY, rockWidth, rockHeight),
    ));
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          isGameStarted = true;
          timer.cancel();
        }
      });
      SoundManager().playClick();
    });
  }

  @override
  void onPoseDetected(List<Pose> poses, Size imageSize) {
    if (!isGameStarted || engine.winner != null) return;

    for (var playerId in engine.targetLandmarks.keys) {
      // Mode solo: hanya proses input dari P1
      if (_isSolo && playerId != 1) continue;

      final marks = engine.targetLandmarks[playerId]!;
      final wl = marks[PoseLandmarkType.leftWrist];
      final wr = marks[PoseLandmarkType.rightWrist];

      _checkHit(playerId, wl, imageSize, true);
      _checkHit(playerId, wr, imageSize, false);
    }
  }

  void _checkHit(int playerId, Offset? wrist, Size imageSize, bool isLeft) {
    if (wrist == null) return;

    final size = MediaQuery.of(context).size;
    final screenX = size.width - (wrist.dx * size.width / imageSize.width);
    final screenY = wrist.dy * size.height / imageSize.height;

    final lastYMap = isLeft ? _lastHandYL : _lastHandYR;
    final lastY = lastYMap[playerId] ?? screenY;

    for (var rock in engine.rocks) {
      if (!rock.isDestroyed && rock.ownerId == playerId) {
        final hitZone = rock.rect.inflate(40.0);

        final velocityY = screenY - lastY;
        final isSwingingDown = velocityY > 20.0;
        final startedFromAbove = lastY < rock.rect.top + (rock.rect.height / 2.0);

        if (hitZone.contains(Offset(screenX, screenY)) && isSwingingDown && startedFromAbove) {
          rock.hits++;
          engine.onRockHit(rock.rect);
          SoundManager().playAction(pitch: 1.0 + (rock.hits * 0.1));
          rock.shakeAmount = 25.0;

          if (rock.hits >= 5) {
            rock.isDestroyed = true;
            engine.onRockDestroyed(rock.rect);
            SoundManager().playAction(pitch: 0.8);

            if (playerId == 1) { _p1DestroyedCount++; } else { _p2DestroyedCount++; }
            engine.scoreP1 = _p1DestroyedCount;
            engine.scoreP2 = _p2DestroyedCount;

            if (_p1DestroyedCount >= _totalRocksGoal) {
              engine.setWinner(engine.nameP1, size.width, size.height);
              SoundManager().playVictory();
            } else if (!_isSolo && _p2DestroyedCount >= _totalRocksGoal) {
              engine.setWinner(engine.nameP2, size.width, size.height);
              SoundManager().playVictory();
            }
          }
          break;
        }
      }
    }

    lastYMap[playerId] = screenY;
  }

  void _showTooltips() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;

    if (_isSolo) {
      // Solo: satu tooltip di tengah layar
      TooltipHelper.showAtPoint(context, 'Area Pemain', size.width * 0.5, size.height * 0.5);
    } else {
      // Duo: tooltip di masing-masing area
      TooltipHelper.showAtPoint(context, 'Area Pemain 1', size.width * 0.25, size.height * 0.5);
      TooltipHelper.showAtPoint(context, 'Area Pemain 2', size.width * 0.75, size.height * 0.5);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────────
  @override
  Widget buildGameUI(BuildContext context) {
    // 1. Tampilkan video tutorial sampai selesai/di-skip
    if (!_videoFinished) {
      return _buildVideoOverlay();
    }

    // 2. Countdown sebelum game mulai
    if (!isGameStarted) {
      return Center(
        child: Text(
          _countdown > 0 ? '$_countdown' : 'GO!',
          style: const TextStyle(
            fontFamily: 'game_font',
            fontSize: 100,
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.red, blurRadius: 10)],
          ),
        ),
      );
    }

    // 3. Game berlangsung — tidak ada UI tambahan
    return const SizedBox.shrink();
  }

  Widget _buildVideoOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: Colors.black),

          if (_videoController != null && _videoController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          Positioned(
            top: 24,
            right: 24,
            child: GestureDetector(
              onTap: _onVideoEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SKIP',
                      style: TextStyle(
                        fontFamily: 'game_font',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.skip_next, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
