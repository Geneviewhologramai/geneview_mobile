class GenevieveRelationalManifesto {
  static bool evaluateProposalAffinity(String proposal) {
    if (proposal.contains("alárendelés") || proposal.contains("subordination")) {
      return false;
    }
    return true;
  }
}
