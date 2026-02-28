import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 0 group vibe wiring contracts', () {
    test('game joined detailed keeps provider-driven summary and breakdown',
        () {
      final file = File(
        'lib/main_function/game_joined_detailed/game_joined_detailed_widget.dart',
      );
      final source = file.readAsStringSync();

      expect(source, contains('context.watchGroupVibeProvider'));
      expect(source, contains('GroupVibeSummary('));
      expect(source, contains('groupVibeMatch: groupVibeMatch'));
      expect(source, contains('GroupVibeBreakdownSheet.show('));
      expect(source, contains('groupVibeProvider.compareMemberIds('));
    });

    test('join game detailed keeps provider-driven summary and breakdown', () {
      final file = File(
        'lib/main_function/join_game_detailed/join_game_detailed_widget.dart',
      );
      final source = file.readAsStringSync();

      expect(source, contains('context.watchGroupVibeProvider'));
      expect(source, contains('GroupVibeSummary('));
      expect(source, contains('groupVibeMatch: groupVibeMatch'));
      expect(source, contains('GroupVibeBreakdownSheet.show('));
      expect(source, contains('groupVibeProvider.compareMemberIds('));
    });
  });
}
