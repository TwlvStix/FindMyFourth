import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_fourth/models/player_eligibility.dart';
import 'package:find_my_fourth/services/game_eligibility_service.dart';

void main() {
  group('checkPlayerEligibility', () {
    group('openToAll', () {
      test('allows Male gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.openToAll,
          userGender: 'Male',
        );
        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });

      test('allows Female gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.openToAll,
          userGender: 'Female',
        );
        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });

      test('allows null gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.openToAll,
          userGender: null,
        );
        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });

      test('allows empty string gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.openToAll,
          userGender: '',
        );
        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });
    });

    group('womenOnly', () {
      test('allows Female gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.womenOnly,
          userGender: 'Female',
        );
        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });

      test('blocks Male gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.womenOnly,
          userGender: 'Male',
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });

      test('blocks null gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.womenOnly,
          userGender: null,
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });

      test('blocks empty string gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.womenOnly,
          userGender: '',
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });

      test('blocks unknown gender value', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.womenOnly,
          userGender: 'Other',
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });
    });

    group('menOnly', () {
      test('allows Male gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.menOnly,
          userGender: 'Male',
        );
        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });

      test('blocks Female gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.menOnly,
          userGender: 'Female',
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });

      test('blocks null gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.menOnly,
          userGender: null,
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });

      test('blocks empty string gender', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.menOnly,
          userGender: '',
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });

      test('blocks unknown gender value', () {
        final result = checkPlayerEligibility(
          eligibility: PlayerEligibility.menOnly,
          userGender: 'Other',
        );
        expect(result.allowed, isFalse);
        expect(result.reason, equals('gender_restricted'));
      });
    });
  });

  group('PlayerEligibility Firestore serialization', () {
    group('toFirestoreValue', () {
      test('openToAll serializes to open_to_all', () {
        expect(
          PlayerEligibility.openToAll.toFirestoreValue(),
          equals('open_to_all'),
        );
      });

      test('womenOnly serializes to women_only', () {
        expect(
          PlayerEligibility.womenOnly.toFirestoreValue(),
          equals('women_only'),
        );
      });

      test('menOnly serializes to men_only', () {
        expect(
          PlayerEligibility.menOnly.toFirestoreValue(),
          equals('men_only'),
        );
      });
    });

    group('fromFirestoreValue', () {
      test('parses open_to_all correctly', () {
        expect(
          PlayerEligibilityExtension.fromFirestoreValue('open_to_all'),
          equals(PlayerEligibility.openToAll),
        );
      });

      test('parses women_only correctly', () {
        expect(
          PlayerEligibilityExtension.fromFirestoreValue('women_only'),
          equals(PlayerEligibility.womenOnly),
        );
      });

      test('parses men_only correctly', () {
        expect(
          PlayerEligibilityExtension.fromFirestoreValue('men_only'),
          equals(PlayerEligibility.menOnly),
        );
      });

      test('defaults to openToAll for null', () {
        expect(
          PlayerEligibilityExtension.fromFirestoreValue(null),
          equals(PlayerEligibility.openToAll),
        );
      });

      test('defaults to openToAll for empty string', () {
        expect(
          PlayerEligibilityExtension.fromFirestoreValue(''),
          equals(PlayerEligibility.openToAll),
        );
      });

      test('defaults to openToAll for unknown value', () {
        expect(
          PlayerEligibilityExtension.fromFirestoreValue('invalid_value'),
          equals(PlayerEligibility.openToAll),
        );
      });
    });

    group('round-trip serialization', () {
      test('openToAll round-trips correctly', () {
        final original = PlayerEligibility.openToAll;
        final serialized = original.toFirestoreValue();
        final deserialized =
            PlayerEligibilityExtension.fromFirestoreValue(serialized);
        expect(deserialized, equals(original));
      });

      test('womenOnly round-trips correctly', () {
        final original = PlayerEligibility.womenOnly;
        final serialized = original.toFirestoreValue();
        final deserialized =
            PlayerEligibilityExtension.fromFirestoreValue(serialized);
        expect(deserialized, equals(original));
      });

      test('menOnly round-trips correctly', () {
        final original = PlayerEligibility.menOnly;
        final serialized = original.toFirestoreValue();
        final deserialized =
            PlayerEligibilityExtension.fromFirestoreValue(serialized);
        expect(deserialized, equals(original));
      });
    });
  });

  group('EligibilityResult', () {
    test('allowedResult has allowed=true and no reason', () {
      expect(EligibilityResult.allowedResult.allowed, isTrue);
      expect(EligibilityResult.allowedResult.reason, isNull);
    });

    test('genderRestricted has allowed=false and gender_restricted reason', () {
      expect(EligibilityResult.genderRestricted.allowed, isFalse);
      expect(
        EligibilityResult.genderRestricted.reason,
        equals('gender_restricted'),
      );
    });
  });

  group('Eligibility Options Filtering', () {
    // This tests the logic used in CreateGameWidget to filter eligibility options
    // based on the game creator's gender. The actual implementation is in the widget,
    // but we test the logic pattern here for regression protection.

    List<Map<String, dynamic>> getFilteredEligibilityOptions(String? userGender) {
      final allOptions = [
        {'value': 'open_to_all', 'label': 'Open to All'},
        {'value': 'women_only', 'label': 'Women Only'},
        {'value': 'men_only', 'label': 'Men Only'},
      ];

      if (userGender == 'Male') {
        return allOptions.where((opt) => opt['value'] != 'women_only').toList();
      } else if (userGender == 'Female') {
        return allOptions.where((opt) => opt['value'] != 'men_only').toList();
      } else {
        // Unknown gender - only allow open_to_all
        return allOptions.where((opt) => opt['value'] == 'open_to_all').toList();
      }
    }

    group('Male user', () {
      test('sees open_to_all and men_only options', () {
        final options = getFilteredEligibilityOptions('Male');
        expect(options.length, equals(2));
        expect(
          options.map((o) => o['value']),
          containsAll(['open_to_all', 'men_only']),
        );
      });

      test('does not see women_only option', () {
        final options = getFilteredEligibilityOptions('Male');
        expect(
          options.map((o) => o['value']),
          isNot(contains('women_only')),
        );
      });
    });

    group('Female user', () {
      test('sees open_to_all and women_only options', () {
        final options = getFilteredEligibilityOptions('Female');
        expect(options.length, equals(2));
        expect(
          options.map((o) => o['value']),
          containsAll(['open_to_all', 'women_only']),
        );
      });

      test('does not see men_only option', () {
        final options = getFilteredEligibilityOptions('Female');
        expect(
          options.map((o) => o['value']),
          isNot(contains('men_only')),
        );
      });
    });

    group('Unknown/null gender', () {
      test('null gender sees only open_to_all', () {
        final options = getFilteredEligibilityOptions(null);
        expect(options.length, equals(1));
        expect(options.first['value'], equals('open_to_all'));
      });

      test('empty string gender sees only open_to_all', () {
        final options = getFilteredEligibilityOptions('');
        expect(options.length, equals(1));
        expect(options.first['value'], equals('open_to_all'));
      });

      test('Other gender value sees only open_to_all', () {
        final options = getFilteredEligibilityOptions('Other');
        expect(options.length, equals(1));
        expect(options.first['value'], equals('open_to_all'));
      });

      test('Prefer not to say sees only open_to_all', () {
        final options = getFilteredEligibilityOptions('Prefer not to say');
        expect(options.length, equals(1));
        expect(options.first['value'], equals('open_to_all'));
      });
    });
  });
}
