import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/theme/app_theme.dart';

/// Lobby screen for online/friend battles.
/// Shows room state, player list, and start button.
///
/// This screen requires a MultiplayerService implementation (Firebase)
/// to be functional. Currently shows the UI structure as a preview.
class LobbyScreen extends StatelessWidget {
  final String mode; // 'online' or 'friend'
  final int playerCount;

  const LobbyScreen({
    super.key,
    required this.mode,
    required this.playerCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = mode == 'online';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOnline ? l10n.onlineBattle : l10n.friendBattle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Room info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          isOnline ? 'Searching for players...' : 'Room Code',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!isOnline)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ABC-123',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (isOnline)
                          const SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Player slots
                Expanded(
                  child: ListView.builder(
                    itemCount: playerCount,
                    itemBuilder: (context, index) {
                      final isJoined = index == 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isJoined
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            child: Icon(
                              isJoined ? Icons.person : Icons.person_outline,
                              color: isJoined ? Colors.white : Colors.grey,
                            ),
                          ),
                          title: Text(
                            isJoined ? 'You' : 'Waiting...',
                            style: TextStyle(
                              fontWeight: isJoined
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isJoined
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: isJoined
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary)
                              : const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOnline
                              ? 'Waiting for $playerCount players to join...'
                              : 'Share the room code with your friends',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
