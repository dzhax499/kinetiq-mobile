import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  bool _isProcessing = false;

  /// Process camera image and return list of Poses
  Future<List<Pose>?> processImage(CameraImage image, int sensorOrientation, CameraLensDirection lensDirection) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image, sensorOrientation, lensDirection);
      if (inputImage == null) return null;

      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint('Error processing image for pose detection: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _poseDetector.close();
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation, CameraLensDirection lensDirection) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final bytes = image.planes[0].bytes;
    final size = Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) return null;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: imageRotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }
}
