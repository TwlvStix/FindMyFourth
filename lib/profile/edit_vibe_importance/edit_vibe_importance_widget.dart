import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_text.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/services/vibe_repository.dart';

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
  final VibeRepository _repository = VibeRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<VibeCategory, VibeImportance> _importance = {
    for (final category in VibeCategory.values)
      category: VibeImportance.normal,
  };

  @override
  void initState() {
    super.initState();
    _loadImportance();
  }

  Future<void> _loadImportance() async {
    try {
      final profile = await _repository.getMyVibesCached(forceRefresh: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _importance = Map<VibeCategory, VibeImportance>.from(profile.importance);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _topCount =>
      _importance.values.where((value) => value == VibeImportance.top).length;

  int get _bottomCount => _importance.values
      .where((value) => value == VibeImportance.bottom)
      .length;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setImportance(VibeCategory category, VibeImportance next) {
    final current = _importance[category] ?? VibeImportance.normal;
    if (current == next) {
      setState(() {
        _importance = Map<VibeCategory, VibeImportance>.from(_importance)
          ..[category] = VibeImportance.normal;
      });
      return;
    }
    setState(() {
      final updated = Map<VibeCategory, VibeImportance>.from(_importance);
      if (next == VibeImportance.top && _topCount >= 2) {
        // Auto-clear another top to allow this selection.
        final otherTop = _orderedCategories.firstWhere(
          (entry) => entry != category && updated[entry] == VibeImportance.top,
          orElse: () => category,
        );
        if (otherTop != category) {
          updated[otherTop] = VibeImportance.normal;
        }
      }
      if (next == VibeImportance.bottom && _bottomCount >= 1) {
        // Auto-clear the existing bottom to allow this selection.
        final otherBottom = _orderedCategories.firstWhere(
          (entry) =>
              entry != category && updated[entry] == VibeImportance.bottom,
          orElse: () => category,
        );
        if (otherBottom != category) {
          updated[otherBottom] = VibeImportance.normal;
        }
      }
      updated[category] = next;
      _importance = updated;
    });
  }

  void _clearImportance() {
    if (_isSaving) {
      return;
    }
    setState(() {
      _importance = {
        for (final category in VibeCategory.values)
          category: VibeImportance.normal,
      };
    });
  }

  Future<void> _saveImportance() async {
    if (_isSaving) {
      return;
    }
    if (_topCount != 2) {
      _showSnack('Pick exactly 2 top priorities.');
      return;
    }
    if (_bottomCount > 1) {
      _showSnack('Only one category can be least important.');
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      _showSnack('Please sign in to save priorities.');
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await _repository.updateImportance(_importance);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Failed to save vibe priorities: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      final message = error.code == 'permission-denied'
          ? 'Unable to save priorities. Permission denied.'
          : 'Unable to save priorities. Please try again.';
      _showSnack(message);
      setState(() {
        _isSaving = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to save vibe priorities: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      _showSnack('Unable to save priorities. Please try again.');
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                        'What makes or breaks your round?',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.pure,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pick the 2 things that matter most. Optional: pick 1 that matters least. You can change this anytime.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.sand,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildCountPill(
                            label: 'Top',
                            count: _topCount,
                            max: 2,
                            color: AppColors.fairway,
                            background: AppColors.fairwayLight.withOpacity(0.15),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _buildCountPill(
                            label: 'Bottom',
                            count: _bottomCount,
                            max: 1,
                            color: AppColors.sunsetGold,
                            background: AppColors.sunsetGold.withOpacity(0.15),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ..._orderedCategories.map(
                        (category) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildImportanceCard(category),
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
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildImportanceCard(VibeCategory category) {
    final importance = _importance[category] ?? VibeImportance.normal;
    final title = _categoryTitles[category] ?? VibeLabels.titleFor(category);

    final isTop = importance == VibeImportance.top;
    final isBottom = importance == VibeImportance.bottom;
    final background = isTop
        ? AppColors.fairwayDark.withOpacity(0.3)
        : isBottom
            ? AppColors.sunsetGold.withOpacity(0.2)
            : AppColors.slate.withOpacity(0.15);
    final borderColor = isTop
        ? AppColors.fairway
        : isBottom
            ? AppColors.sunsetGold
            : AppColors.cloud;
    final label = isTop
        ? 'Top priority'
        : isBottom
            ? 'Least important'
            : 'Normal';
    final titleColor = isTop || isBottom ? AppColors.pure : AppColors.sand;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: titleColor,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isTop || isBottom ? AppColors.sand : AppColors.stone,
                        letterSpacing: AppTypography.letterSpacingNormal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isTop
                    ? Icons.arrow_upward_rounded
                    : isBottom
                        ? Icons.arrow_downward_rounded
                        : Icons.radio_button_unchecked_rounded,
                color: isTop || isBottom ? AppColors.pure : AppColors.stone,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _buildSelectorChip(
                label: 'Matters most',
                selected: isTop,
                color: AppColors.fairway,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _setImportance(category, VibeImportance.top);
                },
              ),
              _buildSelectorChip(
                label: 'Does not matter',
                selected: isBottom,
                color: AppColors.sunsetGold,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _setImportance(category, VibeImportance.bottom);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback? onTap,
  }) {
    // Use white text on colored background for better contrast when selected
    final textColor = selected
        ? AppColors.pure
        : (onTap == null ? AppColors.slate : AppColors.onyx);
    final bgColor = selected ? color : AppColors.sand.withOpacity(0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : AppColors.cloud,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: textColor,
            letterSpacing: AppTypography.letterSpacingNormal,
            fontWeight:
                selected ? AppTypography.semiBold : AppTypography.regular,
          ),
        ),
      ),
    );
  }

  static const List<VibeCategory> _orderedCategories = [
    VibeCategory.pace,
    VibeCategory.competitive,
    VibeCategory.chat,
    VibeCategory.music,
    VibeCategory.drinking,
    VibeCategory.money,
  ];

  static const Map<VibeCategory, String> _categoryTitles = {
    VibeCategory.pace: 'Pace of play',
    VibeCategory.competitive: 'Competition vibe',
    VibeCategory.chat: 'Chat level',
    VibeCategory.music: 'Music',
    VibeCategory.drinking: 'Drinking',
    VibeCategory.money: 'Money / stakes',
  };
}
