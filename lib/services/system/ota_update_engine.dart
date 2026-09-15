// lib/services/system/ota_update_engine.dart
class OTAUpdateEngine {
  static bool verifyExplicitUserAuthorization({
    required bool userApprovedOnDevice,
    required bool cryptographicSignatureValid,
  }) {
    return userApprovedOnDevice && cryptographicSignatureValid;
  }
}