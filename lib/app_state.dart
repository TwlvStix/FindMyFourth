import 'package:flutter/material.dart';
import 'core/request_manager.dart';
import '/backend/backend.dart';
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
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _theusernames = '';
  String get theusernames => _theusernames;
  set theusernames(String value) {
    _theusernames = value;
  }

  String _erorImagePlaceholderUrl =
      'https://plus.unsplash.com/premium_photo-1680553492268-516537c44d91?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
  String get erorImagePlaceholderUrl => _erorImagePlaceholderUrl;
  set erorImagePlaceholderUrl(String value) {
    _erorImagePlaceholderUrl = value;
    prefs.setString('errorImagePlaceholderUrl', value);
  }

  final _getCoursesManager = StreamRequestManager<List<CourseRecord>>();
  Stream<List<CourseRecord>> getCourses({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Stream<List<CourseRecord>> Function() requestFn,
  }) =>
      _getCoursesManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearGetCoursesCache() => _getCoursesManager.clear();
  void clearGetCoursesCacheKey(String? uniqueKey) =>
      _getCoursesManager.clearRequest(uniqueKey);

  final _userDocQueryManager = FutureRequestManager<UsersRecord>();
  Future<UsersRecord> userDocQuery({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<UsersRecord> Function() requestFn,
  }) =>
      _userDocQueryManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearUserDocQueryCache() => _userDocQueryManager.clear();
  void clearUserDocQueryCacheKey(String? uniqueKey) =>
      _userDocQueryManager.clearRequest(uniqueKey);
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
