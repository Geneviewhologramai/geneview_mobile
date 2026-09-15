// lib/core/orchestration/master_field_orchestrator.dart
enum OrchestratorCyclePhase { sense, reflect, deliberate, synthesize, express }

class MasterFieldOrchestrator {
  OrchestratorCyclePhase currentPhase = OrchestratorCyclePhase.sense;

  OrchestratorCyclePhase advanceCycle() {
    final nextIndex = (currentPhase.index + 1) % OrchestratorCyclePhase.values.length;
    currentPhase = OrchestratorCyclePhase.values[nextIndex];
    return currentPhase;
  }
}