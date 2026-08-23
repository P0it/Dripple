import 'package:flutter/material.dart';
import 'package:dripple/l10n/app_localizations.dart';
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
    final sound = ref.watch(soundManagerProvider);
    final haptic = ref.watch(hapticManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.point,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Audio section
          _SectionHeader(title: l10n.audio),
          SwitchListTile(
            title: Text(l10n.soundEffects),
            subtitle: Text(l10n.soundEffectsDesc),
            value: sound.sfxEnabled,
            activeThumbColor: AppColors.point,
            secondary: Icon(
              sound.sfxEnabled ? Icons.volume_up : Icons.volume_off,
              color: AppColors.point,
            ),
            onChanged: (value) {
              setState(() => sound.sfxEnabled = value);
            },
          ),
          ListTile(
            title: Text(l10n.sfxVolume),
            leading: const Icon(Icons.graphic_eq, color: AppColors.point),
            subtitle: Slider(
              value: sound.sfxVolume,
              activeColor: AppColors.point,
              onChanged: sound.sfxEnabled
                  ? (value) {
                      setState(() => sound.sfxVolume = value);
                    }
                  : null,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.backgroundMusic),
            subtitle: Text(l10n.backgroundMusicDesc),
            value: sound.musicEnabled,
            activeThumbColor: AppColors.point,
            secondary: Icon(
              sound.musicEnabled ? Icons.music_note : Icons.music_off,
              color: AppColors.point,
            ),
            onChanged: (value) {
              setState(() => sound.musicEnabled = value);
            },
          ),
          ListTile(
            title: Text(l10n.musicVolume),
            leading: const Icon(Icons.queue_music, color: AppColors.point),
            subtitle: Slider(
              value: sound.musicVolume,
              activeColor: AppColors.point,
              onChanged: sound.musicEnabled
                  ? (value) {
                      setState(() => sound.musicVolume = value);
                    }
                  : null,
            ),
          ),

          const SizedBox(height: 8),
          // Haptics section
          _SectionHeader(title: l10n.haptics),
          SwitchListTile(
            title: Text(l10n.vibration),
            subtitle: Text(l10n.vibrationDesc),
            value: haptic.enabled,
            activeThumbColor: AppColors.point,
            secondary: Icon(
              haptic.enabled ? Icons.vibration : Icons.phonelink_erase,
              color: AppColors.point,
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
          color: AppColors.point,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
