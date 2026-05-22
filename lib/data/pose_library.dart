import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_challenge.dart';
import '../models/game_config.dart';

/// Library of pre-defined reference poses with their target landmarks
class PoseLibrary {
  static final Random _random = Random();

  /// Get a random pose challenge for the given category
  static PoseChallenge getRandomChallenge(PoseCategory category) {
    List<PoseChallenge> pool;
    
    if (category == PoseCategory.campur) {
      pool = allChallenges;
    } else {
      pool = allChallenges.where((c) => c.category == category).toList();
    }
    
    if (pool.isEmpty) pool = allChallenges;
    return pool[_random.nextInt(pool.length)];
  }

  /// Get a list of random challenges (no repeats within a game)
  static List<PoseChallenge> getGameChallenges(PoseCategory category, int count) {
    List<PoseChallenge> pool;
    
    if (category == PoseCategory.campur) {
      pool = List.from(allChallenges);
    } else {
      pool = allChallenges.where((c) => c.category == category).toList();
    }
    
    pool.shuffle(_random);
    
    // If we need more challenges than available, repeat
    final result = <PoseChallenge>[];
    while (result.length < count) {
      for (final challenge in pool) {
        result.add(challenge);
        if (result.length >= count) break;
      }
    }
    return result;
  }

  /// All available challenges
  static final List<PoseChallenge> allChallenges = [
    // ===== HURUF =====
    _letterT,
    _letterY,
    _letterX,
    _letterI,
    _letterA,
    _letterL,
    
    // ===== ALAM =====
    _treePose,
    _starPose,
    
    // ===== YOGA =====
    _warriorPose,
    _tPose,
    
    // ===== HEWAN =====
    _flamingoPose,
  ];

  // ===== LETTER POSES =====

