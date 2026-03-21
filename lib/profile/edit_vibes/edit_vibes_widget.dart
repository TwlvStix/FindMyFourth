import '/core/utils/state_update.dart';
import '/core/content/app_copy.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/motion/motion_tokens.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/profile/edit_vibes/controllers/edit_vibes_controller.dart';
import '/profile/edit_vibes/components/edit_vibes_cooldown_banner.dart';
import '/profile/edit_vibes/components/edit_vibes_archetype_card.dart';
import '/profile/edit_vibes/components/edit_vibes_importance_card.dart';
import '/profile/edit_vibes/vibe_category_slider.dart';
import '/services/vibe_edit_cooldown_service.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';

class EditVibesWidget extends StatefulWidget {
  const EditVibesWidget({super.key});

  static String routeName = 'EditVibes';
  static String routePath = '/editVibes';

  @override
  State<EditVibesWidget> createState() => _EditVibesWidgetState();
}

class _EditVibesWidgetState extends State<EditVibesWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final EditVibesController _controller = EditVibesController();

  VibeProfile _profile = VibeProfile.defaults();
  VibeProfile _originalProfile = VibeProfile.defaults();
  bool _isLoading = true;
  bool _isConfirming = false;
  VibeEditEligibilityResult? _cooldownEligibility;

  bool get _hasChanges => _controller.hasChanges(_profile, _originalProfile);
  bool get _isInCooldown => _controller.isInCooldown(_cooldownEligibility);
  String get _cooldownDateText =>
      _controller.formatCooldownDate(_cooldownEligibility);

  static const _socialCategories = [
    VibeCategory.chat,
    VibeCategory.music,
    VibeCategory.drinking,
  ];

  static const _playStyleCategories = [
    VibeCategory.pace,
    VibeCategory.money,
    VibeCategory.competitive,
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    updateState(this, () => _isLoading = true);
    try {
      final result = await _controller.loadProfile();
      if (!mounted) return;
      updateState(this, () {
        _profile = result.profile;
        _originalProfile = result.profile;
        _cooldownEligibility = result.eligibility;
      });
    } catch (error) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to load vibes. Please try again.');
    } finally {
      if (mounted) {
        updateState(this, () => _isLoading = false);
      }
    }
  }

  void _updateLocalPref(VibeCategory category, VibePreference pref) {
    final updated = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updated[category] = pref;
    updateState(this, () => _profile = _profile.copyWith(prefs: updated));
  }

  void _handleValueChanged(VibeCategory category, int value) {
    final current = _profile.preferenceFor(category);
    _updateLocalPref(category, current.copyWith(value: value, isDefault: false));
  }

  Future<void> _commitValueChanged(VibeCategory category, int value) async {
    if (_isInCooldown) return;
    try {
      await _controller.commitValueChanged(category, value);
    } catch (error) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to update vibe. Please try again.');
      await _loadProfile();
    }
  }

  Future<void> _handleDealbreakerChanged(
    VibeCategory category,
    bool value,
  ) async {
    final current = _profile.preferenceFor(category);
    _updateLocalPref(
        category, current.copyWith(dealbreaker: value, isDefault: false));
    if (_isInCooldown) return;
    try {
      await _controller.toggleDealbreaker(category, value);
    } catch (error) {
      if (!mounted) return;
      showSnackbar(context, 'Unable to update dealbreaker. Please try again.');
      await _loadProfile();
    }
  }

  Future<void> _confirmVibes() async {
    if (_isConfirming || _isInCooldown || !_hasChanges) return;

    final confirmed = await showPremiumDialog(
      context: context,
      variant: PremiumDialogVariant.confirmation,
      icon: AppPhosphorIcons.clock,
      title: AppVibeEditCopy.confirmDialogTitle,
      body: AppVibeEditCopy.confirmDialogBody,
      actionLabel: AppVibeEditCopy.confirmDialogAction,
      cancelLabel: AppVibeEditCopy.confirmDialogCancel,
    );
    if (confirmed != true || !mounted) return;

    updateState(this, () => _isConfirming = true);
    try {
      final result = await _controller.confirmVibes(_cooldownEligibility);
      if (!mounted) return;

      switch (result) {
        case EditVibesConfirmSuccess():
          updateState(this, () => _profile = _profile.confirmed(DateTime.now()));
          context.goMainProfile();
        case EditVibesConfirmFailure():
          showSnackbar(
              context, 'Vibes were not confirmed. Please try again.');
      }
    } finally {
      if (mounted) {
        updateState(this, () => _isConfirming = false);
      }
    }
  }

  Widget _buildSlider(VibeCategory category, {EdgeInsets? margin}) {
    return VibeCategorySlider(
      category: category,
      pref: _profile.preferenceFor(category),
      onValueChanged: (value) => _handleValueChanged(category, value),
      onValueCommitted: (value) => _commitValueChanged(category, value),
      onDealbreakerChanged: (value) =>
          _handleDealbreakerChanged(category, value),
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: const PremiumBackButton(),
        title: AppText.sectionHeader('Edit Vibes', color: AppColors.pure),
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        showTexture: true,
        child: SafeArea(
          top: false,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.pure),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      MediaQuery.of(context).padding.top +
                          56 +
                          AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isInCooldown) ...[
                          EditVibesCooldownBanner(
                            cooldownDateText: _cooldownDateText,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        EditVibesArchetypeCard(profile: _profile),
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
                        const EditVibesImportanceCard(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionHeader(
                          'Social Vibes',
                          'How you connect on the course',
                        ),
                        ..._socialCategories.map(
                          (c) => _buildSlider(c),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildSectionHeader(
                          'Play Style',
                          'Your approach to the game',
                        ),
                        ..._playStyleCategories.map(
                          (c) => _buildSlider(c),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildConfirmButton(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColorsDark.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColorsDark.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return AnimatedContainer(
      duration: MotionTokens.microInteraction,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: _hasChanges && !_isConfirming && !_isInCooldown
            ? [AppElevation.glowGreen]
            : null,
      ),
      child: AppButtonEnhanced(
        text: _isInCooldown
            ? AppVibeEditCopy.cooldownButtonText(_cooldownDateText)
            : 'Confirm my vibes',
        leadingIcon: _isInCooldown
            ? AppPhosphorIcons.clock
            : AppPhosphorIcons.successFill,
        variant: AppButtonVariant.primary,
        size: AppButtonSize.large,
        fullWidth: true,
        enabled: _hasChanges && !_isConfirming && !_isInCooldown,
        onPressed: _confirmVibes,
      ),
    );
  }
}
