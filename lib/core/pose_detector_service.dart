import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

/// Service wrapper for Google ML Kit Pose Detection (MediaPipe backend)
class PoseDetectorService {
  PoseDetector? _poseDetector;
  bool _isProcessing = false;

  /// Initialize the pose detector
  void initialize() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  /// Process a camera image and return detected poses
  Future<List<Pose>> processImage(CameraImage cameraImage, CameraDescription camera) async {
    if (_isProcessing || _poseDetector == null) return [];
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(cameraImage, camera);
      if (inputImage == null) return [];
      
      final poses = await _poseDetector!.processImage(inputImage);
      return poses;
    } catch (e) {
      debugPrint('PoseDetectorService error: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a static image file
  Future<List<Pose>> processImageFile(String filePath) async {
    if (_poseDetector == null) return [];

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      return await _poseDetector!.processImage(inputImage);
    } catch (e) {
      debugPrint('PoseDetectorService processImageFile error: $e');
      return [];
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      // Determine rotation
      switch (sensorOrientation) {
        case 0:
          rotation = InputImageRotation.rotation0deg;
          break;
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      // Build the input image from camera bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final imageSize = ui.Size(image.width.toDouble(), image.height.toDouble());

      InputImageFormat? inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      // Fallback for missing raw value mapping
      if (inputImageFormat == null || inputImageFormat == InputImageFormat.yuv_420_888 || inputImageFormat == InputImageFormat.nv21) {
        inputImageFormat = InputImageFormat.bgra8888;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation!,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Concatenate camera image planes into a single byte array
  Uint8List _concatenatePlanes(List<Plane> planes) {
    int totalLength = 0;
    for (final plane in planes) {
      totalLength += plane.bytes.length;
    }
    final result = Uint8List(totalLength);
    int offset = 0;
    for (final plane in planes) {
      result.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return result;
  }

  bool get isProcessing => _isProcessing;

  /// Dispose resources
  Future<void> dispose() async {
    await _poseDetector?.close();
    _poseDetector = null;
  }
}
