import '/core/design_tokens/colors.dart';
import '/core/motion/motion_tokens.dart';
import '/core/utils/state_update.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/trust/restriction_banner.dart';
import '/providers/provider_extensions.dart';
import '/providers/trust_provider.dart';
import '/providers/user_provider.dart';
import '/services/course_service.dart';
import '/services/create_game_draft_service.dart';
import '/services/create_game_service.dart';
import '/utils/app_util.dart';
import 'controllers/create_game_controller.dart';
import 'create_game_constants.dart';
import 'models/create_game_form_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '/providers/chat_provider.dart';
import 'components/create_game_form_sections.dart';
import 'components/draft_banner.dart';
import 'components/rematch_banner.dart';

class CreateGameWidget extends StatefulWidget {
  const CreateGameWidget({super.key, this.prefillFormData});

  final CreateGameFormData? prefillFormData;

  static String routeName = 'CreateGame';
  static String routePath = '/createGame';

  @override
  State<CreateGameWidget> createState() => _CreateGameWidgetState();
}

class _CreateGameWidgetState extends State<CreateGameWidget> {
  static const List<int> _mondayFirstDayOrder = [1, 2, 3, 4, 5, 6, 0];

  final _courseService = CourseService();
  final _controller = CreateGameController(
    draftService: CreateGameDraftService(),
    gameService: CreateGameService(),
  );

