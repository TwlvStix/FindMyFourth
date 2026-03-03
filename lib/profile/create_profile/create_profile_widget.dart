import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/core/utils/app_snackbar.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/profile_hero_section.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/form_field_controller.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/profile/create_profile/components/personal_info_section.dart';
import '/profile/create_profile/components/golf_profile_section.dart';
import '/profile/create_profile/controllers/create_profile_controller.dart';
import 'package:flutter/material.dart';

class CreateProfileWidget extends StatefulWidget {
  const CreateProfileWidget({super.key});

  static String routeName = 'CreateProfile';
  static String routePath = '/createProfile';

  @override
  State<CreateProfileWidget> createState() => _CreateProfileWidgetState();
}

class _CreateProfileWidgetState extends State<CreateProfileWidget>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = CreateProfileController();

  // Text Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late FocusNode _usernameFocusNode;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _golfCanadaController;

  // Form Values
  String? _coursesValue;
  FormFieldController<String>? _coursesValueController;
  int? _handicapValue;
  String? _genderValue;
  FormFieldController<String>? _genderValueController;
  DateTime? _dateOfBirth;

  // Animation
  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _usernameFocusNode = FocusNode();
    _usernameFocusNode.addListener(_onUsernameBlur);
    _phoneController = TextEditingController();
    _emailController = TextEditingController(text: currentUserEmail);
    _golfCanadaController = TextEditingController();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: ReducedMotionService.adjust(
        MotionTokens.contentReveal + (MotionTokens.staggerDelay * 3),
      ),
      vsync: this,
    );

    _fadeAnimations = ReducedMotionService.shouldStagger
        ? List.generate(3, (index) {
            final totalMs = _fadeController.duration!.inMilliseconds.toDouble();
            final staggerMs = MotionTokens.staggerDelay.inMilliseconds.toDouble();
            final revealMs = MotionTokens.contentReveal.inMilliseconds.toDouble();

            return Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: Interval(
                  (index * staggerMs) / totalMs,
                  (revealMs + (index * staggerMs)) / totalMs,
                  curve: MotionTokens.curveEnter,
                ),
              ),
            );
          })
        : List.generate(
            3,
            (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: MotionTokens.curveEnter,
              ),
            ),
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameFocusNode.removeListener(_onUsernameBlur);
    _usernameFocusNode.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _golfCanadaController.dispose();
    super.dispose();
  }

  void _onUsernameBlur() {
    if (!_usernameFocusNode.hasFocus) {
      final trimmed = _usernameController.text.trim();
      if (trimmed != _usernameController.text) {
        _usernameController.text = trimmed;
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    final formData = CreateProfileFormData(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      phone: _phoneController.text,
      email: _emailController.text.trim(),
      photoUrl: currentUserPhoto,
      gender: _genderValue,
      dateOfBirth: _dateOfBirth,
      handicap: _handicapValue,
      homeCourse: _coursesValue,
      golfCanadaNumber: _golfCanadaController.text,
    );

    final result = await _controller.submitProfile(
      formData: formData,
      isFormValid: _formKey.currentState?.validate() ?? false,
      currentUserEmail: currentUserEmail,
    );

    if (!mounted) return;

    if (result.success) {
      // Update global user document
      currentUserDocument = result.userRecord;

      AppSnackbar.showSuccess(context, 'Profile created successfully!');

      final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
      final nextAfterVibes = nextRoute != null && nextRoute.isNotEmpty
          ? nextRoute
          : AppRouteNames.gamesList;

      context.goVibeOnboarding(
        next: nextAfterVibes,
        transition: TransitionStandards.modalTransition,
      );
    } else {
      AppSnackbar.showError(context, result.message ?? 'An error occurred.');
    }
  }

  Future<void> _showChangePhotoSheet() async {
    await showAppBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: ChangePhotoWidget(),
      ),
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
        key: _scaffoldKey,
        backgroundColor: AppColors.navy,
        body: FairwayBackgroundDark(
          showOrganic: true,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section with Avatar
                  AuthUserStreamWidget(
                    builder: (context) => ProfileHeroSection(
                      photoUrl: currentUserPhoto,
                      displayName: _usernameController.text,
                      onEditPhoto: _showChangePhotoSheet,
                    ),
                  ),

                  // Change Photo text link
                  GestureDetector(
                    onTap: _showChangePhotoSheet,
                    child: Text(
                      'Change Photo',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Main Content Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.xxl),
                        topRight: Radius.circular(AppBorderRadius.xxl),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.overlayDark,
                          blurRadius: 30,
                          offset: Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: EdgeInsets.only(top: AppSpacing.sm),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.navyLight,
                            borderRadius: BorderRadius.circular(AppBorderRadius.xxs),
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // Personal Information Section
                        FadeTransition(
                          opacity: _fadeAnimations[0],
                          child: PersonalInfoSection(
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            usernameController: _usernameController,
                            phoneController: _phoneController,
                            emailController: _emailController,
                            usernameFocusNode: _usernameFocusNode,
                            genderValue: _genderValue,
                            genderValueController: _genderValueController ??=
                                FormFieldController<String>(null),
                            dateOfBirth: _dateOfBirth,
                            onGenderChanged: (val) => setState(() => _genderValue = val),
                            onDateOfBirthChanged: (val) => setState(() => _dateOfBirth = val),
                            validateUsername: (context, val) =>
                                _controller.validateUsername(val),
                            validateEmail: (context, val) =>
                                _controller.validateEmail(val),
                          ),
                        ),

                        // Golf Profile Section
                        FadeTransition(
                          opacity: _fadeAnimations[1],
                          child: StreamBuilder<List<CourseRecord>>(
                            stream: queryCourseRecord(),
                            builder: (context, snapshot) {
                              final courses = snapshot.data ?? [];
                              final sortedCourses = List<CourseRecord>.from(courses)
                                ..sort((a, b) => a.name.compareTo(b.name));

                              return GolfProfileSection(
                                courses: sortedCourses,
                                isLoadingCourses: !snapshot.hasData,
                                coursesValue: _coursesValue,
                                coursesValueController: _coursesValueController ??=
                                    FormFieldController<String>(null),
                                handicapValue: _handicapValue,
                                golfCanadaController: _golfCanadaController,
                                onCourseChanged: (val) => setState(() => _coursesValue = val),
                                onHandicapChanged: (val) => setState(() => _handicapValue = val),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: AppSpacing.md),

                        // Create Profile Button
                        FadeTransition(
                          opacity: _fadeAnimations[2],
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: AppButtonEnhanced(
                              text: 'Create Profile',
                              leadingIcon: AppPhosphorIcons.successFill,
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              fullWidth: true,
                              onPressed: _handleSaveProfile,
                            ),
                          ),
                        ),

                        SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
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
