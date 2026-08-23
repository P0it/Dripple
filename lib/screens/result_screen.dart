import 'package:flutter/material.dart';
import '../core/game_icons.dart';
import 'package:dripple/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final ranking = gameState.ranking;

    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.gameOver,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Podium
              Expanded(
                child: _Podium(ranking: ranking),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)!.home),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/mode-select'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.point,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)!.playAgain),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<Player> ranking;

  const _Podium({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: ranking.length,
      itemBuilder: (context, index) {
        final player = ranking[index];
        final isWinner = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isWinner ? Colors.white : Colors.white.withAlpha(179),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _rankColor(index),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isWinner ? 18 : 16,
                          ),
                        ),
                        if (isWinner) ...[
                          const SizedBox(width: 8),
                          const GameIconView(GameIcon.crown,
                              size: 20, color: Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    Text(
                      '${player.score} pts',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Text(
                '${player.score}',
                style: TextStyle(
                  fontSize: isWinner ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.point,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.pts,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}
