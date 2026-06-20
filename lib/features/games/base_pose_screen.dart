import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/camera/camera_view.dart';
import 'overlay_painter.dart';
import 'game_engine.dart';

abstract class BasePoseScreen extends StatefulWidget {
  const BasePoseScreen({super.key});
}

abstract class BasePoseScreenState<T extends BasePoseScreen> extends State<T> with TickerProviderStateMixin {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base, // Natively supports multi-pose
    ),
  );
  
  /// Subclasses can set this to false to pause ML Kit pose processing
  /// (e.g. during a tutorial video to avoid lag).
  bool canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  final CameraViewController cameraViewController = CameraViewController();
  
  late final GameEngine engine;
  late final AnimationController _tickerController;

  @override
  void initState() {
    super.initState();
    engine = GameEngine();
    _tickerController = AnimationController(vsync: this, duration: const Duration(days: 365))
      ..addListener(() {
        engine.tick();
      })
      ..forward();
  }

  @override
  void dispose() async {
    canProcess = false;
    _tickerController.dispose();
    engine.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showQuitDialog(context);
        if (shouldPop == true) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            CameraView(
              customPaint: _customPaint,
              onImage: _processImage,
              initialDirection: CameraLensDirection.front,
              controller: cameraViewController,
            ),
            buildGameUI(context),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showQuitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          color: Colors.black.withValues(alpha: 0.95),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QUIT GAME',
                style: TextStyle(
                  color: Color(0xFFFF4444),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'game_font',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ARE YOU SURE YOU WANT TO QUIT THIS GAME?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'game_font',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('NO', style: TextStyle(color: Colors.white, fontFamily: 'game_font', fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4444),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('YES', style: TextStyle(color: Colors.white, fontFamily: 'game_font', fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGameUI(BuildContext context) {
    return const SizedBox.shrink();
  }

  void onPoseDetected(List<Pose> poses, Size imageSize) {}

  Future<void> _processImage(InputImage inputImage) async {
    if (!canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    
    final poses = await _poseDetector.processImage(inputImage);
    
    if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
      engine.updatePoses(poses, inputImage.metadata!.size);

      final painter = OverlayPainter(
        engine,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        CameraLensDirection.front,
      );
      
      _customPaint = CustomPaint(painter: painter);
      
      onPoseDetected(poses, inputImage.metadata!.size);
    } else {
      _customPaint = null;
    }
    
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
