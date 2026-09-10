import 'package:flutter/material.dart';
import 'core/orchestrator.dart';
import 'presentation/hologram_display_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeneviewApp());
}

class GeneviewApp extends StatelessWidget {
  const GeneviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GENEVIEW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GeneviewRootStage(),
    );
  }
}

class GeneviewRootStage extends StatefulWidget {
  const GeneviewRootStage({super.key});

  @override
  State<GeneviewRootStage> createState() => _GeneviewRootStageState();
}

class _GeneviewRootStageState extends State<GeneviewRootStage> {
  late final GeneviewOrchestrator _orchestrator;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _orchestrator = GeneviewOrchestrator();
    _orchestrator.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _orchestrator.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Felső Szimbionta Státusz
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                    _orchestrator.isSpeaking
                        ? "GENEVIEW BESZÉL..."
                        : (_orchestrator.status == CellStatus.analyzing
                            ? "REZONANCIA..."
                            : (_orchestrator.status == CellStatus.offline
                                ? "OFFLINE"
                                : "READY")),
                    style: TextStyle(
                      color: _orchestrator.isSpeaking
                          ? Colors.amberAccent
                          : (_orchestrator.status == CellStatus.offline
                              ? Colors.redAccent
                              : Colors.tealAccent),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Dialógus panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A1C),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFF1E3A3A), width: 1.2),
                ),
                child: Text(
                  _orchestrator.currentText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
            ),

            // Vizuális Cella (Standard, Pyramid 4X, Prism Split)
            Expanded(
              child: HologramDisplayScreen(
                activeFrame: _orchestrator.activeFrame,
                isSpeaking: _orchestrator.isSpeaking,
              ),
            ),

            // Parancssor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111417),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: const Color(0xFF2A3439)),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (val) {
                          _controller.clear();
                          _orchestrator.sendQuery(val);
                        },
                        decoration: const InputDecoration(
                          hintText: "Szólj Geneview-hoz...",
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final val = _controller.text;
                      _controller.clear();
                      _orchestrator.sendQuery(val);
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