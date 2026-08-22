import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dripple/core/game_icons.dart';

/// Renders every icon to a golden-style PNG so the shapes can be eyeballed.
void main() {
  testWidgets('render all icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                for (final icon in GameIcon.values)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameIconView(icon, size: 64,
                          color: const Color(0xFF1F2937)),
                      const SizedBox(height: 4),
                      Text(icon.name, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('icons_preview.png'),
    );
  });
}
