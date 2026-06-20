import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_detection_service.dart';
import '../utils/constants.dart';

class CameraOverlay extends StatefulWidget {
  final Widget child;
  final Function(Offset cursorPosition, bool isHolding) onCursorUpdate;
  final bool isActive;

  const CameraOverlay({
    super.key,
    required this.child,
    required this.onCursorUpdate,
    this.isActive = true,
  });

  @override
  State<CameraOverlay> createState() => _CameraOverlayState();
}

class _CameraOverlayState extends State<CameraOverlay> {
  CameraController? _cameraController;
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isCameraInitialized = false;

  // Hand tracking state
  Offset _cursorPosition = const Offset(-100, -100);
  Offset _smoothedCursor = const Offset(-100, -100);
  DateTime? _holdStartTime;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (!_isCameraInitialized) {
        _initializeCamera();
      } else {
        _cameraController?.resumePreview();
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _cameraController?.pausePreview();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Use low res for faster ML processing
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      _cameraController!.startImageStream((image) {
        if (!widget.isActive) return;
        _processCameraImage(image, frontCamera.sensorOrientation, frontCamera.lensDirection);
      });
    } catch (e) {
      debugPrint('Failed to initialize camera: $e');
    }
  }

  Future<void> _processCameraImage(
      CameraImage image, int sensorOrientation, CameraLensDirection lensDirection) async {
    final poses = await _poseService.processImage(image, sensorOrientation, lensDirection);
    
    if (poses != null && poses.isNotEmpty) {
      final pose = poses.first;
      // Prefer right wrist, fallback to left wrist
      var wrist = pose.landmarks[PoseLandmarkType.rightWrist];
      if (wrist == null || wrist.likelihood < 0.5) {
        wrist = pose.landmarks[PoseLandmarkType.leftWrist];
      }

      if (wrist != null && wrist.likelihood > 0.5) {
        if (!mounted) return;
        // Map camera coordinates to screen coordinates
        final screenSize = MediaQuery.of(context).size;
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());
        
        // Handle rotation and mirroring
        double x = wrist.x;
        double y = wrist.y;
        
        // Android front camera usually requires mirroring X
        if (Platform.isAndroid && lensDirection == CameraLensDirection.front) {
          x = imageSize.width - x;
        }

        // Map to screen
        final mappedX = (x / imageSize.width) * screenSize.width;
        final mappedY = (y / imageSize.height) * screenSize.height;

        final newPos = Offset(mappedX, mappedY);

        // Smoothing (Exponential Moving Average)
        if (_smoothedCursor.dx < 0) {
          _smoothedCursor = newPos;
        } else {
          _smoothedCursor = Offset(
            _smoothedCursor.dx * 0.7 + newPos.dx * 0.3,
            _smoothedCursor.dy * 0.7 + newPos.dy * 0.3,
          );
        }

        _checkHoldingState(_smoothedCursor);

        if (mounted) {
          setState(() {
            _cursorPosition = _smoothedCursor;
          });
          widget.onCursorUpdate(_cursorPosition, _isHolding);
        }
      }
    }
  }

  void _checkHoldingState(Offset currentPos) {
    if (_holdStartTime == null) {
      _holdStartTime = DateTime.now();
      _isHolding = false;
      return;
    }

    // If movement is very small, consider it holding
    final distance = (currentPos - _cursorPosition).distance;
    if (distance < 15) {
      final heldDuration = DateTime.now().difference(_holdStartTime!);
      if (heldDuration.inMilliseconds > 1200) {
        _isHolding = true;
      }
    } else {
      // Reset if moved significantly
      _holdStartTime = DateTime.now();
      _isHolding = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main game content
        widget.child,

        // Small camera preview in corner (optional for player reference)
        if (widget.isActive && _isCameraInitialized)
          Positioned(
            right: 16,
            bottom: 16,
            width: 100,
            height: 133,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: 0.3,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),

        // Virtual Hand Cursor
        if (widget.isActive && _cursorPosition.dx >= 0)
          Positioned(
            left: _cursorPosition.dx - 24,
            top: _cursorPosition.dy - 24,
            child: _buildCursor(),
          ),
      ],
    );
  }

  Widget _buildCursor() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _isHolding 
            ? AppColors.success.withValues(alpha: 0.5) 
            : AppColors.accent.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: _isHolding ? AppColors.success : AppColors.accent,
          width: _isHolding ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isHolding ? AppColors.success : AppColors.accent)
                .withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: AnimatedScale(
          scale: _isHolding ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isHolding ? Icons.touch_app : Icons.pan_tool_alt_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
