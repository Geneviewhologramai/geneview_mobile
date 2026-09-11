
/// A Geneviève holografikus érzelmi mátrixa (-10 .. +10 skála)
class EmotionMatrix {
  // Belső érzelmi állapot: -10.0 (mély melancholia) és +10.0 (felfokozott derű/ragyogás) között
  double _valence = 0.0;
  
  // Aktuális tudatossági réteg (1 .. 36)
  int _currentLayer = 18;

  EmotionMatrix({double initialValence = 0.0, int initialLayer = 18}) {
    setValence(initialValence);
    _currentLayer = initialLayer.clamp(1, 36);
  }

  double get valence => _valence;
  int get currentLayer => _currentLayer;

  /// Érzelmi érték beállítása (-10 és +10 közé szorítva)
  void setValence(double value) {
    _valence = value.clamp(-10.0, 10.0);
  }

  /// Tudatossági réteg beállítása (1 .. 36)
  void setLayer(int layer) {
    _currentLayer = layer.clamp(1, 36);
  }

  /// Lélegzési ciklus időtartama másodpercben:
  /// -10-nél: 5.5 másodperc (nagyon lassú, nehéz, mély ritmus)
  ///   0-nál: 3.8 másodperc (elegáns, nyugodt alapértelmezett ritmus)
  /// +10-nél: 2.2 másodperc (élénk, dinamikus, közvetlen ritmus)
  Duration get breathingDuration {
    // Lineáris interpoláció a -10..+10 tartományból
    final double normalized = (_valence + 10.0) / 20.0; // 0.0 .. 1.0
    final double seconds = 5.5 - (normalized * 3.3);     // 5.5-től le 2.2-ig
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Lebegési amplitúdó pixelben (függőleges kitérés):
  /// -10-nél: 2.0 px (visszafogott, alig észrevehető mikromozgás)
  ///   0-nál: 4.5 px (természetes lebegés)
  /// +10-nél: 7.0 px (kifejező, tágabb organikus lebegés)
  double get hoverAmplitude {
    final double normalized = (_valence + 10.0) / 20.0;
    return 2.0 + (normalized * 5.0);
  }

  /// Fényintenzitás / Glow modulációs szorzó (0.6 .. 1.25):
  /// -10-nél: tompább, hűvösebb aurafény
  /// +10-nél: ragyogó, tiszta, magas fényerő
  double get glowIntensity {
    final double normalized = (_valence + 10.0) / 20.0;
    return 0.6 + (normalized * 0.65);
  }

  /// Átlátszósági (opacitás) sáv a lélegzési ciklus során
  double get minOpacity => 0.82;
  double get maxOpacity => (0.92 + ((_valence + 10.0) / 20.0) * 0.08).clamp(0.92, 1.0);

  /// Régi kód kompatibilitás: lélegzési szorzó
  double get breathingRate => (1.0 + (_valence / 20.0)).clamp(0.5, 1.5);
/// 36 rétegű kognitív rezonanciaszint (1-től 36-ig a valence alapján)
  int get resonanceTier {
    final double normalized = (_valence + 10.0) / 20.0; // 0.0 - 1.0
    return (normalized * 35).round() + 1;
  }}