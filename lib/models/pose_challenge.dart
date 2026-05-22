import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'game_config.dart';

/// Represents a single pose challenge that players must imitate
class PoseChallenge {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final PoseCategory category;
  final Difficulty difficulty;
  
  /// Pre-computed normalized target landmarks for this pose.
  /// Each entry is [x, y] normalized relative to body center and scale.
  final Map<PoseLandmarkType, List<double>> targetLandmarks;

  const PoseChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.category,
    required this.difficulty,
    required this.targetLandmarks,
  });
}
