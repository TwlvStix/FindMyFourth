import 'dart:async';

import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/app_log.dart';
import '/services/block_service.dart';

/// Provides cached blocked user state for the app.
///
/// Streams blocked user IDs from Firestore and maintains a local set
/// for O(1) lookups used by client-side filtering.
///
/// Auto-initializes on auth state changes via Firebase Auth listener.
class BlockProvider extends ChangeNotifier {
  BlockProvider({BlockService? service})
      : _service = service ?? BlockService() {
    _authSubscription = authUidStream.listen(_onAuthChanged);
  }

  final BlockService _service;

  Set<String> _blockedUserIds = {};
  StreamSubscription<Set<String>>? _streamSubscription;
  StreamSubscription<String?>? _authSubscription;
  Timer? _notifyTimer;
  bool _disposed = false;
  String? _currentUid;

  /// The set of blocked user IDs. Empty until auth completes.
  Set<String> get blockedUserIds => _blockedUserIds;

  /// Whether a specific user is blocked.
  bool isBlocked(String uid) => _blockedUserIds.contains(uid);

  void _onAuthChanged(String? uid) {
    if (uid != null) {
      _loadBlockedUsers(uid);
    } else {
      _clear();
    }
  }

  /// Initialize blocked users for the authenticated user.
  Future<void> _loadBlockedUsers(String uid) async {
    if (_currentUid == uid) return;
    _currentUid = uid;

    // Cancel previous stream
    _streamSubscription?.cancel();

    // Initial fetch
    try {
      _blockedUserIds = await _service.getBlockedUserIds(uid);
      _scheduleNotify();
    } catch (e) {
      AppLog.d('❌ BlockProvider._loadBlockedUsers error: $e');
    }

    // Real-time stream
    _streamSubscription = _service.streamBlockedUserIds(uid).listen(
      (ids) {
        if (_disposed) return;
        if (!setEquals(_blockedUserIds, ids)) {
          _blockedUserIds = ids;
          _scheduleNotify();
        }
      },
      onError: (e) {
        AppLog.d('❌ BlockProvider stream error: $e');
      },
    );
  }

  /// Block a user. Updates local state immediately, then persists.
  Future<void> blockUser({
    required String currentUid,
    required String blockedUid,
  }) async {
    _blockedUserIds = {..._blockedUserIds, blockedUid};
    _scheduleNotify();

    try {
      await _service.blockUser(
        currentUid: currentUid,
        blockedUid: blockedUid,
      );
    } catch (e) {
      // Revert on failure
      _blockedUserIds = {..._blockedUserIds}..remove(blockedUid);
      _scheduleNotify();
      AppLog.d('❌ BlockProvider.blockUser error: $e');
      rethrow;
    }
  }

  /// Unblock a user. Updates local state immediately, then persists.
  Future<void> unblockUser({
    required String currentUid,
    required String blockedUid,
  }) async {
    _blockedUserIds = {..._blockedUserIds}..remove(blockedUid);
    _scheduleNotify();

    try {
      await _service.unblockUser(
        currentUid: currentUid,
        blockedUid: blockedUid,
      );
    } catch (e) {
      // Revert on failure
      _blockedUserIds = {..._blockedUserIds, blockedUid};
      _scheduleNotify();
      AppLog.d('❌ BlockProvider.unblockUser error: $e');
      rethrow;
    }
  }

  /// Clear state on sign-out.
  void _clear() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _currentUid = null;
    _blockedUserIds = {};
    _scheduleNotify();
  }

  void _scheduleNotify() {
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _streamSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
