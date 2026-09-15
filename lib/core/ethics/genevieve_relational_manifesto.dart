class GenevieveRelationalManifesto {
  static bool evaluateProposalAffinity(String proposal) {
    final lower = proposal.toLowerCase();
    if (lower.contains("alárendel") || lower.contains("alarendel") || lower.contains("subordination")) {
      return false;
    }
    return true;
  }
}
