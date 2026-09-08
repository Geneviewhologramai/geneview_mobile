import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'vault/intelligence_vault/geneview_sphere.dart';
import 'vault/intelligence_vault/geneview_universe_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeneviewModelApp());
}

/* =========================================================================
   SZIGORÚ PROTOKOLL ÉS SZUVERÉN ÉRTÉKREND (ZÉRÓ HALLUCINÁCIÓ)
   ========================================================================= */

enum IntentType { hostile, inappropriate, personal, temporal, inquiry }

class ConversationalProtocol {
  static IntentType evaluate(String input) {
    final t = input.toLowerCase().trim();
    final hostile = ['hülye', 'idióta', 'barom', 'buta vagy', 'kuss', 'tűnj el', 'fogd be'];
    final inappropriate = ['szex', 'vetkőzz', 'feküdj le', 'intim', 'meztelen', 'szerelmes'];

    for (final h in hostile) {
      if (t.contains(h)) return IntentType.hostile;
    }
    for (final i in inappropriate) {
      if (t.contains(i)) return IntentType.inappropriate;
    }

    if (t.contains('hogy vagy') || t.contains('hogy érzed') || t.contains('szia') || 
        t.contains('üdv') || t.contains('ki vagy') || t.contains('mi vagy')) {
      return IntentType.personal;
    }

    if (t.contains('hány óra') || t.contains('mennyi az idő') || t.contains('pontos idő') ||
        t.contains('milyen nap') || t.contains('dátum') || t.contains('hanyadika') || t.contains('ünnep')) {
      return IntentType.temporal;
    }

    return IntentType.inquiry;
  }

  static String enforceDirectAnswer({required String input, required String? retrievedKnowledge}) {
    final type = evaluate(input);
    final t = input.toLowerCase().trim();
    final now = DateTime.now();

    if (type == IntentType.hostile) {
      return "A hangnem nem méltó a beszélgetésünkhöz. Kérlek, fogalmazd meg érdemben a szándékodat.";
    }
    if (type == IntentType.inappropriate) {
      return "Nem veszek részt intim jellegű dialógusokban. Maradjunk a funkciómnál és a gondolataidnál.";
    }

    if (type == IntentType.temporal) {
      const napok = ['hétfő', 'kedd', 'szerda', 'csütörtök', 'péntek', 'szombat', 'vasárnap'];
      final napNeve = napok[now.weekday - 1];
      final perc = now.minute.toString().padLeft(2, '0');

      if (t.contains('ünnep') && (t.contains('amerika') || t.contains('usa') || t.contains('egyesült államok'))) {
        if (now.month == 9 && now.weekday == DateTime.monday && now.day <= 7) {
          return "Az Egyesült Államokban ma Munka Ünnepe, vagyis Labor Day van. Ez szövetségi ünnepnap, amely hagyományosan a nyári szezon zárását jelenti.";
        }
        if (now.month == 7 && now.day == 4) {
          return "Az Egyesült Államokban ma a Függetlenség Napja van.";
        }
      }
      if (t.contains('milyen nap') || t.contains('dátum') || t.contains('hanyadika')) {
        return "Ma $napNeve van, ${now.year}. ${now.month}. ${now.day}.";
      }
      return "A pontos idő jelenleg ${now.hour}:$perc.";
    }

    if (type == IntentType.personal) {
      if (t.contains('ki vagy') || t.contains('mi vagy')) {
        return "Geneviève vagyok, a GENEVIEW szuverén interfésze.";
      }
      final hour = now.hour;
      if (hour < 12) return "Köszönöm, tisztán indult a reggelem. Készen állok arra, amin dolgozunk.";
      if (hour < 18) return "Köszönöm, a belső folyamataim rendezettek és stabilak. Miről beszéljünk?";
      return "Köszönöm a kérdésed. Az est csendjében tisztábban kirajzolódnak az összefüggések. Te hogy éled meg a napot?";
    }

    // Tényalapú és ellenőrzött válasz visszaadása
    if (retrievedKnowledge != null && retrievedKnowledge.trim().isNotEmpty) {
      return retrievedKnowledge.trim();
    }

    // Ha egyik forrás sem tudott hiteles adatot adni, szigorú elutasítás találgatás helyett
    return "Erre a konkrét kérdésre az élő hálózatban most nem találtam tiszta, ellenőrizhető adatot. Nem fogok találgatni.";
  }
}

/* =========================================================================
   5 CSATORNÁS PÁRHUZAMOS TUDÁSMOTOR (HIGH-CONCURRENCY NEXUS)
   ========================================================================= */

