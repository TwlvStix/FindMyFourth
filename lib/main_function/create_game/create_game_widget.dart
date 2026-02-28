import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/widgets/app_text_field.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/providers/provider_extensions.dart';
import '/providers/trust_provider.dart';
import '/providers/user_provider.dart';
import '/models/course.dart';
import '/services/course_service.dart';
import '/services/create_game_draft_service.dart';
import '/services/create_game_service.dart';
import 'create_game_constants.dart';
import 'create_game_validator.dart';
import 'models/create_game_form_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import 'components/draft_banner.dart';
import 'components/section_header.dart';
import 'components/segmented_control.dart';
import 'components/toggle_switch.dart';
import 'components/card_grid.dart';
import 'components/premium_date_picker.dart';
import 'components/tee_time_picker.dart';
import 'components/games_multi_select.dart';

class CreateGameWidget extends StatefulWidget {
  const CreateGameWidget({super.key});

  static String routeName = 'CreateGame';
  static String routePath = '/createGame';

  @override
  State<CreateGameWidget> createState() => _CreateGameWidgetState();
}

class _CreateGameWidgetState extends State<CreateGameWidget>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICES
  // ═══════════════════════════════════════════════════════════════════════════
  final _courseService = CourseService();
  final _draftService = CreateGameDraftService();
  final _gameService = CreateGameService();

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM STATE
  // ═══════════════════════════════════════════════════════════════════════════
  final formKey = GlobalKey<FormState>();
  late CreateGameFormData _formData;

  // Form controllers (manage UI state, synced to _formData on change)
  FormFieldController<String>? friendsValueController;
  FormFieldController<String>? courseValueController;
  FormFieldController<String>? memberValueController;
  FormFieldController<String>? rulesSetValueController;
  FormFieldController<String>? styleGameValueController;
  FormFieldController<String>? gameTypeValueController;
  FormFieldController<String>? scoringValueController;
  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _otherGameController = TextEditingController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // UI state
  bool _isLoading = true;
  bool _hasDraft = false;
  bool _hasAnimated = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _formData = CreateGameFormData();
    _gameNameController.text = _formData.gameName;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDraft();
      if (mounted) {
        // Validate draft eligibility against user's gender
        final userGender = context.read<UserProvider>().currentUser?.gender;
        final validOptions = _getFilteredEligibilityOptions(userGender);
        final validValues = validOptions.map((o) => o['value']).toSet();
        if (!validValues.contains(_formData.playerEligibility)) {
          _formData.playerEligibility = 'open_to_all';
        }
        setState(() {
          _isLoading = false;
        });
        // Trigger entrance animation after a brief delay
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && !_hasAnimated) {
            setState(() => _hasAnimated = true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _otherGameController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRAFT PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadDraft() async {
    final draft = await _draftService.loadDraft();
    if (draft != null) {
      _formData = draft;
      _formData.reconcileDerivedFields();
      // Sync controllers with loaded data
      _syncControllersFromFormData();
      _hasDraft = true;
    }
  }

  void _syncControllersFromFormData() {
    _gameNameController.text = _formData.gameName;
    friendsValueController?.value = _formData.friendsValue;
    courseValueController?.value = _formData.courseValue;
    memberValueController?.value = _formData.memberValue;
    rulesSetValueController?.value = _formData.rulesSetValue;
    styleGameValueController?.value = _formData.styleGameValue;
    gameTypeValueController?.value = _formData.gameTypeValue;
    scoringValueController?.value = _formData.scoringValue;
    if (_formData.otherGameText != null) {
      _otherGameController.text = _formData.otherGameText!;
    }
  }

  Future<void> _saveDraft() async {
    _formData.gameName = _gameNameController.text.trim();
    _formData.reconcileDerivedFields();
    await _draftService.saveDraft(_formData);
  }

  Future<void> _clearDraft() async {
    await _draftService.clearDraft();
    setState(() {
      _hasDraft = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME SUBMISSION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _submitGame() async {
    AppLog.d('🎮 CREATE GAME: Submit triggered');

    // 1. Form structure validation
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      AppLog.d('❌ CREATE GAME: Form validation failed');
      return;
    }
    AppLog.d('✅ CREATE GAME: Form validation passed');

    // 2. Business rule validation
    final error = CreateGameValidator.validateForSubmission(_formData);
    if (error != null) {
      AppLog.d('❌ CREATE GAME: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    AppLog.d('✅ CREATE GAME: All values present');

    // 3. Auth check
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppLog.d('❌ CREATE GAME: User not authenticated');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to create a game.'),
          duration: Duration(milliseconds: 4000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    AppLog.d('✅ CREATE GAME: User authenticated: ${currentUser.uid}');

    final currentUserRef =
        context.userProvider.currentUser?.reference ??
            _gameService.userRefForUid(currentUser.uid);
    final gameName = _formData.ensureGameName();
    AppLog.d('🎮 CREATE GAME: Game name: $gameName');

    try {
      // 4. Generate game reference first (needed for chat creation)
      final gamesRecordReference = _gameService.generateGameRef();
      AppLog.d('🎮 CREATE GAME: Game ID: ${gamesRecordReference.id}');

      // 5. Create game chat
      AppLog.d('🎮 CREATE GAME: Creating game chat...');
      DocumentReference? chatRef;
      try {
        chatRef = await context.read<ChatProvider>().createGameChat(
              createdByUid: currentUser.uid,
              gameId: gamesRecordReference.id,
              gameName: gameName,
            );
        AppLog.d('✅ CREATE GAME: Game chat created: ${chatRef.id}');
      } catch (chatError, chatStackTrace) {
        AppLog.d('❌ CREATE GAME: Chat creation failed!');
        AppLog.d('❌ CREATE GAME: Error: $chatError');
        AppLog.d('❌ CREATE GAME: Stack trace: $chatStackTrace');
        throw Exception('Failed to create game chat: $chatError');
      }

      // 6. Create game via service
      AppLog.d('🎮 CREATE GAME: Saving game to Firestore...');
      try {
        await _gameService.createGameWithRef(
          gameRef: gamesRecordReference,
          formData: _formData,
          uid: currentUser.uid,
          userRef: currentUserRef,
          chatRef: chatRef,
        );
        AppLog.d('✅ CREATE GAME: Game saved to Firestore successfully');
      } catch (saveError, saveStackTrace) {
        AppLog.d('❌ CREATE GAME: Game save failed!');
        AppLog.d('❌ CREATE GAME: Error: $saveError');
        AppLog.d('❌ CREATE GAME: Stack trace: $saveStackTrace');
        throw Exception('Failed to save game data: $saveError');
      }

      // 7. Clear draft
      await _clearDraft();

      // 8. Invalidate caches & navigate
      if (!mounted) return;

      context.gameProvider.invalidateAvailableGamesCache();
      context.gameProvider
          .invalidateUserGamesCache(context.userProvider.userId);
      AppLog.d('CreateGame: refreshed game caches');

      final numExistingFriends = 4 - _formData.numPlayers - 1;
      AppLog.d(
          'CreateGame: numPlayers=${_formData.numPlayers}, existingFriends=$numExistingFriends');

      if (numExistingFriends <= 0) {
        AppLog.d('CreateGame: No existing friends, skipping Player List');
        context.pushNamed(
          GamesListWidget.routeName,
          extra: <String, dynamic>{
            kTransitionInfoKey: TransitionStandards.modalTransition,
          },
        );
      } else {
        AppLog.d(
            'CreateGame: Has $numExistingFriends existing friends, showing Player List');
        context.pushNamed(
          PlayerListWidget.routeName,
          extra: <String, dynamic>{
            'gameRef': gamesRecordReference,
            kTransitionInfoKey: TransitionInfo(
              hasTransition: true,
              transitionType: AppTransitionType.fade,
              enterDuration: Duration(milliseconds: 200),
              exitDuration: Duration(milliseconds: 170),
              scaleOnPush: false,
            ),
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have created a game!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.pure,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: Duration(milliseconds: 4000),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error, stackTrace) {
      AppLog.d('❌ CREATE GAME: FAILED TO CREATE GAME');
      AppLog.d('❌ CREATE GAME: Error: $error');
      AppLog.d('❌ CREATE GAME: Stack trace: $stackTrace');

      String errorMsg = error.toString();
      if (errorMsg.length > 100) {
        errorMsg = errorMsg.substring(0, 100) + '...';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create game: $errorMsg',
            style:
                AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          duration: Duration(milliseconds: 6000),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFilteredEligibilityOptions(
      String? userGender) {
    if (userGender == 'Male') {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] != 'women_only')
          .toList();
    } else if (userGender == 'Female') {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] != 'men_only')
          .toList();
    } else {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] == 'open_to_all')
          .toList();
    }
  }

  void _showHelpDialog(BuildContext context, String title, String message) {
    HapticFeedback.lightImpact();
    showAppDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navyLight, AppColors.navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
            boxShadow: [AppElevation.xl],
          ),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon: AppPhosphorIcons.help,
                  color: AppColors.pure,
                  size: AppIconSize.lg,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.headlineMediumSans.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButtonEnhanced(
                  text: 'Got it',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.large,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLEXIBLE TIME UI
  // ═══════════════════════════════════════════════════════════════════════════

  List<int> _getAvailableDays() {
    final now = DateTime.now();
    switch (_formData.flexibleWeek) {
      case 'this_week':
        final todayDayIndex = now.weekday % 7;
        return List.generate(7, (i) => i)
            .where((d) => d >= todayDayIndex)
            .toList();
      case 'this_weekend':
        return [0, 6];
      case 'next_week':
      case 'next_2_weeks':
      default:
        return [0, 1, 2, 3, 4, 5, 6];
    }
  }

  void _onWeekChanged(String weekValue) {
    setState(() {
      _formData.flexibleWeek = weekValue;
      final availableDays = _getAvailableDays();
      _formData.selectedDays = availableDays.toSet();
    });
    _saveDraft();
  }

  String _buildFlexibleSummary() {
    final parts = <String>[];

    if (_formData.flexibleWeek != null) {
      switch (_formData.flexibleWeek) {
        case 'this_week':
          parts.add('This Week');
          break;
        case 'this_weekend':
          parts.add('This Weekend');
          break;
        case 'next_week':
          parts.add('Next Week');
          break;
        case 'next_2_weeks':
          parts.add('Next 2 Weeks');
          break;
      }
    }

    if (_formData.selectedDays.isNotEmpty &&
        _formData.flexibleWeek != 'this_weekend') {
      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final sortedDays = _formData.selectedDays.toList()..sort();

      if (sortedDays.length == 7) {
        parts.add('Any Day');
      } else if (setEquals(sortedDays.toSet(), {1, 2, 3, 4, 5})) {
        parts.add('Weekdays');
      } else if (setEquals(sortedDays.toSet(), {0, 6})) {
        parts.add('Weekend');
      } else {
        parts.add(sortedDays.map((d) => dayNames[d]).join(', '));
      }
    }

    if (_formData.flexibleTimesOfDay.isNotEmpty) {
      if (_formData.flexibleTimesOfDay.contains('anytime')) {
        parts.add('Anytime');
      } else {
        final timeLabels = <String>[];
        if (_formData.flexibleTimesOfDay.contains('morning'))
          timeLabels.add('Morning');
        if (_formData.flexibleTimesOfDay.contains('afternoon'))
          timeLabels.add('Afternoon');
        if (_formData.flexibleTimesOfDay.contains('twilight'))
          timeLabels.add('Twilight');
        if (timeLabels.isNotEmpty) {
          parts.add(timeLabels.join(', '));
        }
      }
    }

    return parts.isEmpty ? 'Select your availability' : parts.join(' · ');
  }

  TextStyle _labelStyle() => AppTypography.labelSmall.copyWith(
        fontSize: 13,
        color: AppColors.glassTextSecondary,
      );

  Widget _buildAnimatedSection({
    required int sectionIndex,
    required Widget child,
  }) {
    final clampedIndex = sectionIndex < MotionTokens.staggerMaxItems
        ? sectionIndex
        : MotionTokens.staggerMaxItems - 1;
    final staggerDelay = ReducedMotionService.shouldStagger
        ? MotionTokens.staggerDelay * clampedIndex
        : Duration.zero;

    return child.animate(target: _hasAnimated ? 1 : 0).fadeIn(
          delay: staggerDelay,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        );
  }

  Widget _buildFlexibleTimeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              AppIcon(
                  icon: AppPhosphorIcons.info,
                  color: AppColors.pure,
                  size: AppIconSize.button),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No tee time yet? Pick when you\'re available — lock it in once you have your group.',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text('Week', style: _labelStyle()),
        SizedBox(height: AppSpacing.xs),
        _buildWeekChips(),
        SizedBox(height: AppSpacing.md),
        AnimatedCrossFade(
          duration: MotionTokens.contentReveal,
          crossFadeState: _formData.flexibleWeek == 'this_weekend'
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Days — tap to exclude', style: _labelStyle()),
              SizedBox(height: AppSpacing.xs),
              _buildDayChips(),
              SizedBox(height: AppSpacing.md),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
        Text('Time of Day', style: _labelStyle()),
        SizedBox(height: AppSpacing.xs),
        _buildTimeOfDayCards(),
        if (_buildFlexibleSummary().isNotEmpty &&
            _buildFlexibleSummary() != 'Select your availability') ...[
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navyLight, AppColors.navy],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Row(
              children: [
                AppIcon(
                    icon: AppPhosphorIcons.calendarNote,
                    color: AppColors.pure,
                    size: AppIconSize.button),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _buildFlexibleSummary(),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeekChips() {
    final weeks = [
      {'value': 'this_week', 'label': 'This Week'},
      {'value': 'this_weekend', 'label': 'This Weekend'},
      {'value': 'next_week', 'label': 'Next Week'},
      {'value': 'next_2_weeks', 'label': 'Next 2 Weeks'},
    ];

    return Row(
      children: weeks.map((week) {
        final isSelected = _formData.flexibleWeek == week['value'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: week == weeks.last ? 0 : AppSpacing.xs,
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _onWeekChanged(week['value'] as String);
              },
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDark : AppColors.navy,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.navyDark
                        : AppColors.greenLight.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  week['label'] as String,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.pure,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayChips() {
    final allDays = [
      {'value': 0, 'label': 'Sun'},
      {'value': 1, 'label': 'Mon'},
      {'value': 2, 'label': 'Tue'},
      {'value': 3, 'label': 'Wed'},
      {'value': 4, 'label': 'Thu'},
      {'value': 5, 'label': 'Fri'},
      {'value': 6, 'label': 'Sat'},
    ];

    final availableDayIndices = _getAvailableDays().toSet();
    final days =
        allDays.where((d) => availableDayIndices.contains(d['value'])).toList();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: days.map((day) {
        final dayIndex = day['value'] as int;
        final isSelected = _formData.selectedDays.contains(dayIndex);

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _formData.selectedDays.remove(dayIndex);
              } else {
                _formData.selectedDays.add(dayIndex);
              }
            });
            _saveDraft();
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.green, AppColors.greenLight],
                    )
                  : null,
              color: isSelected ? null : AppColors.navy,
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(
                color: isSelected
                    ? AppColors.green
                    : AppColors.greenLight.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              day['label'] as String,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeOfDayCards() {
    final times = [
      {
        'value': 'anytime',
        'label': 'Anytime',
        'icon': AppPhosphorIcons.teeTime,
        'subtitle': 'Any Time'
      },
      {
        'value': 'morning',
        'label': 'Morning',
        'icon': AppPhosphorIcons.morning,
        'subtitle': 'Before 11am'
      },
      {
        'value': 'afternoon',
        'label': 'Afternoon',
        'icon': AppPhosphorIcons.afternoon,
        'subtitle': '11am-3pm'
      },
      {
        'value': 'twilight',
        'label': 'Twilight',
        'icon': AppPhosphorIcons.twilight,
        'subtitle': 'After 3pm'
      },
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.xs,
      mainAxisSpacing: AppSpacing.xs,
      childAspectRatio: 0.75,
      padding: EdgeInsets.zero,
      children: times.map((time) {
        final value = time['value'] as String;
        final isSelected = _formData.flexibleTimesOfDay.contains(value);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (value == 'anytime') {
                _formData.flexibleTimesOfDay = {'anytime'};
              } else {
                if (isSelected) {
                  _formData.flexibleTimesOfDay.remove(value);
                  if (_formData.flexibleTimesOfDay.isEmpty ||
                      (_formData.flexibleTimesOfDay.length == 1 &&
                          _formData.flexibleTimesOfDay.contains('anytime'))) {
                    _formData.flexibleTimesOfDay = {'anytime'};
                  }
                } else {
                  _formData.flexibleTimesOfDay.remove('anytime');
                  _formData.flexibleTimesOfDay.add(value);
                  if (_formData.flexibleTimesOfDay
                      .containsAll({'morning', 'afternoon', 'twilight'})) {
                    _formData.flexibleTimesOfDay = {'anytime'};
                  }
                }
              }
            });
            _saveDraft();
          },
          child: Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.navy.withValues(alpha: 0.5),
                        AppColors.navyDark.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: isSelected ? null : AppColors.navy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.glassSurface,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  icon: time['icon'] as PhosphorIconData,
                  size: AppIconSize.md,
                  color: AppColors.pure,
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  time['label'] as String,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1),
                Text(
                  time['subtitle'] as String,
                  style: AppTypography.labelMicro.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColors.glassTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: AppColors.navyDark,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            key: scaffoldKey,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0.0,
              elevation: 0.0,
              shadowColor: Colors.transparent,
              automaticallyImplyLeading: false,
              leading: const PremiumBackButton(),
              title: Text(
                'Create Game',
                style: AppTypography.headlineMediumSans.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
            ),
            body: FairwayBackgroundDark(
              showOrganic: true,
              showTexture: true,
              child: SafeArea(
                top: false,
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpinKitWanderingCubes(
                              color: AppColors.green,
                              size: 50.0,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Loading...',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          MediaQuery.of(context).padding.top +
                              56 +
                              AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (_hasDraft) DraftBanner(onClear: _clearDraft),
                              Consumer<TrustProvider>(
                                builder: (context, trust, _) {
                                  final restriction =
                                      trust.myStanding?.currentRestriction;
                                  if (restriction == null)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding:
                                        EdgeInsets.only(bottom: AppSpacing.md),
                                    child: RestrictionBanner(
                                      restriction: restriction,
                                      onViewStanding: () =>
                                          context.pushNamed('YourStanding'),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: double.infinity,
                                child: Form(
                                  key: formKey,
                                  autovalidateMode: AutovalidateMode.always,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildAnimatedSection(
                                          sectionIndex: 0,
                                          child: SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.games,
                                            title: 'Game Name',
                                            helpText:
                                                'Auto-generated for you. Edit here if you want a custom name.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Game Name',
                                                'Auto-generated for you. Edit here if you want a custom name.'),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: AppSpacing.xxs),
                                          child: AppTextField(
                                            label: 'Game name',
                                            hint: 'Auto-generated',
                                            controller: _gameNameController,
                                            variant:
                                                AppTextFieldVariant.filledDark,
                                            prefixPhosphorIcon:
                                                AppPhosphorIcons.label,
                                            onChanged: (_) => _saveDraft(),
                                          ),
                                        ),
                                        _buildAnimatedSection(
                                          sectionIndex: 1,
                                          child: SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.calendarCheck,
                                            title: 'Schedule',
                                            helpText:
                                                'Choose if you have a confirmed tee time or flexible availability.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Schedule',
                                                'Choose if you have a confirmed tee time or flexible availability.'),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: AppSpacing.xxs),
                                          child: SegmentedControl(
                                            options: [
                                              {
                                                'value': 'confirmed',
                                                'label': 'I Have a Tee Time',
                                                'phosphorIcon': AppPhosphorIcons
                                                    .calendarCheck
                                              },
                                              {
                                                'value': 'flexible',
                                                'label': 'Flexible Time',
                                                'phosphorIcon': AppPhosphorIcons
                                                    .calendarNote
                                              },
                                            ],
                                            selectedValue:
                                                _formData.scheduleType,
                                            onChanged: (val) {
                                              if (mounted) {
                                                setState(() {
                                                  _formData.scheduleType = val;
                                                  if (val == 'flexible') {
                                                    _formData.datePicked = null;
                                                  } else {
                                                    _formData.flexibleWeek =
                                                        null;
                                                    _formData.selectedDays
                                                        .clear();
                                                    _formData
                                                        .flexibleTimesOfDay = {
                                                      'anytime'
                                                    };
                                                  }
                                                });
                                                _saveDraft();
                                              }
                                            },
                                          ),
                                        ),
                                        if (_formData.scheduleType ==
                                            'confirmed') ...[
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.sm),
                                            child: PremiumDatePicker(
                                              selectedDate:
                                                  _formData.datePicked,
                                              onDateSelected: (date) {
                                                if (mounted) {
                                                  setState(() {
                                                    _formData.datePicked = date;
                                                  });
                                                  _saveDraft();
                                                }
                                              },
                                            ),
                                          ),
                                          if (_formData.datePicked != null) ...[
                                            SizedBox(height: AppSpacing.sm),
                                            InkWell(
                                              onTap: () {
                                                showTeeTimePicker(
                                                  context: context,
                                                  selectedDateTime:
                                                      _formData.datePicked,
                                                  onTimeSelected: (dateTime) {
                                                    if (mounted) {
                                                      setState(() {
                                                        _formData.datePicked =
                                                            dateTime;
                                                      });
                                                      _saveDraft();
                                                    }
                                                  },
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppBorderRadius.md),
                                              child: Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: AppSpacing.md,
                                                    horizontal: AppSpacing.md),
                                                decoration: BoxDecoration(
                                                  color: AppColors.navy,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppBorderRadius.md),
                                                  border: Border.all(
                                                      color: AppColors
                                                          .greenLight
                                                          .withValues(
                                                              alpha: 0.3),
                                                      width: 1.5),
                                                ),
                                                child: Row(
                                                  children: [
                                                    AppIcon(
                                                        icon: AppPhosphorIcons
                                                            .teeTime,
                                                        color: AppColors.pure,
                                                        size:
                                                            AppIconSize.button),
                                                    SizedBox(
                                                        width: AppSpacing.sm),
                                                    Expanded(
                                                      child: Text(
                                                        dateTimeFormat(
                                                            "jm",
                                                            _formData
                                                                .datePicked),
                                                        style: AppTypography
                                                            .labelMedium
                                                            .copyWith(
                                                                color: AppColors
                                                                    .pure,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                    ),
                                                    AppIcon(
                                                        icon: AppPhosphorIcons
                                                            .edit,
                                                        color: AppColors
                                                            .textSecondary,
                                                        size: AppIconSize.sm),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (_formData.datePicked != null) ...[
                                            SizedBox(height: AppSpacing.sm),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  EdgeInsets.all(AppSpacing.md),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.navyLight,
                                                      AppColors.navy
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppBorderRadius.md),
                                              ),
                                              child: Row(
                                                children: [
                                                  AppIcon(
                                                      icon: AppPhosphorIcons
                                                          .golfCourse,
                                                      color: AppColors.pure,
                                                      size: AppIconSize.button),
                                                  SizedBox(
                                                      width: AppSpacing.sm),
                                                  Expanded(
                                                    child: Text(
                                                      '${dateTimeFormat("EEEE, MMM d", _formData.datePicked)} at ${dateTimeFormat("jm", _formData.datePicked)}',
                                                      style: AppTypography
                                                          .labelMedium
                                                          .copyWith(
                                                              color: AppColors
                                                                  .textPrimary),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ] else ...[
                                          _buildFlexibleTimeUI(),
                                        ],
                                        _buildAnimatedSection(
                                          sectionIndex: 2,
                                          child: SectionHeader(
                                            phosphorIcon: AppPhosphorIcons
                                                .publicVisibility,
                                            title: 'Visibility',
                                            helpText:
                                                'Choose whether your game is visible to friends only or everyone in your area.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Visibility',
                                                'Choose whether your game is visible to friends only or everyone in your area.'),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: AppSpacing.xxs),
                                          child: SegmentedControl(
                                            options: [
                                              {
                                                'value': 'Friends',
                                                'label': 'Friends',
                                                'phosphorIcon':
                                                    AppPhosphorIcons.people
                                              },
                                              {
                                                'value': 'Public',
                                                'label': 'Public',
                                                'phosphorIcon': AppPhosphorIcons
                                                    .publicVisibility
                                              },
                                            ],
                                            selectedValue:
                                                _formData.friendsValue,
                                            onChanged: (val) {
                                              if (mounted) {
                                                setState(() => _formData
                                                    .friendsValue = val);
                                                _saveDraft();
                                              }
                                            },
                                          ),
                                        ),
                                        _buildAnimatedSection(
                                          sectionIndex: 3,
                                          child: SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.openToAll,
                                            title: 'Who Can Join',
                                            helpText:
                                                'Choose who can join your game based on gender.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Who Can Join',
                                                'Choose who can join your game. \'Women Only\' and \'Men Only\' restrict joining based on the gender in each player\'s profile.'),
                                          ),
                                        ),
                                        Consumer<UserProvider>(
                                          builder: (context, userProvider, _) {
                                            final filteredOptions =
                                                _getFilteredEligibilityOptions(
                                                    userProvider
                                                        .currentUser?.gender);
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  top: AppSpacing.xxs),
                                              child: CardGrid(
                                                options: filteredOptions,
                                                selectedValue:
                                                    _formData.playerEligibility,
                                                onChanged: (val) {
                                                  if (mounted) {
                                                    setState(() => _formData
                                                            .playerEligibility =
                                                        val);
                                                    _saveDraft();
                                                  }
                                                },
                                                crossAxisCount:
                                                    filteredOptions.length,
                                                childAspectRatio: 1.2,
                                              ),
                                            );
                                          },
                                        ),
                                        _buildAnimatedSection(
                                          sectionIndex: 4,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.md),
                                            child: ToggleSwitch(
                                              label: 'Require vibe match',
                                              description:
                                                  'Players with a different play style will need your approval',
                                              value: _formData.requireVibeMatch,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() => _formData
                                                      .requireVibeMatch = val);
                                                  _saveDraft();
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        _buildAnimatedSection(
                                          sectionIndex: 5,
                                          child: SectionHeader(
                                              phosphorIcon:
                                                  AppPhosphorIcons.course,
                                              title: 'Course'),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(-1.0, 0.0),
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: StreamBuilder<List<Course>>(
                                              stream: _courseService
                                                  .streamAllCourses(),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 50.0,
                                                      height: 50.0,
                                                      child:
                                                          SpinKitWanderingCubes(
                                                              color: AppColors
                                                                  .gold,
                                                              size: 50.0),
                                                    ),
                                                  );
                                                }
                                                final courseCourseRecordList =
                                                    snapshot.data!;
                                                if (courseCourseRecordList
                                                    .isEmpty) {
                                                  return Container(
                                                    padding: EdgeInsets.all(
                                                        AppSpacing.lg),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.navy
                                                          .withValues(
                                                              alpha: 0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppBorderRadius
                                                                  .md),
                                                      border: Border.all(
                                                          color: AppColors
                                                              .navyLight
                                                              .withValues(
                                                                  alpha: 0.3)),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        AppIcon(
                                                            icon:
                                                                AppPhosphorIcons
                                                                    .golfCourse,
                                                            size:
                                                                AppIconSize.xl,
                                                            color: AppColors
                                                                .textMuted),
                                                        SizedBox(
                                                            height:
                                                                AppSpacing.sm),
                                                        Text(
                                                            'No courses available',
                                                            style: AppTypography
                                                                .bodySmall
                                                                .copyWith(
                                                                    color: AppColors
                                                                        .glassTextSecondary)),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                _formData.hydrateSelectedCourse(
                                                    courseCourseRecordList);
                                                courseValueController ??=
                                                    FormFieldController<String>(
                                                        _formData.courseValue);
                                                if (courseValueController
                                                        ?.value !=
                                                    _formData.courseValue) {
                                                  courseValueController?.value =
                                                      _formData.courseValue;
                                                }

                                                return AppDropDown<String>(
                                                  controller:
                                                      courseValueController,
                                                  options:
                                                      courseCourseRecordList
                                                          .map((e) => e.name)
                                                          .toList(),
                                                  onChanged: (val) async {
                                                    if (mounted) {
                                                      setState(() => _formData
                                                          .courseValue = val);
                                                    }
                                                    _formData.setSelectedCourse(
                                                      courseCourseRecordList
                                                          .firstWhereOrNull(
                                                              (course) =>
                                                                  course.name ==
                                                                  val),
                                                    );
                                                    _saveDraft();
                                                  },
                                                  width: 300.0,
                                                  height: 50.0,
                                                  searchHintTextStyle:
                                                      AppTypography
                                                          .labelMedium
                                                          .copyWith(
                                                              color: AppColors
                                                                  .textMuted),
                                                  searchTextStyle: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                          color: AppColors
                                                              .textPrimary),
                                                  searchCursorColor:
                                                      AppColors.green,
                                                  textStyle: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                          color: AppColors
                                                              .textPrimary),
                                                  hintText:
                                                      'Where are you playing?',
                                                  searchHintText:
                                                      'Find your course',
                                                  icon: AppIcon(
                                                      icon: AppPhosphorIcons
                                                          .chevronDown,
                                                      color: AppColors
                                                          .textSecondary,
                                                      size: AppIconSize.md),
                                                  fillColor:
                                                      AppColors.inputBackground,
                                                  elevation: 2.0,
                                                  borderColor:
                                                      AppColors.inputBorderIdle,
                                                  borderWidth: 1.0,
                                                  borderRadius: 10.0,
                                                  margin: EdgeInsetsDirectional
                                                      .only(
                                                          start: AppSpacing.md),
                                                  hidesUnderline: true,
                                                  isOverButton: true,
                                                  isSearchable: true,
                                                  isMultiSelect: false,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.md),
                                        ToggleSwitch(
                                          label: 'Member Guest Rate',
                                          description:
                                              'This game is created by a course member who can offer guest-rate pricing.',
                                          value: _formData.memberDiscount,
                                          onChanged: (val) {
                                            if (mounted) {
                                              setState(() {
                                                _formData.memberDiscount = val;
                                                _formData.memberValue =
                                                    val ? 'Yes' : 'No';
                                              });
                                              _saveDraft();
                                            }
                                          },
                                        ),
                                        ToggleSwitch(
                                          label: 'Just for Fun',
                                          description:
                                              'Skip all the details. Just show up and play.',
                                          value: _formData.isJustForFun,
                                          onChanged: (val) {
                                            if (mounted) {
                                              setState(() {
                                                _formData.isJustForFun = val;
                                              });
                                              _saveDraft();
                                            }
                                          },
                                        ),
                                        if (!_formData.isJustForFun) ...[
                                          SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.competitive,
                                            title: 'Game Vibe',
                                            helpText:
                                                'Set the tone for your round. Competitive focuses on rules and pace, while Casual keeps it relaxed and friendly.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Game Vibe',
                                                'Set the tone for your round. Competitive focuses on rules and pace, while Casual keeps it relaxed and friendly.'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: CardGrid(
                                              options: kCreateGameVibeOptions,
                                              selectedValue:
                                                  _formData.rulesSetValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() => _formData
                                                      .rulesSetValue = val);
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 2,
                                              childAspectRatio: 1.2,
                                            ),
                                          ),
                                          SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.betting,
                                            title: 'Stakes',
                                            helpText:
                                                'Playing for money or keeping it friendly? Choose your comfort level.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Stakes',
                                                'Playing for money or keeping it friendly? Choose your comfort level.'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: CardGrid(
                                              options: kCreateGameStakesOptions,
                                              selectedValue:
                                                  _formData.styleGameValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() => _formData
                                                      .styleGameValue = val);
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.95,
                                            ),
                                          ),
                                          SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.gameType,
                                            title: 'Primary Format',
                                            helpText:
                                                'Choose your core scoring format: Match Play (hole-by-hole), Stroke Play (total strokes), Stableford (points).',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Primary Format',
                                                'Choose your core scoring format: Match Play (hole-by-hole), Stroke Play (total strokes), Stableford (points).'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: CardGrid(
                                              options:
                                                  kCreateGamePrimaryFormatOptions,
                                              selectedValue:
                                                  _formData.gameTypeValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() {
                                                    _formData.gameTypeValue =
                                                        val;
                                                  });
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.95,
                                            ),
                                          ),
                                          SizedBox(height: AppSpacing.md),
                                          ToggleSwitch(
                                            label: '2v2 (Teams)',
                                            description:
                                                'Enable team play mode',
                                            value: _formData.is2v2,
                                            onChanged: (val) {
                                              if (mounted) {
                                                setState(() {
                                                  _formData.is2v2 = val;
                                                  if (!val) {
                                                    _formData.teamStyle = null;
                                                  }
                                                });
                                                _saveDraft();
                                              }
                                            },
                                          ),
                                          if (_formData.is2v2) ...[
                                            SizedBox(height: AppSpacing.sm),
                                            SectionHeader(
                                                phosphorIcon:
                                                    AppPhosphorIcons.teams,
                                                title: 'Team Style'),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: AppSpacing.xxs),
                                              child: CardGrid(
                                                options: [
                                                  {
                                                    'value': 'Best Ball',
                                                    'label': 'Best Ball',
                                                    'phosphorIcon':
                                                        AppPhosphorIcons
                                                            .bestBall
                                                  },
                                                  {
                                                    'value': 'Scramble',
                                                    'label': 'Scramble',
                                                    'phosphorIcon':
                                                        AppPhosphorIcons.groups
                                                  },
                                                ],
                                                selectedValue:
                                                    _formData.teamStyle,
                                                onChanged: (val) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _formData.teamStyle = val;
                                                    });
                                                    _saveDraft();
                                                  }
                                                },
                                                crossAxisCount: 2,
                                                childAspectRatio: 1.2,
                                              ),
                                            ),
                                          ],
                                          SectionHeader(
                                            phosphorIcon:
                                                AppPhosphorIcons.handicap,
                                            title: 'Handicap Use',
                                            helpText:
                                                'Gross is total strokes. Net adjusts for handicap. Gross + Net tracks both scores.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Handicap Use',
                                                'Gross is total strokes. Net adjusts for handicap. Gross + Net tracks both scores.'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: CardGrid(
                                              options:
                                                  kCreateGameHandicapOptions,
                                              selectedValue:
                                                  _formData.scoringValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() => _formData
                                                      .scoringValue = val);
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.95,
                                            ),
                                          ),
                                          SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.dots,
                                            title: 'Games (Optional)',
                                            helpText:
                                                'Add up to 3 side games to your round. These are played alongside your primary format.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Games',
                                                'Add up to 3 side games to your round. These are played alongside your primary format.'),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: GamesMultiSelect(
                                              selectedGames:
                                                  _formData.selectedGames,
                                              onGameToggled: (game) {
                                                if (mounted) {
                                                  setState(() {
                                                    if (_formData.selectedGames
                                                        .contains(game)) {
                                                      _formData.selectedGames
                                                          .remove(game);
                                                      if (game == 'Other') {
                                                        _formData
                                                                .otherGameText =
                                                            null;
                                                        _otherGameController
                                                            .clear();
                                                      }
                                                    } else {
                                                      _formData.selectedGames
                                                          .add(game);
                                                    }
                                                  });
                                                  _saveDraft();
                                                }
                                              },
                                              otherGameController:
                                                  _otherGameController,
                                              onOtherGameChanged: (text) {
                                                setState(() {
                                                  _formData.otherGameText =
                                                      text.trim().isEmpty
                                                          ? null
                                                          : text.trim();
                                                });
                                                _saveDraft();
                                              },
                                              maxGames: 3,
                                            ),
                                          ),
                                          if (_formData.gameTypeValue != null &&
                                              _formData.scoringValue != null &&
                                              _formData.styleGameValue !=
                                                  null &&
                                              _formData.rulesSetValue !=
                                                  null) ...[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: AppSpacing.lg),
                                              child: Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.all(
                                                    AppSpacing.md),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.navy.withValues(
                                                          alpha: 0.3),
                                                      AppColors.navyDark
                                                          .withValues(
                                                              alpha: 0.4)
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppBorderRadius.md),
                                                  border: Border.all(
                                                      color: AppColors.green
                                                          .withValues(
                                                              alpha: 0.3),
                                                      width: 1),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Game Summary',
                                                      style: AppTypography
                                                          .labelSmall
                                                          .copyWith(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: AppColors
                                                                  .glassTextSecondary),
                                                    ),
                                                    SizedBox(
                                                        height: AppSpacing.xs),
                                                    Text(
                                                      _formData
                                                          .buildGameSummary(),
                                                      style: AppTypography
                                                          .labelMedium
                                                          .copyWith(
                                                              color: AppColors
                                                                  .textPrimary,
                                                              height: 1.4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: AppSpacing.xxl),
                                          child: Consumer<TrustProvider>(
                                            builder: (context, trust, _) {
                                              final isRestricted = trust
                                                      .myStanding
                                                      ?.currentRestriction !=
                                                  null;
                                              return AppButtonEnhanced(
                                                text: 'Submit Game',
                                                variant:
                                                    AppButtonVariant.primary,
                                                size: AppButtonSize.large,
                                                onPressed: isRestricted
                                                    ? null
                                                    : _submitGame,
                                                enabled: !isRestricted,
                                              );
                                            },
                                          ),
                                        ),
                                      ]
                                          .divide(
                                              SizedBox(height: AppSpacing.xs))
                                          .addToStart(
                                              SizedBox(height: AppSpacing.xs))
                                          .addToEnd(
                                              SizedBox(height: AppSpacing.xs)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ));
  }
}
