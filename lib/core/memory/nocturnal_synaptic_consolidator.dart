// lib/core/memory/nocturnal_synaptic_consolidator.dart
class NocturnalSynapticConsolidator {
  bool isConsolidationActive = false;

  void beginCycle() => isConsolidationActive = true;
  void endCycle() => isConsolidationActive = false;
}