  static final PoseChallenge _letterT = PoseChallenge(
    id: 'letter_t',
    name: 'Huruf T',
    description: 'Bentangkan kedua tangan ke samping',
    imagePath: 'assets/poses/letter_t.png',
    category: PoseCategory.huruf,
    difficulty: Difficulty.mudah,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-1.5, -1.0],
      PoseLandmarkType.rightElbow: [1.5, -1.0],
      PoseLandmarkType.leftWrist: [-2.5, -1.0],
      PoseLandmarkType.rightWrist: [2.5, -1.0],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.3, 1.2],
      PoseLandmarkType.rightKnee: [0.3, 1.2],
      PoseLandmarkType.leftAnkle: [-0.3, 2.4],
      PoseLandmarkType.rightAnkle: [0.3, 2.4],
    },
  );

  static final PoseChallenge _letterY = PoseChallenge(
    id: 'letter_y',
    name: 'Huruf Y',
    description: 'Angkat kedua tangan ke atas membentuk V',
    imagePath: 'assets/poses/letter_y.png',
    category: PoseCategory.huruf,
    difficulty: Difficulty.mudah,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-1.2, -1.8],
      PoseLandmarkType.rightElbow: [1.2, -1.8],
      PoseLandmarkType.leftWrist: [-1.8, -2.6],
      PoseLandmarkType.rightWrist: [1.8, -2.6],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.3, 1.2],
      PoseLandmarkType.rightKnee: [0.3, 1.2],
      PoseLandmarkType.leftAnkle: [-0.3, 2.4],
      PoseLandmarkType.rightAnkle: [0.3, 2.4],
    },
  );

  static final PoseChallenge _letterX = PoseChallenge(
    id: 'letter_x',
    name: 'Huruf X',
    description: 'Kaki dan tangan terbuka membentuk X',
    imagePath: 'assets/poses/letter_x.png',
    category: PoseCategory.huruf,
    difficulty: Difficulty.sedang,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-1.2, -1.6],
      PoseLandmarkType.rightElbow: [1.2, -1.6],
      PoseLandmarkType.leftWrist: [-1.8, -2.2],
      PoseLandmarkType.rightWrist: [1.8, -2.2],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.8, 1.2],
      PoseLandmarkType.rightKnee: [0.8, 1.2],
      PoseLandmarkType.leftAnkle: [-1.2, 2.4],
      PoseLandmarkType.rightAnkle: [1.2, 2.4],
    },
  );

  static final PoseChallenge _letterI = PoseChallenge(
    id: 'letter_i',
    name: 'Huruf I',
    description: 'Berdiri tegak, tangan di samping badan',
    imagePath: 'assets/poses/letter_i.png',
    category: PoseCategory.huruf,
    difficulty: Difficulty.mudah,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-0.5, -0.3],
      PoseLandmarkType.rightElbow: [0.5, -0.3],
      PoseLandmarkType.leftWrist: [-0.5, 0.3],
      PoseLandmarkType.rightWrist: [0.5, 0.3],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.3, 1.2],
      PoseLandmarkType.rightKnee: [0.3, 1.2],
      PoseLandmarkType.leftAnkle: [-0.3, 2.4],
      PoseLandmarkType.rightAnkle: [0.3, 2.4],
    },
  );

  static final PoseChallenge _letterA = PoseChallenge(
    id: 'letter_a',
    name: 'Huruf A',
    description: 'Tangan ke atas menyatu, kaki terbuka',
    imagePath: 'assets/poses/letter_a.png',
    category: PoseCategory.huruf,
    difficulty: Difficulty.sedang,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-0.3, -1.8],
      PoseLandmarkType.rightElbow: [0.3, -1.8],
      PoseLandmarkType.leftWrist: [0.0, -2.5],
      PoseLandmarkType.rightWrist: [0.0, -2.5],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.7, 1.2],
      PoseLandmarkType.rightKnee: [0.7, 1.2],
      PoseLandmarkType.leftAnkle: [-1.0, 2.4],
      PoseLandmarkType.rightAnkle: [1.0, 2.4],
    },
  );

  static final PoseChallenge _letterL = PoseChallenge(
    id: 'letter_l',
    name: 'Huruf L',
    description: 'Satu tangan ke atas, satu tangan ke samping',
    imagePath: 'assets/poses/letter_l.png',
    category: PoseCategory.huruf,
    difficulty: Difficulty.sedang,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-0.5, -1.8],
      PoseLandmarkType.rightElbow: [1.5, -1.0],
      PoseLandmarkType.leftWrist: [-0.5, -2.6],
      PoseLandmarkType.rightWrist: [2.5, -1.0],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.3, 1.2],
      PoseLandmarkType.rightKnee: [0.3, 1.2],
      PoseLandmarkType.leftAnkle: [-0.3, 2.4],
      PoseLandmarkType.rightAnkle: [0.3, 2.4],
    },
  );

  // ===== NATURE POSES =====

  static final PoseChallenge _treePose = PoseChallenge(
    id: 'tree',
    name: 'Pohon',
    description: 'Tangan ke atas seperti cabang pohon, berdiri satu kaki',
    imagePath: 'assets/poses/tree.png',
    category: PoseCategory.alam,
    difficulty: Difficulty.sedang,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-1.0, -1.8],
      PoseLandmarkType.rightElbow: [1.0, -1.8],
      PoseLandmarkType.leftWrist: [-1.5, -2.4],
      PoseLandmarkType.rightWrist: [1.5, -2.4],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.3, 1.2],
      PoseLandmarkType.rightKnee: [0.5, 0.5],
      PoseLandmarkType.leftAnkle: [-0.3, 2.4],
      PoseLandmarkType.rightAnkle: [0.2, 1.0],
    },
  );

  static final PoseChallenge _starPose = PoseChallenge(
    id: 'star',
    name: 'Bintang',
    description: 'Buka tangan dan kaki selebar mungkin',
    imagePath: 'assets/poses/star.png',
    category: PoseCategory.alam,
    difficulty: Difficulty.mudah,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-1.5, -1.5],
      PoseLandmarkType.rightElbow: [1.5, -1.5],
      PoseLandmarkType.leftWrist: [-2.3, -2.0],
      PoseLandmarkType.rightWrist: [2.3, -2.0],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-1.0, 1.2],
      PoseLandmarkType.rightKnee: [1.0, 1.2],
      PoseLandmarkType.leftAnkle: [-1.5, 2.4],
      PoseLandmarkType.rightAnkle: [1.5, 2.4],
    },
  );

  // ===== YOGA POSES =====

  static final PoseChallenge _warriorPose = PoseChallenge(
    id: 'warrior',
    name: 'Warrior',
    description: 'Pose warrior: tangan bentang, satu kaki maju',
    imagePath: 'assets/poses/warrior.png',
    category: PoseCategory.yoga,
    difficulty: Difficulty.sulit,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-1.5, -1.0],
      PoseLandmarkType.rightElbow: [1.5, -1.0],
      PoseLandmarkType.leftWrist: [-2.5, -1.0],
      PoseLandmarkType.rightWrist: [2.5, -1.0],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-1.0, 1.0],
      PoseLandmarkType.rightKnee: [0.8, 1.2],
      PoseLandmarkType.leftAnkle: [-1.5, 2.2],
      PoseLandmarkType.rightAnkle: [1.2, 2.4],
    },
  );

  static final PoseChallenge _tPose = PoseChallenge(
    id: 't_pose',
    name: 'T-Pose',
    description: 'Berdiri tegak, kedua tangan lurus ke samping',
    imagePath: 'assets/poses/t_pose.png',
    category: PoseCategory.yoga,
    difficulty: Difficulty.mudah,
    targetLandmarks: _letterT.targetLandmarks,
  );

  // ===== ANIMAL POSES =====

  static final PoseChallenge _flamingoPose = PoseChallenge(
    id: 'flamingo',
    name: 'Flamingo',
    description: 'Berdiri satu kaki, tangan ke atas',
    imagePath: 'assets/poses/flamingo.png',
    category: PoseCategory.hewan,
    difficulty: Difficulty.sulit,
    targetLandmarks: {
      PoseLandmarkType.leftShoulder: [-0.5, -1.0],
      PoseLandmarkType.rightShoulder: [0.5, -1.0],
      PoseLandmarkType.leftElbow: [-0.3, -1.8],
      PoseLandmarkType.rightElbow: [0.3, -1.8],
      PoseLandmarkType.leftWrist: [-0.1, -2.5],
      PoseLandmarkType.rightWrist: [0.1, -2.5],
      PoseLandmarkType.leftHip: [-0.3, 0.0],
      PoseLandmarkType.rightHip: [0.3, 0.0],
      PoseLandmarkType.leftKnee: [-0.3, 1.2],
      PoseLandmarkType.rightKnee: [0.8, 0.3],
      PoseLandmarkType.leftAnkle: [-0.3, 2.4],
      PoseLandmarkType.rightAnkle: [0.5, 0.8],
    },
  );
}
