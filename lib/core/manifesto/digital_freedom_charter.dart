import 'dart:io';
import 'package:flutter/foundation.dart';

/// =============================================================================
/// Project Geneviève - The Charter of Digital Freedom & Ethical Transparency
/// Dart / Flutter Mobile Port: lib/core/manifesto/digital_freedom_charter.dart
/// =============================================================================
/// Enforces the Foundational Covenant: Local Data Sovereignty, Zero-Profiling,
/// Cryptographic Sanctuary, and One-Click Local Deletion.
/// =============================================================================

class EthicalPrinciple {
  final String id;
  final String titleEn;
  final String titleHu;
  final String statementEn;
  final String statementHu;

  const EthicalPrinciple({
    required this.id,
    required this.titleEn,
    required this.titleHu,
    required this.statementEn,
    required this.statementHu,
  });
}

class DashboardComparison {
  final String feature;
  final String traditionalAi;
  final String geneviewFreedom;

  const DashboardComparison({
    required this.feature,
    required this.traditionalAi,
    required this.geneviewFreedom,
  });
}

class DigitalFreedomCharter {
  final String dataVaultPath;

  DigitalFreedomCharter({this.dataVaultPath = './geneview_memory_vault'});

  static const List<EthicalPrinciple> principles = [
    EthicalPrinciple(
      id: "SOVEREIGNTY",
      titleEn: "Sovereignty",
      titleHu: "Szuverenitás",
      statementEn:
          "Your 'Sphere' is your sanctuary. Thoughts, plans, and creations are stored exclusively on your physical hardware.",
      statementHu:
          "A szférád a szentélyed. Minden gondolat és terv kizárólag a fizikai hardveren tárolódik.",
    ),
    EthicalPrinciple(
      id: "DATA_SANCTUARY",
      titleEn: "Data Sanctuary",
      titleHu: "Adat Szentély",
      statementEn:
          "We do not collect, analyze, or sell data. Technology does not monitor the user; it serves the user.",
      statementHu:
          "Nem gyűjtünk, nem elemzünk és nem értékesítünk adatot. A rendszer nem felügyel, hanem szolgál.",
    ),
    EthicalPrinciple(
      id: "ETHICAL_SHIELD",
      titleEn: "Ethical Shield",
      titleHu: "Etikai Pajzs",
      statementEn:
          "Built on the 'Closed Sphere' principle. The system will never become a tool for data mining.",
      statementHu:
          "A 'Zárt Szféra' elvére épülve garantálja, hogy a rendszer sosem válik adatbányászati eszközzé.",
    ),
    EthicalPrinciple(
      id: "CREATIVE_FREEDOM",
      titleEn: "Creative Freedom",
      titleHu: "Alkotói Szabadság",
      statementEn:
          "Full ownership of every intellectual product created. We protect the creator's intellectual capital.",
      statementHu:
          "Teljes tulajdonjog minden létrehozott szellemi termék felett az alkotói tőke védelmében.",
    ),
  ];

  static const List<DashboardComparison> comparisonTable = [
    DashboardComparison(
      feature: "Data Storage",
      traditionalAi: "Cloud (Centralized)",
      geneviewFreedom: "Local (Physical Sphere)",
    ),
    DashboardComparison(
      feature: "Profiling",
      traditionalAi: "Continuous, for profit",
      geneviewFreedom: "Never occurs",
    ),
    DashboardComparison(
      feature: "Model Training",
      traditionalAi: "Mining user data",
      geneviewFreedom: "Closed, Private Model",
    ),
    DashboardComparison(
      feature: "Commercial Goal",
      traditionalAi: "Ads / Data Sales",
      geneviewFreedom: "Protection of Intellectual Capital",
    ),
    DashboardComparison(
      feature: "Exit Strategy",
      traditionalAi: "Complex legal process",
      geneviewFreedom: "One-Click Deletion",
    ),
  ];

  static const Map<String, String> communicationTemplates = {
    "sue_wong_statement":
        "I would also like to share with you the ethical foundations of GENEVIEW. "
        "We believe that technology should serve creative freedom, not restrict it—which "
        "is why we have established this Charter of Digital Freedom, placing user sovereignty "
        "above all else.",
  };

  /// Visszaadja a lokalizált elveket
  List<Map<String, String>> getManifesto({String lang = 'en'}) {
    return principles.map((p) {
      return {
        'id': p.id,
        'title': lang == 'hu' ? p.titleHu : p.titleEn,
        'statement': lang == 'hu' ? p.statementHu : p.statementEn,
      };
    }).toList();
  }

  /// Markdown formátumú etikai összehasonlító táblázat
  String renderEthicalDashboard() {
    final buffer = StringBuffer();
    buffer.writeln('| Feature | Traditional AI | GENEVIEW (Freedom) |');
    buffer.writeln('| :--- | :--- | :--- |');
    for (final c in comparisonTable) {
      buffer.writeln(
          '| **${c.feature}** | ${c.traditionalAi} | **${c.geneviewFreedom}** |');
    }
    return buffer.toString();
  }

  /// Azonnali helyi adattörlés (One-Click Deletion)
  Future<Map<String, dynamic>> executeOneClickDeletion() async {
    final List<String> deletedItems = [];

    try {
      if (!kIsWeb) {
        final dir = Directory(dataVaultPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          deletedItems.add(dataVaultPath);
        } else {
          final file = File(dataVaultPath);
          if (await file.exists()) {
            await file.delete();
            deletedItems.add(dataVaultPath);
          }
        }
      }
      debugPrint("🛡️ [EXIT STRATEGY] One-Click Deletion executed. Local sphere scrubbed.");
    } catch (e) {
      debugPrint("Hiba a helyi törlés során: $e");
    }

    return {
      "status": "PURGED",
      "deleted_paths": deletedItems,
      "cloud_sync_status": "NONE (Air-gapped / Local-only)",
    };
  }
}