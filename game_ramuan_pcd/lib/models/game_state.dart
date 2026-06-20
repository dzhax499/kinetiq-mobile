import 'package:flutter/material.dart';
import 'potion.dart';
import 'pcd_filter.dart';
import 'game_level.dart';

enum GamePhase {
  ready,       // Pre-game, waiting to start
  memorize,    // Show potion sequence to memorize
  arrange,     // Player re-arranges potions
  filter,      // Player applies PCD filters to image
  result,      // Show results
  gameOver,    // All levels done or failed
}

class GameState extends ChangeNotifier {
  GamePhase _phase = GamePhase.ready;
  int _currentLevelIndex = 1;
  int _score = 0;
  int _streak = 0;
  int _totalScore = 0;
  double _timeRemaining = 0;
  late GameLevel _currentLevel;
  List<Potion> _playerArrangement = [];
  List<PCDFilter> _playerFilterSequence = [];
  bool _arrangeCorrect = false;
  bool _filterCorrect = false;
  int _livesRemaining = 3;
  int _highScore = 0;

  // Getters
  GamePhase get phase => _phase;
  int get currentLevelIndex => _currentLevelIndex;
  int get score => _score;
  int get streak => _streak;
  int get totalScore => _totalScore;
  double get timeRemaining => _timeRemaining;
  GameLevel get currentLevel => _currentLevel;
  List<Potion> get playerArrangement => _playerArrangement;
  List<PCDFilter> get playerFilterSequence => _playerFilterSequence;
  bool get arrangeCorrect => _arrangeCorrect;
  bool get filterCorrect => _filterCorrect;
  int get livesRemaining => _livesRemaining;
  int get highScore => _highScore;

  GameState() {
    _currentLevel = GameLevel.generate(1);
  }

  void startGame() {
    _currentLevelIndex = 1;
    _score = 0;
    _totalScore = 0;
    _streak = 0;
    _livesRemaining = 3;
    _currentLevel = GameLevel.generate(1);
    _phase = GamePhase.memorize;
    _playerArrangement = [];
    _playerFilterSequence = [];
    notifyListeners();
  }

  void setPhase(GamePhase phase) {
    _phase = phase;
    notifyListeners();
  }

  void setTimeRemaining(double time) {
    _timeRemaining = time;
    notifyListeners();
  }

  void setPlayerArrangement(List<Potion> arrangement) {
    _playerArrangement = arrangement;
    notifyListeners();
  }

  void addFilterToSequence(PCDFilter filter) {
    _playerFilterSequence.add(filter);
    notifyListeners();
  }

  void removeLastFilter() {
    if (_playerFilterSequence.isNotEmpty) {
      _playerFilterSequence.removeLast();
      notifyListeners();
    }
  }

  void clearFilters() {
    _playerFilterSequence.clear();
    notifyListeners();
  }

  /// Check if the potion arrangement is correct
  bool checkArrangement() {
    if (_playerArrangement.length != _currentLevel.potionSequence.length) {
      _arrangeCorrect = false;
      return false;
    }
    for (int i = 0; i < _playerArrangement.length; i++) {
      if (_playerArrangement[i].id != _currentLevel.potionSequence[i].id) {
        _arrangeCorrect = false;
        return false;
      }
    }
    _arrangeCorrect = true;
    notifyListeners();
    return true;
  }

  /// Check if the filter sequence is correct
  bool checkFilterSequence() {
    if (_playerFilterSequence.length !=
        _currentLevel.correctFilterSequence.length) {
      _filterCorrect = false;
      return false;
    }
    for (int i = 0; i < _playerFilterSequence.length; i++) {
      if (_playerFilterSequence[i].id !=
          _currentLevel.correctFilterSequence[i].id) {
        _filterCorrect = false;
        return false;
      }
    }
    _filterCorrect = true;
    notifyListeners();
    return true;
  }

  /// Calculate score for this level
  int calculateLevelScore(double timeLeft, bool arrangePerfect, bool filterPerfect) {
    int levelScore = 0;

    if (arrangePerfect) levelScore += 500;
    if (filterPerfect) levelScore += 500;

    // Time bonus
    levelScore += (timeLeft * 50).toInt();

    // Streak bonus
    if (arrangePerfect && filterPerfect) {
      _streak++;
      levelScore *= (1 + (_streak ~/ 3));
    } else {
      _streak = 0;
    }

    _score = levelScore;
    _totalScore += levelScore;
    notifyListeners();
    return levelScore;
  }

  /// Move to next level
  bool nextLevel() {
    if (_currentLevelIndex >= 10) {
      _phase = GamePhase.gameOver;
      if (_totalScore > _highScore) {
        _highScore = _totalScore;
      }
      notifyListeners();
      return false;
    }
    _currentLevelIndex++;
    _currentLevel = GameLevel.generate(_currentLevelIndex);
    _playerArrangement = [];
    _playerFilterSequence = [];
    _arrangeCorrect = false;
    _filterCorrect = false;
    _phase = GamePhase.memorize;
    notifyListeners();
    return true;
  }

  /// Lose a life
  bool loseLife() {
    _livesRemaining--;
    if (_livesRemaining <= 0) {
      _phase = GamePhase.gameOver;
      if (_totalScore > _highScore) {
        _highScore = _totalScore;
      }
      notifyListeners();
      return false; // Game over
    }
    notifyListeners();
    return true; // Still alive
  }

  void resetLevel() {
    _playerArrangement = [];
    _playerFilterSequence = [];
    _arrangeCorrect = false;
    _filterCorrect = false;
    _phase = GamePhase.memorize;
    notifyListeners();
  }
}
