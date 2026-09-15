// lib/core/orchestration/genevieve_orchestrator.dart
class GenevieveOrchestrator {
  bool isBusy = false;

  void markBusy() => isBusy = true;
  void markIdle() => isBusy = false;
}