import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/games_record.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/debug/services/game_trust_status_service.dart';
import '/providers/game_provider.dart';

/// Bottom sheet for selecting a game from the user's games.
///
/// Shows trust flow prerequisite status indicators so you can see at a glance
/// which games are valid test candidates for HostCheckin vs PeerRating.
class GamePickerBottomSheet extends StatefulWidget {
  final DocumentReference? currentSelection;

  const GamePickerBottomSheet({
    super.key,
    this.currentSelection,
  });

  @override
  State<GamePickerBottomSheet> createState() => _GamePickerBottomSheetState();

  /// Shows the bottom sheet and returns the selected game reference.
  static Future<DocumentReference?> show(
    BuildContext context, {
    DocumentReference? currentSelection,
  }) {
    return showModalBottomSheet<DocumentReference>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GamePickerBottomSheet(
        currentSelection: currentSelection,
      ),
    );
  }
}

class _GamePickerBottomSheetState extends State<GamePickerBottomSheet> {
  final _trustService = GameTrustStatusService();
  final _statusCache = <String, GameTrustStatus>{};
  bool _loading = true;
  List<GamesRecord> _games = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    if (currentUserUid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }

    try {
      final gameProvider = context.read<GameProvider>();
      final games = await gameProvider.userGamesStream(currentUserUid).first;

      // Sort by date descending (most recent first)
      games.sort((a, b) {
        final dateA = a.date ?? DateTime(1900);
        final dateB = b.date ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _games = games;
        _loading = false;
      });

      // Fetch trust status for visible games (lazy load)
      _loadTrustStatuses();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load games';
      });
    }
  }

  Future<void> _loadTrustStatuses() async {
    for (final game in _games) {
      if (!mounted) return;
      try {
        final status = await _trustService.fetchGameTrustStatus(game.reference);
        if (!mounted) return;
        setState(() {
          _statusCache[game.reference.id] = status;
        });
      } catch (_) {
        // Silently ignore status fetch failures
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const SizedBox(height: AppSpacing.sm),
          Flexible(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(PhosphorIconsRegular.x),
            color: AppColors.textPrimary,
            iconSize: AppIconSize.md,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Select Test Game',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Center(
        child: Padding(
          padding: AppSpacing.card,
          child: CircularProgressIndicator(color: AppColors.green),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.card,
          child: Text(
            _error!,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_games.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon: AppPhosphorIcons.golfHole,
                size: AppIconSize.xl,
                color: AppColors.textMuted,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'No games found',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) => _buildGameTile(_games[index]),
    );
  }

  Widget _buildGameTile(GamesRecord game) {
    final isSelected = widget.currentSelection?.id == game.reference.id;
    final status = _statusCache[game.reference.id];

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? AppColors.green.withValues(alpha: 0.1)
            : AppColors.navy,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(game.reference),
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.navyLight,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game name
                Text(
                  game.nameGame.isNotEmpty ? game.nameGame : 'Unnamed Game',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xxs),

                // Course + date + player count
                Text(
                  _buildSubtitle(game),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.sm),

                // Status chips
                _buildStatusChips(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(GamesRecord game) {
    final parts = <String>[];

    if (game.coursePlay.isNotEmpty) {
      parts.add(game.coursePlay);
    }

    if (game.date != null) {
      parts.add(DateFormat('MMM d, y').format(game.date!));
    }

    final playerCount = game.joinedPlayers.length +
        game.guestPlayers.where((g) => g.trim().isNotEmpty).length;
    parts.add('$playerCount/${game.maxPlayers} players');

    return parts.join(' \u2022 ');
  }

  Widget _buildStatusChips(GameTrustStatus? status) {
    if (status == null) {
      // Still loading
      return Row(
        children: [
          _buildChip(
            'Loading...',
            PhosphorIconsRegular.dotsThree,
            AppColors.textMuted,
          ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        _buildStatusChip(
          label: 'Participants',
          valid: status.validForHostCheckin,
          detail: '${status.participantCount}',
        ),
        _buildStatusChip(
          label: 'Attendance',
          valid: status.validForPeerRating,
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool valid,
    String? detail,
  }) {
    final displayLabel = detail != null ? '$label ($detail)' : label;

    return _buildChip(
      displayLabel,
      valid ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.xCircle,
      valid ? AppColors.success : AppColors.textMuted,
    );
  }

  Widget _buildChip(String label, PhosphorIconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon: icon,
            size: AppIconSize.xs,
            color: color,
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
