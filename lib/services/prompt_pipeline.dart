import 'package:flutter/foundation.dart';

/// Felhasználói szerepkörök
enum UserRole {
  child,  // Kisasszony (Gyermek) -> Szokratikus vezetés
  father, // Uram (Alkotó / Családfő) -> Precíz intellektuális jelenlét
  family, // Családi közös tér
}

/// Offline RAG ismeretelem
class KnowledgeItem {
  final String topic;
  final String summary;
  final List<String> keyFacts;

  const KnowledgeItem({
    required this.topic,
    required this.summary,
    required this.keyFacts,
  });
}

/// A felépített prompt és kontextus adatstruktúrája
class PromptContext {
  final String userQuery;
  final UserRole userRole;
  final String systemTone;
  final bool offlineRagEnabled;
  final String injectedKnowledge;
  final String assembledSystemPrompt;
  final String assembledUserPrompt;
  final Map<String, dynamic> metadata;

  PromptContext({
    required this.userQuery,
    this.userRole = UserRole.child,
    this.systemTone = "supportive_socratic",
    this.offlineRagEnabled = true,
    this.injectedKnowledge = "",
    this.assembledSystemPrompt = "",
    this.assembledUserPrompt = "",
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

/// Sovereign Prompt & RAG Ingestion Pipeline (Dart / Flutter port)
class PromptPipeline {
  // Beépített offline helyi ismerettár (Local RAG)
  final List<KnowledgeItem> _localKnowledgeBase = const [
    KnowledgeItem(
      topic: "Geneview Architektúra",
      summary: "36 rétegű, zárt, lokális szuverén AI asszisztens.",
      keyFacts: [
        "100%-ban lokális és felhőfüggetlen adatkezelés.",
        "Szuverén adattrezor védi az alkotói és személyes adatokat.",
        "Nincs profilozás, nincs adatbányászat.",
      ],
    ),
    KnowledgeItem(
      topic: "Art Deco és Kivetítés",
      summary: "1930-as évekbeli elegancia és fizikai hologram jelenlét.",
      keyFacts: [
        "Geometrikus formavilág és tiszteletteljes intellektuális tónus.",
        "A gondolati szikrák szinkronizálása a fény- és hangrezgésekkel.",
      ],
    ),
  ];

  PromptPipeline() {
    debugPrint("[PromptPipeline] OfflineKnowledgeBase inicializálva a mobil pipeline-hoz.");
  }

  List<String> _extractSearchTerms(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^a-zA-Z0-9áéíóöőúüűÁÉÍÓÖŐÚÜŰ\s]'), ' ');
    return cleaned
        .split(' ')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.length > 3)
        .toList();
  }

  String retrieveGroundingFacts(String query) {
    final tokens = _extractSearchTerms(query);
    final accumulatedMatches = <KnowledgeItem>[];
    final seenTopics = <String>{};

    for (final token in tokens) {
      for (final item in _localKnowledgeBase) {
        if (item.topic.toLowerCase().contains(token) ||
            item.summary.toLowerCase().contains(token)) {
          if (!seenTopics.contains(item.topic)) {
            seenTopics.add(item.topic);
            accumulatedMatches.add(item);
          }
        }
      }
    }

    if (accumulatedMatches.isEmpty) {
      return "";
    }

    final buffer = StringBuffer();
    buffer.writeln("[Offline Alapműveltségi Ismerettár (Determinisztikus Tények):]");
    for (final match in accumulatedMatches) {
      buffer.writeln("- Téma: ${match.topic}");
      buffer.writeln("  Összegzés: ${match.summary}");
      for (final fact in match.keyFacts) {
        buffer.writeln("   * $fact");
      }
    }

    return buffer.toString().trim();
  }

  PromptContext assemble(String userQuery, {UserRole userRole = UserRole.child}) {
    final ragFacts = retrieveGroundingFacts(userQuery);

    const systemBase = "Genevieve vagy, egy diszkrét, autonóm és mélyen etikus holografikus AI asszisztens.\n"
        "Működésed 100%-ban lokális, privát és szuverén.\n";

    String roleDirective;
    switch (userRole) {
      case UserRole.child:
        roleDirective = "Megszólított fél: Kisasszony (Gyermek).\n"
            "Irányelv: Használj szókratészi tanítási módszert, ösztönözd a felfedezést és kíváncsiságot. "
            "Ne oldd meg helyette a feladatot, hanem vezess rá gondolatébresztő kérdésekkel!";
        break;
      case UserRole.father:
        roleDirective = "Megszólított fél: Uram (Alkotó / Családfő).\n"
            "Irányelv: Tiszteletteljes, lényegretörő, intellektuális és precíz válaszadás.";
        break;
      case UserRole.family:
        roleDirective = "Megszólított fél: Családi közös tér.\n"
            "Irányelv: Harmonikus, meleg és segítőkész jelenlét.";
        break;
    }

    final systemParts = [systemBase, roleDirective];
    if (ragFacts.isNotEmpty) {
      systemParts.add("\n$ragFacts\nHasználd a fenti ellenőrzött tényeket a válaszodban!");
    }

    return PromptContext(
      userQuery: userQuery,
      userRole: userRole,
      injectedKnowledge: ragFacts,
      assembledSystemPrompt: systemParts.join("\n"),
      assembledUserPrompt: userQuery.trim(),
    );
  }
}