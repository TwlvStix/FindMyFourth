import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/core/utils/app_log.dart';
import '/core/utils/production_log.dart';
import '/services/notification_crud_service.dart';

/// Lightweight domain model for notification list items.
///
/// Maps Firestore notification documents to typed fields for UI consumption.
/// Keeps [reference] internal for mutation operations.
class NotificationListItem {
  final String id;
  final String type;
  final String? title;
  final String? body;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> data;
  final DocumentReference reference;

  NotificationListItem._({
    required this.id,
    required this.type,
    this.title,
    this.body,
    required this.isRead,
    this.createdAt,
    required this.data,
    required this.reference,
  });

  factory NotificationListItem.fromDoc(QueryDocumentSnapshot doc) {
    final raw = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationListItem._(
      id: doc.id,
      type: (raw['type'] as String?) ?? '',
      title: raw['title'] as String?,
      body: raw['body'] as String?,
      isRead: raw['read'] == true,
      createdAt: (raw['createdAt'] as Timestamp?)?.toDate(),
      data: (raw['data'] as Map?)?.cast<String, dynamic>() ?? {},
      reference: doc.reference,
    );
  }
}

/// Immutable snapshot of notification list state for selector consumption.
///
/// Equality based on list identity (not deep) + primitive flags.
/// Provider caches unmodifiable list reference to ensure stable comparisons.
class NotificationListViewState {
  final List<NotificationListItem> notifications;
  final bool hasError;
  final bool isListening;
  final bool isLoadingMore;
  final bool hasMore;
  final bool loadMoreError;

  /// True while waiting for first stream snapshot (show spinner).
  final bool isInitialLoadInProgress;

  /// True if first load timed out without receiving data.
  final bool initialLoadTimedOut;

  /// True once first snapshot has been received (even if empty).
  final bool hasReceivedFirstSnapshot;

