import 'package:flutter/foundation.dart';

class AppLog {
  const AppLog._();

  static String _redact(String message) {
    var safe = message;
    safe = safe.replaceAll(
      RegExp(r'(?i)bearer\s+[A-Za-z0-9\-\._~\+/]+=*'),
      'Bearer [REDACTED]',
    );
    safe = safe.replaceAll(
      RegExp(r'([?&](token|auth|password)=)[^&\s]+'),
      r'$1[REDACTED]',
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
