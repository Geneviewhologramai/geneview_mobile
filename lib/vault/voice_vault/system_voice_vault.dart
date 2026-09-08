import 'dart:js' as js;

class SystemVoiceVault {
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      // Megszólaltatás a böngésző natív beszédszintetizátorával magyar nyelven
      js.context.callMethod('eval', [
        '''
        if ('speechSynthesis' in window) {
          window.speechSynthesis.cancel();
          var utter = new SpeechSynthesisUtterance(${js.context['JSON'].callMethod('stringify', [text])});
          utter.lang = 'hu-HU';
          utter.rate = 0.95;
          utter.pitch = 1.05;
          window.speechSynthesis.speak(utter);
        }
        '''
      ]);
    } catch (e) {
      // Fallback
    }
  }

  Future<void> stop() async {
    try {
      js.context.callMethod('eval', ["if ('speechSynthesis' in window) { window.speechSynthesis.cancel(); }"]);
    } catch (_) {}
  }
}