  final formKey = GlobalKey<FormState>();
  late CreateGameFormData _formData;
  late FormFieldController<String> courseValueController;

  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _otherGameController = TextEditingController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  bool _hasDraft = false;
  bool _isRematch = false;
  bool _hasAnimated = false;
  bool _submitting = false;
  int _courseRetryCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.prefillFormData != null) {
      _formData = widget.prefillFormData!;
      _isRematch = true;
    } else {
      _formData = CreateGameFormData();
    }
    _gameNameController.text = _formData.gameName;
    courseValueController = FormFieldController<String>(_formData.courseValue);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDraft();
      if (mounted) {
        final userGender = context.read<UserProvider>().currentUser?.gender;
        final validOptions = _getFilteredEligibilityOptions(userGender);
        final validValues = validOptions.map((o) => o['value']).toSet();
        if (!validValues.contains(_formData.playerEligibility)) {
          _formData.playerEligibility = 'open_to_all';
        }

        updateState(this, () {
          _isLoading = false;
        });

        // Let the form render one frame before triggering entrance animations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasAnimated) {
            updateState(this, () => _hasAnimated = true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _otherGameController.dispose();
    courseValueController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    if (_isRematch) return;
    final draft = await _controller.loadDraft();
    if (draft != null) {
      _formData = draft;
      _formData.reconcileDerivedFields();
      _syncControllersFromFormData();
      _hasDraft = true;
    }
  }

  void _syncControllersFromFormData() {
    _gameNameController.text = _formData.gameName;
    courseValueController.value = _formData.courseValue;
    if (_formData.otherGameText != null) {
      _otherGameController.text = _formData.otherGameText!;
    }
  }

  Future<void> _saveDraft() async {
    _formData.gameName = _gameNameController.text.trim();
    _formData.reconcileDerivedFields();
    await _controller.saveDraft(_formData);
  }

  Future<void> _clearDraft() async {
    await _controller.clearDraft();
    updateState(this, () {
      _hasDraft = false;
    });
  }

  void _updateFormState(VoidCallback mutation) {
    if (!mounted) {
      return;
    }
    updateState(this, mutation);
  }

  Future<void> _submitGame() async {
    if (_submitting) return;
    updateState(this, () => _submitting = true);

    try {
      await _submitGameInner();
    } finally {
      if (mounted) {
        updateState(this, () => _submitting = false);
      }
    }
  }

  Future<void> _submitGameInner() async {
    final userProvider = context.userProvider;
    final userId = userProvider.userIdOrNull;
    if (!userProvider.isAuthReady || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signing you in... Please try again in a moment.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    final isFormValid =
        formKey.currentState != null && formKey.currentState!.validate();

    if (!isFormValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final formContext = formKey.currentContext;
        if (formContext != null) {
          Scrollable.ensureVisible(
            formContext,
            duration: const Duration(milliseconds: 300),
            curve: MotionTokens.curveEnter,
          );
        }
      });
    }

    final result = await _controller.submitGame(
      formData: _formData,
      isFormValid: isFormValid,
      currentUserRef: userProvider.currentUser?.reference,
      createGameChat: chatProvider.createGameChat,
      invalidateAvailableGamesCache:
          context.gameProvider.invalidateAvailableGamesCache,
      invalidateUserGamesCache: context.gameProvider.invalidateUserGamesCache,
      userIdForCache: userId,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      final message = result.message;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(milliseconds: 4000),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final gameRef = result.gameRef;
    final nextRoute = result.nextRoute;
    if (gameRef == null || nextRoute == null) {
      return;
    }

    updateState(this, () {
      _hasDraft = false;
    });

    final messenger = ScaffoldMessenger.of(context);

    if (nextRoute == CreateGameNextRoute.gamesList) {
      context.pushGamesList(
        transition: TransitionStandards.modalTransition,
      );
    } else {
      context.pushPlayerList(
        gameRef: gameRef,
      );
    }

    if (!mounted) return;
    messenger.showSnackBar(
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
  }

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

  List<int> _getAvailableDays() {
    final now = DateTime.now();
    switch (_formData.flexibleWeek) {
      case 'this_week':
        final todayDayIndex = now.weekday == DateTime.sunday ? 0 : now.weekday;
        final todayPosition = _mondayFirstDayOrder.indexOf(todayDayIndex);
        return _mondayFirstDayOrder.sublist(todayPosition);
      case 'this_weekend':
        return [6, 0];
      case 'next_week':
      case 'next_2_weeks':
      default:
        return [0, 1, 2, 3, 4, 5, 6];
    }
  }

  void _onWeekChanged(String weekValue) {
    updateState(this, () {
      _formData.flexibleWeek = weekValue;
      final availableDays = _getAvailableDays();
      _formData.selectedDays = availableDays.toSet();
    });
    _saveDraft();
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
            backgroundColor: AppColors.transparent,
            surfaceTintColor: AppColors.transparent,
            scrolledUnderElevation: 0.0,
            elevation: 0.0,
            shadowColor: AppColors.transparent,
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
                        MediaQuery.of(context).padding.top + 56 + AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (_isRematch)
                              RematchBanner(
                                courseName: _formData.courseValue,
                                onDismiss: () {
                                  updateState(this, () {
                                    _isRematch = false;
                                    _formData = CreateGameFormData();
                                    _syncControllersFromFormData();
                                  });
                                },
                              )
                            else if (_hasDraft)
                              DraftBanner(onClear: _clearDraft),
                            Consumer<TrustProvider>(
                              builder: (context, trust, _) {
                                final restriction =
                                    trust.myStanding?.currentRestriction;
                                if (restriction == null) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding:
                                      EdgeInsets.only(bottom: AppSpacing.md),
                                  child: RestrictionBanner(
                                    restriction: restriction,
                                    onViewStanding: () =>
                                        context.pushYourStanding(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: CreateGameFormSections(
                                formKey: formKey,
                                formData: _formData,
                                gameNameController: _gameNameController,
                                otherGameController: _otherGameController,
                                courseValueController: courseValueController,
                                courseService: _courseService,
                                hasAnimated: _hasAnimated,
                                isSubmitting: _submitting,
                                updateFormState: _updateFormState,
                                saveDraft: _saveDraft,
                                submitGame: _submitGame,
                                onWeekChanged: _onWeekChanged,
                                getFilteredEligibilityOptions:
                                    _getFilteredEligibilityOptions,
                                courseStreamKey: ValueKey(_courseRetryCount),
                                onCourseRetry: () => updateState(
                                    this, () => _courseRetryCount++),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
