import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/utils/formatting_utils.dart';

/// Displays name, archetype label, age/gender, hometown, and vibe match chip.
class FriendCardUserInfo extends StatelessWidget {
  const FriendCardUserInfo({
    super.key,
    required this.displayName,
    this.archetype,
    this.dateOfBirth,
    this.gender,
    this.hometownName = '',
    this.vibeMatchPercent,
  });

  final String displayName;
  final String? archetype;
  final DateTime? dateOfBirth;
  final String? gender;
  final String hometownName;
  final int? vibeMatchPercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Archetype label
        if (archetype != null) ...[
          Text(
            archetype!.toUpperCase(),
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
        ],
        // Name
        Text(
          displayName,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.sand,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Age + Hometown
        _buildSecondaryInfo(),
      ],
    );
  }

  Widget _buildSecondaryInfo() {
    final age = calculateAge(dateOfBirth);

    // Get gender letter: M for Male, F for Female
    String? genderLetter;
    if (gender == 'Male') {
      genderLetter = 'M';
    } else if (gender == 'Female') {
      genderLetter = 'F';
    }

    final locationParts = <String>[
      if (age != null) '$age${genderLetter ?? ''}',
      if (hometownName.isNotEmpty) hometownName
    ];

    if (locationParts.isEmpty && vibeMatchPercent == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          // Age · Town
          if (locationParts.isNotEmpty)
            Flexible(
              child: Text(
                locationParts.join(' · '),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Vibe match chip
          if (vibeMatchPercent != null) ...[
            if (locationParts.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '·',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            Icon(
              AppPhosphorIcons.heartFill,
              size: 12,
              color: AppColors.green,
            ),
            SizedBox(width: 4),
            Text(
              '$vibeMatchPercent% match',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
