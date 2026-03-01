import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fix #7 no direct backend calls from UI contract', () {
    test('widgets and screens avoid direct Firebase instance usage', () {
      const forbiddenPatterns = <String>[
        'FirebaseFirestore.instance',
        'FirebaseAuth.instance',
        'FirebaseFunctions.instance',
        '.runTransaction(',
      ];

      const exceptions = <String>{};

      // auth_util convenience getters are allowed in UI; we only ban direct
      // Firebase instance access patterns listed above.
      final uiFiles =
          Directory('lib').listSync(recursive: true).whereType<File>().where(
                (file) =>
                    file.path.endsWith('_widget.dart') ||
                    file.path.endsWith('_screen.dart'),
              );

      for (final file in uiFiles) {
        final path = file.path.replaceAll('\\', '/');
        if (exceptions.contains(path)) {
          continue;
        }
        final source = file.readAsStringSync();

        for (final pattern in forbiddenPatterns) {
          expect(
            source,
            isNot(contains(pattern)),
            reason: '$path contains forbidden pattern: $pattern',
          );
        }
      }
    });
  });
}
