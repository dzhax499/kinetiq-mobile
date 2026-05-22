/// Game configuration model
enum PoseCategory {
  huruf('Huruf', 'Tirukan bentuk huruf alfabet', '🔤'),
  alam('Alam', 'Tirukan bentuk alam', '🌿'),
  yoga('Yoga', 'Tirukan pose yoga', '🧘'),
  hewan('Hewan', 'Tirukan bentuk hewan', '🦁'),
  campur('Campur', 'Semua kategori dicampur', '🎲');

  final String label;
  final String description;
  final String emoji;
  const PoseCategory(this.label, this.description, this.emoji);
}

enum Difficulty {
  mudah('Mudah', 10, 7),
  sedang('Sedang', 7, 5),
  sulit('Sulit', 5, 3);

  final String label;
  final int thinkingSeconds;
  final int posingSeconds;
  const Difficulty(this.label, this.thinkingSeconds, this.posingSeconds);
}

class GameConfig {
  final int totalRounds;
  final PoseCategory category;
  final Difficulty difficulty;
  final String player1Name;
  final String player2Name;

  const GameConfig({
    this.totalRounds = 5,
    this.category = PoseCategory.campur,
    this.difficulty = Difficulty.sedang,
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
  });

  int get thinkingSeconds => difficulty.thinkingSeconds;
  int get posingSeconds => difficulty.posingSeconds;

  GameConfig copyWith({
    int? totalRounds,
    PoseCategory? category,
    Difficulty? difficulty,
    String? player1Name,
    String? player2Name,
  }) {
    return GameConfig(
      totalRounds: totalRounds ?? this.totalRounds,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
    );
  }
}
