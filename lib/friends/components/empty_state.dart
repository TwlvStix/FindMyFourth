import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';

/// Empty state widget for friends page
/// Shows contextual illustrations and CTAs based on the tab
class FriendsEmptyState extends StatelessWidget {
  final FriendsEmptyStateType type;
  final VoidCallback? onActionPressed;

  const FriendsEmptyState({
    super.key,
    required this.type,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            _buildIllustration(),

            SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              _getTitle(),
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.onyx,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSpacing.sm),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                _getDescription(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.stone,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            // CTA Button
            if (onActionPressed != null)
              AppButtonEnhanced(
                onPressed: onActionPressed,
                text: _getActionLabel(),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    IconData iconData;
    List<Color> gradientColors;

    switch (type) {
      case FriendsEmptyStateType.noSearchResults:
        iconData = Icons.search_off_rounded;
        gradientColors = [AppColors.stone, AppColors.cloud];
        break;
      case FriendsEmptyStateType.noFriendRequests:
        iconData = Icons.inbox_rounded;
        gradientColors = [AppColors.fairway, AppColors.fairwayLight];
        break;
      case FriendsEmptyStateType.noFriends:
        iconData = Icons.people_outline_rounded;
        gradientColors = [AppColors.sunsetPeach, AppColors.sunsetRose];
        break;
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(0.15),
            gradientColors[1].withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            iconData,
            size: 50,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case FriendsEmptyStateType.noSearchResults:
        return 'No Golfers Found';
      case FriendsEmptyStateType.noFriendRequests:
        return 'No Friend Requests';
      case FriendsEmptyStateType.noFriends:
        return 'No Friends Yet';
    }
  }

  String _getDescription() {
    switch (type) {
      case FriendsEmptyStateType.noSearchResults:
        return 'Try searching with a different name or check your spelling. You can also browse golfers at your club!';
      case FriendsEmptyStateType.noFriendRequests:
        return 'You\'re all caught up! When golfers send you friend requests, they\'ll appear here.';
      case FriendsEmptyStateType.noFriends:
        return 'Start building your golf network! Connect with players from your club or search for golfers to play with.';
    }
  }

  String _getActionLabel() {
    switch (type) {
      case FriendsEmptyStateType.noSearchResults:
        return 'Browse All Golfers';
      case FriendsEmptyStateType.noFriendRequests:
        return 'Find Golfers';
      case FriendsEmptyStateType.noFriends:
        return 'Find Golfers';
    }
  }
}

enum FriendsEmptyStateType {
  noSearchResults,
  noFriendRequests,
  noFriends,
}
