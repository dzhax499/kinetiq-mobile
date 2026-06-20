import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';
import '../base_pose_screen.dart';
import '../game_engine.dart';
import '../../../core/audio/sound_manager.dart';

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
  Timer? _videoRefreshTimer;
  int _tutorialSecondsLeft = 10; // timer tetap 10 detik

  // ── Game state ───────────────────────────────────────────────────────────────
  bool _isWaiting = false;    // menunggu pemain terdeteksi (mode solo)
  bool isGameStarted = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  final Map<int, double> _lastHandYL = {};
  final Map<int, double> _lastHandYR = {};

  int _p1DestroyedCount = 0;
  int _p2DestroyedCount = 0;
  final int _totalRocksGoal = 3;

  bool get _isSolo => widget.playerCount == 1;

  @override
  void initState() {
    super.initState();
    engine.playerCount = widget.playerCount;
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
      // Countdown 10 detik, update UI tiap detik
      _videoRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _videoFinished) return;
        setState(() {
          _tutorialSecondsLeft--;
          if (_tutorialSecondsLeft <= 0) _onVideoEnd();
        });
      });
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
    _videoRefreshTimer?.cancel();
    _videoController?.pause();
    _startGame();
  }

  void _startGame() {
    SoundManager().playBgm('audio/kesatria_pcd_background_music.mp3');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRocks();
      // Tunggu hingga pemain masuk frame (berlaku untuk 1 dan 2 pemain)
      setState(() => _isWaiting = true);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _videoRefreshTimer?.cancel();
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
      // Main sendiri: 3 batu P1 di area kiri (sama seperti P1 mode duo)
      for (int i = 0; i < 3; i++) {
        _spawnRock(1, width, height, i, nextId++);
      }
    } else {
      // Main berdua: masing-masing 3 batu di area separuh layar
      for (int i = 0; i < 3; i++) {
        _spawnRock(1, width, height, i, nextId++);
        _spawnRock(2, width, height, i, nextId++);
      }
    }
  }

  /// Spawn batu untuk tiap pemain di areanya
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
    // Saat waiting: cek apakah pemain yang dibutuhkan sudah terdeteksi
    if (_isWaiting) {
      bool ready = _isSolo ? poses.isNotEmpty : poses.length >= 2;
      if (ready) {
        setState(() => _isWaiting = false);
        _startCountdown();
        _showTooltips();
      }
      return;
    }

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
    // Tooltip dihilangkan sesuai permintaan
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget buildGameUI(BuildContext context) {
    // 1. Video tutorial
    if (!_videoFinished) {
      return _buildVideoOverlay();
    }

    // 2. Waiting screen (mode solo: tunggu pemain terdeteksi)
    if (_isWaiting) {
      return _buildWaitingOverlay();
    }

    // 3. Countdown
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

    // 4. Game berlangsung
    return const SizedBox.shrink();
  }

  Widget _buildWaitingOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        color: const Color(0xFF262626), // Warna abu gelap pekat tanpa radius sesuai gambar
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul WAITING...
            Text(
              'WAITING...',
              style: TextStyle(
                fontFamily: 'game_font',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE8274B),
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 6, offset: const Offset(2, 3)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Instruksi
            Text(
              'PLEASE PROP THE DEVICE UPRIGHT ON A STABLE SURFACE.\nMAKE SURE ${_isSolo ? '1 PLAYER IS' : '2 PLAYERS ARE'} STANDING IN THE FRAME.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'game_font',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Background hitam
          Container(color: Colors.black),

          // Video
          if (_videoController != null && _videoController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // ── Label "TUTORIAL" — tengah atas ──────────────────────────────────
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'TUTORIAL',
                style: TextStyle(
                  fontFamily: 'game_font',
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE8274B),
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(2, 3)),
                  ],
                ),
              ),
            ),
          ),

          // ── Timer countdown — pojok kanan atas ──────────────────────────────
          Positioned(
            top: 16,
            right: 28,
            child: Text(
              _tutorialSecondsLeft.clamp(0, 99).toString().padLeft(2, '0'),
              style: const TextStyle(
                fontFamily: 'game_font',
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
