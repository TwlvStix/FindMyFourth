import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/request_manager.dart';
import '/models/game.dart';

/// UserProvider manages global user state and provides cached access to user data
///
/// Usage:
/// - Access via Provider.of<UserProvider>(context)
/// - Or use Consumer<UserProvider> for reactive updates
///
/// Features:
/// - Reactive user state updates
/// - Cached queries for games, friends, and courses
/// - Automatic cache invalidation
/// - Convenient helper methods
class UserProvider extends ChangeNotifier {
  UserProvider() {
    _init();
  }

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

  // Request managers for caching
  final _myGamesManager = StreamRequestManager<List<Game>>(5);
  final _availableGamesManager = StreamRequestManager<List<Game>>(5);
  final _friendsManager = StreamRequestManager<List<UsersRecord>>(5);
  final _friendRequestsManager = StreamRequestManager<List<UsersRecord>>(5);
  final _coursesManager = FutureRequestManager<List<CourseRecord>>(10);

  /// Initialize the provider by listening to auth changes
  void _init() {
    _userSubscription = authenticatedUserStream.listen(
      (user) {
        final wasLoggedIn = _currentUser != null;
        final isNowLoggedIn = user != null;

        _currentUser = user;
        _isLoading = false;

        // If user logged out, clear all caches
        if (wasLoggedIn && !isNowLoggedIn) {
          clearAllCaches();
        }

        notifyListeners();
      },
      onError: (error) {
        debugPrint('UserProvider error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
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
    _notifyDebounce = Timer(Duration(milliseconds: 50), () {
      notifyListeners();
    });
  }

  // ========================================
  // USER DATA ACCESSORS
  // ========================================

  String get userId => _currentUser?.reference.id ?? '';
  String get displayName => _currentUser?.displayName ?? '';
  String get firstName => _currentUser?.firstName ?? '';
  String get lastName => _currentUser?.lastName ?? '';
  String get email => _currentUser?.email ?? '';
  String get photoUrl => _currentUser?.photoUrl ?? '';
  String get phoneNumber => _currentUser?.phoneNumber ?? '';
  String get homeCourse => _currentUser?.homeCourse ?? '';
  int get handicap => _currentUser?.handicap ?? 0;
  int get music => _currentUser?.music ?? 0;
  int get drinks => _currentUser?.drinks ?? 0;
  int get playForMoney => _currentUser?.playForMoney ?? 0;
  int get paceOfPlay => _currentUser?.paceOfPlay ?? 0;
  bool get onboardingCompleted => _currentUser?.onboardingCompleted ?? false;

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
  // GAMES QUERIES (CACHED)
  // ========================================

  /// Get games the current user has joined (cached)
  Stream<List<Game>> getMyGames({
    bool overrideCache = false,
  }) {
    final currentUser = _currentUser;
    final userRef = currentUser?.reference ?? currentUserReference;
    if (userRef == null) {
      return Stream.value([]);
    }
    final resolvedUserId = currentUser?.reference.id ?? userRef.id;

    return _myGamesManager.performRequest(
      uniqueQueryKey: 'my_games_${resolvedUserId}',
      overrideCache: overrideCache,
      requestFn: () => queryGamesRecord(
        queryBuilder: (gamesRecord) => gamesRecord
            .where('joined_players', arrayContains: userRef)
            .where('isCancelled', isEqualTo: false)
            .orderBy('date'),
      ).map((records) => records.map(Game.fromRecord).toList()),
    );
  }

  /// Get available games to join (cached)
  Stream<List<Game>> getAvailableGames({
    bool overrideCache = false,
    DateTime? fromDate,
  }) {
    if (!isLoggedIn) return Stream.value([]);

    final queryKey = fromDate != null
        ? 'available_games_${fromDate.toIso8601String()}'
        : 'available_games';

    return _availableGamesManager.performRequest(
      uniqueQueryKey: queryKey,
      overrideCache: overrideCache,
      requestFn: () {
        Query query = GamesRecord.collection.where(
          'isCancelled',
          isEqualTo: false,
        );
        if (fromDate != null) {
          query = query.where('date', isGreaterThanOrEqualTo: fromDate);
        }
        return queryGamesRecord(
          queryBuilder: (_) => query.orderBy('date'),
        ).map((records) => records.map(Game.fromRecord).toList());
      },
    );
  }

  /// Refresh my games cache
  void refreshMyGames() {
    final currentUser = _currentUser;
    final userRef = currentUser?.reference ?? currentUserReference;
    final resolvedUserId = currentUser?.reference.id ?? userRef?.id ?? '';
    _myGamesManager.clearRequest('my_games_${resolvedUserId}');
    _scheduleNotify();
  }

  /// Refresh available games cache
  void refreshAvailableGames() {
    _availableGamesManager.clear();
    _scheduleNotify();
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
      uniqueQueryKey: 'friends_${userId}',
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
      uniqueQueryKey: 'friend_requests_${userId}',
      overrideCache: overrideCache,
      requestFn: () => _queryUsersByRefs(friendRequests),
    );
  }

  /// Refresh friends cache
  void refreshFriends() {
    _friendsManager.clearRequest('friends_${userId}');
    _scheduleNotify();
  }

  /// Refresh friend requests cache
  void refreshFriendRequests() {
    _friendRequestsManager.clearRequest('friend_requests_${userId}');
    _scheduleNotify();
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
  void refreshCourses() {
    _coursesManager.clearRequest('all_courses');
    _scheduleNotify();
  }

  // ========================================
  // USER ACTIONS
  // ========================================

  /// Update user profile data
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (!isLoggedIn) return;

    try {
      await currentUserReference!.update(data);
      // User data will automatically update via authenticatedUserStream
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Add a friend (bidirectional - adds both users to each other's friends list)
  Future<void> addFriend(DocumentReference friendRef) async {
    if (!isLoggedIn) return;

    try {
      // Add friend to current user's friends list
      await currentUserReference!.update({
        'friends': FieldValue.arrayUnion([friendRef]),
      });

      // Add current user to friend's friends list (bidirectional)
      await friendRef.update({
        'friends': FieldValue.arrayUnion([currentUserReference]),
      });

      refreshFriends();
    } catch (e) {
      debugPrint('Error adding friend: $e');
      rethrow;
    }
  }

  /// Remove a friend (bidirectional - removes both users from each other's friends list)
  Future<void> removeFriend(DocumentReference friendRef) async {
    if (!isLoggedIn) return;

    try {
      // Remove friend from current user's friends list
      await currentUserReference!.update({
        'friends': FieldValue.arrayRemove([friendRef]),
      });

      // Remove current user from friend's friends list (bidirectional)
      await friendRef.update({
        'friends': FieldValue.arrayRemove([currentUserReference]),
      });

      refreshFriends();
    } catch (e) {
      debugPrint('Error removing friend: $e');
      rethrow;
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(DocumentReference targetUserRef) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    final currentUserRef = UsersRecord.collection.doc(authUser.uid);
    if (targetUserRef.path == currentUserRef.path) return;
    if (friends.contains(targetUserRef)) return;
    if (friendRequests.contains(targetUserRef)) return;

    try {
      final targetUser = await UsersRecord.getDocumentOnce(targetUserRef);
      if (targetUser.friends.contains(currentUserRef) ||
          targetUser.friendRequests.contains(currentUserRef)) {
        return;
      }
      await targetUserRef.update({
        'friend_requests': FieldValue.arrayUnion([currentUserRef.id]),
      });
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(DocumentReference requesterRef) async {
    if (!isLoggedIn) return;

    try {
      await currentUserReference!.update({
        'friend_requests': FieldValue.arrayRemove(
          [requesterRef, requesterRef.id],
        ),
      });
      await currentUserReference!.update({
        'friends': FieldValue.arrayUnion([requesterRef]),
      });
      await requesterRef.update({
        'friends': FieldValue.arrayUnion([currentUserReference]),
      });

      refreshFriends();
      refreshFriendRequests();
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(DocumentReference requesterRef) async {
    if (!isLoggedIn) return;

    try {
      await currentUserReference!.update({
        'friend_requests':
            FieldValue.arrayRemove([requesterRef, requesterRef.id]),
      });
      refreshFriendRequests();
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      rethrow;
    }
  }

  // ========================================
  // CACHE MANAGEMENT
  // ========================================

  /// Clear all caches
  void clearAllCaches() {
    _myGamesManager.clear();
    _availableGamesManager.clear();
    _friendsManager.clear();
    _friendRequestsManager.clear();
    _coursesManager.clear();
  }

  /// Clear game-related caches
  void clearGameCaches() {
    _myGamesManager.clear();
    _availableGamesManager.clear();
  }

  /// Clear social-related caches
  void clearSocialCaches() {
    _friendsManager.clear();
    _friendRequestsManager.clear();
  }
}
