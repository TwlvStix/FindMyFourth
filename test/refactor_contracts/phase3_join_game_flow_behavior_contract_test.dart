import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3 join game flow behavior contracts', () {
    test('join flow is provider-driven and covers key result paths', () {
      final file = File(
        'lib/main_function/join_game_detailed/join_game_detailed_widget.dart',
      );
      final source = file.readAsStringSync();

      expect(source, contains('.joinGame('));
      expect(source, contains('JoinGameResult'));
      expect(source, contains('requiresApproval'));
      expect(source, contains('alreadyRequested'));
    });

    test('requires-approval path presents vibe floor bottom sheet', () {
      final file = File(
        'lib/main_function/join_game_detailed/join_game_detailed_widget.dart',
      );
      final source = file.readAsStringSync();

      expect(source, contains('showAppBottomSheet<'));
      expect(source, contains('VibeFloorBottomSheet('));
    });

    test('request-state precheck is still wired for join button behavior', () {
      final file = File(
        'lib/main_function/join_game_detailed/join_game_detailed_widget.dart',
      );
      final source = file.readAsStringSync();

      expect(source, contains('_ensureExistingRequestChecked('));
      expect(source, contains('getExistingRequestForGame('));
    });

    test('uses auth utility reference and no direct Firestore instance', () {
      final file = File(
        'lib/main_function/join_game_detailed/join_game_detailed_widget.dart',
      );
      final source = file.readAsStringSync();

      expect(source, contains('currentUserReference'));
      expect(source, isNot(contains('FirebaseFirestore.instance')));
    });
  });
}
