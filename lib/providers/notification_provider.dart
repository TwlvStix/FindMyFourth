import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/models/notification_preferences.dart';

/// NotificationProvider manages notification preferences with offline support
///
/// Features:
/// - Offline queue for preference changes
/// - Automatic sync when connectivity restored
/// - Real-time sync status tracking
/// - Error state management
enum SyncStatus { idle, saving, synced, offline, error }

class PendingUpdate {
  final NotificationPreferences prefs;
  final DateTime timestamp;

  PendingUpdate(this.prefs, this.timestamp);
}

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    _init();
  }

  // State
  NotificationPreferences _prefs = NotificationPreferences.defaults();
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _errorMessage;

  // Offline queue
  final Queue<PendingUpdate> _pendingUpdates = Queue();

  // Connectivity subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Getters
  NotificationPreferences get preferences => _prefs;
  SyncStatus get syncStatus => _syncStatus;
  String? get errorMessage => _errorMessage;
  bool get hasPendingUpdates => _pendingUpdates.isNotEmpty;

  void _init() {
    _listenToConnectivity();
    _loadPreferences();
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
  Future<void> _loadPreferences() async {
    if (currentUserUid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .get();

      final prefsMap = userDoc.data()?['notification_prefs'];
      if (prefsMap != null && prefsMap is Map) {
        _prefs = NotificationPreferences.fromMap(
          Map<String, dynamic>.from(prefsMap),
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notification preferences: $e');
      }
    }
  }

  /// Update preferences - queues if offline, saves immediately if online
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    _prefs = prefs;
    notifyListeners();

    // Check if online
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOffline = connectivityResults.every((result) => result == ConnectivityResult.none);

    if (isOffline) {
      // Queue for later
      _pendingUpdates.add(PendingUpdate(prefs, DateTime.now()));
      _syncStatus = SyncStatus.offline;
      notifyListeners();
      return;
    }

    // Save immediately
    await _saveToFirestore(prefs);
  }

  /// Save preferences to Firestore
  Future<void> _saveToFirestore(NotificationPreferences prefs) async {
    if (currentUserUid == null) {
      _syncStatus = SyncStatus.error;
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    _syncStatus = SyncStatus.saving;
    notifyListeners();

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid);

      await userRef.set({
        'notification_prefs': prefs.toFirestore(),
      }, SetOptions(merge: true));

      _syncStatus = SyncStatus.synced;
      _errorMessage = null;

      // Auto-hide synced status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_syncStatus == SyncStatus.synced) {
          _syncStatus = SyncStatus.idle;
          notifyListeners();
        }
      });
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error saving notification preferences: $e');
      }
    }

    notifyListeners();
  }

  /// Process all pending updates in the queue
  Future<void> processOfflineQueue() async {
    while (_pendingUpdates.isNotEmpty) {
      final update = _pendingUpdates.removeFirst();
      await _saveToFirestore(update.prefs);

      // If save failed, add back to queue and stop processing
      if (_syncStatus == SyncStatus.error) {
        _pendingUpdates.addFirst(update);
        break;
      }
    }
  }

  /// Clear error state
  void clearError() {
    _errorMessage = null;
    if (_syncStatus == SyncStatus.error) {
      _syncStatus = SyncStatus.idle;
    }
    notifyListeners();
  }

  /// Reload preferences from Firestore
  Future<void> reload() async {
    await _loadPreferences();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
