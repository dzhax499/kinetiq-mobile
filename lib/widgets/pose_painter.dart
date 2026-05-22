import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../theme/app_theme.dart';

/// CustomPainter that draws pose skeleton landmarks on top of camera preview.
/// Visualizes the 33 MediaPipe body landmarks with connecting lines.
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Landmark point paint
    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;

    // Connection line paint
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Define body connections
    const connections = [
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      // Left arm
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      // Right arm
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      // Left leg
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      // Right leg
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      // Face
      [PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner],
      [PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye],
      [PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter],
      [PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar],
      [PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner],
      [PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye],
      [PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter],
      [PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar],
      [PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth],
      // Left Hand
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
      [PoseLandmarkType.leftIndex, PoseLandmarkType.leftPinky],
      // Right Hand
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
      [PoseLandmarkType.rightIndex, PoseLandmarkType.rightPinky],
    ];

    for (final pose in poses) {
      // Draw connections
      for (final connection in connections) {
        final from = pose.landmarks[connection[0]];
        final to = pose.landmarks[connection[1]];
        if (from != null && to != null) {
          final avgLikelihood = (from.likelihood + to.likelihood) / 2;
          linePaint.color = _getConfidenceColor(avgLikelihood).withValues(alpha: 0.8);
          
          canvas.drawLine(
            _transformPoint(from, size),
            _transformPoint(to, size),
            linePaint,
          );
        }
      }

      // Draw landmarks
      for (final landmark in pose.landmarks.values) {
        pointPaint.color = _getConfidenceColor(landmark.likelihood);
        final point = _transformPoint(landmark, size);
        
        // Outer glow
        canvas.drawCircle(
          point,
          8,
          Paint()
            ..color = pointPaint.color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        
        // Inner solid circle
        canvas.drawCircle(point, 5, pointPaint);
        
        // White center
        canvas.drawCircle(
          point,
          2,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  /// Transform landmark coordinates to canvas coordinates
  Offset _transformPoint(PoseLandmark landmark, Size canvasSize) {
    double x = landmark.x;
    double y = landmark.y;

    // Scale to canvas size
    switch (rotation) {
      case InputImageRotation.rotation0deg:
        x = x * canvasSize.width / imageSize.width;
        y = y * canvasSize.height / imageSize.height;
        break;
      case InputImageRotation.rotation90deg:
        x = landmark.y * canvasSize.width / imageSize.height;
        y = landmark.x * canvasSize.height / imageSize.width;
        break;
      case InputImageRotation.rotation180deg:
        x = (imageSize.width - landmark.x) * canvasSize.width / imageSize.width;
        y = (imageSize.height - landmark.y) * canvasSize.height / imageSize.height;
        break;
      case InputImageRotation.rotation270deg:
        x = (imageSize.height - landmark.y) * canvasSize.width / imageSize.height;
        y = landmark.x * canvasSize.height / imageSize.width;
        break;
    }

    // Mirror for front camera
    if (isFrontCamera) {
      x = canvasSize.width - x;
    }

    return Offset(x, y);
  }

  /// Get color based on landmark confidence
  Color _getConfidenceColor(double likelihood) {
    if (likelihood > 0.8) return AppTheme.primaryCyan;
    if (likelihood > 0.5) return AppTheme.accentYellow;
    return AppTheme.scoreLow;
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
}

/// Static reference pose painter that draws a target skeleton
class ReferencePosePainter extends CustomPainter {
  final Map<PoseLandmarkType, List<double>> landmarks;
  final Color color;

  ReferencePosePainter({
    required this.landmarks,
    this.color = AppTheme.secondaryPink,
  });

  static const connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Find bounds to center the skeleton
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.height / 6; // Scale factor

    Offset toCanvas(List<double> coords) {
      return Offset(
        centerX + coords[0] * scale,
        centerY + coords[1] * scale * 0.8,
      );
    }

    // Draw connections
    for (final conn in connections) {
      final from = landmarks[conn[0]];
      final to = landmarks[conn[1]];
      if (from != null && to != null) {
        canvas.drawLine(toCanvas(from), toCanvas(to), linePaint);
      }
    }

    // Draw points
    for (final coord in landmarks.values) {
      final point = toCanvas(coord);
      canvas.drawCircle(point, 6, pointPaint);
      canvas.drawCircle(
        point,
        3,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(ReferencePosePainter oldDelegate) => false;
}
