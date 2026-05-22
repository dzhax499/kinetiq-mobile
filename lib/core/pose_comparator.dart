import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Compares detected poses against reference poses using cosine similarity
/// and angle-based comparison with normalization.
///
/// Pipeline Pengolahan Citra Digital:
/// 1. Feature Extraction (landmark coordinates)
/// 2. Normalization (translation + scale)
/// 3. Cosine Similarity (vector comparison)
/// 4. Angle Comparison (joint angles)
/// 5. Combined Score with thresholding
class PoseComparator {
  /// Key landmark types used for comparison (excluding face landmarks for simplicity)
  static const List<PoseLandmarkType> keyLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  /// Joint angle definitions: [start, middle, end]
  static const List<List<PoseLandmarkType>> jointAngles = [
    // Left arm
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    // Right arm
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Left leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    // Right leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    // Left shoulder angle
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    // Right shoulder angle
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    // Left hip angle
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    // Right hip angle
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  ];

  /// Normalize pose landmarks:
  /// 1. Translate so mid-hip is at origin (0,0)
  /// 2. Scale by torso length (shoulder-to-hip distance)
  static Map<PoseLandmarkType, List<double>> normalizeLandmarks(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
  ) {
    // Find mid-hip (center point)
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftHip == null || rightHip == null || leftShoulder == null || rightShoulder == null) {
      return {};
    }

    // Center point: mid-hip
    final centerX = (leftHip.x + rightHip.x) / 2;
    final centerY = (leftHip.y + rightHip.y) / 2;

    // Scale factor: average torso length (shoulder to hip)
    final leftTorso = _distance(leftShoulder.x, leftShoulder.y, leftHip.x, leftHip.y);
    final rightTorso = _distance(rightShoulder.x, rightShoulder.y, rightHip.x, rightHip.y);
    final scaleFactor = (leftTorso + rightTorso) / 2;

    if (scaleFactor < 1e-6) return {};

