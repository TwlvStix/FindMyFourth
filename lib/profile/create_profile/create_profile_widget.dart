import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/app_theme.dart';
import '/core/motion/motion_helpers.dart';
import '/core/motion/motion_tokens.dart';
import '/core/motion/reduced_motion.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/profile_hero_section.dart';
import '/core/widgets/profile_card_section.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/core/custom_functions.dart' as functions;
import '/user_onboarding/vibe_onboarding_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    if (userRef == null || desiredUsername.isEmpty) {
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
              color: AppTheme.of(context).secondaryBackground,
            ),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppTheme.of(context).primary,
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
        await userRef.set(
          createUsersRecordData(
            photoUrl: currentUserPhoto,
            phoneNumber: phoneNumTextController!.text,
            handicap: handicapValue,
            golfCanadaNumber:
                golfCanadaRaw.isEmpty ? null : golfCanadaRaw,
            homeCourse: coursesValue,
            firstName: firstNameTextController!.text,
            lastName: lastNameTextController!.text,
            displayName: desiredUsername,
            friends: [],
            friendRequests: [],
          ),
          SetOptions(merge: true),
        );
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
    required FocusNode focusNode,
    required String label,
    TextInputAction? textInputAction,
    String? Function(BuildContext, String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction ?? TextInputAction.next,
      readOnly: readOnly,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.onyx,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.stone,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.cloud,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.fairway,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      validator: validator != null
          ? (val) => validator(context, val)
          : null,
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
        backgroundColor: AppTheme.of(context).secondaryBackground,
        body: FairwayBackgroundDark(
          showOrganic: true,
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
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

                  SizedBox(height: AppSpacing.lg),

                  // Personal Information Card
                  FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: ProfileCardSection(
                      title: 'Personal Information',
                      child: Column(
                        children: [
                          // First & Last Name Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: firstNameTextController!,
                                  focusNode: firstNameFocusNode!,
                                  label: 'First Name',
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildTextField(
                                  controller: lastNameTextController!,
                                  focusNode: lastNameFocusNode!,
                                  label: 'Last Name',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),

                          // Display Name & Phone Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: usernameTextController!,
                                  focusNode: usernameFocusNode!,
                                  label: 'Display Name',
                                  validator: _validateUsername,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildTextField(
                                  controller: phoneNumTextController!,
                                  focusNode: phoneNumFocusNode!,
                                  label: 'Phone',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),

                          // Email
                          _buildTextField(
                            controller: emailTextController!,
                            focusNode: emailFocusNode!,
                            label: 'Email',
                            validator: _validateEmail,
                            readOnly: true,
                          ),
                          SizedBox(height: AppSpacing.md),

                          // Home Course Dropdown
                          StreamBuilder<List<CourseRecord>>(
                            stream: queryCourseRecord(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  height: 56,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    color: AppColors.fairway,
                                  ),
                                );
                              }

                              List<CourseRecord> courses = snapshot.data!;
                              return AppDropDown<String>(
                                controller: coursesValueController ??=
                                    FormFieldController<String>(null),
                                options: courses
                                    .map((c) => c.name)
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => coursesValue = val),
                                width: double.infinity,
                                height: 56,
                                textStyle: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.onyx,
                                ),
                                hintText: 'Select Home Course',
                                icon: Icon(
                                  Icons.golf_course_rounded,
                                  color: AppColors.fairway,
                                  size: 24,
                                ),
                                fillColor: Colors.white,
                                elevation: 2,
                                borderColor: AppColors.cloud,
                                borderWidth: 1.5,
                                borderRadius: 12,
                                margin: EdgeInsetsDirectional.only(start: AppSpacing.md),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Golf Profile Card
                  FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: ProfileCardSection(
                      title: 'Golf Profile',
                      child: Column(
                        children: [
                          ProfilePreferenceItem(
                            icon: FontAwesomeIcons.flagCheckered,
                            label: 'Handicap',
                            iconColor: AppColors.fairway,
                            valueWidget: AppCountController(
                              decrementIconBuilder: (enabled) => Icon(
                                Icons.remove_rounded,
                                color:
                                    enabled ? AppColors.fairway : AppColors.cloud,
                                size: 20,
                              ),
                              incrementIconBuilder: (enabled) => Icon(
                                Icons.add_rounded,
                                color:
                                    enabled ? AppColors.fairway : AppColors.cloud,
                                size: 20,
                              ),
                              countBuilder: (count) => Text(
                                count.toString(),
                                style: AppTypography.headlineMedium.copyWith(
                                  color: AppColors.onyx,
                                ),
                              ),
                              count: handicapValue ?? 0,
                              updateCount: (count) =>
                                  setState(() => handicapValue = count),
                              stepSize: 1,
                              minimum: 0,
                              maximum: 54,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          _buildTextField(
                            controller: golfCanadaTextController!,
                            focusNode: golfCanadaFocusNode!,
                            label: 'Golf Canada #',
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Save Button
                  FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: AppButtonEnhanced(
                        text: 'Create Profile',
                        leadingIcon: Icons.check_circle_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        fullWidth: true,
                        onPressed: _handleSaveProfile,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
