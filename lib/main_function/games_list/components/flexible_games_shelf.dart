import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/opacity.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_icon.dart';
import '/main_function/games_list/components/flexible_game_compact_card.dart';
import '/models/game.dart';

/// Horizontal carousel shelf for flexible games.
/// Displays above the scheduled games list with a "See all" tap target.
/// Features a pulsing gold dot indicator to draw attention.
class FlexibleGamesShelf extends StatefulWidget {
  const FlexibleGamesShelf({
    super.key,
    required this.games,
    required this.currentUserReference,
    required this.onSeeAll,
  });

  final List<Game> games;
  final DocumentReference? currentUserReference;
  final VoidCallback onSeeAll;

  @override
  State<FlexibleGamesShelf> createState() => _FlexibleGamesShelfState();
}

class _FlexibleGamesShelfState extends State<FlexibleGamesShelf>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Scroll state for gradient overlays and progress indicator
  late ScrollController _scrollController;
  double _scrollPosition = 0.0;
  double _maxScrollExtent = 0.0;
  bool _hasOverflow = false;
  Timer? _indicatorFadeTimer;
  double _indicatorOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize scroll controller for gradient overlays and progress indicator
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Check initial overflow state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollMetrics();
    });
  }

  void _onScroll() {
    _updateScrollMetrics();
    _resetIndicatorFadeTimer();
  }

  void _updateScrollMetrics() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final newScrollPosition = position.pixels;
    final newMaxExtent = position.maxScrollExtent;
    final newHasOverflow = newMaxExtent > 0;

    if (newScrollPosition != _scrollPosition ||
        newMaxExtent != _maxScrollExtent ||
        newHasOverflow != _hasOverflow) {
      setState(() {
        _scrollPosition = newScrollPosition;
        _maxScrollExtent = newMaxExtent;
        _hasOverflow = newHasOverflow;
      });
    }
  }

  void _resetIndicatorFadeTimer() {
    _indicatorFadeTimer?.cancel();
    if (_indicatorOpacity != 1.0) {
      setState(() => _indicatorOpacity = 1.0);
    }
    _indicatorFadeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _indicatorOpacity = 0.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _indicatorFadeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildScrollIndicator() {
    // Track dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final trackWidth = screenWidth * 0.4;
    const trackHeight = 2.0;

    // Calculate thumb width proportional to visible vs total content
    final viewportWidth = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : screenWidth;
    final totalWidth = viewportWidth + _maxScrollExtent;
    final thumbWidthRatio = totalWidth > 0 ? viewportWidth / totalWidth : 1.0;
    final thumbWidth = (thumbWidthRatio * trackWidth).clamp(20.0, trackWidth);

    // Calculate thumb position based on scroll ratio
    final scrollRatio = _maxScrollExtent > 0
        ? (_scrollPosition / _maxScrollExtent).clamp(0.0, 1.0)
        : 0.0;
    final thumbPosition = scrollRatio * (trackWidth - thumbWidth);

    return SizedBox(
      width: trackWidth,
      height: trackHeight,
      child: Stack(
        children: [
          // Track background
          Container(
            width: trackWidth,
            height: trackHeight,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: AppOpacity.glass),
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
            ),
          ),
          // Thumb (active indicator)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            left: thumbPosition,
            top: 0,
            child: Container(
              width: thumbWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Label + See all
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                // Pulsing gold dot indicator
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Flexible Games',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See all ${widget.games.length}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xxs),
                        AppIcon(
                          icon: AppPhosphorIcons.chevronRight,
                          size: AppIconSize.xs,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Horizontal scrolling carousel with gradient overlays
          Stack(
            children: [
              // The scrollable content
              SizedBox(
                height: 100, // Fixed height for compact cards
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: widget.games.length,
                  itemBuilder: (context, index) {
                    final game = widget.games[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right:
                            index == widget.games.length - 1 ? 0 : AppSpacing.sm,
                      ),
                      child: FlexibleGameCompactCard(
                        game: game,
                        currentUserReference: widget.currentUserReference,
                        animationIndex: index,
                      ),
                    );
                  },
                ),
              ),

              // Left gradient overlay (visible when scrolled right)
              if (_hasOverflow)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 48,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _scrollPosition > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.navyDark,
                              AppColors.navyDark.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Right gradient overlay (visible when more content to scroll)
              if (_hasOverflow)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 48,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _scrollPosition < _maxScrollExtent ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.navyDark.withValues(alpha: 0.0),
                              AppColors.navyDark,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Scroll progress indicator (only show if content overflows)
          if (_hasOverflow) ...[
            SizedBox(height: AppSpacing.sm),
            Center(
              child: AnimatedOpacity(
                opacity: _indicatorOpacity,
                duration: const Duration(milliseconds: 300),
                child: _buildScrollIndicator(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
