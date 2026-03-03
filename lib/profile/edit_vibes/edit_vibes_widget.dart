import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/state_update.dart';
import '/core/content/app_copy.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_patterns/premium_ui_patterns.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/profile/edit_vibes/vibe_category_slider.dart';
import '/services/vibe_analytics_service.dart';
import '/services/vibe_edit_cooldown_service.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';
import '/utils/vibe_archetypes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class EditVibesWidget extends StatefulWidget {
  const EditVibesWidget({super.key});

  static String routeName = 'EditVibes';
  static String routePath = '/editVibes';

  @override
  State<EditVibesWidget> createState() => _EditVibesWidgetState();
}

class _EditVibesWidgetState extends State<EditVibesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _repository = VibeRepository();
  final VibeEditCooldownService _cooldownService = VibeEditCooldownService();
  final VibeAnalyticsService _analyticsService = VibeAnalyticsService();

  VibeProfile _profile = VibeProfile.defaults();
  VibeProfile _originalProfile = VibeProfile.defaults();
  bool _isLoading = true;
  bool _isConfirming = false;
  bool _archetypeExpanded = false;
  VibeEditEligibilityResult? _cooldownEligibility;

  /// Check if user has made changes from the original profile
  bool get _hasChanges {
    for (final category in VibeCategory.values) {
      final current = _profile.preferenceFor(category);
      final original = _originalProfile.preferenceFor(category);
      if (current.value != original.value ||
          current.dealbreaker != original.dealbreaker) {
        return true;
      }
    }
    return false;
  }

  /// Check if user is in cooldown period
  bool get _isInCooldown =>
      _cooldownEligibility != null && !_cooldownEligibility!.canEdit;

  /// Format the next available edit date
  String _formatCooldownDate() {
    final nextDate = _cooldownEligibility?.nextEditAvailableAt;
    if (nextDate == null) return '';
    return DateFormat.yMMMd().format(nextDate);
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    updateState(this, () {
      _isLoading = true;
    });
    try {
      final userId = currentUserUid;
      final results = await Future.wait([
        _repository.getMyVibesCached(forceRefresh: true),
        if (userId.isNotEmpty) _cooldownService.canEditVibeProfile(userId),
      ]);
      if (!mounted) {
        return;
      }
      updateState(this, () {
        _profile = results[0] as VibeProfile;
        _originalProfile = _profile;
        if (results.length > 1) {
          _cooldownEligibility = results[1] as VibeEditEligibilityResult;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to load vibes. Please try again.');
    } finally {
      if (mounted) {
        updateState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  void _updateLocalPreference(
    VibeCategory category,
    VibePreference preference,
  ) {
    final updatedPrefs = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updatedPrefs[category] = preference;
    updateState(this, () {
      _profile = _profile.copyWith(prefs: updatedPrefs);
    });
  }

  void _handleValueChanged(
    VibeCategory category,
    int value,
  ) {
    final current = _profile.preferenceFor(category);
    _updateLocalPreference(
      category,
      current.copyWith(value: value, isDefault: false),
    );
  }

  Future<void> _commitValueChanged(
    VibeCategory category,
    int value,
  ) async {
    // Don't persist changes during cooldown
    if (_isInCooldown) {
      return;
    }
    try {
      await _repository.updateCategory(category, value);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to update vibe. Please try again.');
      await _loadProfile();
    }
  }

  Future<void> _handleDealbreakerChanged(
    VibeCategory category,
    bool value,
  ) async {
    final current = _profile.preferenceFor(category);
    _updateLocalPreference(
      category,
      current.copyWith(dealbreaker: value, isDefault: false),
    );
    // Don't persist changes during cooldown
    if (_isInCooldown) {
      return;
    }
    try {
      await _repository.toggleDealbreaker(category, value);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to update dealbreaker. Please try again.');
      await _loadProfile();
    }
  }

  Future<void> _confirmVibes() async {
    if (_isConfirming) {
      return;
    }

    // Check cooldown - block if in cooldown
    if (_cooldownEligibility?.canEdit == false) {
      return;
    }

    // Show confirmation dialog warning about 30-day cooldown
    final confirmed = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.confirmation,
      icon: AppPhosphorIcons.clock,
      title: AppVibeEditCopy.confirmDialogTitle,
      body: AppVibeEditCopy.confirmDialogBody,
      actionLabel: AppVibeEditCopy.confirmDialogAction,
      cancelLabel: AppVibeEditCopy.confirmDialogCancel,
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    updateState(this, () {
      _isConfirming = true;
    });
    try {
      await _repository.confirmVibes();

      // Record the edit for cooldown tracking and log analytics
      final userId = currentUserUid;
      if (userId.isNotEmpty) {
        final wasFirstEdit = _cooldownEligibility?.isFirstEdit ?? true;
        final editNumber = (_cooldownEligibility?.editCount ?? 0) + 1;

        await _cooldownService.recordVibeEdit(userId);

        // Fire-and-forget analytics
        _analyticsService.logVibeProfileEdited(
          editNumber: editNumber,
          wasFirstEdit: wasFirstEdit,
        );
      }

      if (!mounted) {
        return;
      }
      updateState(this, () {
        _profile = _profile.confirmed(DateTime.now());
      });
      context.goMainProfile();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Vibes were not confirmed. Please try again.');
    } finally {
      if (mounted) {
        updateState(this, () {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: const PremiumBackButton(),
        title: AppText.sectionHeader(
          'Edit Vibes',
          color: AppColors.pure,
        ),
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: false,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.pure,
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      MediaQuery.of(context).padding.top + 56 + AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cooldown banner - shown when user is in edit cooldown
                        if (_isInCooldown) ...[
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            opacity: 0.20,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColorsDark.navyLight,
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.md),
                                    border: Border.all(
                                      color: AppColorsDark.glassBorder,
                                    ),
                                  ),
                                  child: Center(
                                    child: AppIcon(
                                      icon: AppPhosphorIcons.clock,
                                      size: AppIconSize.button,
                                      color: AppColorsDark.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppVibeEditCopy.cooldownBannerMessage(
                                          _formatCooldownDate(),
                                        ),
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColorsDark.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        AppVibeEditCopy.cooldownBannerSubtitle,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColorsDark.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        // Vibe Archetype Display - tap to expand description
                        Builder(
                          builder: (context) {
                            final archetypeMatch =
                                VibeArchetypes.classifyProfile(_profile);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                updateState(
                                    this,
                                    () => _archetypeExpanded =
                                        !_archetypeExpanded);
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                opacity: 0.25,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon container
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColorsDark.navyLight,
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.md),
                                        border: Border.all(
                                          color: AppColorsDark.glassBorder,
                                        ),
                                      ),
                                      child: Center(
                                        child: AppIcon(
                                          icon: AppPhosphorIcons.trophy,
                                          size: AppIconSize.md,
                                          color: AppColorsDark.gold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Your vibe style',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColorsDark.textMuted,
                                              letterSpacing: AppTypography
                                                  .letterSpacingWide,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.xxs),
                                          Text(
                                            archetypeMatch.name,
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                              color: AppColorsDark.textPrimary,
                                              fontWeight: AppTypography.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppSpacing.xxs),
                                          AnimatedCrossFade(
                                            duration:
                                                MotionTokens.microInteraction,
                                            crossFadeState: _archetypeExpanded
                                                ? CrossFadeState.showSecond
                                                : CrossFadeState.showFirst,
                                            firstChild: Text(
                                              archetypeMatch.description,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color:
                                                    AppColorsDark.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            secondChild: Text(
                                              archetypeMatch.description,
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color:
                                                    AppColorsDark.textSecondary,
                                              ),
                                            ),
                                          ),
                                          if (!_archetypeExpanded) ...[
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                            Text(
                                              'Tap to read more',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                color: AppColorsDark.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _profile.isComplete
                              ? 'Vibe settings: up to date'
                              : 'Vibe settings: incomplete',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.stone,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pushEditVibeImportance();
                          },
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            opacity: 0.25,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColorsDark.navyLight,
                                    borderRadius: BorderRadius.circular(
                                        AppBorderRadius.md),
                                  ),
                                  child: Center(
                                    child: AppIcon(
                                      icon: AppPhosphorIcons.star,
                                      color: AppColorsDark.gold,
                                      size: AppIconSize.button,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Improve your match accuracy',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColorsDark.textPrimary,
                                          fontWeight: AppTypography.semiBold,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        'Fine-tune your preferences for better pairings',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColorsDark.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppIcon(
                                  icon: AppPhosphorIcons.chevronRight,
                                  color: AppColorsDark.textMuted,
                                  size: AppIconSize.xs,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Social Vibes',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'How you connect on the course',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColorsDark.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        VibeCategorySlider(
                          category: VibeCategory.chat,
                          pref: _profile.preferenceFor(VibeCategory.chat),
                          onValueChanged: (value) =>
                              _handleValueChanged(VibeCategory.chat, value),
                          onValueCommitted: (value) =>
                              _commitValueChanged(VibeCategory.chat, value),
                          onDealbreakerChanged: (value) =>
                              _handleDealbreakerChanged(
                                  VibeCategory.chat, value),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        ),
                        VibeCategorySlider(
                          category: VibeCategory.music,
                          pref: _profile.preferenceFor(VibeCategory.music),
                          onValueChanged: (value) =>
                              _handleValueChanged(VibeCategory.music, value),
                          onValueCommitted: (value) =>
                              _commitValueChanged(VibeCategory.music, value),
                          onDealbreakerChanged: (value) =>
                              _handleDealbreakerChanged(
                            VibeCategory.music,
                            value,
                          ),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        ),
                        VibeCategorySlider(
                          category: VibeCategory.drinking,
                          pref: _profile.preferenceFor(VibeCategory.drinking),
                          onValueChanged: (value) =>
                              _handleValueChanged(VibeCategory.drinking, value),
                          onValueCommitted: (value) =>
                              _commitValueChanged(VibeCategory.drinking, value),
                          onDealbreakerChanged: (value) =>
                              _handleDealbreakerChanged(
                            VibeCategory.drinking,
                            value,
                          ),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Play Style',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColorsDark.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Your approach to the game',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColorsDark.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        VibeCategorySlider(
                          category: VibeCategory.pace,
                          pref: _profile.preferenceFor(VibeCategory.pace),
                          onValueChanged: (value) =>
                              _handleValueChanged(VibeCategory.pace, value),
                          onValueCommitted: (value) =>
                              _commitValueChanged(VibeCategory.pace, value),
                          onDealbreakerChanged: (value) =>
                              _handleDealbreakerChanged(
                                  VibeCategory.pace, value),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        ),
                        VibeCategorySlider(
                          category: VibeCategory.money,
                          pref: _profile.preferenceFor(VibeCategory.money),
                          onValueChanged: (value) =>
                              _handleValueChanged(VibeCategory.money, value),
                          onValueCommitted: (value) =>
                              _commitValueChanged(VibeCategory.money, value),
                          onDealbreakerChanged: (value) =>
                              _handleDealbreakerChanged(
                                  VibeCategory.money, value),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        ),
                        VibeCategorySlider(
                          category: VibeCategory.competitive,
                          pref:
                              _profile.preferenceFor(VibeCategory.competitive),
                          onValueChanged: (value) => _handleValueChanged(
                            VibeCategory.competitive,
                            value,
                          ),
                          onValueCommitted: (value) => _commitValueChanged(
                              VibeCategory.competitive, value),
                          onDealbreakerChanged: (value) =>
                              _handleDealbreakerChanged(
                            VibeCategory.competitive,
                            value,
                          ),
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        ),
                        // Confirm button with glow when changes pending
                        // Disabled when in cooldown or no changes
                        AnimatedContainer(
                          duration: MotionTokens.microInteraction,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.lg),
                            boxShadow:
                                _hasChanges && !_isConfirming && !_isInCooldown
                                    ? [AppElevation.glowGreen]
                                    : null,
                          ),
                          child: AppButtonEnhanced(
                            text: _isInCooldown
                                ? AppVibeEditCopy.cooldownButtonText(
                                    _formatCooldownDate(),
                                  )
                                : 'Confirm my vibes',
                            leadingIcon: _isInCooldown
                                ? AppPhosphorIcons.clock
                                : AppPhosphorIcons.successFill,
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.large,
                            fullWidth: true,
                            enabled:
                                _hasChanges && !_isConfirming && !_isInCooldown,
                            onPressed: _confirmVibes,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
