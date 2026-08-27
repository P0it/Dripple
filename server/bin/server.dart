import 'dart:io';

import 'package:dripple_server/dripple_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Run the game server.
///
/// Storage and identity are seams, and the Firebase-backed halves of both are
/// not written yet — they need a Firebase project, which does not exist. Until
/// then this runs entirely in memory, which is enough to play against from a
/// simulator on the same machine and nowhere near enough to deploy.
Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Every room disappears when this process does, and every token is believed.
  // Refusing to start without the flag is the whole guard against this
  // reaching anything real.
  final local = args.contains('--insecure-local');
  if (!local) {
    stderr.writeln(
      'No storage or identity backend is configured yet.\n'
      'Pass --insecure-local to run in memory, trusting every token.\n'
      'Do not do this anywhere a stranger can reach.',
    );
    exitCode = 78; // EX_CONFIG
    return;
  }

  final api = Api(
    service: GameService(store: InMemoryRoomStore()),
    verifier: const TrustingTokenVerifier(),
  );

  final server = await shelf_io.serve(api.handler, InternetAddress.anyIPv4, port);
  stdout.writeln('dripple server (in memory, trusting) on port ${server.port}');
}
