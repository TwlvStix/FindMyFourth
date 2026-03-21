import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/utils/state_update.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/models/vibe_labels.dart';
import '/models/vibe_profile.dart';
import 'components/edit_vibe_importance_labels.dart';
import 'components/edit_vibe_importance_priority_card.dart';
import 'controllers/edit_vibe_importance_controller.dart';

class EditVibeImportanceWidget extends StatefulWidget {
  const EditVibeImportanceWidget({super.key});

  static String routeName = 'EditVibeImportance';
  static String routePath = '/editVibeImportance';

  @override
  State<EditVibeImportanceWidget> createState() =>
      _EditVibeImportanceWidgetState();
}

class _EditVibeImportanceWidgetState extends State<EditVibeImportanceWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final EditVibeImportanceController _controller =
      EditVibeImportanceController();

  bool _isLoading = true;
  bool _isSaving = false;
  VibeProfile _profile = VibeProfile.defaults();
  Map<VibeCategory, VibeImportance> _importance = {
    for (final category in VibeCategory.values) category: VibeImportance.normal,
  };

  int get _topCount => _controller.topCount(_importance);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await _controller.loadProfile();
      if (!mounted) return;
      updateState(this, () {
        _profile = result.profile;
        _importance = result.importance;
        _isLoading = false;
      });
      if (_topCount < 2) {
        updateState(this, () {
          _importance =
              _controller.initializePriorities(_profile, _importance);
        });
      }
    } catch (_) {
      if (!mounted) return;
      updateState(this, () {
        _isLoading = false;
      });
    }
  }

  void _setImportance(VibeCategory category) {
    updateState(this, () {
      _importance = _controller.setImportance(category, _importance);
    });
    HapticFeedback.selectionClick();
  }

  void _clearImportance() {
    if (_isSaving) return;
    updateState(this, () {
      _importance = _controller.clearImportance();
    });
  }

  Future<void> _saveImportance() async {
    if (_isSaving) return;
    updateState(this, () {
      _isSaving = true;
    });
    final result = await _controller.saveImportance(_importance);
    if (!mounted) return;
    switch (result) {
      case EditVibeImportanceSaveSuccess():
        Navigator.of(context).pop();
      case EditVibeImportanceSaveFailure(:final message):
        _showSnack(message);
        updateState(this, () {
          _isSaving = false;
        });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        title: AppText.sectionHeader(
          'Vibe Priorities',
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
                        Text(
                          'What matters most to your round?',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.pure,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Pick the 2 that you care about most. We'll weigh them heavier when matching you.",
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.sand,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildCountPill(
                          label: 'Selected',
                          count: _topCount,
                          max: 2,
                          color: AppColors.green,
                          background:
                              AppColors.green.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPriorityGrid(),
                        const SizedBox(height: AppSpacing.md),
                        if (_topCount < 2)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              "Can't decide? No worries — we'll figure it out from your preferences.",
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.stone,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButtonEnhanced(
                                text: 'Clear',
                                variant: AppButtonVariant.secondary,
                                size: AppButtonSize.large,
                                fullWidth: true,
                                enabled: !_isSaving,
                                onPressed: _clearImportance,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButtonEnhanced(
                                text: 'Save priorities',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.large,
                                fullWidth: true,
                                isLoading: _isSaving,
                                onPressed: _saveImportance,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCountPill({
    required String label,
    required int count,
    required int max,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.pure,
              letterSpacing: AppTypography.letterSpacingNormal,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count/$max',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.sand,
              letterSpacing: AppTypography.letterSpacingNormal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityGrid() {
    final gridOrder = EditVibeImportanceController.priorityGridOrder;
    final List<Widget> rows = [];
    for (var i = 0; i < gridOrder.length; i += 2) {
      final first = gridOrder[i];
      final second = i + 1 < gridOrder.length ? gridOrder[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: _buildCard(first)),
              const SizedBox(width: AppSpacing.sm),
              if (second != null)
                Expanded(child: _buildCard(second))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildCard(VibeCategory category) {
    final pref = _profile.preferenceFor(category);
    return EditVibeImportancePriorityCard(
      title: EditVibeImportanceLabels.categoryTitles[category] ??
          VibeLabels.titleFor(category),
      valueLabel: EditVibeImportanceLabels.shortValueLabel(category, pref.value),
      isSelected: _importance[category] == VibeImportance.top,
      isDealbreaker: pref.dealbreaker,
      onTap: () => _setImportance(category),
    );
  }
}