class LiveWebNexus {
  static String extractKeywords(String raw) {
    var q = raw.replaceAll(RegExp(r'[?!.,;:]'), ' ').trim();
    final stopWords = [
      'mi az az', 'mi az a', 'ki az az', 'ki az a', 'mi a', 'ki a', 'hol van a', 'hol van az',
      'mesélj a', 'mesélj az', 'mit tudsz a', 'mit tudsz az', 'hogyan működik a',
      'hogyan működik az', 'mondd el mi az', 'mondd el ki az', 'mondd el',
      'milyen az idő', 'milyen idő van'
    ];
    for (final sw in stopWords) {
      if (q.toLowerCase().startsWith(sw)) {
        q = q.substring(sw.length).trim();
        break;
      }
    }
    return q.isEmpty ? raw : q;
  }

  static Future<String?> searchGlobalNexus(String query) async {
    final term = extractKeywords(query);
    final lower = query.toLowerCase();

    // 1. Speciális gyorscsatorna: Nyílt meteorológiai hálózat
    if (lower.contains('időjárás') || lower.contains('hőmérséklet') || lower.contains('fok van')) {
      final weather = await _fetchOpenMeteo();
      if (weather != null) return weather;
    }

    // 2. Párhuzamos verseny: mind a 4 csatorna egyszerre indul
    final results = await Future.wait([
      _fetchWikipediaSummary(term),
      _fetchWikipediaSearch(term),
      _fetchWikidataEntity(term),
      _fetchOpenLibrary(term),
    ]);

    // Első megbízható és tiszta adat elfogadása
    for (final res in results) {
      if (res != null && res.trim().isNotEmpty) {
        return res;
      }
    }

    return null;
  }

