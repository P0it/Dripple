import 'errors.dart';

/// The six things a player can ask the server to do on their turn.
///
/// Building and reordering a sentence is not among them. Those move cards
/// around inside one player's own view and change nothing anybody else can
/// see, so they stay on the device and only the finished sentence is sent.
sealed class GameAction {
  const GameAction();

  static GameAction fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    return switch (kind) {
      'draw' => DrawAction(fromDiscard: json['fromDiscard'] as bool? ?? false),
      'submit' => SubmitAction(
          cardIds: [
            for (final id in (json['cardIds'] as List? ?? const []))
              id as String,
          ],
        ),
      'discard' => DiscardAction(cardId: json['cardId'] as String),
      'pass' => const PassAction(),
      'jump' => JumpAction(cardId: json['cardId'] as String),
      'steal' => StealAction(
          cardId: json['cardId'] as String,
          targetSeat: json['targetSeat'] as int,
          giveCardId: json['giveCardId'] as String,
        ),
      _ => throw GameError('bad_action', 'unknown action: $kind'),
    };
  }
}

/// The one mandatory draw that opens a turn, from the deck or from the face-up
/// discard pile.
class DrawAction extends GameAction {
  final bool fromDiscard;
  const DrawAction({this.fromDiscard = false});
}

/// Play a sentence. The ids are in the order the cards were laid out.
class SubmitAction extends GameAction {
  final List<String> cardIds;
  const SubmitAction({required this.cardIds});
}

class DiscardAction extends GameAction {
  final String cardId;
  const DiscardAction({required this.cardId});
}

/// End the turn keeping everything drawn. A real move: only a completed
/// sentence takes cards out of a hand for good, so a growing hand is what a
/// long sentence is made of.
class PassAction extends GameAction {
  const PassAction();
}

class JumpAction extends GameAction {
  final String cardId;
  const JumpAction({required this.cardId});
}

class StealAction extends GameAction {
  final String cardId;
  final int targetSeat;
  final String giveCardId;
  const StealAction({
    required this.cardId,
    required this.targetSeat,
    required this.giveCardId,
  });
}