    final normalized = <PoseLandmarkType, List<double>>{};
    for (final type in keyLandmarks) {
      final landmark = landmarks[type];
      if (landmark != null) {
        normalized[type] = [
          (landmark.x - centerX) / scaleFactor,
          (landmark.y - centerY) / scaleFactor,
        ];
      }
    }
    return normalized;
  }

  /// Normalize from raw coordinate map (for reference poses)
  static Map<PoseLandmarkType, List<double>> normalizeFromCoords(
    Map<PoseLandmarkType, List<double>> coords,
  ) {
    final leftHip = coords[PoseLandmarkType.leftHip];
    final rightHip = coords[PoseLandmarkType.rightHip];
    final leftShoulder = coords[PoseLandmarkType.leftShoulder];
    final rightShoulder = coords[PoseLandmarkType.rightShoulder];

    if (leftHip == null || rightHip == null || leftShoulder == null || rightShoulder == null) {
      return coords;
    }

    final centerX = (leftHip[0] + rightHip[0]) / 2;
    final centerY = (leftHip[1] + rightHip[1]) / 2;

    final leftTorso = _distance(leftShoulder[0], leftShoulder[1], leftHip[0], leftHip[1]);
    final rightTorso = _distance(rightShoulder[0], rightShoulder[1], rightHip[0], rightHip[1]);
    final scaleFactor = (leftTorso + rightTorso) / 2;

    if (scaleFactor < 1e-6) return coords;

    final normalized = <PoseLandmarkType, List<double>>{};
    for (final entry in coords.entries) {
      if (keyLandmarks.contains(entry.key)) {
        normalized[entry.key] = [
          (entry.value[0] - centerX) / scaleFactor,
          (entry.value[1] - centerY) / scaleFactor,
        ];
      }
    }
    return normalized;
  }

  /// Compare detected pose with target pose
  /// Returns a score from 0.0 to 100.0
  static double comparePoses({
    required Map<PoseLandmarkType, PoseLandmark> detectedLandmarks,
    required Map<PoseLandmarkType, List<double>> targetLandmarks,
  }) {
    // Normalize detected pose
    final normalizedDetected = normalizeLandmarks(detectedLandmarks);
    if (normalizedDetected.isEmpty) return 0.0;

    // The target is already normalized
    final normalizedTarget = targetLandmarks;

    // 1. Cosine Similarity (weight: 0.7)
    final cosineSim = _cosineSimilarity(normalizedDetected, normalizedTarget);

    // 2. Angle Similarity (weight: 0.3)
    final angleSim = _angleSimilarity(detectedLandmarks, targetLandmarks);

    // Combined score
    final rawScore = (0.7 * cosineSim + 0.3 * angleSim) * 100;
    return rawScore.clamp(0.0, 100.0);
  }

  /// Compute cosine similarity between two normalized pose vectors
  static double _cosineSimilarity(
    Map<PoseLandmarkType, List<double>> a,
    Map<PoseLandmarkType, List<double>> b,
  ) {
    // Find common landmarks
    final commonKeys = a.keys.where((k) => b.containsKey(k)).toList();
    if (commonKeys.isEmpty) return 0.0;

    // Flatten to vectors
    final vecA = <double>[];
    final vecB = <double>[];
    for (final key in commonKeys) {
      vecA.addAll(a[key]!);
      vecB.addAll(b[key]!);
    }

    // Compute cosine similarity
    double dotProduct = 0;
    double magnitudeA = 0;
    double magnitudeB = 0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      magnitudeA += vecA[i] * vecA[i];
      magnitudeB += vecB[i] * vecB[i];
    }

    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);

    if (magnitudeA < 1e-6 || magnitudeB < 1e-6) return 0.0;

    // Cosine similarity is [-1, 1], map to [0, 1]
    final similarity = dotProduct / (magnitudeA * magnitudeB);
    return ((similarity + 1) / 2).clamp(0.0, 1.0);
  }

  /// Compute angle-based similarity
  static double _angleSimilarity(
    Map<PoseLandmarkType, PoseLandmark> detected,
    Map<PoseLandmarkType, List<double>> target,
  ) {
    int validAngles = 0;
    double totalSimilarity = 0;

    for (final angleDef in jointAngles) {
      final dA = detected[angleDef[0]];
      final dB = detected[angleDef[1]];
      final dC = detected[angleDef[2]];

      final tA = target[angleDef[0]];
      final tB = target[angleDef[1]];
      final tC = target[angleDef[2]];

      if (dA == null || dB == null || dC == null || tA == null || tB == null || tC == null) {
        continue;
      }

      final detectedAngle = _calculateAngle(dA.x, dA.y, dB.x, dB.y, dC.x, dC.y);
      final targetAngle = _calculateAngle(tA[0], tA[1], tB[0], tB[1], tC[0], tC[1]);

      // Angle difference, max 180 degrees
      final diff = (detectedAngle - targetAngle).abs();
      final normalizedDiff = diff > 180 ? 360 - diff : diff;

      // Convert to similarity: 0° diff = 1.0, 180° diff = 0.0
      final similarity = 1.0 - (normalizedDiff / 180.0);
      totalSimilarity += similarity;
      validAngles++;
    }

    if (validAngles == 0) return 0.0;
    return totalSimilarity / validAngles;
  }

  /// Calculate angle at point B formed by points A-B-C (in degrees)
  static double _calculateAngle(
    double ax, double ay,
    double bx, double by,
    double cx, double cy,
  ) {
    final ba = [ax - bx, ay - by];
    final bc = [cx - bx, cy - by];

    final dot = ba[0] * bc[0] + ba[1] * bc[1];
    final magBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
    final magBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);

    if (magBA < 1e-6 || magBC < 1e-6) return 0;

    final cosAngle = (dot / (magBA * magBC)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// Euclidean distance between two points
  static double _distance(double x1, double y1, double x2, double y2) {
    return sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
  }
}
