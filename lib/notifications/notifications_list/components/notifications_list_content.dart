import 'package:flutter/material.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_empty_state_premium.dart';
import '/core/widgets/app_icon.dart';
import '/providers/notification_list_provider.dart';

/// The main content area for the notifications list.
///
/// Handles all display states:
/// - Initial loading spinner
/// - Error/timeout state with retry
/// - Empty state
/// - List with infinite scroll pagination
class NotificationsListContent extends StatelessWidget {
  const NotificationsListContent({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
  });

  final NotificationListViewState state;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(NotificationListItem item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    // Initial loading state - show spinner only while initial load is in progress
    if (state.isInitialLoadInProgress) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.green,
        ),
      );
    }

    // Error or timeout state - show retry UI
    if (state.hasError || state.initialLoadTimedOut) {
      return _buildErrorState(context);
    }

    // Empty state - only show after first load completed with no data
    if (state.notifications.isEmpty && state.hasReceivedFirstSnapshot) {
      return _buildEmptyState(context);
    }

    // Fallback: if not loading and no data and no error, show empty state
    if (state.notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    // List with notifications
    return _buildNotificationsList(context);
  }

  Widget _buildErrorState(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.navy,
      onRefresh: () async => onRetry(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 100,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.warning,
                    size: AppIconSize.section,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    state.initialLoadTimedOut
                        ? 'Taking longer than expected'
                        : 'Unable to load notifications',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pull down to refresh or tap retry.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppButtonEnhanced(
                    text: 'Retry',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.navy,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 100,
              ),
              child: AppEmptyStatePremium(
                icon: AppPhosphorIcons.notifications,
                title: "You're all caught up",
                message: 'New activity will appear here.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    final notifications = state.notifications;

    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.navy,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200 &&
              !state.isLoadingMore &&
              state.hasMore) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            MediaQuery.of(context).padding.top + 60,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          itemCount: notifications.length +
              (state.isLoadingMore || state.loadMoreError ? 1 : 0),
          separatorBuilder: (context, index) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            // Show loading indicator or error retry at the end
            if (index == notifications.length) {
              return _buildLoadMoreIndicator();
            }

            final item = notifications[index];
            return itemBuilder(item);
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (state.loadMoreError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: AppButtonEnhanced(
            text: 'Retry',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: onLoadMore,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: CircularProgressIndicator(
          color: AppColors.green,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
