import 'dart:async';

import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/models/game.dart';
import '/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
      setState(() {
        _isSearching = true;
        _activeQuery = query;
        if (reset) {
          _lastDocument = null;
          _hasMoreResults = false;
        }
      });
    }

    try {
      Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
          .collection('users')
          .orderBy('display_name_lower')
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching players: $e'),
          backgroundColor: Colors.red,
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
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.only(top: 12.0, bottom: 8.0),
                        width: 40.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2.0),
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
                              style: GoogleFonts.outfit(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A4D2E),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Color(0xFF718096)),
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
                          style: AppTheme.of(context).bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search members or add Guest',
                            hintStyle: AppTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.outfit(),
                              color: Color(0xFF718096),
                            ),
                            prefixIcon: Icon(Icons.search, size: 20.0),
                            filled: true,
                            fillColor: AppTheme.of(context).secondaryBackground,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: AppTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: AppTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: AppTheme.of(context).primary,
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
                            style: GoogleFonts.outfit(
                              fontSize: 13.0,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      // Results list
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          children: [
                            // Guest option (always shown at top)
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
                            // Search status or results
                            if (_activeQuery.length < _minSearchChars) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Text(
                                  'Type at least $_minSearchChars characters to search members.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.0,
                                    color: Color(0xFF718096),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ] else if (_isSearching) ...[
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: CircularProgressIndicator(
                                    color: AppTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            ] else if (_searchResults.isEmpty) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Text(
                                  'No members found.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.0,
                                    color: Color(0xFF718096),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ] else ...[
                              ...(_searchResults.map((profile) {
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
                              }).toList()),
                              if (_hasMoreResults)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () async {
                                        await _loadMoreResults();
                                        setModalState(() {});
                                      },
                                      child: Text('Load more'),
                                    ),
                                  ),
                                ),
                            ],
                          ],
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
    );
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.xs),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDisabled
            ? AppTheme.of(context).secondaryBackground.withValues(alpha: 0.5)
            : AppTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppTheme.of(context).alternate,
          ),
        ),
        child: Row(
          children: [
            // Avatar or Guest icon
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: isGuest ? Color(0xFF1A4D2E).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: isGuest
                ? Icon(Icons.person_outline, color: Color(0xFF1A4D2E), size: 24.0)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.network(
                      photoUrl != null && photoUrl.isNotEmpty
                        ? photoUrl
                        : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                      width: 40.0,
                      height: 40.0,
                      fit: BoxFit.cover,
                    ),
                  ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Color(0xFF718096) : Color(0xFF1A4D2E),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 13.0,
                        color: Color(0xFF718096),
                      ),
                    ),
                ],
              ),
            ),
            if (!isDisabled)
              Icon(
                Icons.add_circle_outline,
                color: AppTheme.of(context).primary,
                size: 24.0,
              ),
          ],
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

    if (isEmpty) {
      // Empty slot - show "Add" button
      return InkWell(
        onTap: () => _showAddPlayerModal(slotIndex, joinedPlayerIds),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppTheme.of(context).alternate,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: Color(0xFF1A4D2E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Icon(
                  Icons.person_add_outlined,
                  color: Color(0xFF1A4D2E),
                  size: 20.0,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  slotLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).primary,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Add',
                  style: GoogleFonts.outfit(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filled slot - show player info
    final bool isGuest = playerData['isGuest'] == true;
    final String name = playerData['name'] ?? 'Player';
    final String? photoUrl = playerData['photoUrl'];

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isGuest
          ? Color(0xFFFFF8E1)
          : Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isGuest
            ? Color(0xFFFFA726).withValues(alpha: 0.3)
            : Color(0xFF1A4D2E).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar or guest icon
          if (isGuest)
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: Color(0xFFFFA726).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Icon(
                Icons.person_outline,
                color: Color(0xFFF57C00),
                size: 24.0,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Image.network(
                photoUrl != null && photoUrl.isNotEmpty
                  ? photoUrl
                  : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                width: 40.0,
                height: 40.0,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A4D2E),
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  isGuest ? 'Guest' : 'Member',
                  style: GoogleFonts.outfit(
                    fontSize: 13.0,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icon(
              Icons.close,
              color: AppTheme.of(context).error,
              size: 20.0,
            ),
            borderRadius: 18.0,
            buttonSize: 36.0,
            fillColor: Colors.white,
            tooltip: 'Remove player',
            onPressed: () => _removePlayerFromSlot(slotIndex),
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
            backgroundColor: AppTheme.of(context).primaryBtnText,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: AppTheme.of(context).secondary,
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
                style: GoogleFonts.outfit(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.0,
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
                        style: GoogleFonts.outfit(
                          fontSize: 14.0,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.0,
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
                                borderRadius: BorderRadius.circular(16.0),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12.0,
                                    offset: Offset(0, 4),
                                  ),
                                ],
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
                                          style: GoogleFonts.outfit(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A4D2E),
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
                                              padding: EdgeInsets.all(16.0),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE8F5E9),
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                border: Border.all(
                                                  color: Color(0xFF1A4D2E)
                                                      .withValues(alpha: 0.2),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            24.0),
                                                    child: Image.network(
                                                      profile?.photoUrl
                                                                  .isNotEmpty ??
                                                              false
                                                          ? profile!.photoUrl
                                                          : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                      width: 48.0,
                                                      height: 48.0,
                                                      fit: BoxFit.cover,
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
                                                          style: GoogleFonts
                                                              .outfit(
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                                0xFF1A4D2E),
                                                          ),
                                                        ),
                                                        SizedBox(height: 2.0),
                                                        Text(
                                                          'Game Creator',
                                                          style: GoogleFonts
                                                              .outfit(
                                                            fontSize: 13.0,
                                                            color: Color(
                                                                0xFF718096),
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
                                                      color: Color(0xFF1A4D2E),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                    ),
                                                    child: Text(
                                                      'You',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 13.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
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
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1A4D2E),
                                                ),
                                              ),
                                              Text(
                                                'Tap a slot to add',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13.0,
                                                  color: Color(0xFF718096),
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
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.0,
                                              color: Color(0xFF718096),
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
                                                    backgroundColor: Colors.red,
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
                                                    backgroundColor: Colors.red,
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
                                                    backgroundColor: Colors.red,
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
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: Color(0xFF1A4D2E)
                                        .withValues(alpha: 0.2),
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 20.0,
                                          color: Color(0xFF1A4D2E),
                                        ),
                                        SizedBox(width: 8.0),
                                        Text(
                                          'Game Summary',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A4D2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: AppSpacing.sm),
                                    _buildInfoRow(
                                      Icons.golf_course,
                                      game.coursePlay,
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    _buildInfoRow(
                                      Icons.calendar_today,
                                      '${dateTimeFormat("EEEE, MMM d", game.date)} • ${dateTimeFormat("jm", game.date)}',
                                    ),
                                    SizedBox(height: AppSpacing.xs),
                                    _buildInfoRow(
                                      Icons.people,
                                      '$currentPlayerCount confirmed, $remainingSlots ${remainingSlots == 1 ? 'spot' : 'spots'} open',
                                    ),
                                    if (game.gameType.isNotEmpty) ...[
                                      SizedBox(height: AppSpacing.xs),
                                      _buildInfoRow(
                                        Icons.sports_golf,
                                        game.gameType,
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.0,
          color: Color(0xFF718096),
        ),
        SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14.0,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
      ],
    );
  }
}
