class TherapyController {
  int attempts = 0;
  final int maxAttempts = 3;
  bool levelLocked = false;

  bool tryAgain() {
    attempts++;
    if (attempts >= maxAttempts) {
      levelLocked = true;
      return false; // failed
    }
    return true; // can retry
  }

  void reset() {
    attempts = 0;
    levelLocked = false;
  }
}