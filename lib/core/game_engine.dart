import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';
import '../models/player.dart';
import '../models/pose_challenge.dart';

/// Possible game states
enum GameState {
  idle,
  showingReference,
  thinkingTime,
  posingTime,
  capturing,
  processing,
  showingRoundResult,
  showingFinalResult,
}

/// Which player is currently active
enum ActivePlayer { player1, player2 }

/// Core game engine managing state, timer, rounds, and player data
class GameEngine extends ChangeNotifier {
  // === Game configuration ===
  GameConfig _config = const GameConfig();
  GameConfig get config => _config;

  // === Game state ===
  GameState _state = GameState.idle;
  GameState get state => _state;

  // === Players ===
  late Player _player1;
  late Player _player2;
  Player get player1 => _player1;
  Player get player2 => _player2;

  // === Round tracking ===
  int _currentRound = 0;
  int get currentRound => _currentRound;
  int get totalRounds => _config.totalRounds;
  bool get isLastRound => _currentRound >= _config.totalRounds;

  // === Active player for turn-based mode ===
  ActivePlayer _activePlayer = ActivePlayer.player1;
  ActivePlayer get activePlayer => _activePlayer;
  Player get currentPlayer => _activePlayer == ActivePlayer.player1 ? _player1 : _player2;
  String get currentPlayerName => currentPlayer.name;
  bool get isPlayer1Turn => _activePlayer == ActivePlayer.player1;

  // === Timer ===
  Timer? _timer;
  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;
  bool get isThinkingPhase => _state == GameState.thinkingTime;
  bool get isPosingPhase => _state == GameState.posingTime;

  // === Current challenge ===
  PoseChallenge? _currentChallenge;
  PoseChallenge? get currentChallenge => _currentChallenge;

  // === Round results (temporary storage for current round) ===
  double? _player1RoundScore;
  double? _player2RoundScore;
  double? get player1RoundScore => _player1RoundScore;
  double? get player2RoundScore => _player2RoundScore;

  // === Callbacks ===
  VoidCallback? onCaptureTrigger;
  VoidCallback? onRoundComplete;
  VoidCallback? onGameComplete;

  /// Initialize the game engine with configuration
  void initializeGame(GameConfig config) {
    _config = config;
    _player1 = Player(name: config.player1Name);
    _player2 = Player(name: config.player2Name);
    _currentRound = 0;
    _state = GameState.idle;
    _activePlayer = ActivePlayer.player1;
    _player1RoundScore = null;
    _player2RoundScore = null;
    notifyListeners();
  }

  /// Start a new round with the given challenge
  void startRound(PoseChallenge challenge) {
    _currentRound++;
    _currentChallenge = challenge;
    _activePlayer = ActivePlayer.player1;
    _player1RoundScore = null;
    _player2RoundScore = null;
    
    _setState(GameState.showingReference);
    
    // Show reference for 3 seconds, then start thinking time
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == GameState.showingReference) {
        startThinkingPhase();
      }
    });
  }

  /// Start the thinking phase countdown
  void startThinkingPhase() {
    _remainingSeconds = _config.thinkingSeconds;
    _setState(GameState.thinkingTime);
    _startCountdown(() {
      // Thinking time over → start posing phase
      startPosingPhase();
    });
  }

  /// Start the posing phase countdown
  void startPosingPhase() {
    _remainingSeconds = _config.posingSeconds;
    _setState(GameState.posingTime);
    _startCountdown(() {
      // Posing time over → capture!
      triggerCapture();
    });
  }

  /// Trigger the capture (photo taken!)
  void triggerCapture() {
    _setState(GameState.capturing);
    onCaptureTrigger?.call();
  }

  /// Submit the score for the current player
  void submitPlayerScore(double score, {Uint8List? capturedImage, Uint8List? processedImage}) {
    if (_activePlayer == ActivePlayer.player1) {
      _player1RoundScore = score;
      _player1.addRoundResult(
        score: score,
        capturedImage: capturedImage,
        processedImage: processedImage,
      );
      
      // Switch to Player 2
      _activePlayer = ActivePlayer.player2;
      _setState(GameState.showingReference);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (_state == GameState.showingReference) {
          startThinkingPhase();
        }
      });
    } else {
      _player2RoundScore = score;
      _player2.addRoundResult(
        score: score,
        capturedImage: capturedImage,
        processedImage: processedImage,
      );
      
      // Both players done → show round result
      _setState(GameState.showingRoundResult);
      onRoundComplete?.call();
    }
    notifyListeners();
  }

  /// Proceed to next round or final result
  void proceedAfterRoundResult() {
    if (isLastRound) {
      _setState(GameState.showingFinalResult);
      onGameComplete?.call();
    } else {
      _setState(GameState.idle);
    }
    notifyListeners();
  }

  /// Get the winner of the current round
  String? getRoundWinner() {
    if (_player1RoundScore == null || _player2RoundScore == null) return null;
    if (_player1RoundScore! > _player2RoundScore!) return _player1.name;
    if (_player2RoundScore! > _player1RoundScore!) return _player2.name;
    return 'Seri!';
  }

  /// Get the overall winner
  String getOverallWinner() {
    if (_player1.totalScore > _player2.totalScore) return _player1.name;
    if (_player2.totalScore > _player1.totalScore) return _player2.name;
    return 'Seri!';
  }

  /// Get rounds won by each player
  Map<String, int> getRoundsWon() {
    int p1Wins = 0;
    int p2Wins = 0;
    for (int i = 0; i < _player1.scores.length && i < _player2.scores.length; i++) {
      if (_player1.scores[i] > _player2.scores[i]) {
        p1Wins++;
      } else if (_player2.scores[i] > _player1.scores[i]) {
        p2Wins++;
      }
    }
    return {
      _player1.name: p1Wins,
      _player2.name: p2Wins,
    };
  }

  /// Reset the game
  void resetGame() {
    _cancelTimer();
    _player1.reset();
    _player2.reset();
    _currentRound = 0;
    _activePlayer = ActivePlayer.player1;
    _currentChallenge = null;
    _player1RoundScore = null;
    _player2RoundScore = null;
    _setState(GameState.idle);
  }

  // === Private methods ===

  void _setState(GameState newState) {
    _state = newState;
    notifyListeners();
  }

  void _startCountdown(VoidCallback onComplete) {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();
      if (_remainingSeconds <= 0) {
        _cancelTimer();
        onComplete();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
