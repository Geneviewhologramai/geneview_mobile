class GenevieveHybridMemory {
  final List<String> _workingThoughts = [];
  final List<String> _vault = [];

  void appendWorkingThought(String thought) {
    if (_workingThoughts.length >= 5) {
      _vault.add(_workingThoughts.removeAt(0));
    }
    _workingThoughts.add(thought);
  }

  List<String> getImmediateContext() => List.unmodifiable(_workingThoughts);
  List<String> get longTermConsolidatedVault => List.unmodifiable(_vault);
}
