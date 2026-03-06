import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/providers/chat_provider.dart';
import '/providers/user_provider.dart';
import '/friends/components/golfer_segmented_control.dart';
import '/friends/components/friend_filter_bottom_sheet.dart';
import '/utils/app_util.dart';

/// Controller for TabFriendsWidget state and business logic.
///
/// Manages segment state, search, filters, favorites, and friend operations.
/// Delegates all Firestore operations to providers via context.
class TabFriendsController extends ChangeNotifier {
  TabFriendsController({String? initialSegment}) {
    _initializeSegment(initialSegment);
    _searchController.addListener(_onSearchTextChanged);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEGMENT STATE
  // ═══════════════════════════════════════════════════════════════════════════
  GolferSegment _currentSegment = GolferSegment.discover;
  GolferSegment get currentSegment => _currentSegment;

  void _initializeSegment(String? initial) {
    if (initial == null) return;
    switch (initial) {
      case 'requests':
        _currentSegment = GolferSegment.requests;
        break;
      case 'friends':
        _currentSegment = GolferSegment.friends;
        break;
      case 'discover':
      default:
        _currentSegment = GolferSegment.discover;
        break;
    }
  }

  void setSegment(GolferSegment segment) {
    if (_currentSegment == segment) return;
    HapticFeedback.lightImpact();
    _currentSegment = segment;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH STATE
  // ═══════════════════════════════════════════════════════════════════════════
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchTerm = '';
  Timer? _debounceTimer;

  TextEditingController get searchController => _searchController;
  FocusNode get searchFocusNode => _searchFocusNode;
  String get searchTerm => _searchTerm;

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final newTerm = _searchController.text.trim().toLowerCase();
      if (_searchTerm != newTerm) {
        _searchTerm = newTerm;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  bool matchesSearch(UsersRecord user) {
    if (_searchTerm.isEmpty) return true;
    return user.displayName.toLowerCase().contains(_searchTerm) ||
        user.firstName.toLowerCase().contains(_searchTerm) ||
        user.lastName.toLowerCase().contains(_searchTerm);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER STATE
  // ═══════════════════════════════════════════════════════════════════════════
  FriendFilters _friendFilters = FriendFilters();
  FriendFilters get friendFilters => _friendFilters;

  Future<void> showFilterSheet(BuildContext context) async {
    final topPadding = MediaQuery.of(context).padding.top;
    final result = await showModalBottomSheet<FriendFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => FriendFilterBottomSheet(
        currentFilters: _friendFilters,
        topPadding: topPadding,
      ),
    );

    if (result != null) {
      _friendFilters = result;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAVORITES STATE
  // ═══════════════════════════════════════════════════════════════════════════
  final Set<String> _favoriteFriends = {};
  Set<String> get favoriteFriends => _favoriteFriends;

  void toggleFavorite(String friendId) {
    if (_favoriteFriends.contains(friendId)) {
      _favoriteFriends.remove(friendId);
    } else {
      _favoriteFriends.add(friendId);
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REFRESH STATE
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _isRefreshing = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIMISTIC FRIENDS LIST
  // ═══════════════════════════════════════════════════════════════════════════
  List<DocumentReference>? _optimisticFriendsList;
  List<DocumentReference>? get optimisticFriendsList => _optimisticFriendsList;

  void syncOptimisticState(List<DocumentReference> serverList) {
    if (_optimisticFriendsList == null) return;

    final optimisticIds = _optimisticFriendsList!.map((ref) => ref.id).toSet();
    final serverIds = serverList.map((ref) => ref.id).toSet();

    if (optimisticIds.length == serverIds.length &&
        optimisticIds.difference(serverIds).isEmpty) {
      _optimisticFriendsList = null;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIEND ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> openDirectChat(BuildContext context, UsersRecord user) async {
    final currentUserId = currentUserUid;
    if (currentUserId.isEmpty) {
      _showErrorSnackbar(context, 'Please sign in to chat.');
      return;
    }

    final otherUserId = user.reference.id;
    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserId,
            otherUid: otherUserId,
          );
      if (!context.mounted) return;
      context.pushChatDetails(
        chatId: chatRef.id,
        transition: TransitionStandards.noTransition,
      );
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      _showErrorSnackbar(context, 'Unable to start chat. Please try again.');
    }
  }

  Future<void> sendFriendRequest(BuildContext context, UsersRecord user) async {
    try {
      await context.read<UserProvider>().sendFriendRequest(user.reference);
      if (!context.mounted) return;
      _showSuccessSnackbar(context, 'Friend request sent!');
    } catch (e) {
      AppLog.d('❌ TabFriendsController.sendFriendRequest error: $e');
      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Unable to send request. Please try again.');
    }
  }

  Future<void> cancelFriendRequest(
      BuildContext context, UsersRecord user) async {
    try {
      await context.read<UserProvider>().cancelFriendRequest(user.reference);
      if (!context.mounted) return;
      _showSuccessSnackbar(context, 'Request cancelled.');
    } catch (e) {
      AppLog.d('❌ TabFriendsController.cancelFriendRequest error: $e');
      if (!context.mounted) return;
      _showErrorSnackbar(
          context, 'Unable to cancel request. Please try again.');
    }
  }

  Future<void> acceptFriendRequest(
      BuildContext context, UsersRecord user) async {
    try {
      await context.read<UserProvider>().acceptFriendRequest(user.reference);
      if (!context.mounted) return;
      _showSuccessSnackbar(context, 'Friend request accepted!');
    } catch (e) {
      AppLog.d('❌ TabFriendsController.acceptFriendRequest error: $e');
      if (!context.mounted) return;
      _showErrorSnackbar(
          context, 'Unable to accept request. Please try again.');
    }
  }

  Future<void> denyFriendRequest(BuildContext context, UsersRecord user) async {
    try {
      await context.read<UserProvider>().rejectFriendRequest(user.reference);
      if (!context.mounted) return;
      _showSuccessSnackbar(context, 'Request denied.');
    } catch (e) {
      AppLog.d('❌ TabFriendsController.denyFriendRequest error: $e');
      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Unable to deny request. Please try again.');
    }
  }

  Future<void> removeFriend(
    BuildContext context,
    UsersRecord user,
    List<DocumentReference> currentFriendsList,
  ) async {
    try {
      // Optimistically update local state for immediate UI feedback
      _optimisticFriendsList =
          currentFriendsList.where((ref) => ref.id != user.reference.id).toList();
      notifyListeners();

      await context.read<UserProvider>().removeFriend(user.reference);
      if (!context.mounted) return;
      _showSuccessSnackbar(context, 'Friend removed');
    } catch (e) {
      AppLog.d('❌ TabFriendsController.removeFriend error: $e');
      // Revert optimistic update on error
      _optimisticFriendsList = null;
      notifyListeners();

      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Unable to remove friend. Please try again.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SNACKBAR HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.titleMedium.copyWith(color: AppColors.pure),
        ),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: AppColors.navyDark,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    showSnackbar(context, message);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  String getSectionLabel() {
    switch (_currentSegment) {
      case GolferSegment.discover:
        if (_searchTerm.isNotEmpty) {
          return "Results for '$_searchTerm'";
        }
        return 'Recommended for you';
      case GolferSegment.requests:
        return 'Pending requests';
      case GolferSegment.friends:
        return 'Your circle';
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
