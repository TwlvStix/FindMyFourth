import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:find_my_fourth/vibe/premium_vibe_page/components/archetype_pairing_card.dart';
import 'package:find_my_fourth/utils/vibe_archetypes.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';

/// Short description that fits within the card without overflow
const _shortDescription = 'Short desc.';

/// Long description that definitely overflows the card's minHeight
const _longDescription =
    'This is a very long description that will definitely overflow the '
    'available space in the card. It keeps going and going with more text '
    'to ensure the TextPainter measures a height greater than the available '
    'space. We need enough content here to trigger the overflow detection '
    'logic and show the expand indicator. Adding even more text to be safe.';

VibeArchetypeMatch _buildArchetype({
  required String name,
  required String description,
  bool isWarden = false,
}) {
  final archetype = VibeArchetype(
    name: name,
    description: description,
    ideal: {
      VibeCategory.pace: 3,
      VibeCategory.competitive: 3,
      VibeCategory.drinking: 3,
      VibeCategory.chat: 3,
      VibeCategory.money: 3,
      VibeCategory.music: 3,
    },
  );
  return VibeArchetypeMatch(
    archetype: archetype,
    score: 0.8,
    isWarden: isWarden,
  );
}

void main() {
  group('ArchetypePairingCard overflow behavior', () {
    testWidgets('short description shows no expand indicator', (tester) async {
      final myArchetype = _buildArchetype(
        name: 'The Juggernaut',
        description: _shortDescription,
      );
      final theirArchetype = _buildArchetype(
        name: 'The Everyman',
        description: _shortDescription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: ArchetypePairingCard(
                myArchetype: myArchetype,
                theirArchetype: theirArchetype,
              ),
            ),
          ),
        ),
      );

      // Wait for post-frame callback to measure overflow
      await tester.pumpAndSettle();

      // Should NOT find expand icon when text doesn't overflow
      expect(
        find.byIcon(PhosphorIconsRegular.caretDown),
        findsNothing,
        reason: 'Short description should not show expand indicator',
      );
    });

    testWidgets('long description shows expand indicator when collapsed',
        (tester) async {
      final myArchetype = _buildArchetype(
        name: 'The High Roller',
        description: _longDescription,
      );
      final theirArchetype = _buildArchetype(
        name: 'The Everyman',
        description: _shortDescription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: ArchetypePairingCard(
                myArchetype: myArchetype,
                theirArchetype: theirArchetype,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find at least one expand icon for the overflowing card
      expect(
        find.byIcon(PhosphorIconsRegular.caretDown),
        findsWidgets,
        reason: 'Long description should show expand indicator',
      );
    });

    testWidgets('tapping long description card expands and shows collapse icon',
        (tester) async {
      final myArchetype = _buildArchetype(
        name: 'The High Roller',
        description: _longDescription,
      );
      final theirArchetype = _buildArchetype(
        name: 'The Everyman',
        description: _shortDescription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: ArchetypePairingCard(
                  myArchetype: myArchetype,
                  theirArchetype: theirArchetype,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the card with long description by its name (not the description text
      // which is behind IgnorePointer overlay)
      final archNameFinder = find.text('The High Roller');
      expect(archNameFinder, findsOneWidget);

      await tester.tap(archNameFinder);
      await tester.pumpAndSettle();

      // After expanding, should show collapse icon
      expect(
        find.byIcon(PhosphorIconsRegular.caretUp),
        findsOneWidget,
        reason: 'Expanded card should show collapse indicator',
      );
    });

    testWidgets('tapping short description card does not expand',
        (tester) async {
      final myArchetype = _buildArchetype(
        name: 'The Juggernaut',
        description: _shortDescription,
      );
      final theirArchetype = _buildArchetype(
        name: 'The Everyman',
        description: _shortDescription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: ArchetypePairingCard(
                myArchetype: myArchetype,
                theirArchetype: theirArchetype,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the card by archetype name and tap it
      final archNameFinder = find.text('The Juggernaut');
      expect(archNameFinder, findsOneWidget);

      await tester.tap(archNameFinder);
      await tester.pumpAndSettle();

      // Should NOT show collapse icon (card didn't expand because no overflow)
      expect(
        find.byIcon(PhosphorIconsRegular.caretUp),
        findsNothing,
        reason: 'Short description card should not expand on tap',
      );
    });

    testWidgets('second tap collapses expanded card', (tester) async {
      final myArchetype = _buildArchetype(
        name: 'The High Roller',
        description: _longDescription,
      );
      final theirArchetype = _buildArchetype(
        name: 'The Everyman',
        description: _shortDescription,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: ArchetypePairingCard(
                  myArchetype: myArchetype,
                  theirArchetype: theirArchetype,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First tap - expand (tap on name, not description which is behind overlay)
      final archNameFinder = find.text('The High Roller');
      await tester.tap(archNameFinder);
      await tester.pumpAndSettle();

      expect(
        find.byIcon(PhosphorIconsRegular.caretUp),
        findsOneWidget,
        reason: 'After first tap, should show collapse icon',
      );

      // Second tap - collapse
      await tester.tap(archNameFinder);
      await tester.pumpAndSettle();

      expect(
        find.byIcon(PhosphorIconsRegular.caretDown),
        findsWidgets,
        reason: 'After second tap, should show expand icon again',
      );
    });
  });
}
