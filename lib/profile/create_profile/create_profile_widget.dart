import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_text_field.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/profile_hero_section.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/form_field_controller.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/core/custom_functions.dart' as functions;
import '/user_onboarding/vibe_onboarding_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CreateProfileWidget extends StatefulWidget {
  const CreateProfileWidget({super.key});

  static String routeName = 'CreateProfile';
  static String routePath = '/createProfile';

  @override
  State<CreateProfileWidget> createState() => _CreateProfileWidgetState();
}

class _CreateProfileWidgetState extends State<CreateProfileWidget>
    with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();

  // Text Controllers
  FocusNode? firstNameFocusNode;
  TextEditingController? firstNameTextController;
  FocusNode? lastNameFocusNode;
  TextEditingController? lastNameTextController;
  FocusNode? usernameFocusNode;
  TextEditingController? usernameTextController;
  FocusNode? phoneNumFocusNode;
  TextEditingController? phoneNumTextController;
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  FocusNode? golfCanadaFocusNode;
  TextEditingController? golfCanadaTextController;

  // Form Values
  String? coursesValue;
  FormFieldController<String>? coursesValueController;
  int? handicapValue;
  UsersRecord? usernamesQuery;
  String? genderValue;
  FormFieldController<String>? genderValueController;
  DateTime? dateOfBirth;

  // Animation
  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    firstNameTextController = TextEditingController();
    firstNameFocusNode = FocusNode();
    lastNameTextController = TextEditingController();
    lastNameFocusNode = FocusNode();
    usernameTextController = TextEditingController();
    usernameFocusNode = FocusNode();
    usernameFocusNode!.addListener(_onUsernameBlur);
    phoneNumTextController = TextEditingController();
    phoneNumFocusNode = FocusNode();
    emailTextController = TextEditingController(text: currentUserEmail);
    emailFocusNode = FocusNode();
    golfCanadaTextController = TextEditingController();
    golfCanadaFocusNode = FocusNode();

    // Setup staggered fade-in animations (UPDATED: 800ms → 232ms per premium motion system)
    _fadeController = AnimationController(
      duration: ReducedMotionService.adjust(
        MotionTokens.contentReveal + (MotionTokens.staggerDelay * 3),
      ), // 160ms + 72ms = 232ms total
      vsync: this,
    );

    _fadeAnimations = ReducedMotionService.shouldStagger
        ? List.generate(
            3,
            (index) {
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
            },
          )
        : List.generate(
            3,
            // No stagger in reduced motion - all fade in together
            (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: MotionTokens.curveEnter,
              ),
            ),
          );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    firstNameFocusNode?.dispose();
    firstNameTextController?.dispose();
    lastNameFocusNode?.dispose();
    lastNameTextController?.dispose();
    usernameFocusNode?.removeListener(_onUsernameBlur);
    usernameFocusNode?.dispose();
    usernameTextController?.dispose();
    phoneNumFocusNode?.dispose();
    phoneNumTextController?.dispose();
    emailFocusNode?.dispose();
    emailTextController?.dispose();
    golfCanadaFocusNode?.dispose();
    golfCanadaTextController?.dispose();
    super.dispose();
  }

  void _onUsernameBlur() {
    if (!usernameFocusNode!.hasFocus && usernameTextController != null) {
      final trimmed = usernameTextController!.text.trim();
      if (trimmed != usernameTextController!.text) {
        usernameTextController!.text = trimmed;
      }
    }
  }

  String? _validateUsername(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Username is required';
    }
    if (!RegExp(kTextValidatorUsernameRegex).hasMatch(val)) {
      return 'Must start with a letter and contain only letters, digits, -, or _';
    }
    return null;
  }

  String? _validateEmail(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Must be a valid email address';
    }
    return null;
  }

  Future<void> _handleSaveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate required behavioural dataset fields
    if (genderValue == null || genderValue!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gender is required.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Date of birth is required.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Create username
    final desiredUsername =
        functions.usernameCreator(usernameTextController!.text);
    if (mounted) setState(() {});
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      try {
        firebaseUser = await FirebaseAuth.instance
            .authStateChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign-in not ready. Please try again.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await firebaseUser.getIdToken(true);
    final userRef = UsersRecord.collection.doc(firebaseUser.uid);
    if (desiredUsername.isEmpty) {
      return;
    }
    final usernamesRef = FirebaseFirestore.instance
        .collection('usernames')
        .doc(desiredUsername);
    if (desiredUsername.isNotEmpty &&
        !RegExp(kTextValidatorUsernameRegex).hasMatch(desiredUsername)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Must start with a letter and contain only letters, digits, -, or _',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final desiredEmail = emailTextController?.text.trim() ?? '';
    if (desiredEmail.isNotEmpty && desiredEmail != currentUserEmail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please update your Firebase Auth email ($currentUserEmail) before saving your profile.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.navy,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.navyDark,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final usernameSnap = await transaction.get(usernamesRef);
        if (usernameSnap.exists) {
          final existingRef = usernameSnap.get('uid') as DocumentReference?;
          if (existingRef != null && existingRef.path != userRef.path) {
            throw StateError('username_taken');
          }
        } else {
          transaction.set(usernamesRef, {
            'uid': userRef,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      });
      try {
        final golfCanadaRaw = golfCanadaTextController?.text.trim() ?? '';
        debugPrint('Creating user document with friend fields initialized...');
        final phoneText = phoneNumTextController!.text;
        await Future.wait([
          userRef.set(
            createUsersRecordData(
              photoUrl: currentUserPhoto,
              handicap: handicapValue,
              golfCanadaNumber:
                  golfCanadaRaw.isEmpty ? null : golfCanadaRaw,
              homeCourse: coursesValue,
              firstName: firstNameTextController!.text,
              lastName: lastNameTextController!.text,
              displayName: desiredUsername,
              gender: genderValue,
              dateOfBirth: dateOfBirth,
              friends: [],
              friendRequests: [],
            ),
            SetOptions(merge: true),
          ),
          if (phoneText.isNotEmpty)
            userRef.collection('private').doc('info').set(
              {'phone_number': phoneText},
              SetOptions(merge: true),
            ),
        ]);
        debugPrint('User document created with friend fields initialized');
      } catch (e) {
        try {
          final usernameDoc = await usernamesRef.get();
          final existingRef = usernameDoc.get('uid') as DocumentReference?;
          if (usernameDoc.exists &&
              existingRef != null &&
              existingRef.path == userRef.path) {
            await usernamesRef.delete();
          }
        } catch (_) {}
        rethrow;
      }
      currentUserDocument = await UsersRecord.getDocumentOnce(userRef);
      try {
        await makeCloudCall(
          'completeOnboarding',
          {'userDocPath': userRef.path},
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to finish onboarding. Please try again.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
            duration: Duration(milliseconds: 2000),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } on StateError catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This username is taken. Please choose another.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('CreateProfile save failed: $e');
      debugPrint('CreateProfile save stackTrace: $stackTrace');
      final message = e.code == 'permission-denied'
          ? 'Unable to save profile due to permissions. Please try again.'
          : 'Unable to save profile. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    } catch (e, stackTrace) {
      debugPrint('CreateProfile save failed: $e');
      debugPrint('CreateProfile save stackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save profile. Please try again.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile created successfully!',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: Duration(milliseconds: 3000),
        backgroundColor: AppColors.success,
      ),
    );

    final nextRoute = GoRouterState.of(context).uri.queryParameters['next'];
    final nextAfterVibes = nextRoute != null && nextRoute.isNotEmpty
        ? nextRoute
        : GamesListWidget.routeName;

    context.goNamed(
      VibeOnboardingWidget.routeName,
      queryParameters: {
        'next': nextAfterVibes,
      },
      extra: <String, dynamic>{
        kTransitionInfoKey: TransitionInfo(
                  hasTransition: true,
                  transitionType: PageTransitionType.fade,
                  enterDuration: Duration(milliseconds: 200),
                  exitDuration: Duration(milliseconds: 170),
                  scaleOnPush: true,
                ),
      },
    );

    if (mounted) setState(() {});
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(BuildContext, String?)? validator,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      label: label,
      controller: controller,
      variant: AppTextFieldVariant.filledDark,
      prefixIcon: icon,
      readOnly: readOnly,
      enabled: !readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator != null ? (val) => validator(context, val) : null,
      focusNode: focusNode,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.navy,
        body: FairwayBackgroundDark(
          showOrganic: true,
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Section with Avatar
                  AuthUserStreamWidget(
                    builder: (context) => ProfileHeroSection(
                      photoUrl: currentUserPhoto,
                      displayName: usernameTextController?.text ?? '',
                      onEditPhoto: () async {
                        await showAppBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          enableDrag: false,
                          context: context,
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              child: Padding(
                                padding: MediaQuery.viewInsetsOf(context),
                                child: ChangePhotoWidget(),
                              ),
                            );
                          },
                        ).then((value) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                  ),

                  // Change Photo text link
                  GestureDetector(
                    onTap: () async {
                      await showAppBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        enableDrag: false,
                        context: context,
                        builder: (context) => Padding(
                          padding: MediaQuery.viewInsetsOf(context),
                          child: ChangePhotoWidget(),
                        ),
                      ).then((value) {
                        if (mounted) setState(() {});
                      });
                    },
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
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Information',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),

                                // First & Last Name Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: firstNameTextController!,
                                        label: 'First Name *',
                                        icon: AppPhosphorIcons.profile,
                                        validator: (context, val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'First name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: lastNameTextController!,
                                        label: 'Last Name',
                                        icon: AppPhosphorIcons.profile,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Display Name
                                _buildTextField(
                                  controller: usernameTextController!,
                                  label: 'Display Name',
                                  icon: AppPhosphorIcons.atSign,
                                  validator: _validateUsername,
                                  focusNode: usernameFocusNode,
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Phone
                                _buildTextField(
                                  controller: phoneNumTextController!,
                                  label: 'Phone',
                                  icon: AppPhosphorIcons.phone,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Email
                                _buildTextField(
                                  controller: emailTextController!,
                                  label: 'Email',
                                  icon: AppPhosphorIcons.email,
                                  validator: _validateEmail,
                                  readOnly: true,
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Gender & Date of Birth Row
                                Row(
                                  children: [
                                    // Gender Dropdown
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.inputBackground,
                                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                          border: Border.all(
                                            color: AppColors.inputBorderIdle,
                                          ),
                                        ),
                                        child: AppDropDown<String>(
                                          controller: genderValueController ??=
                                              FormFieldController<String>(null),
                                          options: const ['Male', 'Female'],
                                          onChanged: (val) =>
                                              setState(() => genderValue = val),
                                          width: double.infinity,
                                          height: 56,
                                          textStyle: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                          hintText: 'Gender *',
                                          icon: Icon(
                                            AppPhosphorIcons.profile,
                                            color: AppColors.textMuted,
                                            size: AppIconSize.md,
                                          ),
                                          fillColor: AppColors.inputBackground,
                                          elevation: 0,
                                          borderColor: Colors.transparent,
                                          borderWidth: 0,
                                          borderRadius: 12,
                                          margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    // Date of Birth Picker
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
                                            firstDate: DateTime(1920),
                                            lastDate: DateTime(now.year - 13, now.month, now.day),
                                            helpText: 'SELECT DATE OF BIRTH',
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme: ColorScheme.dark(
                                                    primary: AppColors.green,
                                                    onPrimary: AppColors.textPrimary,
                                                    surface: AppColors.navy,
                                                    onSurface: AppColors.textPrimary,
                                                    onSurfaceVariant: AppColors.textPrimary,
                                                    secondary: AppColors.green,
                                                    onSecondary: AppColors.textPrimary,
                                                  ),
                                                  dialogTheme: DialogThemeData(
                                                    backgroundColor: AppColors.navy,
                                                  ),
                                                  // Text theme for year picker text elements
                                                  textTheme: Theme.of(context).textTheme.apply(
                                                    bodyColor: AppColors.textPrimary,
                                                    displayColor: AppColors.textPrimary,
                                                  ),
                                                  // Input decoration for manual date entry mode
                                                  inputDecorationTheme: InputDecorationTheme(
                                                    labelStyle: TextStyle(color: AppColors.textPrimary),
                                                    hintStyle: TextStyle(color: AppColors.textMuted),
                                                    floatingLabelStyle: TextStyle(color: AppColors.green),
                                                    enabledBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: AppColors.textMuted),
                                                    ),
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: AppColors.green),
                                                    ),
                                                  ),
                                                  // DatePicker-specific theme for year picker
                                                  datePickerTheme: DatePickerThemeData(
                                                    backgroundColor: AppColors.navy,
                                                    headerBackgroundColor: AppColors.navy,
                                                    headerForegroundColor: AppColors.textPrimary,
                                                    yearStyle: TextStyle(color: AppColors.textPrimary),
                                                    yearForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
                                                    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                                                      if (states.contains(WidgetState.selected)) {
                                                        return AppColors.green;
                                                      }
                                                      return Colors.transparent;
                                                    }),
                                                    dayForegroundColor: WidgetStateProperty.all(AppColors.textPrimary),
                                                    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                                                      if (states.contains(WidgetState.selected)) {
                                                        return AppColors.green;
                                                      }
                                                      return Colors.transparent;
                                                    }),
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(() => dateOfBirth = picked);
                                          }
                                        },
                                        child: Container(
                                          height: 56,
                                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                          decoration: BoxDecoration(
                                            color: AppColors.inputBackground,
                                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                            border: Border.all(color: AppColors.inputBorderIdle),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                AppPhosphorIcons.calendar,
                                                color: AppColors.textMuted,
                                                size: AppIconSize.md,
                                              ),
                                              SizedBox(width: AppSpacing.sm),
                                              Expanded(
                                                child: Text(
                                                  dateOfBirth != null
                                                      ? '${dateOfBirth!.month.toString().padLeft(2, '0')}/${dateOfBirth!.day.toString().padLeft(2, '0')}/${dateOfBirth!.year}'
                                                      : 'Birthday *',
                                                  style: AppTypography.bodyMedium.copyWith(
                                                    color: dateOfBirth != null
                                                        ? AppColors.textPrimary
                                                        : AppColors.textMuted,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Golf Profile Section
                        FadeTransition(
                          opacity: _fadeAnimations[1],
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Golf Profile',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Home Course Dropdown
                                StreamBuilder<List<CourseRecord>>(
                                  stream: queryCourseRecord(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.inputBackground,
                                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                          border: Border.all(color: AppColors.inputBorderIdle),
                                        ),
                                        alignment: Alignment.center,
                                        child: CircularProgressIndicator(
                                          color: AppColors.textPrimary,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    List<CourseRecord> courses = snapshot.data!..sort((a, b) => a.name.compareTo(b.name));
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBackground,
                                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                        border: Border.all(color: AppColors.inputBorderIdle),
                                      ),
                                      child: AppDropDown<String>(
                                        controller: coursesValueController ??=
                                            FormFieldController<String>(null),
                                        options: courses.map((c) => c.name).toList(),
                                        onChanged: (val) =>
                                            setState(() => coursesValue = val),
                                        width: double.infinity,
                                        height: 56,
                                        textStyle: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        hintText: 'Select Home Course',
                                        icon: Icon(
                                          AppPhosphorIcons.golfCourse,
                                          color: AppColors.textMuted,
                                          size: AppIconSize.md,
                                        ),
                                        fillColor: AppColors.inputBackground,
                                        elevation: 0,
                                        borderColor: Colors.transparent,
                                        borderWidth: 0,
                                        borderRadius: 12,
                                        margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Handicap
                                Container(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    border: Border.all(color: AppColors.inputBorderIdle),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [AppColors.gold, AppColors.goldLight],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                        ),
                                        child: Icon(
                                          AppPhosphorIcons.flagCheckered,
                                          color: AppColors.pure,
                                          size: AppIconSize.button,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Handicap',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            SizedBox(height: AppSpacing.xxs),
                                            Text(
                                              'Your official handicap index',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AppCountController(
                                        decrementIconBuilder: (enabled) => Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: enabled
                                                ? AppColors.navyLight
                                                : AppColors.navyLight.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                          ),
                                          child: Icon(
                                            AppPhosphorIcons.minus,
                                            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                                            size: AppIconSize.button,
                                          ),
                                        ),
                                        incrementIconBuilder: (enabled) => Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: enabled
                                                ? AppColors.navyLight
                                                : AppColors.navyLight.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                          ),
                                          child: Icon(
                                            AppPhosphorIcons.plus,
                                            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                                            size: AppIconSize.button,
                                          ),
                                        ),
                                        countBuilder: (count) => Container(
                                          constraints: BoxConstraints(minWidth: 56),
                                          alignment: Alignment.center,
                                          child: Text(
                                            formatHandicap(count),
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.clip,
                                            textAlign: TextAlign.center,
                                            style: AppTypography.monoLarge.copyWith(
                                              color: AppColors.textPrimary.withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        count: handicapValue ?? 0,
                                        updateCount: (count) =>
                                            setState(() => handicapValue = count),
                                        stepSize: 1,
                                        minimum: -5,
                                        maximum: 54,
                                        editable: true,
                                        formatValue: formatHandicap,
                                        parseValue: (text) {
                                          final trimmed = text.trim();
                                          if (trimmed.startsWith('+')) {
                                            final num = int.tryParse(trimmed.substring(1));
                                            return num != null ? -num : null;
                                          }
                                          return int.tryParse(trimmed);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),

                                // Golf Canada #
                                _buildTextField(
                                  controller: golfCanadaTextController!,
                                  label: 'Golf Canada #',
                                  icon: AppPhosphorIcons.verified,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ],
                            ),
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
