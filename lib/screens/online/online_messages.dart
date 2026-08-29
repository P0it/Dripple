import 'package:dripple/l10n/app_localizations.dart';

import '../../services/online_client.dart';

/// Turn a refusal into something worth reading.
///
/// The server answers with a code rather than a sentence so that the sentence
/// can be in the player's own language — and so that a six-year-old is told
/// "it's not your turn yet" rather than shown an HTTP status.
String messageForError(AppLocalizations l10n, OnlineError error) {
  if (error.isOffline) return l10n.errorOffline;
  return switch (error.code) {
    'not_your_turn' => l10n.errorNotYourTurn,
    'room_full' => l10n.errorRoomFull,
    'no_such_room' => l10n.errorNoSuchRoom,
    'already_started' => l10n.errorAlreadyStarted,
    'offline' => l10n.errorOffline,
    _ => l10n.errorGeneric,
  };
}
