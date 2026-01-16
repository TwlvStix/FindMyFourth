import 'package:flutter/material.dart';
import 'app_list_tile.dart';
import '../design_tokens/colors.dart';

/// Example usage of AppListTile component demonstrating all variants and features.
///
/// This file shows how AppListTile can replace inline list item patterns
/// across players, friends, games, and other list screens.
///
/// Migration to screens happens in Phase 3-4 screen standardization.
class AppListTileExamples extends StatelessWidget {
  const AppListTileExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: const Text('AppListTile Examples'),
        backgroundColor: AppColors.fairway,
      ),
      body: ListView(
        children: [
          // Standard variant - default for most lists
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Standard Variant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppListTile(
            title: 'John Smith',
            subtitle: 'Handicap: 12 • Pebble Beach Golf Links',
            avatarUrl: 'https://via.placeholder.com/150',
            variant: AppListTileVariant.standard,
            onTap: () {},
          ),
          AppListTile(
            title: 'Sarah Johnson',
            subtitle: 'Handicap: 8 • Torrey Pines Golf Course',
            avatarInitials: 'SJ',
            trailingIcon: Icons.chevron_right,
            variant: AppListTileVariant.standard,
            onTap: () {},
          ),

          // Compact variant - dense lists
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Compact Variant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppListTile(
            title: 'Mike Davis',
            subtitle: 'HC: 15',
            avatarInitials: 'MD',
            variant: AppListTileVariant.compact,
            onTap: () {},
          ),
          AppListTile(
            title: 'Emma Wilson',
            subtitle: 'HC: 10',
            avatarInitials: 'EW',
            variant: AppListTileVariant.compact,
            onTap: () {},
          ),

          // Card variant - standalone items with visual separation
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Card Variant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppListTile(
            title: 'Tournament Round',
            subtitle: 'Saturday, March 15 • 8:30 AM',
            leadingIcon: Icons.golf_course,
            trailing: '4/4 players',
            variant: AppListTileVariant.card,
            onTap: () {},
          ),
          AppListTile(
            title: 'Casual Game',
            subtitle: 'Sunday, March 16 • 2:00 PM',
            leadingIcon: Icons.sports_golf,
            trailing: '2/4 players',
            variant: AppListTileVariant.card,
            onTap: () {},
          ),

          // Highlighted variant - selected/active state
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Highlighted Variant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppListTile(
            title: 'Active Game',
            subtitle: 'In progress • 9 holes completed',
            leadingIcon: Icons.play_circle_filled,
            trailing: 'Live',
            variant: AppListTileVariant.highlighted,
            onTap: () {},
          ),

          // Custom trailing widget example
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Custom Trailing Widget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppListTile(
            title: 'Alex Thompson',
            subtitle: 'Friend request pending',
            avatarInitials: 'AT',
            trailingWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: AppColors.success),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.cancel, color: AppColors.error),
                  onPressed: () {},
                ),
              ],
            ),
            variant: AppListTileVariant.standard,
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// Migration guide for converting inline list items to AppListTile.
///
/// BEFORE (inline pattern):
/// ```dart
/// Container(
///   padding: EdgeInsets.all(16),
///   child: Row(
///     children: [
///       CircleAvatar(
///         backgroundImage: NetworkImage(user.photoUrl),
///         radius: 20,
///       ),
///       SizedBox(width: 12),
///       Expanded(
///         child: Column(
///           crossAxisAlignment: CrossAxisAlignment.start,
///           children: [
///             Text(user.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
///             Text(user.handicap, style: TextStyle(fontSize: 14, color: Colors.grey)),
///           ],
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// AFTER (AppListTile):
/// ```dart
/// AppListTile(
///   title: user.name,
///   subtitle: user.handicap,
///   avatarUrl: user.photoUrl,
///   variant: AppListTileVariant.standard,
///   onTap: () => navigateToProfile(user),
/// )
/// ```
///
/// Benefits:
/// - 20+ lines → 5 lines
/// - Consistent design tokens (spacing, colors, typography)
/// - Automatic dividers and padding
/// - Built-in tap handling with ink ripple
/// - Multiple variants for different contexts
/// - Accessibility support
