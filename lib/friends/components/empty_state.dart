import 'package:flutter/material.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/design_tokens/app_phosphor_icons.dart';

/// Empty state widget for friends page
/// Shows contextual illustrations and CTAs based on the tab
class FriendsEmptyState extends StatefulWidget {
  final FriendsEmptyStateType type;
  final VoidCallback? onActionPressed;

  const FriendsEmptyState({
    super.key,
    required this.type,
    this.onActionPressed,
  });

  @override
  State<FriendsEmptyState> createState() => _FriendsEmptyStateState();
}

class _FriendsEmptyStateState extends State<FriendsEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration with floating animation
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: _buildIllustration(),
            ),

            SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              _getTitle(),
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.onyx,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppSpacing.md),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                _getDescription(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.stone,
                  height: 1.6,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: AppSpacing.xxl),

            // CTA Button with enhanced styling
            if (widget.onActionPressed != null)
              AppButtonEnhanced(
                onPressed: widget.onActionPressed,
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

    switch (widget.type) {
      case FriendsEmptyStateType.noSearchResults:
        iconData = AppPhosphorIcons.searchOff;
        gradientColors = [AppColors.stone, AppColors.cloud];
        break;
      case FriendsEmptyStateType.noFriendRequests:
        iconData = AppPhosphorIcons.inbox;
        gradientColors = [AppColors.navy, AppColors.navyLight];
        break;
      case FriendsEmptyStateType.noFriends:
        iconData = AppPhosphorIcons.people;
        gradientColors = [AppColors.green, AppColors.greenLight];
        break;
    }

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withValues(alpha:0.12),
            gradientColors[1].withValues(alpha:0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha:0.1),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha:0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            iconData,
            size: AppIconSize.xxl,
            color: AppColors.pure,
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case FriendsEmptyStateType.noSearchResults:
        return 'No Golfers Found';
      case FriendsEmptyStateType.noFriendRequests:
        return 'No Friend Requests';
      case FriendsEmptyStateType.noFriends:
        return 'No Friends Yet';
    }
  }

  String _getDescription() {
    switch (widget.type) {
      case FriendsEmptyStateType.noSearchResults:
        return 'Try searching with a different name or check your spelling. You can also browse golfers at your club!';
      case FriendsEmptyStateType.noFriendRequests:
        return 'You\'re all caught up! When golfers send you friend requests, they\'ll appear here.';
      case FriendsEmptyStateType.noFriends:
        return 'Start building your golf network! Connect with players from your club or search for golfers to play with.';
    }
  }

  String _getActionLabel() {
    switch (widget.type) {
      case FriendsEmptyStateType.noSearchResults:
        return 'Clear Search';
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
