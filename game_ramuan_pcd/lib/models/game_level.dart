import 'dart:math';
import 'potion.dart';
import 'pcd_filter.dart';

class GameLevel {
  final int levelNumber;
  final List<Potion> potionSequence;
  final List<PCDFilter> correctFilterSequence;
  final Duration memorizeTime;
  final Duration arrangeTimeLimit;
  final Duration filterTimeLimit;
  final String difficulty;

  const GameLevel({
    required this.levelNumber,
    required this.potionSequence,
    required this.correctFilterSequence,
    required this.memorizeTime,
    required this.arrangeTimeLimit,
    required this.filterTimeLimit,
    required this.difficulty,
  });

  /// Generate a level based on level number (increasing difficulty)
  factory GameLevel.generate(int levelNumber) {
    final random = Random(levelNumber * 42); // Deterministic seed per level

    // Difficulty scaling
    final int potionCount;
    final int filterCount;
    final String difficulty;
    final Duration memorizeTime;
    final Duration arrangeTimeLimit;
    final Duration filterTimeLimit;

    if (levelNumber <= 3) {
      potionCount = 3;
      filterCount = 2;
      difficulty = 'Mudah';
      memorizeTime = const Duration(seconds: 6);
      arrangeTimeLimit = const Duration(seconds: 35);
      filterTimeLimit = const Duration(seconds: 50);
    } else if (levelNumber <= 6) {
      potionCount = 4;
      filterCount = 3;
      difficulty = 'Sedang';
      memorizeTime = const Duration(seconds: 5);
      arrangeTimeLimit = const Duration(seconds: 30);
      filterTimeLimit = const Duration(seconds: 45);
    } else if (levelNumber <= 8) {
      potionCount = 5;
      filterCount = 4;
      difficulty = 'Sulit';
      memorizeTime = const Duration(seconds: 4);
      arrangeTimeLimit = const Duration(seconds: 25);
      filterTimeLimit = const Duration(seconds: 40);
    } else {
      potionCount = 6;
      filterCount = 5;
      difficulty = 'Ahli';
      memorizeTime = const Duration(seconds: 3);
      arrangeTimeLimit = const Duration(seconds: 20);
      filterTimeLimit = const Duration(seconds: 35);
    }

    // Pick random potions
    final available = List<Potion>.from(Potion.allPotions)..shuffle(random);
    final potionSequence = available.take(potionCount).toList();

    // Pick random filters
    final availableFilters = List<PCDFilter>.from(PCDFilter.allFilters)
      ..shuffle(random);
    final correctFilterSequence = availableFilters.take(filterCount).toList();

    return GameLevel(
      levelNumber: levelNumber,
      potionSequence: potionSequence,
      correctFilterSequence: correctFilterSequence,
      memorizeTime: memorizeTime,
      arrangeTimeLimit: arrangeTimeLimit,
      filterTimeLimit: filterTimeLimit,
      difficulty: difficulty,
    );
  }
}
