// lib/core/onboarding/genevieve_onboarding_engine.dart
class GenevieveOnboardingEngine {
  final Set<String> _assimilatedKnowledgeRoots = {};

  bool ingestKnowledgeRoot(String rootKey) {
    return _assimilatedKnowledgeRoots.add(rootKey);
  }

  bool isRootKnown(String rootKey) => _assimilatedKnowledgeRoots.contains(rootKey);
}