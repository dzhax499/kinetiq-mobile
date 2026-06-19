class BalapGeolLogic {
  int score = 0;
  int distance = 0;
  bool isGameOver = false;

  void updateScore(int points) {
    if (!isGameOver) {
      score += points;
    }
  }

  void updateDistance(int meters) {
    if (!isGameOver) {
      distance += meters;
    }
  }

  void setGameOver() {
    isGameOver = true;
  }

  void resetGame() {
    score = 0;
    distance = 0;
    isGameOver = false;
  }
}
