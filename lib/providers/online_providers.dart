import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/online_client.dart';
import '../services/player_identity.dart';

/// Where the game server lives.
///
/// Overridden at startup from --dart-define=DRIPPLE_SERVER=..., which is how
/// a simulator reaches a server running on the same machine without the URL
/// being compiled in.
final serverUrlProvider = Provider<Uri>((ref) {
  const configured = String.fromEnvironment(
    'DRIPPLE_SERVER',
    defaultValue: 'http://localhost:8080',
  );
  return Uri.parse(configured);
});

/// This device's player, once shared_preferences has been read.
///
/// Overridden in main() so the rest of the app can read it synchronously
/// rather than every screen awaiting the same future.
final playerIdentityProvider = Provider<PlayerIdentity>(
  (ref) => throw StateError('playerIdentityProvider was not initialised'),
);

/// The player's chosen name, or null if they have never gone online.
///
/// Held here rather than read from preferences at each use so that setting it
/// rebuilds the screens that show it.
final playerNameProvider = StateProvider<String?>(
  (ref) => ref.watch(playerIdentityProvider).name,
);

final onlineClientProvider = Provider<OnlineClient>((ref) {
  final identity = ref.watch(playerIdentityProvider);
  final client = OnlineClient(
    baseUrl: ref.watch(serverUrlProvider),
    token: identity.uid,
  );
  ref.onDispose(client.dispose);
  return client;
});
