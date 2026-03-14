import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/utils/search_token_utils.dart';

void main() {
  group('SearchTokenUtils.generateSearchTokens', () {
    test('generates all substrings of a single word', () {
      final tokens = SearchTokenUtils.generateSearchTokens('jshew');
      // 5-char word → 10 tokens (lengths 2-5 from each start position)
      expect(tokens, containsAll(['js', 'jsh', 'jshe', 'jshew']));
      expect(tokens, containsAll(['sh', 'she', 'shew']));
      expect(tokens, containsAll(['he', 'hew']));
      expect(tokens, containsAll(['ew']));
      expect(tokens.length, 10);
    });

    test('handles multi-word display name', () {
      final tokens = SearchTokenUtils.generateSearchTokens('John Doe');
      expect(tokens, contains('jo'));
      expect(tokens, contains('john'));
      expect(tokens, contains('oh'));
      expect(tokens, contains('do'));
      expect(tokens, contains('doe'));
      expect(tokens, contains('oe'));
    });

    test('includes tokens from firstName and lastName', () {
      final tokens = SearchTokenUtils.generateSearchTokens(
        'jshew',
        firstName: 'Jay',
        lastName: 'Shew',
      );
      expect(tokens, contains('ja'));
      expect(tokens, contains('jay'));
      expect(tokens, contains('ay'));
      expect(tokens, contains('sh'));
      expect(tokens, contains('shew'));
    });

    test('deduplicates tokens across name fields', () {
      final tokens = SearchTokenUtils.generateSearchTokens(
        'shew',
        firstName: 'Shew',
      );
      // "shew" appears in both display_name and firstName but tokens should be unique
      final uniqueTokens = tokens.toSet();
      expect(tokens.length, uniqueTokens.length);
    });

    test('returns sorted tokens', () {
      final tokens = SearchTokenUtils.generateSearchTokens('zab');
      expect(tokens, orderedEquals(List.of(tokens)..sort()));
    });

    test('returns empty list for empty input', () {
      final tokens = SearchTokenUtils.generateSearchTokens('');
      expect(tokens, isEmpty);
    });

    test('returns empty list for single character', () {
      final tokens = SearchTokenUtils.generateSearchTokens('A');
      expect(tokens, isEmpty);
    });

    test('handles whitespace-only input', () {
      final tokens = SearchTokenUtils.generateSearchTokens('   ');
      expect(tokens, isEmpty);
    });

    test('is case insensitive', () {
      final upper = SearchTokenUtils.generateSearchTokens('JOHN');
      final lower = SearchTokenUtils.generateSearchTokens('john');
      expect(upper, equals(lower));
    });

    test('respects custom minLength', () {
      final tokens = SearchTokenUtils.generateSearchTokens(
        'abc',
        minLength: 3,
      );
      expect(tokens, equals(['abc']));
    });

    test('substring search finds partial matches', () {
      // Simulates the query: search "shew" should match user "jshew"
      final userTokens = SearchTokenUtils.generateSearchTokens('jshew');
      expect(userTokens, contains('shew'));
    });
  });
}
