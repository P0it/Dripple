import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Character placeholder
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(77),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'DRIPPLE',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Word Card Battle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/mode-select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'PLAY',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _navButton(Icons.person, 'Character'),
                    const SizedBox(width: 24),
                    _navButton(Icons.leaderboard, 'Ranking'),
                    const SizedBox(width: 24),
                    _navButton(Icons.settings, 'Settings'),
                  ],
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(icon, color: Colors.white, size: 28),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
