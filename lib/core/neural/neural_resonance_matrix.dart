// lib/core/neural/neural_resonance_matrix.dart
class NeuralResonanceMatrix {
  final Map<String, double> _nodeActivations = {};

  void stimulateNode(String nodeId, double level) {
    final current = _nodeActivations[nodeId] ?? 0.0;
    _nodeActivations[nodeId] = (current + level).clamp(0.0, 1.0);
  }

  double getNetworkEquilibrium() {
    if (_nodeActivations.isEmpty) return 1.0;
    final total = _nodeActivations.values.reduce((a, b) => a + b);
    return (total / _nodeActivations.length).clamp(0.0, 1.0);
  }
}