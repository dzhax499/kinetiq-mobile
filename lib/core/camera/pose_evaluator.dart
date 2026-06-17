import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseEvaluator {
  /// Validates if a detected pose is likely a real human based on confidence scores
  /// and the presence of key landmarks (shoulders, hips, and facial features).
  static bool isLikelyHuman(Pose pose) {
    final landmarks = pose.landmarks.values.toList();
    if (landmarks.length < 15) return false;

    const minConfidence = 0.65;
    
    final essentialParts = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];

    for (var partType in essentialParts) {
      final landmark = pose.landmarks[partType];
      if (landmark == null || landmark.likelihood < minConfidence) {
        return false;
      }
    }

    // Check if at least one facial landmark is high confidence (to ensure facing camera)
    const faceConfidence = 0.7;
    final facialParts = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.rightEye,
    ];
    final hasGoodFace = facialParts.any((type) {
      final landmark = pose.landmarks[type];
      return landmark != null && landmark.likelihood > faceConfidence;
    });

    if (!hasGoodFace) return false;

    // Calculate average confidence for all detected landmarks
    final avgConfidence = landmarks.map((l) => l.likelihood).reduce((a, b) => a + b) / landmarks.length;
    return avgConfidence > 0.5;
  }

  /// Extracts an array of 8 normalized bone angles (in degrees) from a Pose.
  /// The angles are normalized relative to the spine angle, making it robust against tilting.
  static List<double>? extractFeatures(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];

    final le = pose.landmarks[PoseLandmarkType.leftElbow];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final re = pose.landmarks[PoseLandmarkType.rightElbow];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];

    final lk = pose.landmarks[PoseLandmarkType.leftKnee];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rk = pose.landmarks[PoseLandmarkType.rightKnee];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (ls == null || rs == null || lh == null || rh == null ||
        le == null || lw == null || re == null || rw == null ||
        lk == null || la == null || rk == null || ra == null) {
      return null;
    }

    final midShoulderX = (ls.x + rs.x) / 2.0;
    final midShoulderY = (ls.y + rs.y) / 2.0;
    final midHipX = (lh.x + rh.x) / 2.0;
    final midHipY = (lh.y + rh.y) / 2.0;

    // Calculate spine angle (Hip to Shoulder)
    final spineAngle = atan2(midShoulderY - midHipY, midShoulderX - midHipX) * 180.0 / pi;

    // Helper to get relative angle
    double getRelativeAngle(PoseLandmark start, PoseLandmark end) {
      final angle = atan2(end.y - start.y, end.x - start.x) * 180.0 / pi;
      var rel = angle - spineAngle;
      while (rel < -180.0) {
        rel += 360.0;
      }
      while (rel > 180.0) {
        rel -= 360.0;
      }
      return rel;
    }

    return [
      getRelativeAngle(ls, le), // Left Upper Arm
      getRelativeAngle(le, lw), // Left Lower Arm
      getRelativeAngle(rs, re), // Right Upper Arm
      getRelativeAngle(re, rw), // Right Lower Arm
      getRelativeAngle(lh, lk), // Left Upper Leg
      getRelativeAngle(lk, la), // Left Lower Leg
      getRelativeAngle(rh, rk), // Right Upper Leg
      getRelativeAngle(rk, ra), // Right Lower Leg
    ];
  }

  /// Compares two sets of features and returns a similarity percentage (0 to 100)
  static double compareFeatures(List<double> featuresA, List<double> featuresB) {
    if (featuresA.length != featuresB.length) return 0.0;
    double totalSimilarity = 0.0;
    
    for (int i = 0; i < featuresA.length; i++) {
      double diff = (featuresA[i] - featuresB[i]).abs();
      if (diff > 180.0) diff = 360.0 - diff;
      
      // Similarity for this bone: 0 degrees diff = 1.0, 180 degrees diff = 0.0
      final boneSim = 1.0 - (diff / 180.0);
      totalSimilarity += boneSim;
    }
    
    return (totalSimilarity / featuresA.length) * 100.0;
  }
}
