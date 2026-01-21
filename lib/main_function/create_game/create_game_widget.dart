import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/app_text_field.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/form_field_controller.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/main_function/player_list/player_list_widget.dart';
import '/providers/provider_extensions.dart';
import '/models/course.dart';
import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

import '/providers/chat_provider.dart';

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
  int? countControllerValue;
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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Draft & Loading state
  bool _isLoading = true;
  bool _hasDraft = false;
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
        setState(() {
          _isLoading = false;
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
        if (draft['count'] != null) {
          countControllerValue = draft['count'];
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
        final draftName = draft['gameName'] as String?;
        if (draftName != null && draftName.trim().isNotEmpty) {
          _gameNameController.text = draftName;
        } else {
          _ensureGameName();
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
        'count': countControllerValue,
        'rulesSet': rulesSetValue,
        'styleGame': styleGameValue,
        'gameType': gameTypeValue,
        'scoring': scoringValue,
        'gameName': gameName.isEmpty ? null : gameName,
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
  Future<void> _quickCreate() async {
    HapticFeedback.mediumImpact();
    _ensureGameName();

    // Validate required step 1 fields first
    if (datePicked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date and time first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (courseValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a course first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Set smart defaults for all game settings
    setState(() {
      // Visibility
      friendsValue = 'Friends';
      friendsValueController?.value = 'Friends';

      // Member discount
      memberDiscount = false;
      memberValue = 'No';
      memberValueController?.value = 'No';

      // Player count
      countControllerValue = 1;

      // Rules
      rulesSetValue = 'Relaxed';
      rulesSetValueController?.value = 'Relaxed';

      // Style
      styleGameValue = 'All Fun';
      styleGameValueController?.value = 'All Fun';

      // Game type
      gameTypeValue = 'Stroke Play';
      gameTypeValueController?.value = 'Stroke Play';

      // Scoring
      scoringValue = 'Gross';
      scoringValueController?.value = 'Gross';
    });

    // Now create the game immediately
    await _submitGame();
  }

  // Shared game submission logic
  Future<void> _submitGame() async {
    debugPrint('🎮 CREATE GAME: Submit triggered');

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      debugPrint('❌ CREATE GAME: Form validation failed');
      return;
    }
    debugPrint('✅ CREATE GAME: Form validation passed');

    if (courseValue == null) {
      debugPrint('❌ CREATE GAME: courseValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (friendsValue == null) {
      debugPrint('❌ CREATE GAME: friendsValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select Friends or Public game'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (rulesSetValue == null) {
      debugPrint('❌ CREATE GAME: rulesSetValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rules setting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (styleGameValue == null) {
      debugPrint('❌ CREATE GAME: styleGameValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a game style'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (gameTypeValue == null) {
      debugPrint('❌ CREATE GAME: gameTypeValue is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a game type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    debugPrint('✅ CREATE GAME: All values present');

    if (datePicked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date and time.'),
          duration: Duration(milliseconds: 4000),
          backgroundColor: AppTheme.of(context).primary,
        ),
      );
      return;
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
    debugPrint('🎮 CREATE GAME: Player count: ${countControllerValue ?? 0}');

    try {
      debugPrint('🎮 CREATE GAME: Checking authentication...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ CREATE GAME: User not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please sign in to create a game.'),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppTheme.of(context).primary,
          ),
        );
        return;
      }
      debugPrint('✅ CREATE GAME: User authenticated: ${currentUser.uid}');

      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      final numPlayers = countControllerValue ?? 0;
      final maxPlayers = 4;
      debugPrint('CreateGame: creating game $gameName');
      debugPrint('CreateGame: numPlayers=$numPlayers (randoms needed), maxPlayers=$maxPlayers');

      final gamesRecordReference =
          FirebaseFirestore.instance.collection('games').doc();

      debugPrint('🎮 CREATE GAME: Creating game chat...');
      debugPrint('🎮 CREATE GAME: Game ID: ${gamesRecordReference.id}');
      debugPrint('🎮 CREATE GAME: Creator UID: ${currentUser.uid}');

      try {
        final chatsRecordReference = await context
            .read<ChatProvider>()
            .createGameChat(
              createdByUid: currentUser.uid,
              gameId: gamesRecordReference.id,
              gameName: gameName,
            );
        chatRef = chatsRecordReference;
        debugPrint('✅ CREATE GAME: Game chat created: ${chatsRecordReference.id}');
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
          'date': datePicked,
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
          context.userProvider.refreshAvailableGames();
          context.userProvider.refreshMyGames();
          debugPrint('CreateGame: refreshed game caches');

          final numExistingFriends = 4 - numPlayers - 1;
          debugPrint('CreateGame: numPlayers=$numPlayers, existingFriends=$numExistingFriends');

          if (numExistingFriends <= 0) {
            debugPrint('CreateGame: No existing friends, skipping Player List');
            context.pushNamed(GamesListWidget.routeName);
          } else {
            debugPrint('CreateGame: Has $numExistingFriends existing friends, showing Player List');
            context.pushNamed(
              PlayerListWidget.routeName,
              extra: <String, dynamic>{
                'gameRef': gamesRecordReference,
                kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.bottomToTop,
                  duration: Duration(milliseconds: 220),
                ),
              },
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have created a game!',
                style: GoogleFonts.outfit(
                  color: AppTheme.of(context).secondaryBackground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              duration: Duration(milliseconds: 4000),
              backgroundColor: AppTheme.of(context).primary,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create game: $errorMsg',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          duration: Duration(milliseconds: 6000),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) setState(() {});
  }

  // Show help dialog
  void _showHelpDialog(BuildContext context, String title, String message) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.fairwayLight, AppColors.fairway],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
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
    super.dispose();
  }

  // Build draft continuation banner
  Widget _buildDraftBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sunsetGold.withOpacity(0.2),
            AppColors.sunsetPeach.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.sunsetGold.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restore_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue where you left off',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Your draft has been restored',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearDraft,
            child: Text(
              'Clear',
              style: GoogleFonts.outfit(
                color: AppColors.sunsetGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build quick create banner
  Widget _buildQuickCreateBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.fairwayLight.withOpacity(0.2),
            AppColors.fairway.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fairwayLight.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Create',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'Use smart defaults for faster setup',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          AppButtonEnhanced(
            text: 'Go',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: _quickCreate,
          ),
        ],
      ),
    );
  }

  // Build section header with icon and optional help
  Widget _buildSectionHeader(
    String emoji,
    String title, {
    String? helpText,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.fairwayLight, AppColors.fairway],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTheme.of(context).labelMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: AppTheme.of(context).labelMedium.fontWeight,
                    fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                ),
          ),
          if (helpText != null) ...[
            SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: () => _showHelpDialog(context, title, helpText),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.sunsetGold.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.sunsetGold,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Premium selection card for grid-based selections
  Widget _buildSelectionCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? emoji,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.fairway.withOpacity(0.5),
                    AppColors.fairwayDark.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.fairway.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.sunsetGold
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sunsetGold.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: emoji != null
                  ? Center(
                      child: Text(emoji, style: TextStyle(fontSize: 20)),
                    )
                  : Icon(icon, color: Colors.white, size: 22),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Segmented control for binary choices (Visibility)
  Widget _buildSegmentedControl({
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fairway.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          final isSelected = selectedValue == option['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(option['value']);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.sunsetGold,
                            AppColors.sunsetPeach,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.sunsetGold.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      option['label'] as String,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Toggle switch for boolean options (Member Discount)
  Widget _buildToggleSwitch({
    required String label,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.fairway.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.sunsetGold.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                gradient: value
                    ? LinearGradient(
                        colors: [AppColors.sunsetGold, AppColors.sunsetPeach],
                      )
                    : null,
                color: value ? null : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card grid for multiple-choice selections
  Widget _buildCardGrid({
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required Function(String) onChanged,
    int crossAxisCount = 2,
    double childAspectRatio = 1.4,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: childAspectRatio,
      padding: EdgeInsets.zero,
      children: options.map((option) {
        final isSelected = selectedValue == option['value'];
        return _buildSelectionCard(
          icon: option['icon'] as IconData,
          label: option['label'] as String,
          emoji: option['emoji'] as String?,
          isSelected: isSelected,
          onTap: () {
            onChanged(option['value'] as String);
            _saveDraft();
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.of(context).primary,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: AppIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 55.0,
            icon: Icon(
              Icons.arrow_back_sharp,
              color: AppTheme.of(context).primary,
              size: 25.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'Create Game',
            style: AppTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                ),
          ),
          centerTitle: false,
          elevation: 10.0,
        ),
        body: SafeArea(
          top: true,
          child: FairwayBackgroundDark(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitWanderingCubes(
                          color: AppColors.sunsetGold,
                          size: 50.0,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Loading...',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Draft continuation banner
                          if (_hasDraft) _buildDraftBanner(),

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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Quick Create Banner
                                    _buildQuickCreateBanner(),

                                    _buildSectionHeader(
                                      '🏷️',
                                      'Game Name',
                                      helpText:
                                          'Auto-generated for you. Edit here if you want a custom name.',
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: AppSpacing.xxs),
                                      child: AppTextField(
                                        label: 'Game name',
                                        hint: 'Auto-generated',
                                        controller: _gameNameController,
                                        variant: AppTextFieldVariant.filled,
                                        prefixIcon: Icons.label_rounded,
                                        onChanged: (_) => _saveDraft(),
                                      ),
                                    ),

                              _buildSectionHeader(
                                '📅',
                                'Game Day',
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: AppSpacing.xxs,
                                      bottom: AppSpacing.md),
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height: 100.0,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context).tertiary,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: AppSpacing.sm),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Padding(
                                            padding:
                                                EdgeInsets.only(
                                                    left: AppSpacing.sm),
                                            child: Container(
                                              width: MediaQuery.sizeOf(context)
                                                      .width *
                                                  0.65,
                                              height: 85.0,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFA0A0A0),
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(15.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat(
                                                                "MMM",
                                                                datePicked),
                                                            'Jan',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat("d",
                                                                datePicked),
                                                            '22',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 26.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 20.0,
                                                    child: VerticalDivider(
                                                      thickness: 1.0,
                                                      color:
                                                          AppTheme.of(context)
                                                              .accent4,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(10.0, 0.0,
                                                                0.0, 0.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat(
                                                                "EEEE",
                                                                datePicked),
                                                            'Friday',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                        Text(
                                                          valueOrDefault<
                                                              String>(
                                                            dateTimeFormat("jm",
                                                                datePicked),
                                                            '09:00am',
                                                          ),
                                                          style: AppTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: AppTheme.of(
                                                                        context)
                                                                    .primaryBtnText,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(
                                                    left: AppSpacing.sm),
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                final _datePickedDate =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      getCurrentTimestamp,
                                                  firstDate:
                                                      getCurrentTimestamp,
                                                  lastDate: DateTime(2050),
                                                  builder: (context, child) {
                                                    return wrapInMaterialDatePickerTheme(
                                                      context,
                                                      child!,
                                                      headerBackgroundColor:
                                                          AppTheme.of(context)
                                                              .primary,
                                                      headerForegroundColor:
                                                          AppTheme.of(context)
                                                              .info,
                                                      headerTextStyle:
                                                          AppTheme.of(context)
                                                              .headlineLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .headlineLarge
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 32.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontStyle: AppTheme.of(
                                                                        context)
                                                                    .headlineLarge
                                                                    .fontStyle,
                                                              ),
                                                      pickerBackgroundColor:
                                                          AppTheme.of(context)
                                                              .secondaryBackground,
                                                      pickerForegroundColor:
                                                          AppTheme.of(context)
                                                              .primaryText,
                                                      selectedDateTimeBackgroundColor:
                                                          AppTheme.of(context)
                                                              .primary,
                                                      selectedDateTimeForegroundColor:
                                                          AppTheme.of(context)
                                                              .info,
                                                      actionButtonForegroundColor:
                                                          AppTheme.of(context)
                                                              .primaryText,
                                                      iconSize: 24.0,
                                                    );
                                                  },
                                                );

                                                TimeOfDay? _datePickedTime;
                                                if (_datePickedDate != null) {
                                                  _datePickedTime =
                                                      await showTimePicker(
                                                    context: context,
                                                    initialTime:
                                                        TimeOfDay.fromDateTime(
                                                            getCurrentTimestamp),
                                                    builder: (context, child) {
                                                      return wrapInMaterialTimePickerTheme(
                                                        context,
                                                        child!,
                                                        headerBackgroundColor:
                                                            AppTheme.of(context)
                                                                .primary,
                                                        headerForegroundColor:
                                                            AppTheme.of(context)
                                                                .info,
                                                        headerTextStyle:
                                                            AppTheme.of(context)
                                                                .headlineLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .outfit(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontStyle: AppTheme.of(
                                                                            context)
                                                                        .headlineLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  fontSize:
                                                                      32.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontStyle: AppTheme.of(
                                                                          context)
                                                                      .headlineLarge
                                                                      .fontStyle,
                                                                ),
                                                        pickerBackgroundColor:
                                                            AppTheme.of(context)
                                                                .secondaryBackground,
                                                        pickerForegroundColor:
                                                            AppTheme.of(context)
                                                                .primaryText,
                                                        selectedDateTimeBackgroundColor:
                                                            AppTheme.of(context)
                                                                .primary,
                                                        selectedDateTimeForegroundColor:
                                                            AppTheme.of(context)
                                                                .info,
                                                        actionButtonForegroundColor:
                                                            AppTheme.of(context)
                                                                .primaryText,
                                                        iconSize: 24.0,
                                                      );
                                                    },
                                                  );
                                                }

                                                if (_datePickedDate != null &&
                                                    _datePickedTime != null) {
                                                  if (mounted)
                                                    setState(() {
                                                      datePicked = DateTime(
                                                        _datePickedDate.year,
                                                        _datePickedDate.month,
                                                        _datePickedDate.day,
                                                        _datePickedTime!.hour,
                                                        _datePickedTime.minute,
                                                      );
                                                    });
                                                  _saveDraft();
                                                } else if (datePicked != null) {
                                                  if (mounted)
                                                    setState(() {
                                                      datePicked =
                                                          getCurrentTimestamp;
                                                    });
                                                  _saveDraft();
                                                }
                                              },
                                              child: Icon(
                                                Icons.date_range,
                                                color: AppTheme.of(context)
                                                    .primaryBtnText,
                                                size: 36.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _buildSectionHeader(
                                '👁️',
                                'Visibility',
                                helpText: 'Choose whether your game is visible to friends only or everyone in your area.',
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxs),
                                child: _buildSegmentedControl(
                                  options: [
                                    {'value': 'Friends', 'label': 'Friends', 'icon': Icons.people_rounded},
                                    {'value': 'Public', 'label': 'Public', 'icon': Icons.public_rounded},
                                  ],
                                  selectedValue: friendsValue,
                                  onChanged: (val) {
                                    if (mounted) {
                                      setState(() => friendsValue = val);
                                      _saveDraft();
                                    }
                                  },
                                ),
                              ),
                              _buildSectionHeader(
                                '🏌️',
                                'Course',
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.only(top: AppSpacing.xxs),
                                  child: StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>>(
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
                                            child: SpinKitWanderingCubes(
                                              color: AppColors.sunsetGold,
                                              size: 50.0,
                                            ),
                                          ),
                                        );
                                      }
                                      final courseCourseRecordList = snapshot
                                          .data!.docs
                                          .map((doc) => Course.fromDoc(doc))
                                          .toList();

                                      // Empty state
                                      if (courseCourseRecordList.isEmpty) {
                                        return Container(
                                          padding: EdgeInsets.all(AppSpacing.lg),
                                          decoration: BoxDecoration(
                                            color: AppColors.fairway.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.fairwayLight.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.golf_course_rounded,
                                                size: 40,
                                                color: Colors.white.withOpacity(0.4),
                                              ),
                                              SizedBox(height: AppSpacing.sm),
                                              Text(
                                                'No courses available',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return AppDropDown<String>(
                                        controller: courseValueController ??=
                                            FormFieldController<String>(null),
                                        options: courseCourseRecordList
                                            .map((e) => e.name)
                                            .toList(),
                                        onChanged: (val) async {
                                          if (mounted) {
                                            setState(() => courseValue = val);
                                          }
                                          selectedCourse =
                                              courseCourseRecordList
                                                  .firstWhereOrNull((course) =>
                                                      course.name == val);

                                          _saveDraft();
                                          if (mounted) setState(() {});
                                        },
                                        width: 300.0,
                                        height: 50.0,
                                        searchHintTextStyle: AppTheme.of(
                                                context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                            ),
                                        searchTextStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                        textStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                            ),
                                        hintText: 'Where are you playing?',
                                        searchHintText: 'Find your course',
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppTheme.of(context)
                                              .secondaryText,
                                          size: 24.0,
                                        ),
                                        fillColor: AppTheme.of(context)
                                            .secondaryBackground,
                                        elevation: 2.0,
                                        borderColor:
                                            AppTheme.of(context).primary,
                                        borderWidth: 1.0,
                                        borderRadius: 10.0,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.xxs),
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
                              _buildToggleSwitch(
                                label: '💰 Member Perk',
                                description: 'Does the course offer a discount for members bringing guests?',
                                value: memberDiscount,
                                onChanged: (val) {
                                  if (mounted) {
                                    setState(() {
                                      memberDiscount = val;
                                      memberValue = val ? 'Yes' : 'No';
                                    });
                                    _saveDraft();
                                  }
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxs),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    _buildSectionHeader(
                                      '👥',
                                      'Number of Players Needed',
                                      helpText: 'How many additional players are you looking for to join your game?',
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.only(top: AppSpacing.xxs),
                                  child: Container(
                                    width: 160.0,
                                    height: 50.0,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: AppTheme.of(context).primary,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: AppCountController(
                                      decrementIconBuilder: (enabled) => FaIcon(
                                        FontAwesomeIcons.minus,
                                        color: enabled
                                            ? AppTheme.of(context).secondaryText
                                            : AppTheme.of(context).alternate,
                                        size: 20.0,
                                      ),
                                      incrementIconBuilder: (enabled) => FaIcon(
                                        FontAwesomeIcons.plus,
                                        color: enabled
                                            ? AppTheme.of(context).primary
                                            : AppTheme.of(context).alternate,
                                        size: 20.0,
                                      ),
                                      countBuilder: (count) => Text(
                                        count.toString(),
                                        style: AppTheme.of(context)
                                            .titleLarge
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: AppTheme.of(context)
                                                    .titleLarge
                                                    .fontWeight,
                                                fontStyle: AppTheme.of(context)
                                                    .titleLarge
                                                    .fontStyle,
                                              ),
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                              fontWeight: AppTheme.of(context)
                                                  .titleLarge
                                                  .fontWeight,
                                              fontStyle: AppTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                            ),
                                      ),
                                      count: countControllerValue ??= 1,
                                      updateCount: (count) {
                                        if (mounted) {
                                          setState(() =>
                                              countControllerValue = count);
                                          _saveDraft();
                                        }
                                      },
                                      stepSize: 1,
                                      minimum: 1,
                                      maximum: 3,
                                    ),
                                  ),
                                ),
                              ),
                              _buildSectionHeader(
                                '⚙️',
                                'Rules Settings',
                                helpText: 'Strict follows USGA rules precisely. Relaxed allows casual adjustments. Open to Discuss means flexible.',
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxs),
                                child: _buildCardGrid(
                                  options: [
                                    {'value': 'Strict', 'label': 'Strict', 'icon': Icons.gavel_rounded, 'emoji': '📏'},
                                    {'value': 'Relaxed', 'label': 'Relaxed', 'icon': Icons.self_improvement_rounded, 'emoji': '😌'},
                                    {'value': 'Open to Discuss', 'label': 'Flexible', 'icon': Icons.chat_bubble_outline_rounded, 'emoji': '💬'},
                                  ],
                                  selectedValue: rulesSetValue,
                                  onChanged: (val) {
                                    if (mounted) {
                                      setState(() => rulesSetValue = val);
                                    }
                                  },
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.95,
                                ),
                              ),
                              _buildSectionHeader(
                                '🎯',
                                'Style of Game',
                                helpText: 'Are you playing for money, just for fun, or open to discussing stakes?',
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxs),
                                child: _buildCardGrid(
                                  options: [
                                    {'value': 'Money Game', 'label': 'Money', 'icon': Icons.attach_money_rounded, 'emoji': '💵'},
                                    {'value': 'All Fun', 'label': 'Just Fun', 'icon': Icons.celebration_rounded, 'emoji': '🎉'},
                                    {'value': 'Open to Discuss', 'label': 'Flexible', 'icon': Icons.chat_bubble_outline_rounded, 'emoji': '💬'},
                                  ],
                                  selectedValue: styleGameValue,
                                  onChanged: (val) {
                                    if (mounted) {
                                      setState(() => styleGameValue = val);
                                    }
                                  },
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.95,
                                ),
                              ),
                              _buildSectionHeader(
                                '🏆',
                                'Game Type',
                                helpText: 'Choose your preferred format: Match Play (hole-by-hole), Stroke Play (total strokes), Stableford (points), etc.',
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxs),
                                child: _buildCardGrid(
                                  options: [
                                    {'value': 'Match Play', 'label': 'Match Play', 'icon': Icons.sports_golf_rounded, 'emoji': '🆚'},
                                    {'value': 'Stroke Play', 'label': 'Stroke Play', 'icon': Icons.format_list_numbered_rounded, 'emoji': '📝'},
                                    {'value': 'Stableford', 'label': 'Stableford', 'icon': Icons.star_rounded, 'emoji': '⭐'},
                                    {'value': 'Vegas', 'label': 'Vegas', 'icon': Icons.casino_rounded, 'emoji': '🎰'},
                                    {'value': 'Skins', 'label': 'Skins', 'icon': Icons.workspace_premium_rounded, 'emoji': '🏅'},
                                    {'value': 'For Fun', 'label': 'For Fun', 'icon': Icons.celebration_rounded, 'emoji': '🎉'},
                                  ],
                                  selectedValue: gameTypeValue,
                                  onChanged: (val) {
                                    if (mounted) {
                                      setState(() => gameTypeValue = val);
                                    }
                                  },
                                  crossAxisCount: 3,
                                  childAspectRatio: 0.95,
                                ),
                              ),
                              _buildSectionHeader(
                                '📊',
                                'Scoring',
                                helpText: 'Gross is total strokes. Net adjusts for handicap. Both tracks both scores.',
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxs),
                                child: _buildCardGrid(
                                  options: [
                                    {'value': 'Gross', 'label': 'Gross', 'icon': Icons.sports_golf_rounded, 'emoji': '📊'},
                                    {'value': 'Net', 'label': 'Net', 'icon': Icons.calculate_rounded, 'emoji': '🧮'},
                                    {'value': 'Both', 'label': 'Both', 'icon': Icons.compare_arrows_rounded, 'emoji': '↔️'},
                                    {'value': 'FUN', 'label': 'Just Fun', 'icon': Icons.celebration_rounded, 'emoji': '🎉'},
                                  ],
                                  selectedValue: scoringValue,
                                  onChanged: (val) {
                                    if (mounted) {
                                      setState(() => scoringValue = val);
                                    }
                                  },
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.6,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: AppSpacing.xxl),
                                child: AppButtonEnhanced(
                                  text: 'Submit Game',
                                  variant: AppButtonVariant.primary,
                                  size: AppButtonSize.large,
                                  onPressed: _submitGame,
                                ),
                              ),
                            ]
                                .divide(SizedBox(height: AppSpacing.xs))
                                .addToStart(SizedBox(height: AppSpacing.xs))
                                .addToEnd(SizedBox(height: AppSpacing.xs)),
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
    );
  }
}
