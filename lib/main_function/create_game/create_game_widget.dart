import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '/core/widgets/app_drop_down.dart';
import '/utils/flexible_week_resolver.dart';
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
import 'create_game_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

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
  final formKey = GlobalKey<FormState>();
  DateTime? datePicked;
  String? friendsValue;
  FormFieldController<String>? friendsValueController;
  String? courseValue;
  FormFieldController<String>? courseValueController;
  Course? selectedCourse;
  String? memberValue;
  FormFieldController<String>? memberValueController;
  String? rulesSetValue;
  FormFieldController<String>? rulesSetValueController;
  String? styleGameValue;
  FormFieldController<String>? styleGameValueController;
  String? gameTypeValue;
  FormFieldController<String>? gameTypeValueController;
  String? scoringValue;
  FormFieldController<String>? scoringValueController;
  DocumentReference? chatRef;
  DocumentReference? gameRef;
  bool memberDiscount = false;

  // Flexible Time
  String _scheduleType = 'confirmed'; // 'confirmed' | 'flexible'
  String? _flexibleWeek;
  Set<int> _selectedDays = {};
  Set<String> _flexibleTimesOfDay = {'anytime'}; // Multi-select, default to Anytime

  // Team Setup
  bool _is2v2 = false;
  String? _teamStyle;

  // Just for Fun mode
  bool _isJustForFun = false;

  // Player Eligibility (who can join based on gender)
  String _playerEligibility = 'open_to_all'; // 'open_to_all' | 'women_only' | 'men_only'

  // Games multi-select (max 3)
  final Set<String> _selectedGames = {};
  final TextEditingController _otherGameController = TextEditingController();
  String? _otherGameText;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Draft & Loading state
  bool _isLoading = true;
  bool _hasDraft = false;

  // Animation state - triggers once when content loads
  bool _hasAnimated = false;
  static const String _draftKey = 'create_game_draft';
  final TextEditingController _gameNameController = TextEditingController();

  static const List<String> _mastersChampions = [
    'Nicklaus',
    'Woods',
    'Spieth',
    'Mickelson',
    'Hogan',
    'Faldo',
    'Player',
    'Watson',
    'Palmer',
    'Scheffler',
  ];

  static const List<String> _fruits = [
    'Apple',
    'Banana',
    'Cherry',
    'Mango',
    'Peach',
    'Pear',
    'Plum',
    'Orange',
    'Kiwi',
    'Grape',
  ];

  static const List<String> _traits = [
    'Bold',
    'Calm',
    'Clever',
    'Daring',
    'Focused',
    'Gritty',
    'Humble',
    'Loyal',
    'Steady',
    'Swift',
  ];

  String _generateAutoGameName() {
    final random = Random();
    final champion =
        _mastersChampions[random.nextInt(_mastersChampions.length)];
    final fruit = _fruits[random.nextInt(_fruits.length)];
    final trait = _traits[random.nextInt(_traits.length)];
    return '$champion $fruit $trait';
  }

  String _ensureGameName() {
    final existing = _gameNameController.text.trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    final generated = _generateAutoGameName();
    _gameNameController.text = generated;
    return generated;
  }

  @override
  void initState() {
    super.initState();
    _gameNameController.text = _generateAutoGameName();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDraft();
      if (mounted) {
        // Validate draft eligibility against user's gender
        final userGender = context.read<UserProvider>().currentUser?.gender;
        final validOptions = _getFilteredEligibilityOptions(userGender);
        final validValues = validOptions.map((o) => o['value']).toSet();
        if (!validValues.contains(_playerEligibility)) {
          _playerEligibility = 'open_to_all';
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

  // Load draft from SharedPreferences
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey);
      if (draftJson != null && draftJson.isNotEmpty) {
        final draft = json.decode(draftJson) as Map<String, dynamic>;

        // Restore form values
        if (draft['date'] != null) {
          datePicked = DateTime.parse(draft['date']);
        }
        if (draft['friends'] != null) {
          friendsValue = draft['friends'];
          friendsValueController?.value = draft['friends'];
        }
        if (draft['course'] != null) {
          courseValue = draft['course'];
          courseValueController?.value = draft['course'];
        }
        if (draft['member'] != null) {
          memberValue = draft['member'];
          memberValueController?.value = draft['member'];
        }
        if (draft['rulesSet'] != null) {
          rulesSetValue = draft['rulesSet'];
          rulesSetValueController?.value = draft['rulesSet'];
        }
        if (draft['styleGame'] != null) {
          styleGameValue = draft['styleGame'];
          styleGameValueController?.value = draft['styleGame'];
        }
        if (draft['gameType'] != null) {
          gameTypeValue = draft['gameType'];
          gameTypeValueController?.value = draft['gameType'];
        }
        if (draft['scoring'] != null) {
          scoringValue = draft['scoring'];
          scoringValueController?.value = draft['scoring'];
        }
        if (draft['is2v2'] != null) {
          _is2v2 = draft['is2v2'] as bool;
        }
        if (draft['teamStyle'] != null) {
          _teamStyle = draft['teamStyle'];
        }
        if (draft['selectedGames'] != null) {
          final games = draft['selectedGames'] as List<dynamic>;
          _selectedGames.clear();
          _selectedGames.addAll(games.cast<String>());
        }
        if (draft['otherGame'] != null) {
          _otherGameText = draft['otherGame'];
          _otherGameController.text = draft['otherGame'];
        }
        final draftName = draft['gameName'] as String?;
        if (draftName != null && draftName.trim().isNotEmpty) {
          _gameNameController.text = draftName;
        } else {
          _ensureGameName();
        }

        // Load flexible time fields
        if (draft['scheduleType'] != null) {
          _scheduleType = draft['scheduleType'];
        }
        if (draft['flexibleWeek'] != null) {
          _flexibleWeek = draft['flexibleWeek'];
        }
        if (draft['flexibleDays'] != null) {
          final days = draft['flexibleDays'] as List<dynamic>;
          _selectedDays = Set.from(days.cast<int>());
        }
        if (draft['flexibleTimeOfDay'] != null) {
          // Handle both legacy single string and new comma-separated format
          final stored = draft['flexibleTimeOfDay'] as String;
          _flexibleTimesOfDay = stored.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
          if (_flexibleTimesOfDay.isEmpty) {
            _flexibleTimesOfDay = {'anytime'}; // Default
          }
        }
        if (draft['isJustForFun'] != null) {
          _isJustForFun = draft['isJustForFun'] as bool;
        }
        if (draft['playerEligibility'] != null) {
          _playerEligibility = draft['playerEligibility'] as String;
        }

        _hasDraft = true;
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
  }

  // Save draft to SharedPreferences
  Future<void> _saveDraft() async {
    try {
      final gameName = _gameNameController.text.trim();
      final draft = {
        'date': datePicked?.toIso8601String(),
        'friends': friendsValue,
        'course': courseValue,
        'member': memberValue,
        'rulesSet': rulesSetValue,
        'styleGame': styleGameValue,
        'gameType': gameTypeValue,
        'scoring': scoringValue,
        'is2v2': _is2v2,
        'teamStyle': _teamStyle,
        'selectedGames': _selectedGames.toList(),
        'otherGame': _otherGameText,
        'gameName': gameName.isEmpty ? null : gameName,
        'scheduleType': _scheduleType,
        'flexibleWeek': _flexibleWeek,
        'flexibleDays': _selectedDays.toList(),
        'flexibleTimeOfDay': _flexibleTimesOfDay.join(','), // Store as comma-separated
        'isJustForFun': _isJustForFun,
        'playerEligibility': _playerEligibility,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey, json.encode(draft));
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  // Clear draft from SharedPreferences
  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      setState(() {
        _hasDraft = false;
      });
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  // Quick create with defaults - creates game immediately
  // Shared game submission logic
  Future<void> _submitGame() async {
    debugPrint('🎮 CREATE GAME: Submit triggered');

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      debugPrint('❌ CREATE GAME: Form validation failed');
      return;
    }
    debugPrint('✅ CREATE GAME: Form validation passed');

    // Course is required for confirmed games but optional for flexible games
    if (_scheduleType == 'confirmed' && courseValue == null) {
      debugPrint('❌ CREATE GAME: courseValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a course'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (friendsValue == null) {
      debugPrint('❌ CREATE GAME: friendsValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select Friends or Public game'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_isJustForFun) {
      if (rulesSetValue == null) {
        debugPrint('❌ CREATE GAME: rulesSetValue is null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a game vibe'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (styleGameValue == null) {
        debugPrint('❌ CREATE GAME: styleGameValue is null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select stakes'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (gameTypeValue == null) {
        debugPrint('❌ CREATE GAME: gameTypeValue is null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a primary format'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    debugPrint('✅ CREATE GAME: All values present');

    // Validate schedule based on type
    if (_scheduleType == 'confirmed') {
      if (datePicked == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a date and time.'),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      // Flexible mode validation - week is required
      if (_flexibleWeek == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a week for your flexible game.'),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (!_isJustForFun) {
      // Validate Team Style is required if 2v2 is enabled
      if (_is2v2 && (_teamStyle == null || _teamStyle!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a team style for 2v2 games.'),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate "Other" game requires description if selected
      if (_selectedGames.contains('Other') &&
          (_otherGameText == null || _otherGameText!.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please describe the other game.'),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    debugPrint('✅ CREATE GAME: Date validation passed');
    debugPrint('🎮 CREATE GAME: Starting game creation...');
    final gameName = _ensureGameName();
    debugPrint('🎮 CREATE GAME: Game name: $gameName');
    debugPrint('🎮 CREATE GAME: Course: $courseValue');
    debugPrint('🎮 CREATE GAME: Date: $datePicked');
    debugPrint('🎮 CREATE GAME: Style: $styleGameValue');
    debugPrint('🎮 CREATE GAME: Type: $gameTypeValue');
    debugPrint('🎮 CREATE GAME: Friends: $friendsValue');
    debugPrint('🎮 CREATE GAME: Rules: $rulesSetValue');

    try {
      debugPrint('🎮 CREATE GAME: Checking authentication...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ CREATE GAME: User not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please sign in to create a game.'),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      debugPrint('✅ CREATE GAME: User authenticated: ${currentUser.uid}');

      final currentUserRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      // Default to 1 player needed for backend compatibility
      final numPlayers = 1;
      final maxPlayers = 4;
      debugPrint('CreateGame: creating game $gameName');
      debugPrint(
          'CreateGame: numPlayers=$numPlayers (default), maxPlayers=$maxPlayers');

      final gamesRecordReference =
          FirebaseFirestore.instance.collection('games').doc();

      debugPrint('🎮 CREATE GAME: Creating game chat...');
      debugPrint('🎮 CREATE GAME: Game ID: ${gamesRecordReference.id}');
      debugPrint('🎮 CREATE GAME: Creator UID: ${currentUser.uid}');

      try {
        final chatsRecordReference =
            await context.read<ChatProvider>().createGameChat(
                  createdByUid: currentUser.uid,
                  gameId: gamesRecordReference.id,
                  gameName: gameName,
                );
        chatRef = chatsRecordReference;
        debugPrint(
            '✅ CREATE GAME: Game chat created: ${chatsRecordReference.id}');
      } catch (chatError, chatStackTrace) {
        debugPrint('❌ CREATE GAME: Chat creation failed!');
        debugPrint('❌ CREATE GAME: Error type: ${chatError.runtimeType}');
        debugPrint('❌ CREATE GAME: Error: $chatError');
        debugPrintStack(stackTrace: chatStackTrace);
        throw Exception('Failed to create game chat: $chatError');
      }

      debugPrint('🎮 CREATE GAME: Saving game to Firestore...');
      debugPrint('🎮 CREATE GAME: Path: ${gamesRecordReference.path}');

      try {
        await gamesRecordReference.set({
          'name_game': gameName,
          'date': _scheduleType == 'confirmed' ? datePicked : null,
          'num_players': numPlayers,
          'style_game': styleGameValue,
          'game_type': gameTypeValue,
          'course_play': courseValue,
          'member_discount': memberValue,
          'scoring': scoringValue,
          'friend_game': friendsValue,
          'max_players': maxPlayers,
          'rules_setting': rulesSetValue,
          'created_time': DateTime.now(),
          'chatRef': chatRef,
          'userRef': currentUserRef,
          'courseRef': selectedCourse?.reference,
          'isCancelled': false,
          'status': 'active',
          'joined_players': [currentUserRef],
          'guest_players': [],
          'uid': currentUser.uid,
          'is_fun_game': _isJustForFun,
          'schedule_type': _scheduleType,
          'player_eligibility': _playerEligibility,
          if (_scheduleType == 'flexible') ...{
            'flexible_week': _flexibleWeek,
            'flexible_days': _selectedDays.toList(),
            // Store as comma-separated for multi-select (e.g., "morning,afternoon")
            'flexible_time_of_day': _flexibleTimesOfDay.where((t) => t != 'anytime').isEmpty
                ? 'anytime'
                : _flexibleTimesOfDay.where((t) => t != 'anytime').join(','),
            // Compute concrete dates at creation time
            if (FlexibleWeekResolver.resolveWeekDates(_flexibleWeek)
                case final dates?) ...{
              'flexible_start_date': dates.start,
              'flexible_end_date': dates.end,
            },
          },
        });
        gameRef = gamesRecordReference;
        await _clearDraft();
        debugPrint('✅ CREATE GAME: Game saved to Firestore successfully');
        debugPrint('CreateGame: game saved ${gamesRecordReference.path}');
      } catch (saveError, saveStackTrace) {
        debugPrint('❌ CREATE GAME: Game save failed!');
        debugPrint('❌ CREATE GAME: Error type: ${saveError.runtimeType}');
        debugPrint('❌ CREATE GAME: Error: $saveError');
        debugPrintStack(stackTrace: saveStackTrace);
        throw Exception('Failed to save game data: $saveError');
      }

      await Future.wait([
        Future(() async {
          if (!mounted) {
            return;
          }
          context.gameProvider.invalidateAvailableGamesCache();
          context.gameProvider.invalidateUserGamesCache(context.userProvider.userId);
          debugPrint('CreateGame: refreshed game caches');

          final numExistingFriends = 4 - numPlayers - 1;
          debugPrint(
              'CreateGame: numPlayers=$numPlayers, existingFriends=$numExistingFriends');

          if (numExistingFriends <= 0) {
            debugPrint('CreateGame: No existing friends, skipping Player List');
            context.pushNamed(
              GamesListWidget.routeName,
              extra: <String, dynamic>{
                kTransitionInfoKey: TransitionStandards.modalTransition,
              },
            );
          } else {
            debugPrint(
                'CreateGame: Has $numExistingFriends existing friends, showing Player List');
            context.pushNamed(
              PlayerListWidget.routeName,
              extra: <String, dynamic>{
                'gameRef': gamesRecordReference,
                kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
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
        }),
      ]);
    } catch (error, stackTrace) {
      debugPrint('❌ CREATE GAME: FAILED TO CREATE GAME');
      debugPrint('❌ CREATE GAME: Error type: ${error.runtimeType}');
      debugPrint('❌ CREATE GAME: Error message: $error');
      debugPrint('❌ CREATE GAME: Stack trace:');
      debugPrintStack(stackTrace: stackTrace);

      String errorMsg = error.toString();
      if (errorMsg.length > 100) {
        errorMsg = errorMsg.substring(0, 100) + '...';
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create game: $errorMsg',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          duration: Duration(milliseconds: 6000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (mounted) setState(() {});
  }

  // Build game summary string
  String _buildGameSummary() {
    // Primary Format
    String format = gameTypeValue ?? '';

    // Add 2v2 Team Style if enabled
    if (_is2v2 && _teamStyle != null && _teamStyle!.isNotEmpty) {
      format += ' + 2v2 ($_teamStyle)';
    }

    // Display "Gross + Net" instead of "Both" for better readability
    final handicap =
        scoringValue == 'Both' ? 'Gross + Net' : (scoringValue ?? '');
    final stakes = styleGameValue ?? '';
    final vibe = rulesSetValue ?? '';

    // Build base summary
    String summary = '$format • $handicap • $stakes • $vibe';

    // Add Games if any selected
    if (_selectedGames.isNotEmpty) {
      final gamesList = _selectedGames.map((game) {
        if (game == 'Other' &&
            _otherGameText != null &&
            _otherGameText!.isNotEmpty) {
          return _otherGameText!;
        }
        return game;
      }).join(', ');
      summary += ' • Games: $gamesList';
    }

    return summary;
  }

  /// Returns filtered eligibility options based on user's gender.
  /// Male users see: Open to All, Men Only
  /// Female users see: Open to All, Women Only
  /// Unknown gender sees: Open to All only
  List<Map<String, dynamic>> _getFilteredEligibilityOptions(String? userGender) {
    if (userGender == 'Male') {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] != 'women_only')
          .toList();
    } else if (userGender == 'Female') {
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] != 'men_only')
          .toList();
    } else {
      // Gender not yet loaded or unknown - show Open to All only
      return kCreateGameEligibilityOptions
          .where((opt) => opt['value'] == 'open_to_all')
          .toList();
    }
  }

  // Show help dialog
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

  @override
  void dispose() {
    _gameNameController.dispose();
    _otherGameController.dispose();
    super.dispose();
  }

  // Flexible Time UI Components
  Widget _buildFlexibleTimeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.sm),

        // Info hint
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              AppIcon(icon: AppPhosphorIcons.info, color: AppColors.pure, size: AppIconSize.button),
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

        // Week selector
        Text('Week', style: _labelStyle()),
        SizedBox(height: AppSpacing.xs),
        _buildWeekChips(),

        SizedBox(height: AppSpacing.md),

        // Day selector - hidden when "This Weekend" is selected
        AnimatedCrossFade(
          duration: MotionTokens.contentReveal,
          crossFadeState: _flexibleWeek == 'this_weekend'
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

        // Time of day
        Text('Time of Day', style: _labelStyle()),
        SizedBox(height: AppSpacing.xs),
        _buildTimeOfDayCards(),

        // Summary bar
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
                AppIcon(icon: AppPhosphorIcons.calendarNote, color: AppColors.pure, size: AppIconSize.button),
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

  TextStyle _labelStyle() => AppTypography.labelSmall.copyWith(
        fontSize: 13,
        color: AppColors.glassTextSecondary,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATED SECTION HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAnimatedSection({
    required int sectionIndex,
    required Widget child,
  }) {
    // Calculate stagger delay based on section index (max 8 sections animated)
    final clampedIndex = sectionIndex < MotionTokens.staggerMaxItems
        ? sectionIndex
        : MotionTokens.staggerMaxItems - 1;
    final staggerDelay = ReducedMotionService.shouldStagger
        ? MotionTokens.staggerDelay * clampedIndex
        : Duration.zero;

    return child
        .animate(target: _hasAnimated ? 1 : 0)
        .fadeIn(
          delay: staggerDelay,
          duration: ReducedMotionService.adjust(MotionTokens.contentReveal),
          curve: MotionTokens.curveEnter,
        );
  }

  /// Returns available days based on selected week.
  /// - 'this_week': Only remaining days this week (from today onwards)
  /// - 'this_weekend': Sat, Sun (not shown in UI - row hidden)
  /// - 'next_week' / 'next_2_weeks': All 7 days
  List<int> _getAvailableDays() {
    final now = DateTime.now();
    switch (_flexibleWeek) {
      case 'this_week':
        // Only days from today onwards
        // Dart weekday: Mon=1...Sun=7, we need Sun=0...Sat=6
        final todayDayIndex = now.weekday % 7; // Sun=0, Mon=1, ... Sat=6
        return List.generate(7, (i) => i).where((d) => d >= todayDayIndex).toList();
      case 'this_weekend':
        return [0, 6]; // Sun, Sat
      case 'next_week':
      case 'next_2_weeks':
      default:
        return [0, 1, 2, 3, 4, 5, 6]; // All days
    }
  }

  /// Called when week selection changes - updates days to match available days
  void _onWeekChanged(String weekValue) {
    setState(() {
      _flexibleWeek = weekValue;
      // Reset days to all available days for the selected week
      final availableDays = _getAvailableDays();
      _selectedDays = availableDays.toSet();
    });
    _saveDraft();
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
        final isSelected = _flexibleWeek == week['value'];
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
                  color: isSelected
                      ? AppColors.navyDark
                      : AppColors.navy,
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

    // Filter to only available days for the selected week
    final availableDayIndices = _getAvailableDays().toSet();
    final days = allDays.where((d) => availableDayIndices.contains(d['value'])).toList();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: days.map((day) {
        final dayIndex = day['value'] as int;
        final isSelected = _selectedDays.contains(dayIndex);

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedDays.remove(dayIndex);
              } else {
                _selectedDays.add(dayIndex);
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
              color:
                  isSelected ? null : AppColors.navy,
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
        'subtitle': 'Any Time',
      },
      {
        'value': 'morning',
        'label': 'Morning',
        'icon': AppPhosphorIcons.morning,
        'subtitle': 'Before 11am',
      },
      {
        'value': 'afternoon',
        'label': 'Afternoon',
        'icon': AppPhosphorIcons.afternoon,
        'subtitle': '11am-3pm',
      },
      {
        'value': 'twilight',
        'label': 'Twilight',
        'icon': AppPhosphorIcons.twilight,
        'subtitle': 'After 3pm',
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
        final isSelected = _flexibleTimesOfDay.contains(value);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (value == 'anytime') {
                // Selecting Anytime clears all others and selects only Anytime
                _flexibleTimesOfDay = {'anytime'};
              } else {
                // Selecting a specific time
                if (isSelected) {
                  // Deselecting - if it would leave empty, default to Anytime
                  _flexibleTimesOfDay.remove(value);
                  if (_flexibleTimesOfDay.isEmpty ||
                      (_flexibleTimesOfDay.length == 1 && _flexibleTimesOfDay.contains('anytime'))) {
                    _flexibleTimesOfDay = {'anytime'};
                  }
                } else {
                  // Adding - remove Anytime if present and add selection
                  _flexibleTimesOfDay.remove('anytime');
                  _flexibleTimesOfDay.add(value);
                  // If all 3 specific times selected, auto-switch to Anytime
                  if (_flexibleTimesOfDay.containsAll({'morning', 'afternoon', 'twilight'})) {
                    _flexibleTimesOfDay = {'anytime'};
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
              color:
                  isSelected ? null : AppColors.navy.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: isSelected
                    ? AppColors.green
                    : AppColors.glassSurface,
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

  String _buildFlexibleSummary() {
    final parts = <String>[];

    // Week part
    if (_flexibleWeek != null) {
      switch (_flexibleWeek) {
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

    // Days part - use intelligent collapsing
    if (_selectedDays.isNotEmpty && _flexibleWeek != 'this_weekend') {
      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final sortedDays = _selectedDays.toList()..sort();

      // Check for special patterns
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

    // Time of day part - handle multi-select
    if (_flexibleTimesOfDay.isNotEmpty) {
      if (_flexibleTimesOfDay.contains('anytime')) {
        parts.add('Anytime');
      } else {
        final timeLabels = <String>[];
        // Sort in logical order: morning, afternoon, twilight
        if (_flexibleTimesOfDay.contains('morning')) timeLabels.add('Morning');
        if (_flexibleTimesOfDay.contains('afternoon')) timeLabels.add('Afternoon');
        if (_flexibleTimesOfDay.contains('twilight')) timeLabels.add('Twilight');
        if (timeLabels.isNotEmpty) {
          parts.add(timeLabels.join(', '));
        }
      }
    }

    return parts.isEmpty ? 'Select your availability' : parts.join(' · ');
  }

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
                              // Draft continuation banner
                              if (_hasDraft) DraftBanner(onClear: _clearDraft),

                              // Restriction banner
                              Consumer<TrustProvider>(
                                builder: (context, trust, _) {
                                  final restriction = trust.myStanding?.currentRestriction;
                                  if (restriction == null) return const SizedBox.shrink();
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                                    child: RestrictionBanner(
                                      restriction: restriction,
                                      onViewStanding: () => context.pushNamed('YourStanding'),
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
                                            phosphorIcon: AppPhosphorIcons.games,
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
                                            variant: AppTextFieldVariant.filledDark,
                                            prefixPhosphorIcon: AppPhosphorIcons.label,
                                            onChanged: (_) => _saveDraft(),
                                          ),
                                        ),

                                        _buildAnimatedSection(
                                          sectionIndex: 1,
                                          child: SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.calendarCheck,
                                            title: 'Schedule',
                                            helpText:
                                                'Choose if you have a confirmed tee time or flexible availability.',
                                            onHelpTap: () => _showHelpDialog(
                                                context,
                                                'Schedule',
                                                'Choose if you have a confirmed tee time or flexible availability.'),
                                          ),
                                        ),

                                        // Schedule Type Selector
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: AppSpacing.xxs),
                                          child: SegmentedControl(
                                            options: [
                                              {
                                                'value': 'confirmed',
                                                'label': 'I Have a Tee Time',
                                                'phosphorIcon': AppPhosphorIcons.calendarCheck,
                                              },
                                              {
                                                'value': 'flexible',
                                                'label': 'Flexible Time',
                                                'phosphorIcon': AppPhosphorIcons.calendarNote,
                                              },
                                            ],
                                            selectedValue: _scheduleType,
                                            onChanged: (val) {
                                              if (mounted) {
                                                setState(() {
                                                  _scheduleType = val;
                                                  if (val == 'flexible') {
                                                    datePicked = null;
                                                  } else {
                                                    _flexibleWeek = null;
                                                    _selectedDays.clear();
                                                    _flexibleTimesOfDay = {'anytime'}; // Reset to default
                                                  }
                                                });
                                                _saveDraft();
                                              }
                                            },
                                          ),
                                        ),

                                        if (_scheduleType == 'confirmed') ...[
                                          // Premium date picker
                                          Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.sm),
                                            child: PremiumDatePicker(
                                              selectedDate: datePicked,
                                              onDateSelected: (date) {
                                                if (mounted) {
                                                  setState(() {
                                                    datePicked = date;
                                                  });
                                                  _saveDraft();
                                                }
                                              },
                                            ),
                                          ),

                                          // Tee time picker row
                                          if (datePicked != null) ...[
                                            SizedBox(height: AppSpacing.sm),
                                            InkWell(
                                              onTap: () {
                                                showTeeTimePicker(
                                                  context: context,
                                                  selectedDateTime: datePicked,
                                                  onTimeSelected: (dateTime) {
                                                    if (mounted) {
                                                      setState(() {
                                                        datePicked = dateTime;
                                                      });
                                                      _saveDraft();
                                                    }
                                                  },
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(AppBorderRadius.md),
                                              child: Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: AppSpacing.md,
                                                  horizontal: AppSpacing.md,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.navy,
                                                  borderRadius:
                                                      BorderRadius.circular(AppBorderRadius.md),
                                                  border: Border.all(
                                                    color: AppColors.greenLight.withValues(alpha: 0.3),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    AppIcon(
                                                      icon: AppPhosphorIcons.teeTime,
                                                      color: AppColors.pure,
                                                      size: AppIconSize.button,
                                                    ),
                                                    SizedBox(
                                                        width: AppSpacing.sm),
                                                    Expanded(
                                                      child: Text(
                                                        dateTimeFormat("jm",
                                                            datePicked),
                                                        style: AppTypography.labelMedium.copyWith(
                                                          color: AppColors.pure,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    AppIcon(
                                                      icon: AppPhosphorIcons.edit,
                                                      color: AppColors.textSecondary,
                                                      size: AppIconSize.sm,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],

                                          // Human-readable summary
                                          if (datePicked != null) ...[
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
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(AppBorderRadius.md),
                                              ),
                                              child: Row(
                                                children: [
                                                  AppIcon(
                                                    icon: AppPhosphorIcons.golfCourse,
                                                    color: AppColors.pure,
                                                    size: AppIconSize.button,
                                                  ),
                                                  SizedBox(
                                                      width: AppSpacing.sm),
                                                  Expanded(
                                                    child: Text(
                                                      '${dateTimeFormat("EEEE, MMM d", datePicked)} at ${dateTimeFormat("jm", datePicked)}',
                                                      style: AppTypography.labelMedium.copyWith(
                                                        color: AppColors.textPrimary,
                                                      ),
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
                                            phosphorIcon: AppPhosphorIcons.publicVisibility,
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
                                                'phosphorIcon': AppPhosphorIcons.people,
                                              },
                                              {
                                                'value': 'Public',
                                                'label': 'Public',
                                                'phosphorIcon': AppPhosphorIcons.publicVisibility,
                                              },
                                            ],
                                            selectedValue: friendsValue,
                                            onChanged: (val) {
                                              if (mounted) {
                                                setState(
                                                    () => friendsValue = val);
                                                _saveDraft();
                                              }
                                            },
                                          ),
                                        ),
                                        _buildAnimatedSection(
                                          sectionIndex: 3,
                                          child: SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.openToAll,
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
                                              userProvider.currentUser?.gender,
                                            );
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  top: AppSpacing.xxs),
                                              child: CardGrid(
                                                options: filteredOptions,
                                                selectedValue: _playerEligibility,
                                                onChanged: (val) {
                                                  if (mounted) {
                                                    setState(() =>
                                                        _playerEligibility = val);
                                                    _saveDraft();
                                                  }
                                                },
                                                crossAxisCount: filteredOptions.length,
                                                childAspectRatio: 1.2,
                                              ),
                                            );
                                          },
                                        ),
                                        _buildAnimatedSection(
                                          sectionIndex: 4,
                                          child: SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.course,
                                            title: 'Course',
                                          ),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional(-1.0, 0.0),
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                top: AppSpacing.xxs),
                                            child: StreamBuilder<
                                                QuerySnapshot<
                                                    Map<String, dynamic>>>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('course')
                                                  .orderBy('name')
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 50.0,
                                                      height: 50.0,
                                                      child:
                                                          SpinKitWanderingCubes(
                                                        color: AppColors
                                                            .gold,
                                                        size: 50.0,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                final courseCourseRecordList =
                                                    snapshot.data!.docs
                                                        .map((doc) =>
                                                            Course.fromDoc(doc))
                                                        .toList();

                                                // Empty state
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
                                                              AppBorderRadius.md),
                                                      border: Border.all(
                                                        color: AppColors
                                                            .navyLight
                                                            .withValues(
                                                                alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        AppIcon(
                                                          icon: AppPhosphorIcons.golfCourse,
                                                          size: AppIconSize.xl,
                                                          color: AppColors.textMuted,
                                                        ),
                                                        SizedBox(
                                                            height:
                                                                AppSpacing.sm),
                                                        Text(
                                                          'No courses available',
                                                          style: AppTypography.bodySmall.copyWith(
                                                            color: AppColors.glassTextSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }

                                                return AppDropDown<String>(
                                                  controller:
                                                      courseValueController ??=
                                                          FormFieldController<
                                                              String>(null),
                                                  options:
                                                      courseCourseRecordList
                                                          .map((e) => e.name)
                                                          .toList(),
                                                  onChanged: (val) async {
                                                    if (mounted) {
                                                      setState(() =>
                                                          courseValue = val);
                                                    }
                                                    selectedCourse =
                                                        courseCourseRecordList
                                                            .firstWhereOrNull(
                                                                (course) =>
                                                                    course
                                                                        .name ==
                                                                    val);

                                                    _saveDraft();
                                                    if (mounted)
                                                      setState(() {});
                                                  },
                                                  width: 300.0,
                                                  height: 50.0,
                                                  searchHintTextStyle: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                                                  searchTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                                  searchCursorColor: AppColors.green,
                                                  textStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                                  hintText:
                                                      'Where are you playing?',
                                                  searchHintText:
                                                      'Find your course',
                                                  icon: AppIcon(
                                                    icon: AppPhosphorIcons.chevronDown,
                                                    color: AppColors.textSecondary,
                                                    size: AppIconSize.md,
                                                  ),
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
                                          value: memberDiscount,
                                          onChanged: (val) {
                                            if (mounted) {
                                              setState(() {
                                                memberDiscount = val;
                                                memberValue =
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
                                          value: _isJustForFun,
                                          onChanged: (val) {
                                            if (mounted) {
                                              setState(() {
                                                _isJustForFun = val;
                                              });
                                              _saveDraft();
                                            }
                                          },
                                        ),
                                        if (!_isJustForFun) ...[
                                          SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.competitive,
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
                                              selectedValue: rulesSetValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() =>
                                                      rulesSetValue = val);
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 2,
                                              childAspectRatio: 1.2,
                                            ),
                                          ),
                                          SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.betting,
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
                                              selectedValue: styleGameValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() =>
                                                      styleGameValue = val);
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.95,
                                            ),
                                          ),
                                          SectionHeader(
                                            phosphorIcon: AppPhosphorIcons.gameType,
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
                                              selectedValue: gameTypeValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(() {
                                                    gameTypeValue = val;
                                                  });
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.95,
                                            ),
                                          ),

                                          // Team Setup Section
                                          SizedBox(height: AppSpacing.md),
                                          ToggleSwitch(
                                            label: '2v2 (Teams)',
                                            description:
                                                'Enable team play mode',
                                            value: _is2v2,
                                            onChanged: (val) {
                                              if (mounted) {
                                                setState(() {
                                                  _is2v2 = val;
                                                  if (!val) {
                                                    _teamStyle = null;
                                                  }
                                                });
                                                _saveDraft();
                                              }
                                            },
                                          ),

                                          // Team Style (conditional, shown only if 2v2 is enabled)
                                          if (_is2v2) ...[
                                            SizedBox(height: AppSpacing.sm),
                                            SectionHeader(
                                              phosphorIcon: AppPhosphorIcons.teams,
                                              title: 'Team Style',
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: AppSpacing.xxs),
                                              child: CardGrid(
                                                options: [
                                                  {
                                                    'value': 'Best Ball',
                                                    'label': 'Best Ball',
                                                    'phosphorIcon': AppPhosphorIcons.bestBall,
                                                  },
                                                  {
                                                    'value': 'Scramble',
                                                    'label': 'Scramble',
                                                    'phosphorIcon': AppPhosphorIcons.groups,
                                                  },
                                                ],
                                                selectedValue: _teamStyle,
                                                onChanged: (val) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _teamStyle = val;
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
                                            phosphorIcon: AppPhosphorIcons.handicap,
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
                                              selectedValue: scoringValue,
                                              onChanged: (val) {
                                                if (mounted) {
                                                  setState(
                                                      () => scoringValue = val);
                                                  _saveDraft();
                                                }
                                              },
                                              crossAxisCount: 3,
                                              childAspectRatio: 0.95,
                                            ),
                                          ),

                                          // Games Multi-Select Section
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
                                              selectedGames: _selectedGames,
                                              onGameToggled: (game) {
                                                if (mounted) {
                                                  setState(() {
                                                    if (_selectedGames
                                                        .contains(game)) {
                                                      _selectedGames
                                                          .remove(game);
                                                      // Clear other game text if deselecting Other
                                                      if (game == 'Other') {
                                                        _otherGameText = null;
                                                        _otherGameController
                                                            .clear();
                                                      }
                                                    } else {
                                                      _selectedGames.add(game);
                                                    }
                                                  });
                                                  _saveDraft();
                                                }
                                              },
                                              otherGameController:
                                                  _otherGameController,
                                              onOtherGameChanged: (text) {
                                                setState(() {
                                                  _otherGameText =
                                                      text.trim().isEmpty
                                                          ? null
                                                          : text.trim();
                                                });
                                                _saveDraft();
                                              },
                                              maxGames: 3,
                                            ),
                                          ),

                                          // Auto-Generated Summary
                                          if (gameTypeValue != null &&
                                              scoringValue != null &&
                                              styleGameValue != null &&
                                              rulesSetValue != null) ...[
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
                                                      AppColors.navy
                                                          .withValues(
                                                              alpha: 0.3),
                                                      AppColors.navyDark
                                                          .withValues(
                                                              alpha: 0.4),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(AppBorderRadius.md),
                                                  border: Border.all(
                                                    color: AppColors.green
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Game Summary',
                                                      style: AppTypography.labelSmall.copyWith(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                        color: AppColors.glassTextSecondary,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        height: AppSpacing.xs),
                                                    Text(
                                                      _buildGameSummary(),
                                                      style: AppTypography.labelMedium.copyWith(
                                                        color: AppColors.textPrimary,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ], // end if (!_isJustForFun)


                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: AppSpacing.xxl),
                                          child: Consumer<TrustProvider>(
                                            builder: (context, trust, _) {
                                              final isRestricted = trust.myStanding?.currentRestriction != null;
                                              return AppButtonEnhanced(
                                                text: 'Submit Game',
                                                variant: AppButtonVariant.primary,
                                                size: AppButtonSize.large,
                                                onPressed: isRestricted ? null : _submitGame,
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
