import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/core/utils/app_log.dart';
import '/services/friend_service.dart';
import '/services/profile_service.dart';

/// UserProvider manages global user state and provides cached access to user data
///
/// Usage:
/// - Access via `Provider.of<UserProvider>(context)`
/// - Or use `Consumer<UserProvider>` for reactive updates
///
/// Features:
/// - Reactive user state updates
/// - Cached queries for games, friends, and courses
/// - Automatic cache invalidation
/// - Convenient helper methods
class UserProvider extends ChangeNotifier {
  UserProvider({
    FriendService? friendService,
    ProfileService? profileService,
  })  : _friendService = friendService ?? FriendService(),
        _profileService = profileService ?? ProfileService() {
    _init();
  }

  final FriendService _friendService;
  final ProfileService _profileService;

  // Current user data
  UsersRecord? _currentUser;
  UsersRecord? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Loading states
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Stream subscription
  StreamSubscription<UsersRecord?>? _userSubscription;

  // Debounced notifyListeners to prevent excessive rebuilds (Phase 10-03 A-RACE-001)
  Timer? _notifyDebounce;

  // Disposed flag to prevent post-dispose notifications
  bool _disposed = false;

  // Request managers for caching
  final _friendsManager = StreamRequestManager<List<UsersRecord>>(5);
  final _friendRequestsManager = StreamRequestManager<List<UsersRecord>>(5);
  final _coursesManager = FutureRequestManager<List<CourseRecord>>(10);

  // Track pending outgoing friend requests (for immediate UI updates)
  final Set<String> _pendingOutgoingRequests = {};

  /// Check if we have a pending outgoing request to this user (by uid)
  bool hasPendingOutgoingRequest(String uid) => _pendingOutgoingRequests.contains(uid);

  /// Add a pending outgoing request (called after successful send)
  void _addPendingOutgoingRequest(String uid) {
    _pendingOutgoingRequests.add(uid);
    _scheduleNotify(); // Mutation state - UI needs to know
  }

  /// Clear pending outgoing request (e.g., when cancelled or accepted)
  void clearPendingOutgoingRequest(String uid) {
    _pendingOutgoingRequests.remove(uid);
    _scheduleNotify(); // Mutation state - UI needs to know
  }

  // In-memory override for onboarding_completed to avoid race condition
  // where Firestore snapshot listener hasn't caught up yet after writing
  bool? _onboardingCompletedOverride;

  // Individual user document cache
  final Map<String, UsersRecord> _userCache = {};
  final Map<String, StreamRequestManager<UsersRecord?>> _userStreamManagers = {};

  // User query caching (for candidate users, recently joined, etc.)
  final Map<String, StreamRequestManager<List<UsersRecord>>> _userQueryManagers = {};
  final Map<String, List<UsersRecord>> _userQueryCache = {};
  final Map<String, DateTime> _userQueryCacheTimestamps = {};
  final Duration _userQueryCacheTTL = const Duration(minutes: 5);

  /// Initialize the provider by listening to auth changes
  void _init() {
    // Seed initial value from global currentUserDocument
    // (handles race condition where broadcast stream already emitted before we subscribed)
    if (currentUserDocument != null) {
      _currentUser = currentUserDocument;
      _isLoading = false;
    }

    _userSubscription = authenticatedUserStream.listen(
      (user) async {
        final wasLoggedIn = _currentUser != null;
        final isNowLoggedIn = user != null;

        _currentUser = user;
        _isLoading = false;

        // Log auth transitions for crash correlation
        if (wasLoggedIn && !isNowLoggedIn) {
          AppLog.d('🔐 UserProvider: auth transition → logged out');
        } else if (!wasLoggedIn && isNowLoggedIn) {
          AppLog.d('🔐 UserProvider: auth transition → logged in (${user.reference.id})');
        }

        // Clear onboarding override once stream confirms the value
        if (user?.onboardingCompleted == true) {
          _onboardingCompletedOverride = null;
        }

        // Ensure friend_requests field exists for logged-in user.
        // Awaited so the field exists before _scheduleNotify() fires,
        // preventing UI from rendering before the field is initialized.
        // Safe to await: the method catches its own errors and doesn't rethrow.
        if (isNowLoggedIn) {
          await _ensureFriendRequestsFieldExists(user);
        }

        // If user logged out, clear all caches
        if (wasLoggedIn && !isNowLoggedIn) {
          clearAllCaches();
        }

        _scheduleNotify(); // Session state - UI needs to know
      },
      onError: (error) {
        AppLog.d('❌ UserProvider._init error: $error');
        _isLoading = false;
        _scheduleNotify(); // Session state - UI needs to know
      },
    );
  }

