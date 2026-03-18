import 'package:flutter_test/flutter_test.dart';

import 'package:find_my_fourth/core/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer.sanitize', () {
    test('returns null for null input', () {
      expect(InputSanitizer.sanitize(null), isNull);
    });

    test('trims leading and trailing whitespace', () {
      expect(InputSanitizer.sanitize('  hello  '), equals('hello'));
    });

    test('truncates to maxLength', () {
      expect(
        InputSanitizer.sanitize('abcdef', maxLength: 3),
        equals('abc'),
      );
    });

    test('trims before truncating', () {
      expect(
        InputSanitizer.sanitize('  ab  ', maxLength: 1),
        equals('a'),
      );
    });

    test('returns empty string for empty input', () {
      expect(InputSanitizer.sanitize(''), equals(''));
    });

    test('returns whitespace-only input as empty string', () {
      expect(InputSanitizer.sanitize('   '), equals(''));
    });

    test('does not truncate when within maxLength', () {
      expect(
        InputSanitizer.sanitize('hello', maxLength: 10),
        equals('hello'),
      );
    });

    test('uses default maxLength of 500', () {
      final longString = 'a' * 600;
      expect(InputSanitizer.sanitize(longString)!.length, equals(500));
    });
  });

  group('Convenience methods', () {
    test('displayName enforces max 30 chars', () {
      final long = 'a' * 50;
      expect(InputSanitizer.displayName(long)!.length, equals(30));
    });

    test('firstName enforces max 50 chars', () {
      final long = 'a' * 60;
      expect(InputSanitizer.firstName(long)!.length, equals(50));
    });

    test('lastName enforces max 50 chars', () {
      final long = 'a' * 60;
      expect(InputSanitizer.lastName(long)!.length, equals(50));
    });

    test('gameName enforces max 100 chars', () {
      final long = 'a' * 150;
      expect(InputSanitizer.gameName(long)!.length, equals(100));
    });

    test('chatMessage enforces max 2000 chars', () {
      final long = 'a' * 2500;
      expect(InputSanitizer.chatMessage(long)!.length, equals(2000));
    });

    test('bio enforces max 500 chars', () {
      final long = 'a' * 600;
      expect(InputSanitizer.bio(long)!.length, equals(500));
    });

    test('golfCanadaNumber enforces max 20 chars', () {
      final long = 'a' * 30;
      expect(InputSanitizer.golfCanadaNumber(long)!.length, equals(20));
    });

    test('phoneNumber enforces max 15 chars', () {
      final long = '1' * 20;
      expect(InputSanitizer.phoneNumber(long)!.length, equals(15));
    });

    test('username enforces max 30 chars', () {
      final long = 'a' * 40;
      expect(InputSanitizer.username(long)!.length, equals(30));
    });

    test('all convenience methods return null for null input', () {
      expect(InputSanitizer.displayName(null), isNull);
      expect(InputSanitizer.firstName(null), isNull);
      expect(InputSanitizer.lastName(null), isNull);
      expect(InputSanitizer.gameName(null), isNull);
      expect(InputSanitizer.chatMessage(null), isNull);
      expect(InputSanitizer.bio(null), isNull);
      expect(InputSanitizer.golfCanadaNumber(null), isNull);
      expect(InputSanitizer.phoneNumber(null), isNull);
      expect(InputSanitizer.username(null), isNull);
    });

    test('all convenience methods trim whitespace', () {
      expect(InputSanitizer.displayName('  test  '), equals('test'));
      expect(InputSanitizer.firstName('  test  '), equals('test'));
      expect(InputSanitizer.gameName('  test  '), equals('test'));
      expect(InputSanitizer.chatMessage('  test  '), equals('test'));
      expect(InputSanitizer.bio('  test  '), equals('test'));
      expect(InputSanitizer.phoneNumber('  123  '), equals('123'));
    });
  });
}
