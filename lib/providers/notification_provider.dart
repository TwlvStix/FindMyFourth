import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '/core/utils/app_log.dart';
import '/models/notification_preferences.dart';

/// NotificationProvider manages notification preferences with offline support
///
/// Features:
/// - Offline queue for preference changes
/// - Automatic sync when connectivity restored
/// - Real-time sync status tracking
/// - Error state management
/// - Backend error monitoring
enum SyncStatus { idle, saving, synced, offline, error }

class PendingUpdate {
  final NotificationPreferences prefs;
  final DateTime timestamp;

  PendingUpdate(this.prefs, this.timestamp);
}

class NotificationError {
  final String message;
  final String? code;
  final DateTime timestamp;
  final String type;

  NotificationError({
    required this.message,
    this.code,
    required this.timestamp,
    required this.type,
  });

  factory NotificationError.fromMap(Map<String, dynamic> map) {
    return NotificationError(
      message: map['message'] as String? ?? 'Unknown error',
      code: map['code'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] as String? ?? 'unknown',
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    _init();
  }

  // State
  NotificationPreferences _prefs = NotificationPreferences.defaults();
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _errorMessage;
  NotificationError? _lastBackendError;
  bool _disposed = false;

  // Offline queue
  final Queue<PendingUpdate> _pendingUpdates = Queue();

  // Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Auth state tracking
  StreamSubscription<User?>? _authSubscription;
  String? _activeUid;

  // Getters
  NotificationPreferences get preferences => _prefs;
  SyncStatus get syncStatus => _syncStatus;
  String? get errorMessage => _errorMessage;
  NotificationError? get lastBackendError => _lastBackendError;
  bool get hasPendingUpdates => _pendingUpdates.isNotEmpty;

  void _init() {
    _listenToConnectivity();
    _listenToAuthState();
  }

  /// Listen to auth state changes and manage UID transitions
  void _listenToAuthState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        final newUid = user?.uid;
        final oldUid = _activeUid;

        // No change in UID - nothing to do
        if (newUid == oldUid) return;

        // Update active UID
        _activeUid = newUid;

        if (newUid != null) {
          // User logged in or switched - load their preferences
          _loadPreferences(newUid);
          _checkBackendErrors(newUid);
        } else {
          // User logged out - reset to defaults
          _clearState();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          AppLog.d('❌ NotificationProvider._listenToAuthState error: $error');
        }
      },
    );
  }

  /// Clear all state on logout
  void _clearState() {
    _prefs = NotificationPreferences.defaults();
    _syncStatus = SyncStatus.idle;
    _errorMessage = null;
    _lastBackendError = null;
    _pendingUpdates.clear();
    notifyListeners();
  }

  /// Listen for connectivity changes and process queue when online
  void _listenToConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.every((result) => result == ConnectivityResult.none);

      if (!isOffline && _pendingUpdates.isNotEmpty) {
        processOfflineQueue();
      }
    });
  }

  /// Load current preferences from Firestore
  Future<void> _loadPreferences(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Stale result guard - UID changed during await
      if (_activeUid != uid) return;

      final prefsMap = userDoc.data()?['notification_prefs'];
      if (prefsMap != null && prefsMap is Map) {
        _prefs = NotificationPreferences.fromMap(
          Map<String, dynamic>.from(prefsMap),
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        AppLog.d('❌ NotificationProvider._loadPreferences error: $e');
      }
    }
  }

  /// Update preferences - queues if offline, saves immediately if online
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    final uid = _activeUid;
    if (uid == null) return; // Not logged in

    _prefs = prefs;
    notifyListeners();

    // Check if online
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOffline = connectivityResults.every((result) => result == ConnectivityResult.none);

    // UID changed during await
    if (_activeUid != uid) return;

    if (isOffline) {
      // Queue for later
      _pendingUpdates.add(PendingUpdate(prefs, DateTime.now()));
      _syncStatus = SyncStatus.offline;
      notifyListeners();
      return;
    }

    // Save immediately
    await _saveToFirestore(prefs, uid);
  }

  /// Save preferences to Firestore
  Future<void> _saveToFirestore(NotificationPreferences prefs, String uid) async {
    _syncStatus = SyncStatus.saving;
    notifyListeners();

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      await userRef.set({
        'notification_prefs': prefs.toFirestore(),
      }, SetOptions(merge: true));

      // Stale result guard - UID changed during await
      if (_activeUid != uid) return;

      _syncStatus = SyncStatus.synced;
      _errorMessage = null;

      // Auto-hide synced status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_disposed) return;
        if (_activeUid != uid) return; // Also guard the delayed callback
        if (_syncStatus == SyncStatus.synced) {
          _syncStatus = SyncStatus.idle;
          notifyListeners();
        }
      });
    } catch (e) {
      // Stale result guard
      if (_activeUid != uid) return;

      _syncStatus = SyncStatus.error;
      _errorMessage = e.toString();
      if (kDebugMode) {
        AppLog.d('❌ NotificationProvider._saveToFirestore error: $e');
      }
    }

    notifyListeners();
  }

  /// Process all pending updates in the queue
  Future<void> processOfflineQueue() async {
    final uid = _activeUid;
    if (uid == null) {
      _pendingUpdates.clear(); // Clear queue if logged out
      return;
    }

    while (_pendingUpdates.isNotEmpty) {
      final update = _pendingUpdates.removeFirst();

      // Check UID still valid before each save
      if (_activeUid != uid) {
        _pendingUpdates.clear();
        return;
      }

      await _saveToFirestore(update.prefs, uid);

      // If save failed, add back to queue and stop processing
      if (_syncStatus == SyncStatus.error) {
        _pendingUpdates.addFirst(update);
        break;
      }
    }
  }

  /// Check for backend errors (e.g., notification send failures)
  Future<void> _checkBackendErrors(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Stale result guard - UID changed during await
      if (_activeUid != uid) return;

      final errorData = userDoc.data()?['notification_state']?['last_error'];
      if (errorData != null && errorData is Map) {
        final error = NotificationError.fromMap(
          Map<String, dynamic>.from(errorData),
        );

        // Only show if within last 24 hours
        final hoursSinceError = DateTime.now().difference(error.timestamp).inHours;
        if (hoursSinceError < 24) {
          _lastBackendError = error;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLog.d('❌ NotificationProvider._checkBackendErrors error: $e');
      }
    }
  }

  /// Clear error state
  void clearError() {
    _errorMessage = null;
    _lastBackendError = null;
    if (_syncStatus == SyncStatus.error) {
      _syncStatus = SyncStatus.idle;
    }
    notifyListeners();
  }

  /// Reload preferences from Firestore
  Future<void> reload() async {
    final uid = _activeUid;
    if (uid == null) return;

    await _loadPreferences(uid);
    await _checkBackendErrors(uid);
  }

  // ========================================
  // GRANULAR UPDATE METHODS
  // ========================================

  /// Apply a notification profile preset, preserving quiet hours and muted threads.
  Future<void> applyProfile(NotificationProfile profile) async {
    final profilePrefs = NotificationPreferences.fromProfile(profile);

    // Preserve quiet hours config and muted threads from current prefs
    final newPrefs = profilePrefs.copyWith(
      quietHours: _prefs.quietHours,
      mutedThreads: _prefs.mutedThreads,
    );

    await updatePreferences(newPrefs);
  }

  /// Update game alert settings.
  Future<void> updateGameAlerts({
    bool? enabled,
    DeliveryFrequency? delivery,
  }) async {
    final newGameAlerts = _prefs.gameAlerts.copyWith(
      enabled: enabled,
      deliveryFrequency: delivery,
    );

    var newPrefs = _prefs.copyWith(gameAlerts: newGameAlerts);

    // Recalculate active profile
    final detectedProfile = newPrefs.detectActiveProfile();
    newPrefs = newPrefs.copyWith(
      activeProfile: detectedProfile,
      clearActiveProfile: detectedProfile == null,
    );

    await updatePreferences(newPrefs);
  }

  /// Update chat alert settings.
  Future<void> updateChatAlerts({
    bool? enabled,
    DeliveryFrequency? delivery,
  }) async {
    final newChatAlerts = _prefs.chatAlerts.copyWith(
      enabled: enabled,
      deliveryFrequency: delivery,
    );

    var newPrefs = _prefs.copyWith(chatAlerts: newChatAlerts);

    // Recalculate active profile
    final detectedProfile = newPrefs.detectActiveProfile();
    newPrefs = newPrefs.copyWith(
      activeProfile: detectedProfile,
      clearActiveProfile: detectedProfile == null,
    );

    await updatePreferences(newPrefs);
  }

  /// Update trust category settings.
  /// When enabled=false, sub-toggle states are preserved for restore on re-enable.
  Future<void> updateTrustCategories({
    bool? enabled,
    bool? postRound,
    bool? trustAlerts,
    bool? badges,
    DeliveryFrequency? delivery,
  }) async {
    final newTrustCategories = _prefs.trustCategories.copyWith(
      enabled: enabled,
      postRound: postRound,
      trustAlerts: trustAlerts,
      badges: badges,
      deliveryFrequency: delivery,
    );

    var newPrefs = _prefs.copyWith(trustCategories: newTrustCategories);

    // Recalculate active profile
    final detectedProfile = newPrefs.detectActiveProfile();
    newPrefs = newPrefs.copyWith(
      activeProfile: detectedProfile,
      clearActiveProfile: detectedProfile == null,
    );

    await updatePreferences(newPrefs);
  }

  /// Update quiet hours settings.
  Future<void> updateQuietHours({
    bool? enabled,
    String? start,
    String? end,
    List<int>? activeDays,
  }) async {
    final newQuietHours = _prefs.quietHours.copyWith(
      enabled: enabled,
      start: start,
      end: end,
      activeDays: activeDays,
    );

    var newPrefs = _prefs.copyWith(quietHours: newQuietHours);

    // Recalculate active profile (quiet hours don't affect profile detection)
    final detectedProfile = newPrefs.detectActiveProfile();
    newPrefs = newPrefs.copyWith(
      activeProfile: detectedProfile,
      clearActiveProfile: detectedProfile == null,
    );

    await updatePreferences(newPrefs);
  }

  /// Update social alerts settings.
  Future<void> updateSocialAlerts({bool? enabled}) async {
    final newSocialAlerts = _prefs.socialAlerts.copyWith(enabled: enabled);

    var newPrefs = _prefs.copyWith(socialAlerts: newSocialAlerts);

    // Recalculate active profile
    final detectedProfile = newPrefs.detectActiveProfile();
    newPrefs = newPrefs.copyWith(
      activeProfile: detectedProfile,
      clearActiveProfile: detectedProfile == null,
    );

    await updatePreferences(newPrefs);
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
