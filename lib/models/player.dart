import 'dart:typed_data';

/// Represents a player in the game
class Player {
  final String name;
  final List<double> scores;
  final List<Uint8List?> capturedImages;
  final List<Uint8List?> processedImages;

  Player({
    required this.name,
    List<double>? scores,
    List<Uint8List?>? capturedImages,
    List<Uint8List?>? processedImages,
  })  : scores = scores ?? [],
        capturedImages = capturedImages ?? [],
        processedImages = processedImages ?? [];

  double get totalScore {
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  int get roundsPlayed => scores.length;

  double? getScoreForRound(int round) {
    if (round < 0 || round >= scores.length) return null;
    return scores[round];
  }

  void addRoundResult({
    required double score,
    Uint8List? capturedImage,
    Uint8List? processedImage,
  }) {
    scores.add(score);
    capturedImages.add(capturedImage);
    processedImages.add(processedImage);
  }

  void reset() {
    scores.clear();
    capturedImages.clear();
    processedImages.clear();
  }
}
