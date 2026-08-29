import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/haptic_manager.dart';
import 'core/sound_manager.dart';
import 'providers/online_providers.dart';
import 'services/player_identity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted audio and haptic settings before the first frame.
  // SoundManager and HapticManager are plain objects here (not yet wired to
  // Riverpod), so we initialise them once and pass the loaded values into the
  // providers via the ProviderScope overrides.
  final soundManager = SoundManager();
  final hapticManager = HapticManager();
  await Future.wait([soundManager.init(), hapticManager.init()]);

  // Who this device plays as. Read once here so screens can ask for it
  // without each of them awaiting the same preferences future.
  final identity = await PlayerIdentity.load();

  runApp(
    ProviderScope(
      overrides: [
        // Override with pre-initialised instances so settings are ready on
        // the first frame. Disposal is registered inside each provider's
        // overrideWith factory below so ref.onDispose still fires correctly.
        soundManagerProvider.overrideWith((ref) {
          ref.onDispose(soundManager.dispose);
          return soundManager;
        }),
        hapticManagerProvider.overrideWith((_) => hapticManager),
        playerIdentityProvider.overrideWithValue(identity),
      ],
      child: const DrippleApp(),
    ),
  );
}
