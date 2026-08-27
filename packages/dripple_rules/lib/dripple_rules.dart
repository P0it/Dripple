/// Dripple's rules, shared by the app and the online game server.
///
/// Everything here is pure Dart. Nothing in this package may import
/// `package:flutter/…` — that is the whole point of it being a package.
library;

export 'data/card_deck.dart';
export 'engine/ai/ai_player.dart';
export 'engine/grammar/grammar_engine.dart';
export 'engine/grammar/sentence_parser.dart';
export 'models/game_state.dart';
export 'models/player.dart';
export 'models/word_card.dart';
