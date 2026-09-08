import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Epizodikus interakció modell
class EpisodicRecord {
  final int? id;
  final double timestamp;
  final String sessionId;
  final String speaker;
  final String content;
  final double emotionalValence; // -1.0 és +1.0 között
  final List<String> topics;
  final String notes;

  EpisodicRecord({
    this.id,
    required this.timestamp,
    required this.sessionId,
    required this.speaker,
    required this.content,
    this.emotionalValence = 0.0,
    this.topics = const [],
    this.notes = "",
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp,
        'session_id': sessionId,
        'speaker': speaker,
        'content': content,
        'emotional_valence': emotionalValence,
        'topics': jsonEncode(topics),
        'reflection_notes': notes,
      };

  factory EpisodicRecord.fromMap(Map<String, dynamic> map) => EpisodicRecord(
        id: map['id'] as int?,
        timestamp: (map['timestamp'] as num).toDouble(),
        sessionId: map['session_id'] as String,
        speaker: map['speaker'] as String,
        content: map['content'] as String,
        emotionalValence: (map['emotional_valence'] as num?)?.toDouble() ?? 0.0,
        topics: List<String>.from(jsonDecode(map['topics'] as String? ?? '[]')),
        notes: map['reflection_notes'] as String? ?? "",
      );
}

/// Szuverén Helyi Memóriamotor (SovereignMemoryEngine Dart port)
/// Zárt, helyi-első tárolás (Local-First), felhős szinkronizáció nélkül.
class SovereignMemoryEngine {
  final List<EpisodicRecord> _inMemoryFallback = [];
  final Map<String, dynamic> _milestonesFallback = {};

  SovereignMemoryEngine();

  Future<void> initStorage() async {
    debugPrint("[SOVEREIGN-MEMORY]: Helyi memóriatár inicializálva.");
  }

  /// Új interakció rögzítése a helyi memóriába
  Future<void> recordInteraction({
    required String sessionId,
    required String speaker,
    required String content,
    double valence = 0.0,
    List<String>? topics,
    String notes = "",
  }) async {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final record = EpisodicRecord(
      timestamp: nowEpoch,
      sessionId: sessionId,
      speaker: speaker,
      content: content,
      emotionalValence: valence,
      topics: topics ?? [],
      notes: notes,
    );

    _inMemoryFallback.add(record);
    debugPrint("[SOVEREIGN-MEMORY]: Interakció rögzítve [$speaker]: '$content'");
  }

  /// Visszaadja a másodpercek számát az utolsó interakció óta
  double getTimeElapsedSinceLastSeen() {
    if (_inMemoryFallback.isEmpty) return 0.0;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final lastRecord = _inMemoryFallback.last;
    return nowEpoch - lastRecord.timestamp;
  }

  /// Legutóbbi kontextus visszahívása a dialógusmotorhoz
  List<Map<String, dynamic>> recallRecentContext({int limit = 5}) {
    if (_inMemoryFallback.isEmpty) return [];

    final startIndex = _inMemoryFallback.length > limit 
        ? _inMemoryFallback.length - limit 
        : 0;

    final slice = _inMemoryFallback.sublist(startIndex);

    return slice.map((record) => {
      'timestamp': record.timestamp,
      'speaker': record.speaker,
      'content': record.content,
      'valence': record.emotionalValence,
      'topics': record.topics,
      'notes': record.notes,
    }).toList();
  }

  /// Mérföldkő rögzítése
  Future<void> recordMilestone(String key, String value, {double score = 1.0}) async {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _milestonesFallback[key] = {
      'value': value,
      'last_updated': now,
      'significance_score': score,
    };
  }
}