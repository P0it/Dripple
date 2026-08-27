import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dripple_rules/engine/game_engine.dart';
import 'package:dripple_rules/models/game_state.dart';

/// The turn logic itself lives in `dripple_rules` so the online game server
/// runs the same code the app plays by. This file is only the Riverpod seam.
export 'package:dripple_rules/engine/game_engine.dart' show GameNotifier, JudgmentResult;

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
