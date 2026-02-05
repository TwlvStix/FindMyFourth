import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/widgets/app_text_field.dart';

/// Multi-select games widget with max 3 cap
class GamesMultiSelect extends StatelessWidget {
  final Set<String> selectedGames;
  final Function(String) onGameToggled;
  final TextEditingController otherGameController;
  final Function(String) onOtherGameChanged;
  final int maxGames;

  const GamesMultiSelect({
    super.key,
    required this.selectedGames,
    required this.onGameToggled,
    required this.otherGameController,
    required this.onOtherGameChanged,
    this.maxGames = 3,
  });

  static const List<Map<String, dynamic>> gameOptions = [
    {'value': 'Skins', 'label': 'Skins', 'icon': Icons.workspace_premium_rounded, 'emoji': '🏅'},
    {'value': 'Vegas', 'label': 'Vegas', 'icon': Icons.casino_rounded, 'emoji': '🎰'},
    {'value': 'Nassau', 'label': 'Nassau', 'icon': Icons.emoji_events_rounded, 'emoji': '🏆'},
    {'value': 'Wolf', 'label': 'Wolf', 'icon': Icons.pets_rounded, 'emoji': '🐺'},
    {'value': 'BBB', 'label': 'BBB', 'icon': Icons.sports_golf_rounded, 'emoji': '⛳'},
    {'value': '6-6-6', 'label': '6-6-6', 'icon': Icons.looks_6_rounded, 'emoji': '6️⃣'},
    {'value': 'Dots', 'label': 'Dots', 'icon': Icons.fiber_manual_record_rounded, 'emoji': '🔴'},
    {'value': 'Other', 'label': 'Other', 'icon': Icons.edit_note_rounded, 'emoji': '✏️'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Games grid
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.85,
          padding: EdgeInsets.zero,
          children: gameOptions.map((option) {
            final value = option['value'] as String;
            final isSelected = selectedGames.contains(value);
            final canSelect = isSelected || selectedGames.length < maxGames;

            return GestureDetector(
              onTap: () {
                if (isSelected) {
                  // Can always deselect
                  HapticFeedback.lightImpact();
                  onGameToggled(value);
                } else if (canSelect) {
                  // Can select if under max
                  HapticFeedback.lightImpact();
                  onGameToggled(value);
                } else {
                  // Show error if trying to exceed max
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Max $maxGames games'),
                      duration: const Duration(milliseconds: 2000),
                      backgroundColor: AppTheme.of(context).primary,
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.fairway.withValues(alpha: 0.5),
                            AppColors.fairwayDark.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : AppColors.fairway.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sunsetGold
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.sunsetGold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                              )
                            : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          option['emoji'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      option['label'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Other game text input (conditional)
        if (selectedGames.contains('Other'))
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: AppTextField(
              label: 'Describe the game',
              hint: 'e.g., Chapman, Alternate Shot, etc.',
              controller: otherGameController,
              variant: AppTextFieldVariant.filled,
              prefixIcon: Icons.edit_rounded,
              maxLength: 40,
              onChanged: onOtherGameChanged,
            ),
          ),
      ],
    );
  }
}
