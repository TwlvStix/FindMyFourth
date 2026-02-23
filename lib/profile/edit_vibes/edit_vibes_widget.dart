import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/widgets/app_icon.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/profile/edit_vibe_importance/edit_vibe_importance_widget.dart';
import '/profile/edit_vibes/vibe_category_slider.dart';
import '/profile/main_profile/main_profile_widget.dart';
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

  VibeProfile _profile = VibeProfile.defaults();
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _repository.getMyVibesCached(forceRefresh: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to load vibes. Please try again.');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateLocalPreference(
    VibeCategory category,
    VibePreference preference,
  ) {
    final updatedPrefs = Map<VibeCategory, VibePreference>.from(_profile.prefs);
    updatedPrefs[category] = preference;
    setState(() {
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
    setState(() {
      _isConfirming = true;
    });
    try {
      await _repository.confirmVibes();
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = _profile.confirmed(DateTime.now());
      });
      context.goNamed(MainProfileWidget.routeName);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Vibes were not confirmed. Please try again.');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                        // Vibe Archetype Display
                        Builder(
                          builder: (context) {
                            final archetypeMatch =
                                VibeArchetypes.classifyProfile(_profile);
                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha:0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AppIcon(
                                        icon: AppPhosphorIcons.trophy,
                                        size: AppIconSize.button,
                                        color: AppColors.gold,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Your vibe style',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.sand,
                                          fontWeight: AppTypography.medium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    archetypeMatch.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.pure,
                                      fontWeight: AppTypography.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    archetypeMatch.description,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.sand,
                                    ),
                                  ),
                                ],
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
                            context.pushNamed(
                              EditVibeImportanceWidget.routeName,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                              border: Border.all(
                                color: AppColors.cloud,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.navyLight.withValues(alpha:0.2),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                  child: AppIcon(
                                    icon: AppPhosphorIcons.star,
                                    color: AppColors.navy,
                                    size: AppIconSize.button,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set your priorities',
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.onyx,
                                          fontWeight: AppTypography.semiBold,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        'Pick the 2 things that matter most',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.stone,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppIcon(
                                  icon: AppPhosphorIcons.chevronRight,
                                  color: AppColors.stone,
                                  size: AppIconSize.xs,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Social Vibes',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.pure,
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        ),
                        Text(
                          'Play Style',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.pure,
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                        AppButtonEnhanced(
                          text: 'Confirm my vibes',
                          leadingIcon: AppPhosphorIcons.successFill,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.large,
                          fullWidth: true,
                          onPressed: _isConfirming ? null : _confirmVibes,
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
