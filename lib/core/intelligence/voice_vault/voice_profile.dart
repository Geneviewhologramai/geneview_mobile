enum VoiceGender { female, male }

class VoiceProfile {
  final String id;
  final String displayName;
  final String languageCode; // 'hu_HU' vagy 'en_US'
  final VoiceGender gender;
  final String modelName; // Piper modellfájl azonosítója

  const VoiceProfile({
    required this.id,
    required this.displayName,
    required this.languageCode,
    required this.gender,
    required this.modelName,
  });
}

class VoiceCatalog {
  static const List<VoiceProfile> builtInVoices = [
    // Magyar hangok
    VoiceProfile(
      id: 'hu_anna',
      displayName: 'Anna (Magyar női)',
      languageCode: 'hu_HU',
      gender: VoiceGender.female,
      modelName: 'hu_HU-anna-medium',
    ),
    VoiceProfile(
      id: 'hu_eszter',
      displayName: 'Eszter (Magyar női lágy)',
      languageCode: 'hu_HU',
      gender: VoiceGender.female,
      modelName: 'hu_HU-eszter-medium',
    ),
    VoiceProfile(
      id: 'hu_bence',
      displayName: 'Bence (Magyar férfi mély)',
      languageCode: 'hu_HU',
      gender: VoiceGender.male,
      modelName: 'hu_HU-bence-medium',
    ),
    VoiceProfile(
      id: 'hu_tamas',
      displayName: 'Tamás (Magyar férfi narrátor)',
      languageCode: 'hu_HU',
      gender: VoiceGender.male,
      modelName: 'hu_HU-tamas-medium',
    ),

    // Angol hangok
    VoiceProfile(
      id: 'en_amy',
      displayName: 'Amy (English Female)',
      languageCode: 'en_US',
      gender: VoiceGender.female,
      modelName: 'en_US-amy-medium',
    ),
    VoiceProfile(
      id: 'en_lessac',
      displayName: 'Lessac (English Female Clear)',
      languageCode: 'en_US',
      gender: VoiceGender.female,
      modelName: 'en_US-lessac-medium',
    ),
    VoiceProfile(
      id: 'en_ryan',
      displayName: 'Ryan (English Male Warm)',
      languageCode: 'en_US',
      gender: VoiceGender.male,
      modelName: 'en_US-ryan-medium',
    ),
    VoiceProfile(
      id: 'en_danny',
      displayName: 'Danny (English Male Crisp)',
      languageCode: 'en_US',
      gender: VoiceGender.male,
      modelName: 'en_US-danny-low',
    ),
  ];
}