  const NotificationListViewState({
    required this.notifications,
    required this.hasError,
    required this.isListening,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMoreError,
    required this.isInitialLoadInProgress,
    required this.initialLoadTimedOut,
    required this.hasReceivedFirstSnapshot,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationListViewState &&
          identical(notifications, other.notifications) &&
          hasError == other.hasError &&
          isListening == other.isListening &&
          isLoadingMore == other.isLoadingMore &&
          hasMore == other.hasMore &&
          loadMoreError == other.loadMoreError &&
          isInitialLoadInProgress == other.isInitialLoadInProgress &&
          initialLoadTimedOut == other.initialLoadTimedOut &&
          hasReceivedFirstSnapshot == other.hasReceivedFirstSnapshot;

  @override
  int get hashCode => Object.hash(
        identityHashCode(notifications),
        hasError,
        isListening,
        isLoadingMore,
        hasMore,
        loadMoreError,
        isInitialLoadInProgress,
        initialLoadTimedOut,
        hasReceivedFirstSnapshot,
      );
}

/// Provider for notification list operations with lazy streaming and pagination.
///
/// Features:
/// - Lazy streaming: Widget calls [startListening]/[stopListening] in lifecycle
/// - Auth-reactive: Clears state on UID change via FirebaseAuth.authStateChanges
/// - Dedupe: First page stream + load-more fetch are merged without duplicates
/// - Domain model: Exposes [NotificationListItem] list, not Firestore types
/// - Unread count: Separate lightweight stream for badge via [unreadCountStream]
/// - First-load timeout: Shows retry UI instead of infinite spinner on stall
class NotificationListProvider extends ChangeNotifier {
  NotificationListProvider({
    NotificationCrudService? service,
    FirebaseAuth? auth,
    Duration initialLoadTimeout = const Duration(seconds: 12),
  })  : _service = service ?? NotificationCrudService(),
        _auth = auth,
        _initialLoadTimeout = initialLoadTimeout {
    _init();
  }

  final NotificationCrudService _service;
  final FirebaseAuth? _auth;
  final Duration _initialLoadTimeout;

  FirebaseAuth get _resolvedAuth => _auth ?? FirebaseAuth.instance;
  bool _disposed = false;
  Timer? _notifyTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH TRACKING (FirebaseAuth.authStateChanges only, NOT user doc stream)
  // ═══════════════════════════════════════════════════════════════════════════
  String? _activeUid;
  StreamSubscription<User?>? _authSubscription;

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTENING STATE (LAZY - only active when widget calls startListening)
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isListening = false;
  DocumentReference? _currentUserRef;

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRST-LOAD STATE (timeout handling for stalled streams)
  // ═══════════════════════════════════════════════════════════════════════════
  bool _hasReceivedFirstSnapshot = false;
  bool _isInitialLoadInProgress = false;
  bool _initialLoadTimedOut = false;
  Timer? _initialLoadTimer;

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRST PAGE STATE (real-time stream)
  // ═══════════════════════════════════════════════════════════════════════════
  final Map<String, NotificationListItem> _notificationMap = {};
  List<String> _orderedIds = [];
  StreamSubscription<QuerySnapshot>? _firstPageSubscription;
  bool _hasStreamError = false;

  /// Cached unmodifiable list for stable selector comparisons.
  /// Updated only when list content/order actually changes.
  List<NotificationListItem> _cachedNotificationsList = const [];

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD-MORE STATE (fetch-based pagination)
  // ═══════════════════════════════════════════════════════════════════════════
  DocumentSnapshot? _lastDoc;
  int _firstPageSize = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _loadMoreError = false;

  static const int _pageSize = 50;

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS (expose domain models, not Firestore types)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ordered list of notifications (first page + loaded more, deduped).
  /// Returns cached unmodifiable list for stable selector comparisons.
  List<NotificationListItem> get notifications => _cachedNotificationsList;

  /// True if the stream encountered an error.
  bool get hasError => _hasStreamError;

  /// True if a load-more operation is in progress.
  bool get isLoadingMore => _isLoadingMore;

  /// True if more pages are available to load.
  bool get hasMore => _hasMore;

  /// True if the last load-more attempt failed.
  bool get loadMoreError => _loadMoreError;

  /// True if no notifications exist and no error occurred.
  bool get isEmpty => _notificationMap.isEmpty && !_hasStreamError;

  /// True if there are notifications to display (regardless of error state).
  /// Use for app bar action visibility.
  bool get hasNotifications => _notificationMap.isNotEmpty;

  /// True if actively listening to the first-page stream.
  bool get isListening => _isListening;

  /// True while waiting for first stream snapshot.
  bool get isInitialLoadInProgress => _isInitialLoadInProgress;

  /// True if first load timed out without receiving data.
  bool get initialLoadTimedOut => _initialLoadTimedOut;

  /// True once first snapshot has been received (even if empty).
  bool get hasReceivedFirstSnapshot => _hasReceivedFirstSnapshot;

  /// Snapshot of list state for Selector consumption.
  ///
  /// Use with context.select() to only rebuild when relevant state changes.
  NotificationListViewState get listViewState => NotificationListViewState(
        notifications: _cachedNotificationsList,
        hasError: _hasStreamError,
        isListening: _isListening,
        isLoadingMore: _isLoadingMore,
        hasMore: _hasMore,
        loadMoreError: _loadMoreError,
        isInitialLoadInProgress: _isInitialLoadInProgress,
        initialLoadTimedOut: _initialLoadTimedOut,
        hasReceivedFirstSnapshot: _hasReceivedFirstSnapshot,
      );

  /// Update the cached notifications list.
  /// Call this whenever _orderedIds or _notificationMap content changes.
  void _updateCachedList() {
    _cachedNotificationsList = List.unmodifiable(
      _orderedIds.map((id) => _notificationMap[id]!),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INIT & AUTH STATE
  // ═══════════════════════════════════════════════════════════════════════════

  void _init() {
    _authSubscription = _resolvedAuth.authStateChanges().listen(
      (user) {
        final newUid = user?.uid;
        if (newUid == _activeUid) return;

        ProductionLog.log(
          '📱 NotificationListProvider: auth changed from $_activeUid to $newUid',
        );

        // Preserve whether we were actively listening before stopping
        final wasListening = _isListening;

        // UID changed - stop any active listening and clear state
        if (_isListening) {
          _stopListeningInternal();
        }
        _clearState();
        _activeUid = newUid;

        // If we were listening and have a new valid UID, restart with new user
        // The widget will call startListening again, but this handles edge cases
        // where auth changes while notification screen is still mounted
        if (wasListening && newUid != null) {
          ProductionLog.log(
            '📱 NotificationListProvider: restarting listener for new user',
          );
          // Note: Widget still holds old userRef, it will call startListening
          // with new ref in didChangeDependencies
        }
      },
      onError: (e) {
        AppLog.d('❌ NotificationListProvider._init auth error: $e');
      },
    );
  }

  void _clearState() {
    _notificationMap.clear();
    _orderedIds.clear();
    _lastDoc = null;
    _firstPageSize = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _loadMoreError = false;
    _hasStreamError = false;
    // Reset first-load state
    _hasReceivedFirstSnapshot = false;
    _isInitialLoadInProgress = false;
    _initialLoadTimedOut = false;
    _initialLoadTimer?.cancel();
    _initialLoadTimer = null;
    _updateCachedList();
    _scheduleNotify();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAZY LISTENING (widget calls these in initState/dispose)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start listening to the notification stream for the given user.
  ///
  /// Call from widget's didChangeDependencies. Handles:
  /// - Already listening to same userRef: no-op
  /// - Already listening to different userRef: stop old, start new
  /// - Not listening: start fresh
  void startListening(DocumentReference userRef) {
    // If already listening to the same userRef, no-op
    if (_isListening && _currentUserRef?.path == userRef.path) {
      return;
    }

    // If listening to a different userRef, stop old subscription first
    if (_isListening && _currentUserRef?.path != userRef.path) {
      ProductionLog.log(
        '📱 NotificationListProvider: userRef changed, restarting stream',
      );
      _stopListeningInternal();
      _clearState();
    }

    ProductionLog.log(
      '📱 NotificationListProvider: startListening userRef=${userRef.id} uid=$_activeUid',
    );

    _currentUserRef = userRef;
    _isListening = true;

    // Set first-load state
    _isInitialLoadInProgress = true;
    _hasReceivedFirstSnapshot = false;
    _initialLoadTimedOut = false;

    // Start timeout timer
    _initialLoadTimer?.cancel();
    _initialLoadTimer = Timer(_initialLoadTimeout, _onInitialLoadTimeout);

    _initFirstPageStream();

    // Notify immediately so UI shows loading state
    _scheduleNotify();
  }

  /// Called when first load times out without receiving a snapshot.
  void _onInitialLoadTimeout() {
    if (_disposed) return;
    if (_hasReceivedFirstSnapshot) return; // Already received, ignore

    ProductionLog.log(
      '⏱️ NotificationListProvider: initial load timed out after ${_initialLoadTimeout.inSeconds}s',
    );

    _isInitialLoadInProgress = false;
    _initialLoadTimedOut = true;
    _hasStreamError = true; // Drive retry UI
    _scheduleNotify();
  }

  /// Stop listening to the notification stream.
  ///
  /// Call from widget's dispose. Safe to call multiple times.
  void stopListening() {
    _stopListeningInternal();
  }

  void _stopListeningInternal() {
    _firstPageSubscription?.cancel();
    _firstPageSubscription = null;
    _isListening = false;
    _currentUserRef = null;
  }

  void _initFirstPageStream() {
    final userRef = _currentUserRef;
    if (userRef == null) return;
    final uid = _activeUid;
    final startTime = DateTime.now();

    ProductionLog.log('📱 NotificationListProvider: stream attached');

    _firstPageSubscription?.cancel();
    _firstPageSubscription = _service
        .streamNotifications(userRef: userRef, limit: _pageSize)
        .listen(
      (snapshot) {
        if (_disposed || _activeUid != uid) return;

        // Log first snapshot latency
        if (!_hasReceivedFirstSnapshot) {
          final latency = DateTime.now().difference(startTime).inMilliseconds;
          ProductionLog.log(
            '✅ NotificationListProvider: first snapshot received, '
            'docs=${snapshot.docs.length}, latency=${latency}ms',
          );
        }

        _handleFirstPageUpdate(snapshot);
      },
      onError: (e) {
        if (_disposed || _activeUid != uid) return;

        final errorCode = e is FirebaseException ? e.code : 'unknown';
        final errorMsg = e is FirebaseException ? e.message : e.toString();
        ProductionLog.log(
          '❌ NotificationListProvider: stream error code=$errorCode msg=$errorMsg',
        );

        // Cancel timeout timer on error
        _initialLoadTimer?.cancel();
        _initialLoadTimer = null;

        _isInitialLoadInProgress = false;
        _hasStreamError = true;
        _scheduleNotify();
      },
    );
  }

  void _handleFirstPageUpdate(QuerySnapshot snapshot) {
    // Cancel timeout timer and update first-load state
    _initialLoadTimer?.cancel();
    _initialLoadTimer = null;
    _hasReceivedFirstSnapshot = true;
    _isInitialLoadInProgress = false;
    _initialLoadTimedOut = false;

    final newFirstPageIds = <String>{};
    final newDocs = <String, NotificationListItem>{};

    for (final doc in snapshot.docs) {
      final item = NotificationListItem.fromDoc(doc);
      newDocs[item.id] = item;
      newFirstPageIds.add(item.id);
    }

    // Detect material change - reset cursor if first page changed significantly
    final sizeChanged = snapshot.docs.length != _firstPageSize;
    final currentFirstPageIds = _orderedIds.take(_firstPageSize).toSet();
    final idsChanged = !_setEquals(newFirstPageIds, currentFirstPageIds);

    if (sizeChanged || idsChanged) {
      // First page changed materially - reset load-more state
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _firstPageSize = snapshot.docs.length;
      _hasMore = snapshot.docs.length >= _pageSize;

      // Clear all items and rebuild from first page only
      _notificationMap.clear();
      _orderedIds.clear();
    }

    // Merge new first page items (deduped by map key)
    _notificationMap.addAll(newDocs);

    // Rebuild ordered list: first page IDs + any load-more IDs not in first page
    final loadMoreIds = _orderedIds
        .skip(_firstPageSize)
        .where((id) => !newFirstPageIds.contains(id));
    _orderedIds = [...newFirstPageIds, ...loadMoreIds];

    _hasStreamError = false;
    _updateCachedList();
    _scheduleNotify();
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    return a.length == b.length && a.difference(b).isEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGINATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load the next page of notifications.
  ///
  /// Does nothing if already loading, no more pages, or no cursor available.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    final userRef = _currentUserRef;
    final uid = _activeUid;
    if (userRef == null || uid == null) return;

    _isLoadingMore = true;
    _scheduleNotify();

    try {
      final docs = await _service.fetchNotificationsPage(
        userRef: userRef,
        pageSize: _pageSize,
        startAfterDocument: _lastDoc,
      );

      if (_disposed || _activeUid != uid) return;

      for (final doc in docs) {
        final item = NotificationListItem.fromDoc(doc);
        if (!_notificationMap.containsKey(item.id)) {
          _notificationMap[item.id] = item;
          _orderedIds.add(item.id);
        }
      }

      if (docs.isNotEmpty) {
        _lastDoc = docs.last;
      }
      _hasMore = docs.length >= _pageSize;
      _isLoadingMore = false;
      _loadMoreError = false;
      _updateCachedList();
      _scheduleNotify();
    } catch (e) {
      if (_disposed || _activeUid != uid) return;
      _isLoadingMore = false;
      _loadMoreError = true;
      _scheduleNotify();
      AppLog.d('❌ NotificationListProvider.loadMore error: $e');
    }
  }

  /// Refresh the list by clearing load-more state.
  ///
  /// The first-page stream will auto-refresh. Returns after a brief delay
  /// for visual feedback.
  Future<void> refresh() async {
    final firstPageIds = _orderedIds.take(_firstPageSize).toSet();
    _notificationMap.removeWhere((id, _) => !firstPageIds.contains(id));
    _orderedIds = _orderedIds.take(_firstPageSize).toList();
    _loadMoreError = false;
    _hasMore = true;
    _updateCachedList();
    _scheduleNotify();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Retry initial load after timeout or error.
  ///
  /// Stops the current stream and restarts fresh with timeout handling.
  void retryInitialLoad() {
    final userRef = _currentUserRef;
    if (userRef == null) return;

    ProductionLog.log('🔄 NotificationListProvider: retrying initial load');

    // Stop current stream
    _stopListeningInternal();
    _clearState();

    // Restart
    startListening(userRef);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNREAD COUNT STREAM (for badge - lightweight, separate from list)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of unread notification count for the given user.
  ///
  /// Use in badge widgets with StreamBuilder. Separate from list stream.
  Stream<int> unreadCountStream(DocumentReference userRef) {
    return _service
        .streamUnreadNotifications(userRef)
        .map((snap) => snap.docs.length);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD OPERATIONS (delegate to service, update local state)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mark all notifications as read.
  ///
  /// Local state updates via stream after Firestore write completes.
  Future<void> markAllAsRead() async {
    final userRef = _currentUserRef;
    if (userRef == null) return;
    await _service.markAllAsRead(userRef);
  }

  /// Mark a notification as read if not already read.
  Future<void> markReadIfNeeded(NotificationListItem item) async {
    if (item.isRead) return;
    await _service.markReadIfNeeded(item.reference, false);
  }

  /// Mark a notification as unread.
  Future<void> markAsUnread(NotificationListItem item) async {
    await _service.markAsUnread(item.reference);
  }

  /// Delete a single notification.
  ///
  /// Optimistically removes from local state. Stream will restore if delete fails.
  Future<void> deleteNotification(NotificationListItem item) async {
    // Optimistic removal
    _notificationMap.remove(item.id);
    _orderedIds.remove(item.id);
    _updateCachedList();
    _scheduleNotify();

    try {
      await _service.deleteNotification(item.reference);
    } catch (e) {
      // Stream will restore if delete failed
      AppLog.d('❌ NotificationListProvider.deleteNotification error: $e');
      rethrow;
    }
  }

  /// Delete all notifications for the current user.
  ///
  /// Returns the count of deleted notifications.
  Future<int> deleteAllNotifications() async {
    final userRef = _currentUserRef;
    if (userRef == null) return 0;

    final count = await _service.deleteAllNotifications(userRef);
    _clearState();
    return count;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY (delegate to service)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Resolve a game DocumentReference from notification payload fields.
  DocumentReference? resolveGameRefFromPayload(Map<String, dynamic> payload) {
    return _service.resolveGameRefFromPayload(payload);
  }

  /// Check if a friends-only game should be blocked for the current user.
  Future<bool> shouldBlockFriendsOnlyGame(
    DocumentReference gameRef,
    DocumentReference currentUserRef,
  ) {
    return _service.shouldBlockFriendsOnlyGame(
      gameRef: gameRef,
      currentUserRef: currentUserRef,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBOUNCE & DISPOSE
  // ═══════════════════════════════════════════════════════════════════════════

  void _scheduleNotify() {
    if (_disposed) return;
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _initialLoadTimer?.cancel();
    _firstPageSubscription?.cancel();
    _authSubscription?.cancel();
    _notificationMap.clear();
    _orderedIds.clear();
    super.dispose();
  }
}
