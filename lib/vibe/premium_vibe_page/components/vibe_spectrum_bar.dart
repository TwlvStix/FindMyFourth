import 'package:flutter/material.dart';
import 'package:find_my_fourth/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/core/design_tokens/typography.dart';
import 'package:find_my_fourth/models/vibe_profile.dart';
import 'package:find_my_fourth/vibe/premium_vibe_page/styles/premium_vibe_page_styles.dart';

/// Visual spectrum bar showing "You" vs "Them" positions on a 0-5 scale.
///
/// Uses spatial positioning instead of numeric labels - users can see at a
/// glance where alignment exists and where gaps live.
class VibeSpectrumBar extends StatelessWidget {
  const VibeSpectrumBar({
    super.key,
    required this.myValue,
    required this.theirValue,
    required this.category,
  });

  /// Current user's preference value (0-5)
  final int myValue;

  /// Matched user's preference value (0-5)
  final int theirValue;

  /// The category (for potential future use)
  final VibeCategory category;

  /// Horizontal padding to prevent edge clipping
  static const double _horizontalPadding = 22.0;

  /// Dot size
  static const double _dotSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Available width for spectrum, accounting for padding on both sides
        final spectrumWidth = totalWidth - (_horizontalPadding * 2);

        // Calculate dot positions (left edge of each dot within spectrum area)
        final myDotLeft = _calculateDotPosition(myValue, spectrumWidth);
        final theirDotLeft = _calculateDotPosition(theirValue, spectrumWidth);

        // Calculate dot centers for label positioning
        final myDotCenter = myDotLeft + (_dotSize / 2);
        final theirDotCenter = theirDotLeft + (_dotSize / 2);

        // Check if dots are overlapping or very close (within 30px)
        final dotsAreClose = (myDotCenter - theirDotCenter).abs() < 30;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: SizedBox(
            height: 60,
            width: spectrumWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background spectrum line
                Positioned(
                  left: 0,
                  right: 0,
                  top: 28,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: PremiumVibePageStyles.spectrumBarColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // "You" marker
                _buildMarker(
                  dotLeft: myDotLeft,
                  dotCenter: myDotCenter,
                  label: 'You',
                  color: PremiumVibePageStyles.youDotColor,
                  spectrumWidth: spectrumWidth,
                  // Offset vertically if dots are close and "You" is on left
                  verticalOffset: dotsAreClose && myValue <= theirValue ? -8 : 0,
                ),

                // "Them" marker
                _buildMarker(
                  dotLeft: theirDotLeft,
                  dotCenter: theirDotCenter,
                  label: 'Them',
                  color: PremiumVibePageStyles.themDotColor,
                  spectrumWidth: spectrumWidth,
                  // Offset vertically if dots are close and "Them" is on right
                  verticalOffset: dotsAreClose && theirValue > myValue ? -8 : 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calculates horizontal position for a value on the 0-5 scale
  /// Returns position of the dot's LEFT EDGE relative to the padded area
  double _calculateDotPosition(int value, double availableWidth) {
    // Value is 0-5, map to 0.0-1.0 percentage
    final percentage = value / 5.0;
    // Calculate position ensuring dot stays fully within bounds
    // At value 0: left edge at 0
    // At value 5: left edge at (availableWidth - dotSize), so right edge at availableWidth
    return percentage * (availableWidth - _dotSize);
  }

  Widget _buildMarker({
    required double dotLeft,
    required double dotCenter,
    required String label,
    required Color color,
    required double spectrumWidth,
    double verticalOffset = 0,
  }) {
    // Calculate percentage position for smart label alignment
    final percentage = dotCenter / spectrumWidth;

    // Determine how to position the label to avoid edges
    // Near left edge: left-align label starting from dot
    // Near right edge: right-align label ending at dot
    // Middle: center label under dot
    final double labelLeft;
    final Alignment labelAlignment;

    if (percentage < 0.25) {
      // Left edge - align label to start at dot left edge
      labelLeft = dotLeft;
      labelAlignment = Alignment.centerLeft;
    } else if (percentage > 0.75) {
      // Right edge - align label to end at dot right edge
      // Position label container so its right edge aligns with dot right edge
      labelLeft = dotLeft + _dotSize - 40; // Assuming label width ~40px
      labelAlignment = Alignment.centerRight;
    } else {
      // Middle - center label under dot
      labelLeft = dotCenter - 20; // Center of assumed 40px label width
      labelAlignment = Alignment.center;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dot
        Positioned(
          left: dotLeft,
          top: 0 + verticalOffset,
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Connecting line (centered below dot)
        Positioned(
          left: dotCenter - 1, // Center the 2px line under the dot
          top: 10 + verticalOffset,
          child: Container(
            width: 2,
            height: 18,
            color: color,
          ),
        ),

        // Label (smart positioned to avoid edges)
        Positioned(
          left: labelLeft.clamp(0, spectrumWidth - 40),
          top: 32 + verticalOffset,
          width: 40,
          child: Align(
            alignment: labelAlignment,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
