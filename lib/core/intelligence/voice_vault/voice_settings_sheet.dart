import 'package:flutter/material.dart';
import 'voice_profile.dart';
import 'voice_manager.dart';

class VoiceSettingsSheet extends StatelessWidget {
  final VoiceManager voiceManager;

  const VoiceSettingsSheet({super.key, required this.voiceManager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1523),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GENEVIEW HANG ÉS NYELV',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 14,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: voiceManager,
              builder: (context, _) {
                return ListView.separated(
                  itemCount: VoiceCatalog.builtInVoices.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final voice = VoiceCatalog.builtInVoices[index];
                    final isSelected = voice.id == voiceManager.activeVoice.id;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        voice.gender == VoiceGender.female ? Icons.female : Icons.male,
                        color: isSelected ? Colors.cyanAccent : Colors.white54,
                      ),
                      title: Text(
                        voice.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.cyanAccent : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        voice.languageCode == 'hu_HU' ? 'Magyar' : 'English',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.cyanAccent)
                          : null,
                      onTap: () {
                        voiceManager.selectVoice(voice);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}