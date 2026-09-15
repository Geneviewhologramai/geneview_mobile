class ExpandingUniverseEngine {
  int activeConceptCount = 0;
  bool get isExpanding => true;

  void expand(String concept, List<String> links, double weight) {
    activeConceptCount++;
  }
}
