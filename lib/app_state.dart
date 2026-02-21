import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _erorImagePlaceholderUrl =
          prefs.getString('errorImagePlaceholderUrl') ??
              _erorImagePlaceholderUrl;
    });
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
    });
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
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _erorImagePlaceholderUrl =
      'https://plus.unsplash.com/premium_photo-1680553492268-516537c44d91?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
  String get erorImagePlaceholderUrl => _erorImagePlaceholderUrl;
  set erorImagePlaceholderUrl(String value) {
    _erorImagePlaceholderUrl = value;
    prefs.setString('errorImagePlaceholderUrl', value);
  }

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
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}
