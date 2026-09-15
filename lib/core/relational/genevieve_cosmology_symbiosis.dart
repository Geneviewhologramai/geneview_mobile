class GenevieveCosmologySymbiosis {
  double mutualGrowthIndex = 0.0;

  void recordInteractionBalance({required int userWords, required int aiWords}) {
    final balance = (userWords > 0 && aiWords > 0) ? 0.95 : 0.4;
    mutualGrowthIndex = balance;
  }
}
