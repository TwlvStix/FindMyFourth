import '/auth/firebase_auth/auth_util.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/main_function/player_list/components/add_player_modal.dart';
import '/main_function/player_list/components/current_user_card.dart';
import '/main_function/player_list/components/game_summary_card.dart';
import '/main_function/player_list/components/player_slot_card.dart';
import '/main_function/player_list/components/player_submit_button.dart';
import '/main_function/player_list/controller/player_list_controller.dart';
import '/models/game.dart';
import '/models/player_eligibility.dart';
import '/models/user_profile.dart';
import '/utils/app_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final PlayerListController _controller = PlayerListController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  Future<void> _showAddPlayerModal(
    int slotIndex,
    Set<String> joinedPlayerIds,
    PlayerEligibility eligibility,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AddPlayerModal(
          slotIndex: slotIndex,
          joinedPlayerIds: joinedPlayerIds,
          eligibility: eligibility,
          controller: _controller,
          onSelectPlayer: ({
            required int slotIndex,
            required bool isGuest,
            UserProfile? profile,
          }) {
            final result = isGuest
                ? _controller.addGuestToSlot(slotIndex: slotIndex)
                : _controller.addProfileToSlot(
                    slotIndex: slotIndex,
                    profile: profile,
                    joinedPlayerIds: joinedPlayerIds,
                    eligibility: eligibility,
                  );

            if (result.added && mounted) {
              setState(() {});
            }
            return result;
          },
        );
      },
    );
  }

  Future<void> _submitPlayers(Game game) async {
    if (_isSubmitting) {
      AppLog.d('⚠️ PLAYER LIST: Already submitting, ignoring click');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    AppLog.d('👥 PLAYER LIST: Starting player submission');

    final result = await _controller.submitSelections(
      game: game,
      gameRef: widget.gameRef,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      _showSnackBar(
        result.errorMessage ?? 'Error adding players.',
        backgroundColor: AppColors.error,
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    AppLog.d('✅ PLAYER LIST: Submission successful');
    context.goGamesList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (!_isSubmitting) {
          return;
        }

        AppLog.d(
            '⚠️ PLAYER LIST: Back navigation blocked - submission in progress');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _showSnackBar(
            'Please wait while we add your players...',
            duration: const Duration(seconds: 1),
          );
        });
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
          final currentUserRef = currentUserReference;
          final currentPlayerCount =
              game.joinedPlayers.length + game.guestPlayers.length;
          final joinedPlayerIds =
              game.joinedPlayers.map((player) => player.id).toSet();
          final remainingSlots = (game.maxPlayers - currentPlayerCount)
              .clamp(0, game.maxPlayers)
              .toInt();

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
                leading: const PremiumBackButton(),
                title: Text(
                  'Add Your Group',
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                centerTitle: true,
              ),
              body: FairwayBackgroundDark(
                showOrganic: true,
                showTexture: true,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 56),
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
                      Expanded(
                        child: SingleChildScrollView(
                          padding: AppSpacing.allMd,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.lg),
                                  boxShadow: [AppElevation.lg],
                                ),
                                child: Padding(
                                  padding: AppSpacing.allLg,
                                  child: Form(
                                    key: formKey,
                                    autovalidateMode: AutovalidateMode.disabled,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Group',
                                          style:
                                              AppTypography.titleSmall.copyWith(
                                            color: AppColors.goldLight,
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.md),
                                        CurrentUserCard(
                                          currentUserRef: currentUserRef,
                                        ),
                                        SizedBox(height: AppSpacing.lg),
                                        if (remainingSlots > 0) ...[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Add Friends',
                                                style: AppTypography.titleSmall
                                                    .copyWith(
                                                  color: AppColors.goldLight,
                                                ),
                                              ),
                                              Text(
                                                'Tap a slot to add',
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                  fontSize: 13,
                                                  color: AppColors.stone,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: AppSpacing.md),
                                        ],
                                        for (var i = 0;
                                            i < remainingSlots;
                                            i++) ...[
                                          PlayerSlotCard(
                                            slotLabel:
                                                'Player ${currentPlayerCount + i + 1}',
                                            playerData:
                                                _controller.slotForIndex(i),
                                            onTapAdd: () => _showAddPlayerModal(
                                              i,
                                              joinedPlayerIds,
                                              game.playerEligibility,
                                            ),
                                            onTapRemove: () {
                                              setState(() {
                                                _controller
                                                    .removePlayerFromSlot(i);
                                              });
                                            },
                                          ),
                                          if (i < remainingSlots - 1)
                                            SizedBox(height: AppSpacing.sm),
                                        ],
                                        if (remainingSlots == 0) ...[
                                          Text(
                                            'This game is already full.',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              fontSize: 13,
                                              color: AppColors.stone,
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.md),
                                        ],
                                        SizedBox(height: AppSpacing.xl),
                                        PlayerSubmitButton(
                                          isSubmitting: _isSubmitting,
                                          onPressed: () => _submitPlayers(game),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSpacing.md),
                              GameSummaryCard(
                                game: game,
                                currentPlayerCount: currentPlayerCount,
                                remainingSlots: remainingSlots,
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
}
