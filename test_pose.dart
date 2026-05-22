import 'dart:math';

enum PoseLandmarkType { leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist, leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle }

class PoseLandmark {
  final double x;
  final double y;
  PoseLandmark(this.x, this.y);
}

const keyLandmarks = [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip];

void main() {
  // Target (Huruf T)
  Map<PoseLandmarkType, List<double>> target = {
    PoseLandmarkType.leftShoulder: [-0.5, -1.0],
    PoseLandmarkType.rightShoulder: [0.5, -1.0],
    PoseLandmarkType.leftHip: [-0.3, 0.0],
    PoseLandmarkType.rightHip: [0.3, 0.0],
  };

  // Detected
  Map<PoseLandmarkType, PoseLandmark> detected = {
    PoseLandmarkType.leftShoulder: PoseLandmark(150, 100),
    PoseLandmarkType.rightShoulder: PoseLandmark(250, 100),
    PoseLandmarkType.leftHip: PoseLandmark(170, 200),
    PoseLandmarkType.rightHip: PoseLandmark(230, 200),
  };

  // Normalize detected
  final leftHip = detected[PoseLandmarkType.leftHip]!;
  final rightHip = detected[PoseLandmarkType.rightHip]!;
  final leftShoulder = detected[PoseLandmarkType.leftShoulder]!;
  final rightShoulder = detected[PoseLandmarkType.rightShoulder]!;

  final centerX = (leftHip.x + rightHip.x) / 2;
  final centerY = (leftHip.y + rightHip.y) / 2;
  
  double _distance(double x1, double y1, double x2, double y2) => sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
  
  final leftTorso = _distance(leftShoulder.x, leftShoulder.y, leftHip.x, leftHip.y);
  final rightTorso = _distance(rightShoulder.x, rightShoulder.y, rightHip.x, rightHip.y);
  final scaleFactor = (leftTorso + rightTorso) / 2;

  final normalized = <PoseLandmarkType, List<double>>{};
  for (final type in keyLandmarks) {
    final lm = detected[type]!;
    normalized[type] = [(lm.x - centerX) / scaleFactor, (lm.y - centerY) / scaleFactor];
  }

  print('Normalized: \$normalized');
  
  // Cosine Sim
  final vecA = <double>[];
  final vecB = <double>[];
  for (final key in keyLandmarks) {
    vecA.addAll(normalized[key]!);
    vecB.addAll(target[key]!);
  }
  
  double dot = 0, magA = 0, magB = 0;
  for(int i=0; i<vecA.length; i++) {
    dot += vecA[i] * vecB[i];
    magA += vecA[i] * vecA[i];
    magB += vecB[i] * vecB[i];
  }
  magA = sqrt(magA);
  magB = sqrt(magB);
  
  print('Dot: \$dot, MagA: \$magA, MagB: \$magB');
  final sim = dot / (magA * magB);
  final cosSim = ((sim + 1) / 2);
  print('Cosine Sim: \$cosSim');
}
