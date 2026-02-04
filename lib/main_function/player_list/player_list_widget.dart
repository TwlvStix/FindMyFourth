import 'dart:async';

import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/form_field_controller.dart';
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
  final List<FormFieldController<String>> _dropDownControllers = [];

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
    for (final controller in _dropDownControllers) {
      controller.dispose();
    }
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

  void _addPlayerToNextSlot(UserProfile profile) {
    final uid = profile.uid;
    if (uid.isEmpty) return;
    final alreadySelected =
        _dropDownControllers.any((controller) => controller.value == uid);
    if (alreadySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player already selected.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    FormFieldController<String>? targetController;
    for (final controller in _dropDownControllers) {
      final value = controller.value;
      if (value == null || value.isEmpty) {
        targetController = controller;
        break;
      }
    }

    if (targetController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No open slots available.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      targetController!.value = uid;
      _labelCache[uid] =
          profile.displayName.isNotEmpty ? profile.displayName : 'Player';
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

        while (_dropDownControllers.length < remainingSlots) {
          _dropDownControllers.add(FormFieldController<String>(null));
        }
        if (_dropDownControllers.length > remainingSlots) {
          _dropDownControllers.removeRange(
              remainingSlots, _dropDownControllers.length);
        }

        final selectedValues = _dropDownControllers
            .map((controller) => controller.value)
            .whereType<String>()
            .toList();
        final selectedUids = selectedValues
            .where((value) => value != guestOptionValue && value.isNotEmpty)
            .toList();

        final labelMap = Map<String, String>.from(_labelCache);
        for (final profile in _searchResults) {
          if (profile.uid.isEmpty) continue;
          labelMap[profile.uid] =
              profile.displayName.isNotEmpty ? profile.displayName : 'Name';
        }
        for (final uid in selectedUids) {
          labelMap.putIfAbsent(uid, () => 'Player');
        }

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
                        'Select your friends who are already playing',
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
                                        Text(
                                          'Search Players',
                                          style: AppTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                                  fontStyle: AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                                ),
                                                color: Color(0xFF1A4D2E),
                                                letterSpacing: 0.0,
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                        ),
                                        SizedBox(height: AppSpacing.sm),
                                        TextField(
                                          controller: _searchController,
                                          onChanged: _onSearchChanged,
                                          style: AppTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.outfit(
                                                  fontWeight: AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                                  fontStyle: AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Type at least $_minSearchChars characters',
                                            hintStyle: AppTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.outfit(
                                                    fontWeight: AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                    fontStyle: AppTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                  ),
                                                  letterSpacing: 0.0,
                                                  fontWeight: AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                                  fontStyle: AppTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                                ),
                                            prefixIcon:
                                                Icon(Icons.search, size: 20.0),
                                            filled: true,
                                            fillColor: AppTheme.of(context)
                                                .secondaryBackground,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                              vertical: 12.0,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide(
                                                color: AppTheme.of(context)
                                                    .alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide(
                                                color: AppTheme.of(context)
                                                    .alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              borderSide: BorderSide(
                                                color: AppTheme.of(context)
                                                    .primary,
                                                width: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.sm),
                                        if (_activeQuery.length <
                                            _minSearchChars)
                                          Text(
                                            'Type at least $_minSearchChars characters to search all players.',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.0,
                                              color: Color(0xFF718096),
                                            ),
                                          )
                                        else if (_isSearching)
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 16.0,
                                                height: 16.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  color: AppTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                              SizedBox(width: 8.0),
                                              Text(
                                                'Searching...',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13.0,
                                                  color: Color(0xFF718096),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.0,
                                              color: Color(0xFF718096),
                                            ),
                                          ),
                                        if (_activeQuery.length >=
                                            _minSearchChars) ...[
                                          SizedBox(height: AppSpacing.md),
                                          if (_searchResults.isNotEmpty)
                                            Column(
                                              children: _searchResults
                                                  .map((profile) {
                                                final isInGame =
                                                    joinedPlayerIds
                                                        .contains(profile.uid);
                                                final isSelected =
                                                    selectedUids
                                                        .contains(profile.uid);
                                                final canAdd =
                                                    !isInGame && !isSelected;

                                                return Container(
                                                  width: double.infinity,
                                                  margin: EdgeInsets.only(
                                                      bottom: AppSpacing.xs),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.sm,
                                                    vertical: AppSpacing.xs,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.of(context)
                                                        .secondaryBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0),
                                                    border: Border.all(
                                                      color: AppTheme.of(context)
                                                          .alternate,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                18.0),
                                                        child: Image.network(
                                                          profile.photoUrl
                                                                  .isNotEmpty
                                                              ? profile.photoUrl
                                                              : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                          width: 36.0,
                                                          height: 36.0,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: AppSpacing.sm),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              profile.displayName
                                                                      .isNotEmpty
                                                                  ? profile
                                                                      .displayName
                                                                  : 'Player',
                                                              style: GoogleFonts
                                                                  .outfit(
                                                                fontSize: 14.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                    0xFF1A4D2E),
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            if (isInGame ||
                                                                isSelected)
                                                              Text(
                                                                isInGame
                                                                    ? 'Already in game'
                                                                    : 'Selected',
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
                                                      TextButton(
                                                        onPressed: canAdd
                                                            ? () => _addPlayerToNextSlot(
                                                                profile)
                                                            : null,
                                                        child: Text(
                                                          canAdd
                                                              ? 'Add'
                                                              : 'Added',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            )
                                          else if (!_isSearching)
                                            Text(
                                              'No players found.',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13.0,
                                                color: Color(0xFF718096),
                                              ),
                                            ),
                                          if (_hasMoreResults)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: _loadMoreResults,
                                                child: Text('Load more'),
                                              ),
                                            ),
                                          SizedBox(height: AppSpacing.lg),
                                        ],
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
                                        // Player dropdowns section
                                        if (remainingSlots > 0) ...[
                                          Text(
                                            'Add Friends',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A4D2E),
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.sm),
                                        ],
                                        for (var i = 0;
                                            i < remainingSlots;
                                            i++) ...[
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Player ${currentPlayerCount + i + 1}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF718096),
                                                    ),
                                                  ),
                                                  if (_dropDownControllers[i]
                                                          .value !=
                                                      null &&
                                                      _dropDownControllers[i]
                                                          .value!
                                                          .isNotEmpty)
                                                    AppIconButton(
                                                      icon: Icon(
                                                        Icons.delete_outline,
                                                        color: AppTheme.of(context)
                                                            .error,
                                                        size: 20.0,
                                                      ),
                                                      borderRadius: 18.0,
                                                      buttonSize: 32.0,
                                                      fillColor:
                                                          Colors.transparent,
                                                      tooltip: 'Remove player',
                                                      onPressed: () {
                                                        setState(() {
                                                          _dropDownControllers[i]
                                                              .value = null;
                                                        });
                                                      },
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: AppSpacing.xs),
                                              Builder(
                                                builder: (context) {
                                                  final currentValue =
                                                      _dropDownControllers[i]
                                                          .value;
                                                  final slotOptions = <String>[
                                                    if (currentValue != null &&
                                                        currentValue.isNotEmpty &&
                                                        currentValue !=
                                                            guestOptionValue)
                                                      currentValue,
                                                    guestOptionValue,
                                                  ];
                                                  final slotLabels = slotOptions
                                                      .map(
                                                        (uid) =>
                                                            uid == guestOptionValue
                                                                ? 'Guest'
                                                                : (labelMap[uid] ??
                                                                    'Player'),
                                                      )
                                                      .toList();

                                                  return AppDropDown<String>(
                                                    controller:
                                                        _dropDownControllers[i],
                                                    options: slotOptions,
                                                    optionLabels: slotLabels,
                                                    onChanged: (val) {
                                                      if (val != null &&
                                                          val !=
                                                              guestOptionValue) {
                                                        _labelCache[val] ??=
                                                            labelMap[val] ??
                                                                'Player';
                                                      }
                                                      if (mounted) {
                                                        setState(() {});
                                                      }
                                                    },
                                                    width: 300.0,
                                                    height: 50.0,
                                                    searchHintTextStyle:
                                                        AppTheme.of(context)
                                                            .labelMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .outfit(
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing: 0.0,
                                                              fontWeight: AppTheme
                                                                      .of(context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                              fontStyle: AppTheme
                                                                      .of(context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                            ),
                                                    searchTextStyle:
                                                        AppTheme.of(context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .outfit(
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing: 0.0,
                                                              fontWeight: AppTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                              fontStyle: AppTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                            ),
                                                    textStyle:
                                                        AppTheme.of(context)
                                                            .bodyMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .outfit(
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing: 0.0,
                                                              fontWeight: AppTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                              fontStyle: AppTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                            ),
                                                    hintText:
                                                        'Find Player ${currentPlayerCount + i + 1}',
                                                    searchHintText:
                                                        'Search Players',
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color: AppTheme.of(context)
                                                          .secondaryText,
                                                      size: 24.0,
                                                    ),
                                                    fillColor: AppTheme.of(context)
                                                        .secondaryBackground,
                                                    elevation: 2.0,
                                                    borderColor:
                                                        AppTheme.of(context)
                                                            .alternate,
                                                    borderWidth: 2.0,
                                                    borderRadius: 8.0,
                                                    margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
                                                    hidesUnderline: true,
                                                    isOverButton: true,
                                                    isSearchable: false,
                                                    isMultiSelect: false,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          if (i < remainingSlots - 1)
                                            SizedBox(height: AppSpacing.md),
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

                                              final selections = _dropDownControllers
                                                  .map((controller) => controller.value)
                                                  .toList();
                                              final joinedPlayersToAdd =
                                                  <DocumentReference>[];
                                              final guestPlayersToAdd =
                                                  <String>[];

                                              for (final selection
                                                  in selections) {
                                                if (selection == null ||
                                                    selection.isEmpty) {
                                                  continue;
                                                }
                                                if (selection ==
                                                    guestOptionValue) {
                                                  guestPlayersToAdd.add(
                                                    'Guest ${game.guestPlayers.length + guestPlayersToAdd.length + 1}',
                                                  );
                                                } else {
                                                  final playerRef =
                                                      FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'users')
                                                          .doc(selection);
                                                  if (playerRef != null) {
                                                    joinedPlayersToAdd
                                                        .add(playerRef);
                                                  }
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
