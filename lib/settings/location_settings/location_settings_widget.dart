import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/motion/motion_tokens.dart';
import '/providers/geo_filter_provider.dart';
import '/providers/user_provider.dart';

/// Location settings screen.
///
/// Allows user to configure:
/// - Location source (Home Course / Hometown / Phone GPS)
/// - Search radius (5 / 10 / 25 / 50 miles)
class LocationSettingsWidget extends StatefulWidget {
  const LocationSettingsWidget({super.key});

  static const routeName = 'LocationSettings';
  static const routePath = '/locationSettings';

  @override
  State<LocationSettingsWidget> createState() => _LocationSettingsWidgetState();
}

class _LocationSettingsWidgetState extends State<LocationSettingsWidget> {
  /// Available radius options in kilometers.
  static const List<double> _radiusOptions = [10, 20, 40, 80];

  Future<void> _handleSourceChange(GeoLocationSource source) async {
    HapticFeedback.lightImpact();

    final geoFilter = context.read<GeoFilterProvider>();
    final userProvider = context.read<UserProvider>();

    await geoFilter.setSource(source);

    // Persist to user profile
    final sourceStr = _sourceToString(source);
    userProvider.updateProfile({'location_source': sourceStr});
  }

  void _handleRadiusChange(double km) {
    HapticFeedback.lightImpact();

    final geoFilter = context.read<GeoFilterProvider>();
    final userProvider = context.read<UserProvider>();

    geoFilter.setRadius(km, onPersist: () {
      userProvider.updateProfile({'search_radius_km': km});
    });
  }

  String _sourceToString(GeoLocationSource source) {
    switch (source) {
      case GeoLocationSource.homeCourse:
        return 'home_course';
      case GeoLocationSource.hometown:
        return 'hometown';
      case GeoLocationSource.phoneGps:
        return 'phone_gps';
    }
  }

  @override
  Widget build(BuildContext context) {
    final geoFilter = context.watch<GeoFilterProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: const PremiumBackButton(),
        title: Text(
          'Location',
          style: AppTypography.headlineMediumSans.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding + 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Center Section
            Text(
              'SEARCH CENTER',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Games will be filtered by distance from this location.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Source Options
            _SourceOption(
              icon: AppPhosphorIcons.homeCourse,
              title: 'Home Course',
              subtitle: userProvider.hasHomeCourseLocation
                  ? 'Your default course location'
                  : 'Not configured',
              isSelected: geoFilter.source == GeoLocationSource.homeCourse,
              isEnabled: userProvider.hasHomeCourseLocation,
              onTap: userProvider.hasHomeCourseLocation
                  ? () => _handleSourceChange(GeoLocationSource.homeCourse)
                  : null,
            ),
            SizedBox(height: AppSpacing.sm),
            _SourceOption(
              icon: AppPhosphorIcons.hometown,
              title: 'Hometown',
              subtitle: userProvider.hasHometownLocation
                  ? 'Your hometown location'
                  : 'Not configured',
              isSelected: geoFilter.source == GeoLocationSource.hometown,
              isEnabled: userProvider.hasHometownLocation,
              onTap: userProvider.hasHometownLocation
                  ? () => _handleSourceChange(GeoLocationSource.hometown)
                  : null,
            ),
            SizedBox(height: AppSpacing.sm),
            _SourceOption(
              icon: AppPhosphorIcons.gpsLocation,
              title: 'Phone GPS',
              subtitle: geoFilter.isLoadingLocation
                  ? 'Getting location...'
                  : geoFilter.locationError ?? 'Use your current location',
              isSelected: geoFilter.source == GeoLocationSource.phoneGps,
              isEnabled: true,
              isLoading: geoFilter.isLoadingLocation,
              hasError: geoFilter.locationError != null &&
                  geoFilter.source == GeoLocationSource.phoneGps,
              onTap: () => _handleSourceChange(GeoLocationSource.phoneGps),
            ),

            SizedBox(height: AppSpacing.xxl),

            // Search Radius Section
            Text(
              'SEARCH RADIUS',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Only show games within this distance.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Radius Chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _radiusOptions.map((km) {
                final isSelected = geoFilter.radiusKm == km;
                return _RadiusChip(
                  km: km,
                  isSelected: isSelected,
                  onTap: () => _handleRadiusChange(km),
                );
              }).toList(),
            ),

            SizedBox(height: AppSpacing.xxl),

            // Info Card
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(
                    icon: AppPhosphorIcons.info,
                    size: AppIconSize.md,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'The "Near Me" filter uses these settings when enabled '
                      'on the games list.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Source option card with radio-like selection.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isEnabled,
    this.isLoading = false,
    this.hasError = false,
    this.onTap,
  });

  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isEnabled;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = !isEnabled
        ? AppColors.textMuted
        : isSelected
            ? AppColors.green
            : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green.withValues(alpha: 0.1) : AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.navyLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AppIcon(
              icon: icon,
              size: AppIconSize.lg,
              color: effectiveColor,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: !isEnabled
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: hasError
                          ? AppColors.error
                          : !isEnabled
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: AppIconSize.md,
                height: AppIconSize.md,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                ),
              )
            else if (isSelected)
              AppIcon(
                icon: AppPhosphorIcons.checkCircle,
                size: AppIconSize.md,
                color: AppColors.green,
              )
            else if (!isEnabled)
              AppIcon(
                icon: AppPhosphorIcons.warning,
                size: AppIconSize.md,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Radius selection chip.
class _RadiusChip extends StatefulWidget {
  const _RadiusChip({
    required this.km,
    required this.isSelected,
    required this.onTap,
  });

  final double km;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_RadiusChip> createState() => _RadiusChipState();
}

class _RadiusChipState extends State<_RadiusChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: MotionTokens.microInteraction,
        curve: MotionTokens.curveEnter,
        transform: _isPressed
            ? (Matrix4.identity()
              ..setEntry(0, 0, 0.96)
              ..setEntry(1, 1, 0.96))
            : Matrix4.identity(),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected ? AppColors.green : AppColors.navy,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: widget.isSelected ? AppColors.green : AppColors.navyLight,
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          '${widget.km.toInt()} km',
          style: AppTypography.labelLarge.copyWith(
            color: widget.isSelected ? AppColors.pure : AppColors.textSecondary,
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
