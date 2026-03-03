import '/backend/backend.dart';
import '/core/utils/app_log.dart';
import '/core/utils/firebase_error_utils.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/main_function/game_joined_detailed/components/premium_app_bar.dart';
import '/utils/app_util.dart';
import '/models/game.dart';
import '/models/join_request.dart';
import '/providers/group_vibe_provider.dart';
import '/providers/user_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/join_game_detailed_controller.dart';
import 'controllers/join_game_detailed_stream_controller.dart';
import 'controllers/join_game_join_action_coordinator.dart';
import 'components/join_game_state_handler.dart';
import 'components/join_game_detailed_content.dart';

class JoinGameDetailedWidget extends StatefulWidget {
  const JoinGameDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'JoinGameDetailed';
  static String routePath = '/joinGameDetailed';

  @override
  State<JoinGameDetailedWidget> createState() => _JoinGameDetailedWidgetState();
}

class _JoinGameDetailedWidgetState extends State<JoinGameDetailedWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = JoinGameDetailedController();
  late final JoinGameDetailedStreamController _streamController;

  bool _hasLoggedAccessDenied = false;
  bool _hasShownAccessDeniedDialog = false;
  bool _hasAnimated = false;
  JoinRequest? _existingRequest;
  bool _isCheckingRequest = true;
  GamesRecord? _gamesRecord;
  bool _hasStreamError = false;
  Object? _streamError;

  @override
  void initState() {
    super.initState();
    _streamController = JoinGameDetailedStreamController(
      controller: _controller,
    );
    _initGameSubscription();
  }

  @override
  void didUpdateWidget(JoinGameDetailedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameRef?.id != oldWidget.gameRef?.id) {
      _streamController.resetAndCancel();
      updateState(this, () {
        _existingRequest = null;
        _isCheckingRequest = true;
        _hasShownAccessDeniedDialog = false;
        _gamesRecord = null;
        _hasStreamError = false;
        _streamError = null;
        _hasAnimated = false;
      });
      _initGameSubscription();
    }
  }

  @override
  void dispose() {
    _streamController.dispose();
    super.dispose();
  }

  void _initGameSubscription() {
    final gameRef = widget.gameRef;
    if (gameRef == null) return;

    _streamController.initSubscription(
      context: context,
      gameId: gameRef.id,
      onData: _onGameDataReceived,
      onError: _onStreamError,
    );
  }

  void _onGameDataReceived(GamesRecord? gamesRecord) {
    if (!mounted) return;
    updateState(this, () {
      _gamesRecord = gamesRecord;
      _hasStreamError = false;
      _streamError = null;
    });
    _streamController.processGameData(
      state: this,
      context: context,
      gamesRecord: gamesRecord,
      currentUserId: currentUserReference?.id,
      onAnimationTrigger: () {
        if (mounted) {
          updateState(this, () => _hasAnimated = true);
        }
      },
      onExistingRequestLoaded: (request, isLoading) {
        if (mounted) {
          updateState(this, () {
            _existingRequest = request;
            _isCheckingRequest = isLoading;
          });
        }
      },
    );
  }

  void _onStreamError(bool hasError, Object? error) {
    if (!mounted) return;
    updateState(this, () {
      _hasStreamError = hasError;
      _streamError = error;
    });
    // Handle permission-denied (friends-only game) with one-shot dialog
    if (error != null &&
        FirebaseErrorUtils.isPermissionDenied(error) &&
        !_hasShownAccessDeniedDialog) {
      _hasShownAccessDeniedDialog = true;
      if (!_hasLoggedAccessDenied) {
        _hasLoggedAccessDenied = true;
        AppLog.d(
          'JoinGameDetailed: access denied for game ${widget.gameRef?.id} '
          '(likely friends-only). Error: $error',
        );
      }
      _showFriendsOnlyDialogAndPop(context);
    }
  }

  Future<void> _showFriendsOnlyDialogAndPop(BuildContext context) async {
    await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.informational,
      icon: PhosphorIconsRegular.lock,
      title: 'Friends Only Game',
      body:
          'This game is visible to friends only. Add the host as a friend to view details.',
      actionLabel: 'Got It',
    );
    if (!context.mounted) return;
    context.pop();
  }

  Future<void> _handleJoinPressed({
    required Game game,
    required DocumentReference? currentUserRef,
    required bool isCreatorFriend,
    required String? userGender,
  }) async {
    final coordinator = JoinGameJoinActionCoordinator(controller: _controller);
    final result = await coordinator.executeJoinAction(
      context: context,
      game: game,
      currentUserRef: currentUserRef,
      isCreatorFriend: isCreatorFriend,
      userGender: userGender,
    );

    if (!mounted) return;

    switch (result) {
      case JoinActionSuccess(:final gameRef):
        context.goGameJoinedDetailed(gameRef: gameRef);
      case JoinActionRequestSubmitted(:final request):
        setState(() {
          _existingRequest = request;
          _isCheckingRequest = false;
        });
      case JoinActionError(:final message):
        if (message != null && message.isNotEmpty) {
          showSnackbar(context, message);
        }
      case JoinActionDismissed():
        // User dismissed dialog, no action needed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserRef = currentUserReference;
    final gameRef = widget.gameRef;

    if (gameRef == null) {
      return _buildStateHandler(gameRef: null, hasError: false, hasData: false);
    }
    if (_hasStreamError) {
      final error = _streamError;
      if (error != null && FirebaseErrorUtils.isPermissionDenied(error)) {
        return const SizedBox.shrink();
      }
      return _buildStateHandler(gameRef: gameRef, hasError: true, hasData: false);
    }
    final gamesRecord = _gamesRecord;
    if (gamesRecord == null) {
      return _buildStateHandler(gameRef: gameRef, hasError: false, hasData: false);
    }
    return _buildGameContent(
      context: context,
      gamesRecord: gamesRecord,
      currentUserRef: currentUserRef,
    );
  }

  Widget _buildStateHandler({
    required DocumentReference? gameRef,
    required bool hasError,
    required bool hasData,
  }) {
    return JoinGameStateHandler(
      props: JoinGameStateProps(
        gameRef: gameRef,
        hasError: hasError,
        hasData: hasData,
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildGameContent({
    required BuildContext context,
    required GamesRecord gamesRecord,
    required DocumentReference? currentUserRef,
  }) {
    final game = Game.fromRecord(gamesRecord);
    final currentUserId = currentUserRef?.id;

    // Build cache key for GroupVibe selectors
    final groupVibeCacheKey = currentUserId == null
        ? null
        : context.read<GroupVibeProvider>().buildGameCacheKey(
            gameRecord: game,
            currentUserId: currentUserId,
          );

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Available Game'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: false,
          child: StreamBuilder<UsersRecord>(
            stream: currentUserRef == null
                ? null
                : UsersRecord.getDocument(currentUserRef),
            builder: (context, userSnapshot) {
              final currentUserRecord =
                  userSnapshot.hasData ? userSnapshot.data : null;
              final isCreatorFriend =
                  currentUserRecord?.friends.contains(game.userRef) ?? false;

              return JoinGameDetailedContent(
                game: game,
                currentUserRef: currentUserRef,
                groupVibeCacheKey: groupVibeCacheKey,
                hasAnimated: _hasAnimated,
                existingRequest: _existingRequest,
                isCheckingRequest: _isCheckingRequest,
                isCreatorFriend: isCreatorFriend,
                onJoinPressed: () => _handleJoinPressed(
                  game: game,
                  currentUserRef: currentUserRef,
                  isCreatorFriend: isCreatorFriend,
                  userGender: context.read<UserProvider>().currentUser?.gender,
                ),
                onPlayerTap: (userRef) => context.pushProfileUser(
                  userRef: userRef,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
