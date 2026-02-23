import 'dart:async';

import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/models/game.dart';
import '/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PlayerListWidget extends StatefulWidget {
  const PlayerListWidget({
    super.key,
    required this.gameRef,
  });

  final DocumentReference gameRef;

  static String routeName = 'PlayerList';
  static String routePath = '/usersinCreateGame';

  @override
  State<PlayerListWidget> createState() => _PlayerListWidgetState();
}

class _PlayerListWidgetState extends State<PlayerListWidget> {
  static const String guestOptionValue = 'guest';

  // Design token for gold accent
  static final Color _goldAccent = AppColors.goldLight;

  List<DocumentReference> playersJoined = [];
  void addToPlayersJoined(DocumentReference item) => playersJoined.add(item);
  void removeFromPlayersJoined(DocumentReference item) =>
      playersJoined.remove(item);
  void removeAtIndexFromPlayersJoined(int index) =>
      playersJoined.removeAt(index);
  void insertAtIndexInPlayersJoined(int index, DocumentReference item) =>
      playersJoined.insert(index, item);
  void updatePlayersJoinedAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      playersJoined[index] = updateFn(playersJoined[index]);

  List<String> playersJoinedUID = [];
  void addToPlayersJoinedUID(String item) => playersJoinedUID.add(item);
  void removeFromPlayersJoinedUID(String item) => playersJoinedUID.remove(item);
  void removeAtIndexFromPlayersJoinedUID(int index) =>
      playersJoinedUID.removeAt(index);
  void insertAtIndexInPlayersJoinedUID(int index, String item) =>
      playersJoinedUID.insert(index, item);
  void updatePlayersJoinedUIDAtIndex(int index, Function(String) updateFn) =>
      playersJoinedUID[index] = updateFn(playersJoinedUID[index]);

  final formKey = GlobalKey<FormState>();

  // Player slots state: Map<slot_index, player_data>
  // player_data format: {'uid': string, 'name': string, 'isGuest': bool, 'photoUrl': string?}
  final Map<int, Map<String, dynamic>> _playerSlots = {};

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Track if submission is in progress to prevent double submission
  bool _isSubmitting = false;

  static const int _minSearchChars = 2;
  static const int _pageSize = 25;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _activeQuery = '';
  bool _isSearching = false;
  bool _hasMoreResults = false;
  int _searchToken = 0;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  List<UserProfile> _searchResults = [];
  final Map<String, String> _labelCache = {};
  StateSetter? _modalSetState;
  BuildContext? _modalContext;