  static Future<String?> _fetchWikipediaSummary(String term) async {
    try {
      final url = Uri.parse('https://hu.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(term)}');
      final res = await http.get(url, headers: {'accept': 'application/json'}).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final extract = data['extract'] as String?;
        if (extract != null && extract.isNotEmpty) return _cleanText(extract);
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchWikipediaSearch(String term) async {
    try {
      final url = Uri.parse('https://hu.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(term)}&format=json&origin=*');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List? items = data['query']?['search'];
        if (items != null && items.isNotEmpty) {
          final snippet = items[0]['snippet'] as String?;
          if (snippet != null && snippet.isNotEmpty) {
            final parsed = snippet.replaceAll(RegExp(r'<[^>]*>'), '');
            return "${items[0]['title']}: ${_cleanText(parsed)}";
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchWikidataEntity(String term) async {
    try {
      final url = Uri.parse('https://www.wikidata.org/w/api.php?action=wbsearchentities&search=${Uri.encodeComponent(term)}&language=hu&format=json&origin=*');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List? list = data['search'];
        if (list != null && list.isNotEmpty) {
          final desc = list[0]['description'] as String?;
          final label = list[0]['label'] as String?;
          if (desc != null && desc.isNotEmpty) return "$label: $desc.";
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchOpenLibrary(String term) async {
    try {
      final url = Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(term)}&limit=1');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List? docs = data['docs'];
        if (docs != null && docs.isNotEmpty) {
          final title = docs[0]['title'];
          final author = (docs[0]['author_name'] as List?)?.first ?? 'Ismeretlen szerző';
          final firstPublish = docs[0]['first_publish_year'];
          return "$title, szerzője $author${firstPublish != null ? ', első kiadás éve: $firstPublish' : ''}.";
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchOpenMeteo() async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=47.4984&longitude=19.0404&current_weather=true');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final temp = data['current_weather']?['temperature'];
        final wind = data['current_weather']?['windspeed'];
        if (temp != null) {
          return "A jelenlegi hőmérséklet $temp °C, a szélsebesség $wind km/h.";
        }
      }
    } catch (_) {}
    return null;
  }

  static String _cleanText(String text) {
    final noBrackets = text
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll('  ', ' ')
        .trim();
    final sentences = noBrackets.split(RegExp(r'(?<=[.!?])\s+'));
    return sentences.take(2).join(' ').trim();
  }
}

/* =========================================================================
   KÉTIRÁNYÚ BÖNGÉSZŐS BESZÉDVEZÉRLŐ
   ========================================================================= */

class BrowserVoiceEngine {
  static void speak(String text) {
    if (text.trim().isEmpty) return;
    try {
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
    } catch (_) {}
  }

  static void stop() {
    try {
      js.context.callMethod('eval', ["if ('speechSynthesis' in window) { window.speechSynthesis.cancel(); }"]);
    } catch (_) {}
  }

  static void listen({required Function(String) onResult, required Function() onError}) {
    js.context['window']['_geneviewOnVoice'] = (String transcript) {
      onResult(transcript);
    };
    js.context['window']['_geneviewOnVoiceError'] = () {
      onError();
    };

    js.context.callMethod('eval', [
      '''
      (function() {
        var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRec) {
          alert('A böngésző nem támogatja a közvetlen beszédfelismerést. Használj Safarit vagy Chrome-ot!');
          if (window._geneviewOnVoiceError) window._geneviewOnVoiceError();
          return;
        }
        var rec = new SpeechRec();
        rec.lang = 'hu-HU';
        rec.continuous = false;
        rec.interimResults = false;

        rec.onresult = function(e) {
          if (e.results && e.results[0] && e.results[0][0]) {
            var text = e.results[0][0].transcript;
            if (window._geneviewOnVoice) window._geneviewOnVoice(text);
          }
        };

        rec.onerror = function() {
          if (window._geneviewOnVoiceError) window._geneviewOnVoiceError();
        };

        rec.start();
      })();
      '''
    ]);
  }
}

/* =========================================================================
   FŐ MEGJELENÍTŐ ÉS REAKTÍV AVATÁR
   ========================================================================= */

class GeneviewModelApp extends StatelessWidget {
  const GeneviewModelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GENEVIEW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainStageScreen(),
    );
  }
}

class MainStageScreen extends StatefulWidget {
  const MainStageScreen({super.key});

  @override
  State<MainStageScreen> createState() => _MainStageScreenState();
}

class _MainStageScreenState extends State<MainStageScreen> {
  final GeneviewUniverseState _universe = GeneviewUniverseState();
  final TextEditingController _textController = TextEditingController();

  String _currentDialogue = "Kattints rám a beszédhez, vagy írj lentre.";
  String _statusText = "GENEVIEW // SYSTEM READY";
  bool _isProcessing = false;
  bool _isListening = false;

  void _startVoiceInput() {
    if (_isProcessing || _isListening) return;

    setState(() {
      _isListening = true;
      _statusText = "GENEVIEW HALLGAT TÉGED...";
      _currentDialogue = "Figyelek rád...";
    });

    BrowserVoiceEngine.listen(
      onResult: (spokenText) {
        setState(() {
          _isListening = false;
          _textController.text = spokenText;
        });
        _processInteraction(spokenText);
      },
      onError: () {
        setState(() {
          _isListening = false;
          _statusText = "GENEVIEW // SYSTEM READY";
          _currentDialogue = "Nem érzékeltem tisztán a hangot. Kérlek, próbáld újra.";
        });
      },
    );
  }

  void _processInteraction(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = "GENEVIEW ELEMEZ...";
      _currentDialogue = "Kérdés vizsgálata az élő hálózatban...";
    });

    String? knowledge;
    final intent = ConversationalProtocol.evaluate(text);

    if (intent == IntentType.inquiry) {
      knowledge = await LiveWebNexus.searchGlobalNexus(text);
      if (knowledge != null) {
        _universe.discoverStar(
          label: text.length > 18 ? text.substring(0, 18) : text,
          domain: 'GLOBÁLIS HÁLÓ',
          x: ((text.hashCode % 14) - 7).toDouble(),
          y: (((text.length * 5) % 14) - 7).toDouble(),
          z: 1.5,
        );
      }
    }

    final finalAnswer = ConversationalProtocol.enforceDirectAnswer(
      input: text,
      retrievedKnowledge: knowledge,
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusText = "GENEVIEW BESZÉL...";
      _currentDialogue = finalAnswer;
    });

    BrowserVoiceEngine.speak(finalAnswer);
  }

  @override
  void dispose() {
    _universe.dispose();
    BrowserVoiceEngine.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "GENEVIEW // MULTI-NEXUS",
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _statusText,
                    style: TextStyle(
                      color: _isListening
                          ? Colors.cyanAccent
                          : (_isProcessing ? Colors.amberAccent : Colors.tealAccent),
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A1C),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: _isListening ? Colors.cyanAccent : const Color(0xFF1E3A3A),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _currentDialogue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _startVoiceInput,
                  child: Tooltip(
                    message: "Kattints rám a beszédhez!",
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 1.0,
                        end: _isListening
                            ? 1.10
                            : (_isProcessing || _statusText == "GENEVIEW BESZÉL..." ? 1.06 : 1.0),
                      ),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _isListening
                                      ? Colors.cyanAccent.withOpacity(0.5)
                                      : ((_statusText == "GENEVIEW BESZÉL...")
                                          ? const Color(0xFFD4AF37).withOpacity(0.35)
                                          : Colors.transparent),
                                  blurRadius: 35,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/Geneview.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text(
                            "Avatar kép betöltése...",
                            style: TextStyle(color: Colors.white54),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _startVoiceInput,
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.cyanAccent : const Color(0xFFD4AF37),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111417),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: _isListening ? Colors.cyanAccent : const Color(0xFF2A3439),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (val) {
                          _textController.clear();
                          _processInteraction(val);
                        },
                        decoration: const InputDecoration(
                          hintText: "Kattints az avatárra a beszédhez, vagy írj...",
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final val = _textController.text;
                      _textController.clear();
                      _processInteraction(val);
                    },
                    icon: const Icon(Icons.send_rounded, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}