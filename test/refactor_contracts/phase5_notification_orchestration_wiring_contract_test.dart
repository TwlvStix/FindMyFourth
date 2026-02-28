import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5 notification orchestration wiring contracts', () {
    test(
        'main.dart delegates auth-change notification lifecycle to orchestration service',
        () {
      final file = File('lib/main.dart');
      final source = file.readAsStringSync();

      expect(source, contains('NotificationOrchestrationService'));
      expect(
        source,
        contains(
            'unawaited(_notificationOrchestrationService.onUserChanged(newUid));'),
      );

      expect(source, isNot(contains('FcmNotificationService().dispose();')));
      expect(
        source,
        isNot(contains('NotificationPermissionService().reset();')),
      );
      expect(
          source, isNot(contains('await LocalNotificationsService().init();')));
      expect(source, isNot(contains('await FcmNotificationService().init();')));
    });

    test('router imports NavBarPage from dedicated file', () {
      final file = File('lib/core/navigation/app_router.dart');
      final source = file.readAsStringSync();

      expect(source, contains("import '/core/navigation/nav_bar_page.dart';"));
      expect(source, isNot(contains("import '/main.dart';")));
      expect(source, contains('NavBarPage('));
    });

    test('main.dart no longer declares NavBarPage', () {
      final file = File('lib/main.dart');
      final source = file.readAsStringSync();

      expect(
          source, isNot(contains('class NavBarPage extends StatefulWidget')));
      expect(source,
          isNot(contains('class _NavBarPageState extends State<NavBarPage>')));
    });
  });
}
