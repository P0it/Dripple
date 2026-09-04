import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/table_scaffold.dart';
import '../core/design/app_spacing.dart';
import '../core/game_feedback.dart';
import '../core/haptic_manager.dart';
import '../core/sound_manager.dart';
import '../providers/theme_provider.dart';
import 'widgets/settings_tile.dart';

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
    final theme = ref.watch(themeChoiceProvider);

    return TableScaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          SettingsSection(
            title: l10n.display,
            tiles: [
              SettingsTile(
                title: l10n.theme,
                showDivider: false,
                below: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SegmentedButton<ThemeChoice>(
                    segments: [
                      ButtonSegment(
                        value: ThemeChoice.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeChoice.day,
                        label: Text(l10n.themeDay),
                      ),
                      ButtonSegment(
                        value: ThemeChoice.night,
                        label: Text(l10n.themeNight),
                      ),
                    ],
                    selected: {theme},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        ref.read(themeChoiceProvider.notifier).choose(s.first),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.audio,
            tiles: [
              SettingsTile(
                title: l10n.soundEffects,
                subtitle: l10n.soundEffectsDesc,
                trailing: Switch(
                  value: sound.sfxEnabled,
                  onChanged: (v) => setState(() => sound.sfxEnabled = v),
                ),
              ),
              SettingsTile(
                title: l10n.sfxVolume,
                below: Slider(
                  value: sound.sfxVolume,
                  onChanged: sound.sfxEnabled
                      ? (v) => setState(() => sound.sfxVolume = v)
                      : null,
                ),
              ),
              SettingsTile(
                title: l10n.backgroundMusic,
                subtitle: l10n.backgroundMusicDesc,
                trailing: Switch(
                  value: sound.musicEnabled,
                  onChanged: (v) => setState(() => sound.musicEnabled = v),
                ),
              ),
              SettingsTile(
                title: l10n.musicVolume,
                showDivider: false,
                below: Slider(
                  value: sound.musicVolume,
                  onChanged: sound.musicEnabled
                      ? (v) => setState(() => sound.musicVolume = v)
                      : null,
                ),
              ),
            ],
          ),
          SettingsSection(
            title: l10n.haptics,
            tiles: [
              SettingsTile(
                title: l10n.vibration,
                subtitle: l10n.vibrationDesc,
                showDivider: false,
                trailing: Switch(
                  value: haptic.enabled,
                  onChanged: (v) {
                    setState(() => haptic.enabled = v);
                    // Feel it immediately — a vibration setting you cannot
                    // feel is a setting you cannot check.
                    if (v) ref.read(gameFeedbackProvider).onButtonTap();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
