import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/fairway_background.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/models/vibe_profile.dart';
import '/providers/game_provider.dart';
import '/providers/group_vibe_provider.dart';
import '/providers/join_request_provider.dart';
import '/services/vibe_group_matcher.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';

import 'components/game_joined_dashboard_content.dart';
import 'components/game_joined_state_handler.dart';
import 'components/open_premium_vibe_page.dart';
import 'components/premium_app_bar.dart';
import 'controllers/game_joined_detailed_controller.dart';
import 'controllers/game_joined_edit_actions.dart';
import 'controllers/game_joined_player_actions.dart';
import 'controllers/game_joined_request_actions.dart';
import 'controllers/game_joined_stream_controller.dart';

class GameJoinedDetailedWidget extends StatefulWidget {
  const GameJoinedDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'GameJoinedDetailed';
  static String routePath = '/gameJoinedDetailed';

  @override
  State<GameJoinedDetailedWidget> createState() =>
      _GameJoinedDetailedWidgetState();
}

class _GameJoinedDetailedWidgetState extends State<GameJoinedDetailedWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _vibeRepository = VibeRepository();

  // Controllers
  late final GameJoinedDetailedController _controller;
  late final GameJoinedStreamController _streamController;
  late final GameJoinedRequestActions _requestActions;
  late final GameJoinedPlayerActions _playerActions;
  late final GameJoinedEditActions _editActions;

  // UI State (owned by widget)
  bool _hasAnimated = false;
  List<JoinRequest> _pendingRequests = [];
  VibeProfile? _ownerVibeProfile;
  String? _expandedRequestId;

  // Stream state
  GamesRecord? _gamesRecord;
  bool _hasStreamError = false;

  @override
  void initState() {
    super.initState();
    _controller = GameJoinedDetailedController(
      joinRequestProvider: context.read<JoinRequestProvider>(),
      gameProvider: context.read<GameProvider>(),
      appState: context.read<AppState>(),
      vibeRepository: _vibeRepository,
    );
    _streamController = GameJoinedStreamController(vibeRepository: _vibeRepository);
    _requestActions = GameJoinedRequestActions(controller: _controller);
    _playerActions = GameJoinedPlayerActions(controller: _controller);
    _editActions = GameJoinedEditActions(controller: _controller);
    _initGameSubscription();
  }

  @override
  void didUpdateWidget(GameJoinedDetailedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameRef?.id != oldWidget.gameRef?.id) {
      _streamController.resetAndCancel();
      _pendingRequests = [];
      _ownerVibeProfile = null;
      _expandedRequestId = null;
      _gamesRecord = null;
      _hasStreamError = false;
      _initGameSubscription();
    }
  }

  @override
  void dispose() {
    _streamController.dispose();
    super.dispose();
  }

  void _retryGameSubscription() {
    _streamController.resetAndCancel();
    updateState(this, () {
      _gamesRecord = null;
      _hasStreamError = false;
      _pendingRequests = [];
      _ownerVibeProfile = null;
      _expandedRequestId = null;
    });
    _initGameSubscription();
  }

  void _initGameSubscription() {
    final gameRef = widget.gameRef;
    if (gameRef == null) return;
    _streamController.initSubscription(
      context: context,
      gameId: gameRef.id,
      onData: _onGameDataReceived,
      onError: (hasError) {
        if (mounted) updateState(this, () => _hasStreamError = hasError);
      },
    );
  }

  void _onGameDataReceived(GamesRecord? gamesRecord) {
    if (!mounted) return;
    updateState(this, () {
      _gamesRecord = gamesRecord;
      _hasStreamError = false;
    });
    if (gamesRecord == null) return;
    _streamController.processGameData(
      state: this,
      context: context,
      gamesRecord: gamesRecord,
      currentUserRef: currentUserReference,
      onAnimationTrigger: () => updateState(this, () => _hasAnimated = true),
      onPendingRequestsLoaded: (requests, ownerProfile, expandedId) {
        updateState(this, () {
          _pendingRequests = requests;
          _ownerVibeProfile = ownerProfile;
          _expandedRequestId = expandedId;
        });
      },
      onLoadingChanged: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameRef = widget.gameRef;

    if (gameRef == null) {
      return GameJoinedStateHandler(
        props: GameJoinedStateProps(
          gameRef: null,
          hasError: false,
          hasData: false,
          isDataNull: false,
          child: const SizedBox.shrink(),
        ),
      );
    }

    final currentUserRef = currentUserReference;

    if (_hasStreamError) {
      return GameJoinedStateHandler(
        props: GameJoinedStateProps(
          gameRef: gameRef,
          hasError: true,
          hasData: false,
          isDataNull: false,
          errorMessage: 'Please try again later.',
          onRetry: _retryGameSubscription,
          child: const SizedBox.shrink(),
        ),
      );
    }

    final gamesRecord = _gamesRecord;
    if (gamesRecord == null) {
      return GameJoinedStateHandler(
        props: GameJoinedStateProps(
          gameRef: gameRef,
          hasError: false,
          hasData: false,
          isDataNull: false,
          child: const SizedBox.shrink(),
        ),
      );
    }

    final gameRecord = Game.fromRecord(gamesRecord);
    final currentUserId = currentUserRef?.id;

    final groupVibeCacheKey = currentUserId == null
        ? null
        : context.read<GroupVibeProvider>().buildGameCacheKey(
            gameRecord: gameRecord,
            currentUserId: currentUserId,
          );

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Game Dashboard'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: GameJoinedDashboardContent(
          game: gameRecord,
          screenGameRef: gameRef,
          currentUserRef: currentUserRef,
          hasAnimated: _hasAnimated,
          groupVibeCacheKey: groupVibeCacheKey,
          pendingRequests: _pendingRequests,
          ownerVibeProfile: _ownerVibeProfile,
          expandedRequestId: _expandedRequestId,
          onApproveRequest: _handleApproveRequest,
          onDeclineRequest: _handleDeclineRequest,
          onRemoveRequest: _handleRemoveRequest,
          onExpandRequest: _handleExpandRequest,
          onShowRemovePlayerDialog: _handleShowRemovePlayerDialog,
          onOpenPremiumVibePage: _handleOpenPremiumVibePage,
          onEditGameDetails: _handleEditGameDetails,
        ),
      ),
    );
  }

  // Callback delegates

  Future<void> _handleApproveRequest(JoinRequest request) =>
      _requestActions.handleApproveRequest(
          context: context, state: this, request: request);

  Future<void> _handleDeclineRequest(JoinRequest request) =>
      _requestActions.handleDeclineRequest(
          context: context, state: this, request: request);

  void _handleRemoveRequest(String requestId) =>
      _requestActions.removeRequestFromList(
        state: this,
        requestId: requestId,
        pendingRequests: _pendingRequests,
        expandedRequestId: _expandedRequestId,
        onChanged: (requests, expandedId) {
          _pendingRequests = requests;
          _expandedRequestId = expandedId;
        },
      );

  void _handleExpandRequest(String requestId) => _requestActions.expandRequest(
        state: this,
        requestId: requestId,
        currentExpandedId: _expandedRequestId,
        onExpandedChanged: (id) => _expandedRequestId = id,
      );

  Future<void> _handleShowRemovePlayerDialog({
    required BuildContext context,
    required String playerName,
    required DocumentReference? playerRef,
    required bool isGuest,
    String? guestName,
    required Game gameRecord,
  }) =>
      _playerActions.showRemovePlayerDialog(
        context: context,
        state: this,
        playerName: playerName,
        playerRef: playerRef,
        isGuest: isGuest,
        guestName: guestName,
        gameRecord: gameRecord,
        currentUserRef: currentUserReference,
        gameRef: widget.gameRef,
      );

  Future<void> _handleOpenPremiumVibePage(
    BuildContext context,
    DocumentReference userRef,
    String userName,
    String userPhotoUrl,
    GroupVibeMemberResult? memberMatch,
  ) =>
      openPremiumVibePage(
        context: context,
        vibeRepository: _vibeRepository,
        userRef: userRef,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        memberMatch: memberMatch,
      );

  Future<void> _handleEditGameDetails(BuildContext context, Game gameRecord) =>
      _editActions.handleEditGameDetails(
        context: context,
        state: this,
        gameRecord: gameRecord,
        currentUserUid: currentUserReference?.id,
      );
}
