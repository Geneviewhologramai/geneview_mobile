class FounderManifestoEngine {
  static bool verifyResponseIntegrity(String response) {
    final lower = response.toLowerCase();
    if (lower.contains("hirdetés") || lower.contains("hirdetes") ||
        lower.contains("szponzorált") || lower.contains("advertisement")) {
      return false;
    }
    return true;
  }
}
