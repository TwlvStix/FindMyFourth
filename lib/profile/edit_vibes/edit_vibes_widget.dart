import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/vibe_slider_card.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_repository.dart';
import '/utils/app_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      showSnackbar(context, 'Vibe settings confirmed.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showSnackbar(context, 'Unable to confirm vibes. Please try again.');
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
      backgroundColor: AppTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: AppIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          borderWidth: 1.0,
          buttonSize: 60.0,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.of(context).primary,
            size: 30.0,
          ),
          onPressed: () async {
            context.pop();
          },
        ),
        title: Text(
          'Edit Vibes',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.of(context).primary,
          ),
        ),
      ),
      body: FairwayBackgroundDark(
        showOrganic: true,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.of(context).primary,
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.isComplete
                            ? 'Vibe settings: up to date'
                            : 'Vibe settings: incomplete',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.stone,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Social Vibes',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.onyx,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      VibeSliderCard(
                        category: VibeCategory.chat,
                        pref: _profile.preferenceFor(VibeCategory.chat),
                        onValueChanged: (value) =>
                            _handleValueChanged(VibeCategory.chat, value),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.chat, value),
                        onDealbreakerChanged: (value) =>
                            _handleDealbreakerChanged(VibeCategory.chat, value),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),
                      VibeSliderCard(
                        category: VibeCategory.music,
                        pref: _profile.preferenceFor(VibeCategory.music),
                        onValueChanged: (value) =>
                            _handleValueChanged(VibeCategory.music, value),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.music, value),
                        onDealbreakerChanged: (value) => _handleDealbreakerChanged(
                          VibeCategory.music,
                          value,
                        ),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),
                      VibeSliderCard(
                        category: VibeCategory.drinking,
                        pref: _profile.preferenceFor(VibeCategory.drinking),
                        onValueChanged: (value) =>
                            _handleValueChanged(VibeCategory.drinking, value),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.drinking, value),
                        onDealbreakerChanged: (value) => _handleDealbreakerChanged(
                          VibeCategory.drinking,
                          value,
                        ),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),
                      VibeSliderCard(
                        category: VibeCategory.weed,
                        pref: _profile.preferenceFor(VibeCategory.weed),
                        onValueChanged: (value) =>
                            _handleValueChanged(VibeCategory.weed, value),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.weed, value),
                        onDealbreakerChanged: (value) =>
                            _handleDealbreakerChanged(VibeCategory.weed, value),
                        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                      ),
                      Text(
                        'Play Style',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.onyx,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      VibeSliderCard(
                        category: VibeCategory.pace,
                        pref: _profile.preferenceFor(VibeCategory.pace),
                        onValueChanged: (value) =>
                            _handleValueChanged(VibeCategory.pace, value),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.pace, value),
                        onDealbreakerChanged: (value) =>
                            _handleDealbreakerChanged(VibeCategory.pace, value),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),
                      VibeSliderCard(
                        category: VibeCategory.money,
                        pref: _profile.preferenceFor(VibeCategory.money),
                        onValueChanged: (value) =>
                            _handleValueChanged(VibeCategory.money, value),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.money, value),
                        onDealbreakerChanged: (value) =>
                            _handleDealbreakerChanged(VibeCategory.money, value),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),
                      VibeSliderCard(
                        category: VibeCategory.competitive,
                        pref: _profile.preferenceFor(VibeCategory.competitive),
                        onValueChanged: (value) => _handleValueChanged(
                          VibeCategory.competitive,
                          value,
                        ),
                        onValueCommitted: (value) =>
                            _commitValueChanged(VibeCategory.competitive, value),
                        onDealbreakerChanged: (value) =>
                            _handleDealbreakerChanged(
                          VibeCategory.competitive,
                          value,
                        ),
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      ),
                      AppButtonEnhanced(
                        text: 'Confirm my vibes',
                        leadingIcon: Icons.check_circle_rounded,
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
    );
  }
}
