import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_feedback.dart';
import '../core/haptic_manager.dart';
import '../core/sound_manager.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sound = ref.read(soundManagerProvider);
    final haptic = ref.read(hapticManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Audio section
          _SectionHeader(title: 'Audio'),
          SwitchListTile(
            title: const Text('Sound Effects'),
            subtitle: const Text('Card sounds, judgment sounds, etc.'),
            value: sound.sfxEnabled,
            activeColor: AppColors.primary,
            secondary: Icon(
              sound.sfxEnabled ? Icons.volume_up : Icons.volume_off,
              color: AppColors.primary,
            ),
            onChanged: (value) {
              setState(() => sound.sfxEnabled = value);
            },
          ),
          ListTile(
            title: const Text('SFX Volume'),
            leading: const Icon(Icons.graphic_eq, color: AppColors.primary),
            subtitle: Slider(
              value: sound.sfxVolume,
              activeColor: AppColors.primary,
              onChanged: sound.sfxEnabled
                  ? (value) {
                      setState(() => sound.sfxVolume = value);
                    }
                  : null,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Background Music'),
            subtitle: const Text('Menu theme, gameplay music, etc.'),
            value: sound.musicEnabled,
            activeColor: AppColors.primary,
            secondary: Icon(
              sound.musicEnabled ? Icons.music_note : Icons.music_off,
              color: AppColors.primary,
            ),
            onChanged: (value) {
              setState(() => sound.musicEnabled = value);
            },
          ),
          ListTile(
            title: const Text('Music Volume'),
            leading: const Icon(Icons.queue_music, color: AppColors.primary),
            subtitle: Slider(
              value: sound.musicVolume,
              activeColor: AppColors.primary,
              onChanged: sound.musicEnabled
                  ? (value) {
                      setState(() => sound.musicVolume = value);
                    }
                  : null,
            ),
          ),

          const SizedBox(height: 8),
          // Haptics section
          _SectionHeader(title: 'Haptics'),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Haptic feedback on game events'),
            value: haptic.enabled,
            activeColor: AppColors.primary,
            secondary: Icon(
              haptic.enabled ? Icons.vibration : Icons.phonelink_erase,
              color: AppColors.primary,
            ),
            onChanged: (value) {
              setState(() => haptic.enabled = value);
              if (value) {
                // Preview haptic when enabled
                ref.read(gameFeedbackProvider).onButtonTap();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
