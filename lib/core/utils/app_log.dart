import 'package:flutter/foundation.dart';

class AppLog {
  const AppLog._();

  static String _redact(String message) {
    var safe = message;
    safe = safe.replaceAll(
      RegExp(r'bearer\s+[A-Za-z0-9\-\._~\+/]+=*', caseSensitive: false),
      'Bearer [REDACTED]',
    );
    safe = safe.replaceAll(
      RegExp(r'([?&](token|auth|password)=)[^&\s]+'),
      r'$1[REDACTED]',
    );
    safe = safe.replaceAllMapped(
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
      (m) {
        final email = m.group(0)!;
        return '${email[0]}***@***.${email.split('.').last}';
      },
    );
    return safe;
  }

  static void d(String message) {
    assert(() {
      debugPrint(_redact(message));
      return true;
    }());
  }
}
