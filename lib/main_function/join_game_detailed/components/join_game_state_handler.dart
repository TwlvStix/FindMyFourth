import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
import '/main_function/game_joined_detailed/components/premium_app_bar.dart';

/// Defines the state of game loading for JoinGameDetailed screen.
enum JoinGameLoadState {
  /// gameRef is null - no game reference provided
  nullRef,

  /// StreamBuilder error (non-permission)
  error,

  /// StreamBuilder loading - waiting for data
  loading,

  /// Data loaded successfully - render child
  ready,
}

/// Props for [JoinGameStateHandler].
class JoinGameStateProps {
  final DocumentReference? gameRef;
  final bool hasError;
  final bool hasData;
  final String? errorMessage;
  final Widget child;

  const JoinGameStateProps({
    required this.gameRef,
    required this.hasError,
    required this.hasData,
    this.errorMessage,
    required this.child,
  });

  JoinGameLoadState get state {
    if (gameRef == null) return JoinGameLoadState.nullRef;
    if (hasError) return JoinGameLoadState.error;
    if (!hasData) return JoinGameLoadState.loading;
    return JoinGameLoadState.ready;
  }
}

/// Handles null/error/loading states for join game screen.
///
/// Renders [child] when game data is ready.
/// Otherwise shows appropriate fallback UI.
class JoinGameStateHandler extends StatelessWidget {
  final JoinGameStateProps props;

  const JoinGameStateHandler({
    super.key,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    switch (props.state) {
      case JoinGameLoadState.nullRef:
        return _buildNullRefState(context);
      case JoinGameLoadState.error:
        return _buildErrorState(context);
      case JoinGameLoadState.loading:
        return _buildLoadingState(context);
      case JoinGameLoadState.ready:
        return props.child;
    }
  }

  Widget _buildNullRefState(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Game'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.error,
                  color: AppColors.glassTextTertiary,
                  size: AppIconSize.xl,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Game Unavailable',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'This game is no longer available',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.glassTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Game'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.error,
                  color: AppColors.glassTextTertiary,
                  size: AppIconSize.xl,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Unable to load game',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                props.errorMessage ?? 'Please try again later.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.glassTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PremiumAppBar(title: 'Loading...'),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitWanderingCubes(
                color: AppColors.gold,
                size: 50.0,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Loading game details...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.glassTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
