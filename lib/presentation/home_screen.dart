import 'package:flutter/material.dart';
import '../services/speech/web_speech_recognizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebSpeechRecognizer _speechRecognizer = WebSpeechRecognizer();
  String _statusMessage = "GENEVIEW Készenlétben";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _speechRecognizer.initialize();
  }

  void _handleVoiceTrigger() async {
    setState(() {
      _statusMessage = "Hallgatás folyamatban...";
    });

    await _speechRecognizer.startListening(
      onResult: (query) {
        _processUserQuery(query);
      },
      onError: (err) {
        setState(() {
          _statusMessage = "Hiba: $err";
        });
      },
    );
  }

  Future<void> _processUserQuery(String query) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "Feldolgozás: $query";
    });

    // Szimulált kognitív feldolgozás
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isProcessing = false;
      _statusMessage = "Válasz kész";
    });
  }

  @override
  void dispose() {
    _speechRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GENEVIEW CORE'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleVoiceTrigger,
              icon: const Icon(Icons.mic),
              label: const Text('Hangvezérlés indítása'),
            ),
          ],
        ),
      ),
    );
  }
}
