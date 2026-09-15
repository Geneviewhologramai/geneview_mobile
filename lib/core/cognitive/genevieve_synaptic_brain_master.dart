class GenevieveSynapticBrainMaster {
  final Map<String, double> _weights = {};

  void reinforceSynapse(String from, String to) {
    final key = "$from::$to";
    _weights[key] = (_weights[key] ?? 0.0) + 0.3;
  }

  double getSynapticStrength(String from, String to) {
    final key = "$from::$to";
    return _weights[key] ?? 0.0;
  }
}