  void _refreshModalIfOpen() {
    final modalSetState = _modalSetState;
    final modalContext = _modalContext;
    if (!mounted || modalSetState == null || modalContext == null) {
      return;
    }
    if (!modalContext.mounted) {
      _modalSetState = null;
      _modalContext = null;
      return;
    }
    modalSetState(() {});
  }

  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _modalSetState = null;
    _modalContext = null;
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (query.length < _minSearchChars) {
        setState(() {
          _activeQuery = query;
          _searchResults = [];
          _lastDocument = null;
          _hasMoreResults = false;
          _isSearching = false;
        });
        _refreshModalIfOpen();
        return;
      }
      _runSearch(query: query, reset: true);
    });
  }

  void _addPlayerToSlot(int slotIndex, {UserProfile? profile, bool isGuest = false}) {
    if (isGuest) {
      setState(() {
        _playerSlots[slotIndex] = {
          'uid': guestOptionValue,
          'name': 'Guest',
          'isGuest': true,
        };
      });
      return;
    }

    if (profile == null) return;
    final uid = profile.uid;
    if (uid.isEmpty) return;

    // Check if player already selected in any slot
    final alreadySelected = _playerSlots.values.any((slot) => slot['uid'] == uid);
    if (alreadySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player already selected.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _playerSlots[slotIndex] = {
        'uid': uid,
        'name': profile.displayName.isNotEmpty ? profile.displayName : 'Player',
        'isGuest': false,
        'photoUrl': profile.photoUrl,
      };
      _labelCache[uid] = profile.displayName.isNotEmpty ? profile.displayName : 'Player';
    });
  }

  void _removePlayerFromSlot(int slotIndex) {
    setState(() {
      _playerSlots.remove(slotIndex);
    });
  }

  Future<void> _runSearch({required String query, required bool reset}) async {
    final searchToken = ++_searchToken;
    if (mounted) {
      debugPrint(
        '🔍 AddPlayer search: query="$query" length=${query.length} reset=$reset',
      );
      setState(() {
        _isSearching = true;
        _activeQuery = query;
        if (reset) {
          _lastDocument = null;
          _hasMoreResults = false;
        }
      });
      _refreshModalIfOpen();
    }

    try {
      Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
          .collection('users')
          .orderBy('display_name_lowercase')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(_pageSize);

      if (!reset && _lastDocument != null) {
        baseQuery = baseQuery.startAfterDocument(_lastDocument!);
      }

      final snapshot = await baseQuery.get();
      if (!mounted || searchToken != _searchToken) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final results = snapshot.docs
          .map(UserProfile.fromDoc)
          .where((profile) => profile.uid != currentUserId)
          .toList();

      for (final profile in results) {
        _labelCache[profile.uid] =
            profile.displayName.isNotEmpty ? profile.displayName : 'Name';
      }

      setState(() {
        _lastDocument =
            snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDocument;
        _hasMoreResults = snapshot.docs.length == _pageSize;
        if (reset) {
          _searchResults = results;
        } else {
          final existing = _searchResults.map((e) => e.uid).toSet();
          _searchResults = [
            ..._searchResults,
            ...results.where((profile) => !existing.contains(profile.uid)),
          ];
        }
        _isSearching = false;
      });
      _refreshModalIfOpen();
    } catch (e) {
      if (!mounted || searchToken != _searchToken) return;
      setState(() {
        _isSearching = false;
        _hasMoreResults = false;
        if (reset) {
          _searchResults = [];
          _lastDocument = null;
        }
      });
      _refreshModalIfOpen();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching players: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isSearching || !_hasMoreResults) return;
    if (_activeQuery.length < _minSearchChars) return;
    await _runSearch(query: _activeQuery, reset: false);
  }

  Future<void> _showAddPlayerModal(int slotIndex, Set<String> joinedPlayerIds) async {
    // Reset search for modal
    _searchController.clear();
    _activeQuery = '';
    _searchResults = [];
    _lastDocument = null;
    _hasMoreResults = false;
    _isSearching = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            _modalSetState = setModalState;
            _modalContext = context;
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.xl),
                      topRight: Radius.circular(AppBorderRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                        width: 40.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Player',
                              style: AppTypography.sectionHeader.copyWith(
                                color: AppColors.greenDark,
                              ),
                            ),
                            IconButton(
                              icon: AppIcon(
                                icon: AppPhosphorIcons.close,
                                color: AppColors.textMuted,
                                size: AppIconSize.md,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1.0),
                      // Search field
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (value) {
                            _onSearchChanged(value);
                            setModalState(() {});
                          },
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search members or add Guest',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: AppIcon(
                                icon: AppPhosphorIcons.search,
                                size: AppIconSize.button,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                              borderSide: BorderSide(
                                color: AppColors.inputBorderIdle,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                              borderSide: BorderSide(
                                color: AppColors.inputBorderIdle,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                              borderSide: BorderSide(
                                color: AppColors.inputBorderFocused,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Helper text
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tap a player to add them to this slot',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 13,
                              color: AppColors.stone,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      // Results list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          itemCount: _calculateItemCount(),
                          itemBuilder: (context, index) {
                            return _buildListItem(context, index, slotIndex, joinedPlayerIds);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _modalSetState = null;
      _modalContext = null;
    });
  }

  int _calculateItemCount() {
    // Item 0: Guest option (always shown)
    int count = 1;

    // Item 1+: Status message or search results
    if (_activeQuery.length < _minSearchChars) {
      count += 1; // Status message
    } else if (_isSearching) {
      count += 1; // Loading spinner
    } else if (_searchResults.isEmpty) {
      count += 1; // No results message
    } else {
      count += _searchResults.length; // Search results
      if (_hasMoreResults) {
        count += 1; // Load more button
      }
    }

    return count;
  }

  Widget _buildListItem(BuildContext context, int index, int slotIndex, Set<String> joinedPlayerIds) {
    // Index 0: Guest option
    if (index == 0) {
      return Column(
        children: [
          _buildPlayerOption(
            context: context,
            name: 'Guest',
            subtitle: 'Add a guest player',
            photoUrl: null,
            isGuest: true,
            onTap: () {
              _addPlayerToSlot(slotIndex, isGuest: true);
              Navigator.pop(context);
            },
          ),
          SizedBox(height: AppSpacing.sm),
        ],
      );
    }

    // Index 1+: Status messages or search results
    final contentIndex = index - 1;

    if (_activeQuery.length < _minSearchChars) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'Type at least $_minSearchChars characters to search members.',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 13,
            color: AppColors.stone,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else if (_isSearching) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(
            color: AppColors.navyDark,
          ),
        ),
      );
    } else if (_searchResults.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'No members found.',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 13,
            color: AppColors.stone,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      // Search results
      if (contentIndex < _searchResults.length) {
        final profile = _searchResults[contentIndex];
        final isInGame = joinedPlayerIds.contains(profile.uid);
        final isSelected = _playerSlots.values.any((slot) => slot['uid'] == profile.uid);
        final canAdd = !isInGame && !isSelected;

        return _buildPlayerOption(
          context: context,
          name: profile.displayName.isNotEmpty ? profile.displayName : 'Player',
          subtitle: isInGame ? 'Already in game' : (isSelected ? 'Already selected' : null),
          photoUrl: profile.photoUrl,
          isGuest: false,
          onTap: canAdd ? () {
            _addPlayerToSlot(slotIndex, profile: profile);
            Navigator.pop(context);
          } : null,
        );
      } else if (_hasMoreResults) {
        // Load more button
        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: TextButton(
              onPressed: () async {
                await _loadMoreResults();
                final modalSetState = _modalSetState;
                if (modalSetState != null) {
                  modalSetState(() {});
                }
              },
              child: Text('Load more'),
            ),
          ),
        );
      }
    }

    return SizedBox.shrink();
  }

  Widget _buildPlayerOption({
    required BuildContext context,
    required String name,
    String? subtitle,
    String? photoUrl,
    required bool isGuest,
    VoidCallback? onTap,
  }) {
    final bool isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.xs),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.navyLight.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // ── Avatar ─────────────────────────────────────────────────
              if (isGuest)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _goldAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: _goldAccent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: AppIcon(
                    icon: AppPhosphorIcons.profile,
                    color: _goldAccent,
                    size: AppIconSize.md,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.navyLight,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            width: 48,
                            height: 48,
                            cacheWidth: 144,
                            cacheHeight: 144,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => AppIcon(
                              icon: AppPhosphorIcons.profile,
                              color: AppColors.textMuted,
                              size: AppIconSize.md,
                            ),
                          )
                        : AppIcon(
                            icon: AppPhosphorIcons.profile,
                            color: AppColors.textMuted,
                            size: AppIconSize.md,
                          ),
                  ),
                ),
              AppSpacing.horizontalSmBox,

              // ── Name + subtitle ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _goldAccent,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Add action ─────────────────────────────────────────────
              if (!isDisabled)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _goldAccent,
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: AppIcon(
                    icon: AppPhosphorIcons.add,
                    color: AppColors.navyDark,
                    size: AppIconSize.button,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSlotCard({
    required int slotIndex,
    required String slotLabel,
    required Map<String, dynamic>? playerData,
    required Set<String> joinedPlayerIds,
  }) {
    final bool isEmpty = playerData == null;

    // ── Empty slot — "Add" placeholder ──────────────────────────────────
    if (isEmpty) {
      return GestureDetector(
        onTap: () => _showAddPlayerModal(slotIndex, joinedPlayerIds),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.navy.withValues(alpha: 0.3),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: AppColors.navy.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.addPlayer,
                  color: AppColors.navy.withValues(alpha: 0.6),
                  size: AppIconSize.md,
                ),
              ),
              AppSpacing.horizontalSmBox,
              Expanded(
                child: Text(
                  slotLabel,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy.withValues(alpha: 0.6),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  'Add',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Filled slot — player info ───────────────────────────────────────
    final bool isGuest = playerData['isGuest'] == true;
    final String name = playerData['name'] ?? 'Player';
    final String? photoUrl = playerData['photoUrl'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.navyLight.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Avatar ─────────────────────────────────────────────────────
          if (isGuest)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _goldAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: _goldAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.profile,
                color: _goldAccent,
                size: AppIconSize.md,
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        width: 48,
                        height: 48,
                        cacheWidth: 144,
                        cacheHeight: 144,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => AppIcon(
                          icon: AppPhosphorIcons.profile,
                          color: AppColors.textMuted,
                          size: AppIconSize.md,
                        ),
                      )
                    : AppIcon(
                        icon: AppPhosphorIcons.profile,
                        color: AppColors.textMuted,
                        size: AppIconSize.md,
                      ),
              ),
            ),
          AppSpacing.horizontalSmBox,

          // ── Name + role ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest ? 'Guest' : 'Member',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _goldAccent,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // ── Remove action ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => _removePlayerFromSlot(slotIndex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: AppIcon(
                icon: AppPhosphorIcons.close,
                color: AppColors.textPrimary,
                size: AppIconSize.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation after submission
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (_isSubmitting) {
          debugPrint('⚠️ PLAYER LIST: Back navigation blocked - submission in progress');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please wait while we add your players...'),
                duration: Duration(seconds: 1),
              ),
            );
          });
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.gameRef.snapshots(),
        builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: AppColors.pure,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: AppColors.navy,
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final game = Game.fromDoc(snapshot.data!);
        final currentUser = FirebaseAuth.instance.currentUser;
        final currentUserRef = currentUser == null
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid);

        final currentPlayerCount =
            game.joinedPlayers.length + game.guestPlayers.length;
        final joinedPlayerIds =
            game.joinedPlayers.map((player) => player.id).toSet();
        final remainingSlots =
            (game.maxPlayers - currentPlayerCount).clamp(0, game.maxPlayers);

        debugPrint(
            'PlayerList: current=$currentPlayerCount/${game.maxPlayers}, remaining=$remainingSlots');

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0.0,
              elevation: 0.0,
              shadowColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Text(
                'Add Your Group',
                style: AppTypography.sectionHeader.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [],
              centerTitle: true,
            ),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Top spacing for AppBar
                    SizedBox(height: MediaQuery.of(context).padding.top + 56),
                    // Subtitle section
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Build your group by adding friends or guests',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Content area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: AppSpacing.allMd,
                        child: Column(
                          children: [
                            // Main content card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                                boxShadow: [AppElevation.lg],
                              ),
                                child: Padding(
                                  padding: AppSpacing.allLg,
                                  child: Form(
                                    key: formKey,
                                    autovalidateMode:
                                        AutovalidateMode.disabled,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Section header
                                        Text(
                                          'Your Group',
                                          style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.greenDark,
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.md),
                                        // Current user card
                                        StreamBuilder<DocumentSnapshot>(
                                          stream:
                                              currentUserRef?.snapshots(),
                                          builder: (context, userSnapshot) {
                                            final profile = userSnapshot.hasData
                                                ? UserProfile.fromDoc(
                                                    userSnapshot.data!)
                                                : null;
                                            return Container(
                                              padding: AppSpacing.allMd,
                                              decoration: BoxDecoration(
                                                color: AppColors.cloud,
                                                borderRadius:
                                                    BorderRadius.circular(AppBorderRadius.md),
                                                border: Border.all(
                                                  color: AppColors.greenDark
                                                      .withValues(alpha: 0.2),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 48.0,
                                                    height: 48.0,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.navyLight,
                                                      borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                                                      child: profile?.photoUrl.isNotEmpty ?? false
                                                          ? Image.network(
                                                              profile!.photoUrl,
                                                              width: 48.0,
                                                              height: 48.0,
                                                              fit: BoxFit.cover,
                                                              cacheWidth: 96,
                                                              cacheHeight: 96,
                                                              errorBuilder: (_, __, ___) => AppIcon(
                                                                icon: AppPhosphorIcons.profile,
                                                                color: AppColors.textMuted,
                                                                size: AppIconSize.md,
                                                              ),
                                                            )
                                                          : AppIcon(
                                                              icon: AppPhosphorIcons.profile,
                                                              color: AppColors.textMuted,
                                                              size: AppIconSize.md,
                                                            ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12.0),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          profile?.displayName
                                                                      .isNotEmpty ??
                                                                  false
                                                              ? profile!
                                                                  .displayName
                                                              : 'You',
                                                          style: AppTypography.titleSmall.copyWith(
                                                            color: AppColors.greenDark,
                                                          ),
                                                        ),
                                                        SizedBox(height: 2.0),
                                                        Text(
                                                          'Game Creator',
                                                          style: AppTypography.labelSmall.copyWith(
                                                            fontSize: 13,
                                                            color: AppColors.textMuted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                      vertical: 6.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.greenDark,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppBorderRadius.xl),
                                                    ),
                                                    child: Text(
                                                      'You',
                                                      style: AppTypography.labelSmall.copyWith(
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: AppSpacing.lg),
                                        // Player slots section
                                        if (remainingSlots > 0) ...[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Add Friends',
                                                style: AppTypography.titleSmall.copyWith(
                                                  color: AppColors.greenDark,
                                                ),
                                              ),
                                              Text(
                                                'Tap a slot to add',
                                                style: AppTypography.labelSmall.copyWith(
                                                  fontSize: 13,
                                                  color: AppColors.stone,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: AppSpacing.md),
                                        ],
                                        for (var i = 0; i < remainingSlots; i++) ...[
                                          _buildPlayerSlotCard(
                                            slotIndex: i,
                                            slotLabel: 'Player ${currentPlayerCount + i + 1}',
                                            playerData: _playerSlots[i],
                                            joinedPlayerIds: joinedPlayerIds,
                                          ),
                                          if (i < remainingSlots - 1)
                                            SizedBox(height: AppSpacing.sm),
                                        ],
                                        if (remainingSlots == 0) ...[
                                          Text(
                                            'This game is already full.',
                                            style: AppTypography.labelSmall.copyWith(
                                              fontSize: 13,
                                              color: AppColors.stone,
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.md),
                                        ],
                                        SizedBox(height: AppSpacing.xl),
                                        // Submit button
                                        SizedBox(
                                          width: double.infinity,
                                          child: AppButtonEnhanced(
                                            onPressed: _isSubmitting ? null : () async {
                                              // Prevent double submission
                                              if (_isSubmitting) {
                                                debugPrint('⚠️ PLAYER LIST: Already submitting, ignoring click');
                                                return;
                                              }

                                              setState(() {
                                                _isSubmitting = true;
                                              });

                                              debugPrint('👥 PLAYER LIST: Starting player submission');
                                              debugPrint('👥 PLAYER LIST: Current game max players: ${game.maxPlayers}');
                                              debugPrint('👥 PLAYER LIST: Current joined players: ${game.joinedPlayers.length}');
                                              debugPrint('👥 PLAYER LIST: Current guest players: ${game.guestPlayers.length}');

                                              // Calculate current player count
                                              final currentPlayerCount = game.joinedPlayers.length + game.guestPlayers.length;
                                              debugPrint('👥 PLAYER LIST: Current total players: $currentPlayerCount / ${game.maxPlayers}');

                                              // Validate we haven't exceeded max players
                                              if (currentPlayerCount >= game.maxPlayers) {
                                                debugPrint('❌ PLAYER LIST: Game is already full!');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Game is already full (${game.maxPlayers} players)'),
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                );
                                                setState(() {
                                                  _isSubmitting = false;
                                                });
                                                return;
                                              }

                                              final joinedPlayersToAdd =
                                                  <DocumentReference>[];
                                              final guestPlayersToAdd =
                                                  <String>[];

                                              for (final slotData in _playerSlots.values) {
                                                final uid = slotData['uid'];
                                                final isGuest = slotData['isGuest'] == true;

                                                if (isGuest) {
                                                  guestPlayersToAdd.add(
                                                    'Guest ${game.guestPlayers.length + guestPlayersToAdd.length + 1}',
                                                  );
                                                } else if (uid != null && uid.isNotEmpty) {
                                                  final playerRef =
                                                      FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(uid);
                                                  joinedPlayersToAdd.add(playerRef);
                                                }
                                              }

                                              debugPrint('👥 PLAYER LIST: Adding ${joinedPlayersToAdd.length} joined players');
                                              debugPrint('👥 PLAYER LIST: Adding ${guestPlayersToAdd.length} guest players');

                                              // Validate total count won't exceed max
                                              final newPlayerCount = currentPlayerCount + joinedPlayersToAdd.length + guestPlayersToAdd.length;
                                              if (newPlayerCount > game.maxPlayers) {
                                                debugPrint('❌ PLAYER LIST: Would exceed max players: $newPlayerCount > ${game.maxPlayers}');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Cannot add ${joinedPlayersToAdd.length + guestPlayersToAdd.length} players - would exceed max (${game.maxPlayers})'),
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                );
                                                setState(() {
                                                  _isSubmitting = false;
                                                });
                                                return;
                                              }

                                              try {
                                                if (joinedPlayersToAdd
                                                        .isNotEmpty ||
                                                    guestPlayersToAdd
                                                        .isNotEmpty) {
                                                  await widget.gameRef
                                                      .update({
                                                    if (joinedPlayersToAdd
                                                        .isNotEmpty)
                                                      'joined_players':
                                                          FieldValue.arrayUnion(
                                                              joinedPlayersToAdd),
                                                    if (guestPlayersToAdd
                                                        .isNotEmpty)
                                                      'guest_players':
                                                          FieldValue.arrayUnion(
                                                              guestPlayersToAdd),
                                                  });
                                                  debugPrint('✅ PLAYER LIST: Players added successfully');
                                                } else {
                                                  debugPrint('ℹ️ PLAYER LIST: No players selected, proceeding anyway');
                                                }

                                                // Navigate to Game List
                                                // This replaces the current location and prevents back navigation issues
                                                debugPrint('🚀 PLAYER LIST: Navigating to Game List');

                                                if (!mounted) return;

                                                // Use context.goNamed for standard API
                                                context.goNamed(GamesListWidget.routeName);
                                              } catch (e) {
                                                debugPrint('❌ PLAYER LIST: Error adding players: $e');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error adding players: $e'),
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                );
                                                setState(() {
                                                  _isSubmitting = false;
                                                });
                                              }
                                            },
                                            text: _isSubmitting ? 'Adding...' : 'Add to Group',
                                            variant:
                                                AppButtonVariant.primary,
                                            size: AppButtonSize.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.md),
                              // Game summary card
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  border: Border.all(
                                    color: AppColors.greenDark
                                        .withValues(alpha: 0.2),
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        AppIcon(
                                          icon: AppPhosphorIcons.info,
                                          size: AppIconSize.button,
                                          color: AppColors.greenDark,
                                        ),
                                        SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Game Summary',
                                          style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.greenDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: AppSpacing.sm),
                                    _buildInfoRow(
                                      phosphorIcon: AppPhosphorIcons.course,
                                      text: game.coursePlay,
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    _buildInfoRow(
                                      phosphorIcon: AppPhosphorIcons.calendarCheck,
                                      text: '${dateTimeFormat("EEEE, MMM d", game.date)} • ${dateTimeFormat("jm", game.date)}',
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    _buildInfoRow(
                                      phosphorIcon: AppPhosphorIcons.golfers,
                                      text: '$currentPlayerCount confirmed, $remainingSlots ${remainingSlots == 1 ? 'spot' : 'spots'} open',
                                    ),
                                    if (game.gameType.isNotEmpty) ...[
                                      SizedBox(height: AppSpacing.xs),
                                      _buildInfoRow(
                                        phosphorIcon: AppPhosphorIcons.golfCourse,
                                        text: game.gameType,
                                      ),
                                    ],
                                  ],
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildInfoRow({PhosphorIconData? phosphorIcon, required String text}) {
    return Row(
      children: [
        if (phosphorIcon != null)
          AppIcon(
            icon: phosphorIcon,
            size: AppIconSize.xs,
            color: AppColors.textSecondary,
          ),
        AppSpacing.horizontalXsBox,
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