  /// Ensure friend_requests field exists for the current user
  ///
  /// Delegates to FriendService.initializeFriendFields() which handles
  /// both friend_requests and friends field initialization.
  Future<void> _ensureFriendRequestsFieldExists(UsersRecord user) async {
    try {
      await _friendService.initializeFriendFields(user.uid);
    } catch (e) {
      AppLog.d('❌ UserProvider._ensureFriendRequestsFieldExists error: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _userSubscription?.cancel();
    _notifyDebounce?.cancel();
    clearAllCaches();
    super.dispose();
  }

  /// Schedule a debounced notifyListeners call
  ///
  /// During login, multiple async operations trigger rapid notifyListeners calls,
  /// causing widgets to rebuild mid-login with unstable state. This debounces
  /// those calls to batch state updates into a single rebuild after 50ms.
  ///
  /// This prevents Phase 10-03 A-RACE-001 (concurrent notifyListeners during login).
  void _scheduleNotify() {
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  /// Force immediate notify (bypass debounce)
  ///
  /// Use for critical state changes that require instant UI updates,
  /// such as friend removal where users expect immediate visual feedback.
  void forceNotify() {
    _notifyDebounce?.cancel();
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ========================================
  // USER DATA ACCESSORS
  // ========================================

  String get userId => _currentUser?.reference.id ?? '';

  /// Returns userId or null if auth not ready. Prefer this for guards.
  String? get userIdOrNull => _currentUser?.reference.id;

  /// True when auth has resolved AND user is logged in with valid ID.
  bool get isAuthReady => !_isLoading && userIdOrNull != null;

  String get displayName => _currentUser?.displayName ?? '';
  String get firstName => _currentUser?.firstName ?? '';
  String get lastName => _currentUser?.lastName ?? '';
  String get photoUrl => _currentUser?.photoUrl ?? '';
  String get homeCourse => _currentUser?.homeCourse ?? '';
  int get handicap => _currentUser?.handicap ?? 0;
  int get music => _currentUser?.music ?? 0;
  int get drinks => _currentUser?.drinks ?? 0;
  int get playForMoney => _currentUser?.playForMoney ?? 0;
  int get paceOfPlay => _currentUser?.paceOfPlay ?? 0;
  bool get onboardingCompleted =>
      _onboardingCompletedOverride ?? _currentUser?.onboardingCompleted ?? false;

  // ========================================
  // LOCATION ACCESSORS (for GeoFilterProvider)
  // ========================================

  // Home course location (primary)
  double? get homeCourseLat => _currentUser?.homeCourseLat;
  double? get homeCourseLng => _currentUser?.homeCourseLng;
  bool get hasHomeCourseLocation =>
      homeCourseLat != null && homeCourseLng != null;

  // Hometown location (fallback)
  double? get hometownLat => _currentUser?.hometownLat;
  double? get hometownLng => _currentUser?.hometownLng;
  bool get hasHometownLocation => hometownLat != null && hometownLng != null;

  // Resolved default location (home course → hometown)
  double? get defaultLocationLat => homeCourseLat ?? hometownLat;
  double? get defaultLocationLng => homeCourseLng ?? hometownLng;
  bool get hasDefaultLocation =>
      defaultLocationLat != null && defaultLocationLng != null;

  // Radius preference
  double get searchRadiusKm => _currentUser?.searchRadiusKm ?? 40.0;

  List<DocumentReference> get friends => _currentUser?.friends ?? [];
  List<DocumentReference> get friendRequests => _currentUser?.friendRequests ?? [];

  /// Check if a user is a friend
  bool isFriend(DocumentReference userRef) {
    return friends.contains(userRef);
  }

  /// Check if user has pending friend request from someone
  bool hasFriendRequest(DocumentReference userRef) {
    return friendRequests.contains(userRef);
  }

  // ========================================
  // USER DOCUMENT QUERIES (CACHED)
  // ========================================

  /// Get cached user by ID
  UsersRecord? getCachedUser(String userId) {
    // Check map cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    // Fall back to BehaviorSubject cache
    final streamManager = _userStreamManagers[userId];
    if (streamManager != null) {
      return streamManager.getLastValue(userId);
    }

    return null;
  }

  /// Watch a user document with caching
  Stream<UsersRecord?> watchUser(DocumentReference userRef) {
    final userId = userRef.id;

    // Get or create StreamRequestManager for this user
    if (!_userStreamManagers.containsKey(userId)) {
      _userStreamManagers[userId] = StreamRequestManager<UsersRecord?>(10);
    }

    return _userStreamManagers[userId]!.performRequest(
      uniqueQueryKey: userId,
      requestFn: () => UsersRecord.getDocument(userRef),
    ).map((user) {
      if (user != null) {
        // Cache the user when it comes through the stream
        _userCache[userId] = user;
      }
      return user;
    });
  }

  // ========================================
  // USER QUERIES (CACHED)
  // ========================================

  /// Query candidate users for VIBE matching (cached)
  Stream<List<UsersRecord>> queryCandidateUsers({
    int limit = 60,
    bool overrideCache = false,
  }) {
    final queryKey = 'candidate_users_$limit';

    // Get or create StreamRequestManager
    if (!_userQueryManagers.containsKey(queryKey)) {
      _userQueryManagers[queryKey] = StreamRequestManager<List<UsersRecord>>(5);
    }

    return _userQueryManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () => queryUsersRecord(
        queryBuilder: (users) => users.limit(limit),
      ),
    ).map((users) {
      // Cache query results
      _userQueryCache[queryKey] = users;
      _userQueryCacheTimestamps[queryKey] = DateTime.now();
      return users;
    });
  }

  /// Query recently joined users (cached)
  Stream<List<UsersRecord>> queryRecentlyJoinedUsers({
    int limit = 20,
    bool overrideCache = false,
  }) {
    final queryKey = 'recently_joined_$limit';

    // Get or create StreamRequestManager
    if (!_userQueryManagers.containsKey(queryKey)) {
      _userQueryManagers[queryKey] = StreamRequestManager<List<UsersRecord>>(5);
    }

    return _userQueryManagers[queryKey]!.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () => queryUsersRecord(
        queryBuilder: (users) => users
            .orderBy('created_time', descending: true)
            .limit(limit),
      ),
    ).map((users) {
      // Cache query results
      _userQueryCache[queryKey] = users;
      _userQueryCacheTimestamps[queryKey] = DateTime.now();
      return users;
    });
  }

  /// Check if user query cache is valid (within TTL)
  bool isUserQueryCacheValid(String queryKey) {
    final timestamp = _userQueryCacheTimestamps[queryKey];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _userQueryCacheTTL;
  }

  /// Get cached candidate users if available (no fetch)
  List<UsersRecord>? getCachedCandidateUsers({int limit = 60}) {
    final queryKey = 'candidate_users_$limit';

    // Check query result cache first
    if (isUserQueryCacheValid(queryKey)) {
      return _userQueryCache[queryKey];
    }

    // Fall back to BehaviorSubject cache
    return _userQueryManagers[queryKey]?.getLastValue(queryKey);
  }

  /// Get cached recently joined users if available (no fetch)
  List<UsersRecord>? getCachedRecentlyJoinedUsers({int limit = 20}) {
    final queryKey = 'recently_joined_$limit';

    // Check query result cache first
    if (isUserQueryCacheValid(queryKey)) {
      return _userQueryCache[queryKey];
    }

    // Fall back to BehaviorSubject cache
    return _userQueryManagers[queryKey]?.getLastValue(queryKey);
  }

  // ========================================
  // FRIENDS QUERIES (CACHED)
  // ========================================

  /// Get user's friends list (cached)
  Stream<List<UsersRecord>> getFriends({
    bool overrideCache = false,
  }) {
    if (!isLoggedIn || friends.isEmpty) return Stream.value([]);

    return _friendsManager.performRequest(
      uniqueQueryKey: 'friends_$userId',
      overrideCache: overrideCache,
      requestFn: () => _queryUsersByRefs(friends),
    );
  }

  /// Get user's friend requests (cached)
  Stream<List<UsersRecord>> getFriendRequests({
    bool overrideCache = false,
  }) {
    if (!isLoggedIn || friendRequests.isEmpty) return Stream.value([]);

    return _friendRequestsManager.performRequest(
      uniqueQueryKey: 'friend_requests_$userId',
      overrideCache: overrideCache,
      requestFn: () => _queryUsersByRefs(friendRequests),
    );
  }

  /// Refresh friends cache
  ///
  /// Note: No _scheduleNotify() - cache invalidation doesn't need to notify.
  /// Stream consumers get fresh data directly from the stream when resubscribed.
  void refreshFriends() {
    _friendsManager.clearRequest('friends_$userId');
  }

  /// Refresh friend requests cache
  ///
  /// Note: No _scheduleNotify() - cache invalidation doesn't need to notify.
  /// Stream consumers get fresh data directly from the stream when resubscribed.
  void refreshFriendRequests() {
    _friendRequestsManager.clearRequest('friend_requests_$userId');
  }

  Stream<List<UsersRecord>> _queryUsersByRefs(List<DocumentReference> refs) {
    if (refs.isEmpty) {
      return Stream.value([]);
    }

    final chunkStreams = <Stream<List<UsersRecord>>>[];
    for (var i = 0; i < refs.length; i += 10) {
      final end = (i + 10) > refs.length ? refs.length : i + 10;
      final batchIds = refs.sublist(i, end).map((ref) => ref.id).toList();
      chunkStreams.add(
        queryUsersRecord(
          queryBuilder: (usersRecord) => usersRecord.where(
            FieldPath.documentId,
            whereIn: batchIds,
          ),
        ),
      );
    }

    return Rx.combineLatestList(chunkStreams).map(
      (batches) => [
        for (final batch in batches) ...batch,
      ],
    );
  }

  // ========================================
  // COURSES QUERIES (CACHED)
  // ========================================

  /// Get all golf courses (cached)
  Future<List<CourseRecord>> getCourses({
    bool overrideCache = false,
  }) {
    return _coursesManager.performRequest(
      uniqueQueryKey: 'all_courses',
      overrideCache: overrideCache,
      requestFn: () => queryCourseRecordOnce(),
    );
  }

  /// Refresh courses cache
  ///
  /// Note: No _scheduleNotify() - cache invalidation doesn't need to notify.
  /// Future consumers get fresh data when they call getCourses() again.
  void refreshCourses() {
    _coursesManager.clearRequest('all_courses');
  }

  // ========================================
  // USER ACTIONS
  // ========================================

  /// Update user profile data
  ///
  /// Delegates to ProfileService.updateProfile() which adds updated_at timestamp.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = userIdOrNull;
    if (userId == null) return;

    try {
      await _profileService.updateProfile(userId, data);
      // User data will automatically update via authenticatedUserStream
    } catch (e) {
      AppLog.d('❌ UserProvider.updateProfile error: $e');
      rethrow;
    }
  }

  /// Set the in-memory onboarding override without a Firestore write.
  ///
  /// Use when Firestore already has onboarding_completed=true and we just
  /// need the route guard to see the correct value immediately.
  void setOnboardingCompletedOverride() {
    if (_onboardingCompletedOverride == true) return;
    _onboardingCompletedOverride = true;
    forceNotify();
  }

  /// Mark onboarding as completed for the current user
  ///
  /// Sets the override immediately so route guards see the correct value
  /// without waiting for the Firestore snapshot listener to catch up.
  Future<void> markOnboardingCompleted() async {
    final uid = userIdOrNull;
    if (uid == null) return;

    try {
      await _profileService.markOnboardingCompleted(uid);
      _onboardingCompletedOverride = true;
      forceNotify();
    } catch (e) {
      AppLog.d('❌ UserProvider.markOnboardingCompleted error: $e');
      rethrow;
    }
  }

  /// Add a friend (bidirectional - adds both users to each other's friends list)
  ///
  /// Delegates to FriendService.addFriend() which uses a transaction for atomicity.
  Future<void> addFriend(DocumentReference friendRef) async {
    final userRef = currentUserReference;
    if (userRef == null) return;

    try {
      await _friendService.addFriend(
        currentUserRef: userRef,
        friendRef: friendRef,
      );
      refreshFriends();
    } catch (e) {
      AppLog.d('❌ UserProvider.addFriend error: $e');
      rethrow;
    }
  }

  /// Remove a friend (bidirectional - removes both users from each other's friends list)
  Future<void> removeFriend(DocumentReference friendRef) async {
    final uid = userIdOrNull;
    if (uid == null) return;

    try {
      await _friendService.removeFriend(
        currentUserId: uid,
        friendRef: friendRef,
      );
      refreshFriends();
    } catch (e) {
      AppLog.d('❌ UserProvider.removeFriend error: $e');
      rethrow;
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(DocumentReference targetUserRef) async {
    final uid = userIdOrNull;
    if (uid == null) return;
    final currentUserRef = UsersRecord.collection.doc(uid);
    if (targetUserRef.path == currentUserRef.path) return;

    // Check current user's lists for target
    final currentUserFriends = friends;
    if (currentUserFriends.any((ref) => ref.id == targetUserRef.id)) return;

    final currentUserRequests = friendRequests;
    if (currentUserRequests.any((ref) => ref.id == targetUserRef.id)) return;

    try {
      final sent = await _friendService.sendFriendRequest(
        currentUserId: uid,
        targetUserRef: targetUserRef,
      );

      if (sent) {
        _addPendingOutgoingRequest(targetUserRef.id);

        // Fire-and-forget notification to recipient
        final currentUserName = _currentUser?.displayName ?? 'A golfer';
        _friendService.notifyFriendRequestSent(
          recipientUserId: targetUserRef.id,
          senderName: currentUserName,
        );
      }
    } catch (e) {
      AppLog.d('❌ UserProvider.sendFriendRequest error: $e');
      rethrow;
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(DocumentReference requesterRef) async {
    final uid = userIdOrNull;
    if (uid == null) return;

    try {
      await _friendService.acceptFriendRequest(
        currentUserId: uid,
        requesterRef: requesterRef,
      );

      // Fire-and-forget notification to requester
      final currentUserName = _currentUser?.displayName ?? 'A golfer';
      _friendService.notifyFriendRequestAccepted(
        requesterUserId: requesterRef.id,
        acceptorName: currentUserName,
      );
    } catch (e) {
      AppLog.d('❌ UserProvider.acceptFriendRequest error: $e');
      rethrow;
    }

    try {
      refreshFriends();
      refreshFriendRequests();
    } catch (e) {
      AppLog.d('❌ UserProvider.acceptFriendRequest refresh error: $e');
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(DocumentReference requesterRef) async {
    try {
      final uid = userIdOrNull;
      if (uid == null) return;

      await _friendService.rejectFriendRequest(
        currentUserId: uid,
        requesterRef: requesterRef,
      );
      refreshFriendRequests();
    } catch (e) {
      AppLog.d('❌ UserProvider.rejectFriendRequest error: $e');
      rethrow;
    }
  }

  /// Cancel a friend request that the current user previously sent
  Future<void> cancelFriendRequest(DocumentReference targetUserRef) async {
    try {
      final uid = userIdOrNull;
      if (uid == null) return;

      await _friendService.cancelFriendRequest(
        currentUserId: uid,
        targetUserRef: targetUserRef,
      );
      clearPendingOutgoingRequest(targetUserRef.id);
    } catch (e) {
      AppLog.d('❌ UserProvider.cancelFriendRequest error: $e');
      rethrow;
    }
  }

  // ========================================
  // CACHE MANAGEMENT
  // ========================================

  /// Clear all caches
  void clearAllCaches() {
    _friendsManager.clear();
    _friendRequestsManager.clear();
    _coursesManager.clear();

    // Clear user caches
    _userCache.clear();
    for (final manager in _userStreamManagers.values) {
      manager.clear();
    }
    _userStreamManagers.clear();

    // Clear user query caches
    _userQueryCache.clear();
    _userQueryCacheTimestamps.clear();
    for (final manager in _userQueryManagers.values) {
      manager.clear();
    }
    _userQueryManagers.clear();
  }

  /// Clear social-related caches
  void clearSocialCaches() {
    _friendsManager.clear();
    _friendRequestsManager.clear();
  }
}
