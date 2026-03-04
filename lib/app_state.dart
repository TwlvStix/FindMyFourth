import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/utils/app_log.dart';

class AppState extends ChangeNotifier {
  static AppState _instance = AppState._internal();

  factory AppState() {
    return _instance;
  }

  AppState._internal();

  static void reset() {
    _instance = AppState._internal();
  }

  Future<void> initializePersistedState() async {
    if (_prefs != null) return; // Idempotency guard

    _prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      final stored = _prefs!.getString('cancelledGameHandlingByPath');
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          _cancelledGameHandlingByPath = decoded.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        }
      }
    }, 'cancelledGameHandlingByPath');
    _safeInit(() {
      final stored = _prefs!.getString('cancelledGameHideAtByPath');
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          _cancelledGameHideAtByPath = decoded.map(
            (key, value) => MapEntry(
              key,
              value is int ? value : int.tryParse(value.toString()) ?? 0,
            ),
          )..removeWhere((key, value) => value == 0);
        }
      }
    }, 'cancelledGameHideAtByPath');
    _safeInit(() {
      _hideFriendsOnlyGames = _prefs!.getBool('hideFriendsOnlyGames') ?? false;
    }, 'hideFriendsOnlyGames');
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  SharedPreferences? _prefs;
  bool get isInitialized => _prefs != null;

  Map<String, String> _cancelledGameHandlingByPath = {};
  String? getCancelledGameHandling(String gamePath) =>
      _cancelledGameHandlingByPath[gamePath];
  void setCancelledGameHandling(String gamePath, String handling) {
    if (_cancelledGameHandlingByPath[gamePath] == handling) return;
    _cancelledGameHandlingByPath[gamePath] = handling;
    if (_prefs == null) {
      AppLog.d('⚠️ AppState.setCancelledGameHandling: _prefs null, skipping persistence');
    }
    _prefs?.setString(
      'cancelledGameHandlingByPath',
      jsonEncode(_cancelledGameHandlingByPath),
    );
    notifyListeners();
  }

  Map<String, int> _cancelledGameHideAtByPath = {};
  DateTime? getCancelledGameHideAt(String gamePath) {
    final millis = _cancelledGameHideAtByPath[gamePath];
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  void setCancelledGameHideAt(String gamePath, DateTime hideAt) {
    final millis = hideAt.millisecondsSinceEpoch;
    if (_cancelledGameHideAtByPath[gamePath] == millis) return;
    _cancelledGameHideAtByPath[gamePath] = millis;
    if (_prefs == null) {
      AppLog.d('⚠️ AppState.setCancelledGameHideAt: _prefs null, skipping persistence');
    }
    _prefs?.setString(
      'cancelledGameHideAtByPath',
      jsonEncode(_cancelledGameHideAtByPath),
    );
    notifyListeners();
  }

  bool _hideFriendsOnlyGames = false;
  bool get hideFriendsOnlyGames => _hideFriendsOnlyGames;
  set hideFriendsOnlyGames(bool value) {
    if (_hideFriendsOnlyGames == value) return;
    _hideFriendsOnlyGames = value;
    if (_prefs == null) {
      AppLog.d('⚠️ AppState.hideFriendsOnlyGames: _prefs null, skipping persistence');
    }
    _prefs?.setBool('hideFriendsOnlyGames', value);
    notifyListeners();
  }
}

void _safeInit(Function() initializeField, String fieldName) {
  try {
    initializeField();
  } catch (e, stackTrace) {
    AppLog.d('❌ AppState._safeInit failed for $fieldName: $e');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AppState._safeInit failed for $fieldName',
        fatal: false,
      );
    }
  }
}
