import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      final stored = prefs.getString('cancelledGameHandlingByPath');
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
      final stored = prefs.getString('cancelledGameHideAtByPath');
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
      _hideFriendsOnlyGames = prefs.getBool('hideFriendsOnlyGames') ?? false;
    }, 'hideFriendsOnlyGames');
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  Map<String, String> _cancelledGameHandlingByPath = {};
  String? getCancelledGameHandling(String gamePath) =>
      _cancelledGameHandlingByPath[gamePath];
  void setCancelledGameHandling(String gamePath, String handling) {
    _cancelledGameHandlingByPath[gamePath] = handling;
    prefs.setString(
      'cancelledGameHandlingByPath',
      jsonEncode(_cancelledGameHandlingByPath),
    );
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
    _cancelledGameHideAtByPath[gamePath] = hideAt.millisecondsSinceEpoch;
    prefs.setString(
      'cancelledGameHideAtByPath',
      jsonEncode(_cancelledGameHideAtByPath),
    );
  }

  bool _hideFriendsOnlyGames = false;
  bool get hideFriendsOnlyGames => _hideFriendsOnlyGames;
  set hideFriendsOnlyGames(bool value) {
    _hideFriendsOnlyGames = value;
    prefs.setBool('hideFriendsOnlyGames', value);
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
