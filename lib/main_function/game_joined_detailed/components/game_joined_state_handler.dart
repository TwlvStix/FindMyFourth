import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '/backend/backend.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/navigation/nav_extensions.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/fairway_background.dart';
import 'premium_app_bar.dart';

/// Defines the state of game loading for GameJoinedDetailed screen.
enum GameJoinedLoadState {
  /// gameRef is null - no game reference provided
  nullRef,

  /// StreamBuilder error
  error,

  /// StreamBuilder loading - waiting for data
  loading,

  /// Data is null after load
  notFound,

  /// Data loaded successfully - render child
  ready,
}

/// Props for [GameJoinedStateHandler].
class GameJoinedStateProps {
  final DocumentReference? gameRef;
  final bool hasError;
  final bool hasData;
  final bool isDataNull;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget child;

  const GameJoinedStateProps({
    required this.gameRef,
    required this.hasError,
    required this.hasData,
    required this.isDataNull,
    this.errorMessage,
    this.onRetry,
    required this.child,
  });

  GameJoinedLoadState get state {
    if (gameRef == null) return GameJoinedLoadState.nullRef;
    if (hasError) return GameJoinedLoadState.error;
    if (!hasData) return GameJoinedLoadState.loading;
    if (isDataNull) return GameJoinedLoadState.notFound;
    return GameJoinedLoadState.ready;
  }
}

/// Handles null/error/loading states for game joined detailed screen.
///
/// Renders [child] when game data is ready.
/// Otherwise shows appropriate fallback UI.
class GameJoinedStateHandler extends StatelessWidget {
  final GameJoinedStateProps props;

  const GameJoinedStateHandler({
    super.key,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    switch (props.state) {
      case GameJoinedLoadState.nullRef:
        return _buildUnavailableState(
          title: 'Game Unavailable',
          subtitle: 'This game is no longer available',
        );
      case GameJoinedLoadState.error:
        return _buildUnavailableState(
          title: 'Unable to load game',
          subtitle: props.errorMessage ?? 'Please try again later.',
        );
      case GameJoinedLoadState.loading:
        return _buildLoadingState();
      case GameJoinedLoadState.notFound:
        return _buildNotFoundState(context);
      case GameJoinedLoadState.ready:
        return props.child;
    }
  }

  Widget _buildUnavailableState({
    required String title,
    required String subtitle,
  }) {
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
                  color: AppColors.pure.withValues(alpha: 0.5),
                  size: AppIconSize.xl,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.pure,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6), // Keep: no 60% token
                ),
              ),
              if (props.onRetry != null) ...[
                SizedBox(height: AppSpacing.lg),
                AppButtonEnhanced(
                  text: 'Try again',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: props.onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
                color: AppColors.green,
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

  Widget _buildNotFoundState(BuildContext context) {
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
                  color: AppColors.pure.withValues(alpha: 0.5),
                  size: AppIconSize.xl,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Game not found',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.pure,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'This game may have been removed.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6), // Keep: no 60% token
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              AppButtonEnhanced(
                text: 'Go to My Games',
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
                onPressed: () => context.goGamesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
