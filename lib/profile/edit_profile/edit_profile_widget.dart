import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/form_field_controller.dart';
import '/core/motion/motion_helpers.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/widgets/fairway_background.dart';
import '/core/widgets/premium_back_button.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/utils/app_util.dart';

import 'components/edit_profile_actions.dart';
import 'components/edit_profile_golf_section.dart';
import 'components/edit_profile_hero_section.dart';
import 'components/edit_profile_personal_info_section.dart';
import 'controllers/edit_profile_controller.dart';
import 'controllers/edit_profile_result.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  static String routeName = 'EditProfile';
  static String routePath = '/editProfile';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controller = EditProfileController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Text Controllers
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _golfCanadaController;

  // Form Values
  String? _coursesValue;
  FormFieldController<String>? _coursesValueController;
  int? _handicapValue;

  // Animation
  late AnimationController _ringController;

  // Loading States
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _firstNameController = TextEditingController(
      text: valueOrDefault(currentUserDocument?.firstName, ''),
    );
    _lastNameController = TextEditingController(
      text: valueOrDefault(currentUserDocument?.lastName, ''),
    );
    _usernameController = TextEditingController(text: currentUserDisplayName);
    _phoneController = TextEditingController(text: currentPhoneNumber);
    _emailController = TextEditingController(text: currentUserEmail);
    _golfCanadaController = TextEditingController(
      text: valueOrDefault(currentUserDocument?.golfCanadaNumber, ''),
    );

    _handicapValue = currentUserDocument?.handicap;
    _coursesValue = currentUserDocument?.homeCourse;
  }

  @override
  void dispose() {
    _ringController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _golfCanadaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving || _isDeleting) return;

    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) return;

    final desiredEmail = _emailController.text.trim();
    if (desiredEmail.isNotEmpty && desiredEmail != currentUserEmail) {
      _showSnackbar('Please update your email in account settings first.',
          isError: true);
      return;
    }

    final userRef = currentUserReference;
    if (userRef == null) return;

    setState(() => _isSaving = true);

    try {
      final result = await _controller.saveProfile(
        userRef: userRef,
        userData: createUsersRecordData(
          photoUrl: currentUserPhoto,
          handicap: _handicapValue,
          golfCanadaNumber: () {
            final raw = _golfCanadaController.text.trim();
            return raw.isEmpty ? null : raw;
          }(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          homeCourse: _coursesValue,
        ),
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      switch (result) {
        case EditProfileSaveSuccess():
          currentUserDocument =
              await UsersRecord.getDocumentOnce(userRef);
          if (!mounted) return;
          _showSnackbar('Profile updated successfully.');
          context.goMainProfile(transition: TransitionStandards.modalTransition);
        case EditProfileSaveValidationError(:final message):
          _showSnackbar(message, isError: true);
        case EditProfileSaveFailure(:final message):
          _showSnackbar(message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_isSaving || _isDeleting) return;

    HapticFeedback.mediumImpact();

    final confirm = await showPremiumDialog(
          context: context,
          variant: PremiumDialogVariant.destructive,
          icon: Icons.delete_outline,
          title: 'Delete Account',
          body:
              'This permanently deletes your account and all associated data. This action cannot be undone.',
          actionLabel: 'Delete',
        ) ??
        false;

    if (!confirm || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final result = await _controller.deleteUserAccount();

      if (!mounted) return;

      switch (result) {
        case EditProfileDeleteSuccess():
          context.goSignIn(transition: TransitionStandards.modalTransition);
        case EditProfileDeleteCancelled():
          break;
        case EditProfileDeleteFailure(:final message):
          _showSnackbar(message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.pure),
        ),
        duration: const Duration(milliseconds: 2500),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _handleChangePhoto() async {
    await showAppBottomSheet(
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const ChangePhotoWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: const PremiumBackButton(),
          title: Text(
            'Edit Profile',
            style: AppTypography.titleLarge.copyWith(color: AppColors.pure),
          ),
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                      height: MediaQuery.of(context).padding.top + kToolbarHeight),

                  // Hero Section
                  AuthUserStreamWidget(
                    builder: (context) => EditProfileHeroSection(
                      photoUrl: currentUserPhoto,
                      ringController: _ringController,
                      onChangePhoto: _handleChangePhoto,
                    ),
                  ),

                  SizedBox(height: AppSpacing.xl),

                  // Main Content Card
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
                          offset: const Offset(0, -10),
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
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xxs),
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // Personal Info
                        AuthUserStreamWidget(
                          builder: (context) => EditProfilePersonalInfoSection(
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            usernameController: _usernameController,
                            phoneController: _phoneController,
                            emailController: _emailController,
                            gender: currentUserDocument?.gender,
                            dateOfBirth: currentUserDocument?.dateOfBirth,
                            firstNameValidator: _controller.validateFirstName,
                            lastNameValidator: _controller.validateLastName,
                            phoneValidator: _controller.validatePhone,
                          ),
                        ),

                        // Golf Profile
                        AuthUserStreamWidget(
                          builder: (context) => StreamBuilder<List<CourseRecord>>(
                            stream: queryCourseRecord(),
                            builder: (context, snapshot) {
                              final courses = (snapshot.data ?? [])
                                ..sort((a, b) => a.name.compareTo(b.name));
                              final isLoading = !snapshot.hasData;

                              // Initialize course value from user doc if not set
                              if (_coursesValue == null && mounted) {
                                _coursesValue = currentUserDocument?.homeCourse;
                              }

                              return EditProfileGolfSection(
                                courses: courses,
                                isLoadingCourses: isLoading,
                                selectedCourse: _coursesValue,
                                onCourseChanged: (val) =>
                                    setState(() => _coursesValue = val),
                                handicapValue: _handicapValue ??
                                    valueOrDefault(
                                        currentUserDocument?.handicap, 0),
                                onHandicapChanged: (val) =>
                                    setState(() => _handicapValue = val),
                                golfCanadaController: _golfCanadaController,
                                coursesValueController: _coursesValueController ??=
                                    FormFieldController<String>(_coursesValue),
                                golfCanadaValidator:
                                    _controller.validateGolfCanadaNumber,
                              );
                            },
                          ),
                        ),

                        // Actions
                        EditProfileActions(
                          onSave: _handleSave,
                          onDelete: _handleDelete,
                          isSaving: _isSaving,
                          isDeleting: _isDeleting,
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
