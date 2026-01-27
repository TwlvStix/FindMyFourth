import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_text.dart';
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

  bool get _canSave => _topCount == 2 && _bottomCount <= 1 && !_isSaving;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleImportance(VibeCategory category) {
    final current = _importance[category] ?? VibeImportance.normal;
    final next = current == VibeImportance.normal
        ? VibeImportance.top
        : current == VibeImportance.top
            ? VibeImportance.bottom
            : VibeImportance.normal;

    if (next == VibeImportance.top && current != VibeImportance.top) {
      if (_topCount >= 2) {
        return;
      }
    }
    if (next == VibeImportance.bottom && current != VibeImportance.bottom) {
      if (_bottomCount >= 1) {
        return;
      }
    }

    setState(() {
      _importance = Map<VibeCategory, VibeImportance>.from(_importance)
        ..[category] = next;
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
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.of(context).primary,
            size: 30.0,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: AppText.sectionHeader(
          'Vibe Priorities',
          color: AppTheme.of(context).primary,
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
                        'What makes or breaks your round?',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.onyx,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pick the 2 things that matter most. Optional: pick 1 that matters least. You can change this anytime.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.stone,
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
                            color: AppColors.sunsetRose,
                            background: AppColors.sunsetRose.withOpacity(0.15),
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
              color: color,
              letterSpacing: AppTypography.letterSpacingNormal,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count/$max',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.slate,
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
        ? AppColors.fairwayLight.withOpacity(0.18)
        : isBottom
            ? AppColors.sunsetRose.withOpacity(0.14)
            : AppColors.sand;
    final borderColor = isTop
        ? AppColors.fairway
        : isBottom
            ? AppColors.sunsetRose
            : AppColors.cloud;
    final label = isTop
        ? 'Top priority'
        : isBottom
            ? 'Least important'
            : 'Normal';
    final labelColor = isTop
        ? AppColors.fairway
        : isBottom
            ? AppColors.sunsetRose
            : AppColors.stone;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _toggleImportance(category);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onyx,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: labelColor,
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
                      : Icons.swap_vert_rounded,
              color: labelColor,
              size: 22,
            ),
          ],
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
    VibeCategory.weed,
    VibeCategory.money,
  ];

  static const Map<VibeCategory, String> _categoryTitles = {
    VibeCategory.pace: 'Pace of play',
    VibeCategory.competitive: 'Competition vibe',
    VibeCategory.chat: 'Chat level',
    VibeCategory.music: 'Music',
    VibeCategory.drinking: 'Drinking',
    VibeCategory.weed: 'Weed',
    VibeCategory.money: 'Money / stakes',
  };
}
