import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/widgets/app_count_controller.dart';
import '/core/utils/app_log.dart';
import '/core/widgets/premium_back_button.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/widgets/app_text_field.dart';
import '/core/widgets/app_premium_dialog.dart';
import '/core/motion/motion_helpers.dart';
import '/utils/app_util.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/elevation.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/border_radius.dart';
import '/core/form_field_controller.dart';
import '/profile/change_photo/change_photo_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/app_phosphor_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  static String routeName = 'EditProfile';
  static String routePath = '/editProfile';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget>
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

  // Animation Controllers
  late AnimationController _ringController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // Initialize ring animation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Initialize controllers with current user data
    firstNameTextController = TextEditingController(
      text: valueOrDefault(currentUserDocument?.firstName, ''),
    );
    firstNameFocusNode = FocusNode();

    lastNameTextController = TextEditingController(
      text: valueOrDefault(currentUserDocument?.lastName, ''),
    );
    lastNameFocusNode = FocusNode();

    usernameTextController = TextEditingController(
      text: currentUserDisplayName,
    );
    usernameFocusNode = FocusNode();

    phoneNumTextController = TextEditingController(
      text: currentPhoneNumber,
    );
    phoneNumFocusNode = FocusNode();

    emailTextController = TextEditingController(
      text: currentUserEmail,
    );
    emailFocusNode = FocusNode();

    golfCanadaTextController = TextEditingController(
      text: valueOrDefault(currentUserDocument?.golfCanadaNumber, ''),
    );
    golfCanadaFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ PERFORMANCE: Removed empty setState (no-op rebuild)
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
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

  Future<void> _handleSaveProfile() async {
    HapticFeedback.mediumImpact();

    if (!formKey.currentState!.validate()) {
      return;
    }

    final desiredEmail = emailTextController?.text.trim() ?? '';
    if (desiredEmail.isNotEmpty && desiredEmail != currentUserEmail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please update your email in account settings first.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (currentUserReference == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(
          currentUserReference!,
          createUsersRecordData(
            photoUrl: currentUserPhoto,
            handicap: handicapValue,
            golfCanadaNumber: () {
              final golfCanadaRaw = golfCanadaTextController?.text.trim() ?? '';
              return golfCanadaRaw.isEmpty ? null : golfCanadaRaw;
            }(),
            firstName: firstNameTextController!.text,
            lastName: lastNameTextController!.text,
            homeCourse: coursesValue,
          ),
        );
        transaction.set(
          currentUserReference!.collection('private').doc('info'),
          {'phone_number': phoneNumTextController!.text},
          SetOptions(merge: true),
        );
      });
      currentUserDocument =
          await UsersRecord.getDocumentOnce(currentUserReference!);
      _showSuccessAndNavigate();
    } catch (e) {
      AppLog.d('EditProfile: profile save failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save profile. Please try again.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          duration: Duration(milliseconds: 2000),
          backgroundColor: AppColors.error,
        ),
      );
    }

    if (mounted) setState(() {});
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully!',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.medium,
          ),
        ),
        duration: Duration(milliseconds: 2500),
        backgroundColor: AppColors.success,
      ),
    );

    context.goNamed(
      MainProfileWidget.routeName,
      extra: <String, dynamic>{
        kTransitionInfoKey: TransitionStandards.modalTransition,
      },
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: const PremiumBackButton(),
          title: Text(
            'Edit Profile',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 60),

                  // ═══════════════════════════════════════════════════════════
                  // HERO SECTION - Animated Avatar
                  // ═══════════════════════════════════════════════════════════
                  _buildHeroSection(context),

                  SizedBox(height: AppSpacing.xl),

                  // ═══════════════════════════════════════════════════════════
                  // MAIN CONTENT CARD
                  // ═══════════════════════════════════════════════════════════
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
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.xxs),
                          ),
                        ),

                        SizedBox(height: AppSpacing.lg),

                        // Personal Information Section
                        _buildPersonalInfoSection(context),

                        // Golf Profile Section
                        _buildGolfProfileSection(context),

                        // Save Button
                        _buildSaveButton(context),

                        // Delete Account
                        _buildDeleteAccountButton(context),

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

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        // Animated Avatar with Rotating Gradient Ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Rotating gradient ring - member badge aesthetic
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _ringController.value * 2 * 3.14159,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.navy,
                          AppColors.gold.withValues(alpha: 0.9),
                          AppColors.gold,
                          AppColors.goldLight,
                          AppColors.gold.withValues(alpha: 0.9),
                          AppColors.navy,
                        ],
                        stops: [0.0, 0.15, 0.35, 0.65, 0.85, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // White border
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pure,
              ),
            ),

            // Profile photo
            AuthUserStreamWidget(
              builder: (context) => Container(
                width: 132,
                height: 132,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: Image.network(
                  valueOrDefault<String>(
                    currentUserPhoto,
                    'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.sand,
                    child: Icon(AppPhosphorIcons.profile,
                        size: AppIconSize.hero, color: AppColors.stone),
                  ),
                ),
              ),
            ),

            // Edit photo button
            Positioned(
              bottom: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkResponse(
                  radius: 30,
                  onTap: () async {
                    HapticFeedback.lightImpact();
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
                      // ✅ PERFORMANCE: Removed empty setState (no-op rebuild)
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.green, AppColors.greenLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [AppElevation.glowGreen],
                    ),
                    child: Icon(AppPhosphorIcons.camera,
                        color: AppColors.pure, size: AppIconSize.md),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.md),

        // Change Photo text
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
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
              // ✅ PERFORMANCE: Removed empty setState (no-op rebuild)
            });
          },
          child: Text(
            'Change Photo',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSONAL INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalInfoSection(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
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
          AuthUserStreamWidget(
            builder: (context) => Column(
              children: [
                // First & Last Name Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: firstNameTextController!,
                        focusNode: firstNameFocusNode!,
                        label: 'First Name',
                        icon: AppPhosphorIcons.profile,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildTextField(
                        controller: lastNameTextController!,
                        focusNode: lastNameFocusNode!,
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
                  focusNode: usernameFocusNode!,
                  label: 'Display Name',
                  icon: AppPhosphorIcons.atSign,
                  readOnly: true,
                ),
                SizedBox(height: AppSpacing.md),

                // Phone
                _buildTextField(
                  controller: phoneNumTextController!,
                  focusNode: phoneNumFocusNode!,
                  label: 'Phone',
                  icon: AppPhosphorIcons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: AppSpacing.md),

                // Email
                _buildTextField(
                  controller: emailTextController!,
                  focusNode: emailFocusNode!,
                  label: 'Email',
                  icon: AppPhosphorIcons.email,
                  readOnly: true,
                ),
                SizedBox(height: AppSpacing.md),

                // Gender & Date of Birth Row (Read-only)
                Row(
                  children: [
                    // Gender (Read-only)
                    Expanded(
                      child: Container(
                        height: 56,
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                          border: Border.all(color: AppColors.inputBorderIdle),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppPhosphorIcons.profile,
                              color: AppColors.textMuted,
                              size: AppIconSize.md,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                valueOrDefault(currentUserDocument?.gender, '')
                                        .isNotEmpty
                                    ? currentUserDocument!.gender
                                    : 'Gender',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: valueOrDefault(
                                              currentUserDocument?.gender, '')
                                          .isNotEmpty
                                      ? AppColors.textSecondary
                                      : AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    // Date of Birth (Read-only)
                    Expanded(
                      child: Container(
                        height: 56,
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
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
                                currentUserDocument?.dateOfBirth != null
                                    ? '${currentUserDocument!.dateOfBirth!.month.toString().padLeft(2, '0')}/${currentUserDocument!.dateOfBirth!.day.toString().padLeft(2, '0')}/${currentUserDocument!.dateOfBirth!.year}'
                                    : 'Birthday',
                                style: AppTypography.bodyMedium.copyWith(
                                  color:
                                      currentUserDocument?.dateOfBirth != null
                                          ? AppColors.textSecondary
                                          : AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLF PROFILE SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGolfProfileSection(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
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
          AuthUserStreamWidget(
            builder: (context) => Column(
              children: [
                // Home Course Dropdown
                StreamBuilder<List<CourseRecord>>(
                  stream: queryCourseRecord(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                          border: Border.all(color: AppColors.inputBorderIdle),
                        ),
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    List<CourseRecord> courses = snapshot.data!
                      ..sort((a, b) => a.name.compareTo(b.name));

                    if (coursesValue == null && mounted) {
                      coursesValue = valueOrDefault(
                        currentUserDocument?.homeCourse,
                        '',
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(color: AppColors.inputBorderIdle),
                      ),
                      child: AppDropDown<String>(
                        controller: coursesValueController ??=
                            FormFieldController<String>(coursesValue),
                        options: courses.map((c) => c.name).toList(),
                        onChanged: (val) => setState(() => coursesValue = val),
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
                        margin:
                            EdgeInsetsDirectional.only(start: AppSpacing.md),
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
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.sm),
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
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Icon(
                            AppPhosphorIcons.minus,
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
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
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Icon(
                            AppPhosphorIcons.plus,
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
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
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        count: handicapValue ??
                            valueOrDefault(currentUserDocument?.handicap, 0),
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
                  focusNode: golfCanadaFocusNode!,
                  label: 'Golf Canada #',
                  icon: AppPhosphorIcons.verified,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: _handleSaveProfile,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navyLight, AppColors.navy],
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            boxShadow: [AppElevation.lg],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppPhosphorIcons.success,
                  color: AppColors.pure, size: AppIconSize.md),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Save Changes',
                style: AppTypography.titleSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeleteAccountButton(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          final confirm = await showPremiumDialog(
                context: context,
                variant: PremiumDialogVariant.destructive,
                icon: PhosphorIconsRegular.trash,
                title: 'Delete Account',
                body:
                    'This permanently deletes your account and all associated data. This action cannot be undone.',
                actionLabel: 'Delete',
              ) ??
              false;

          if (!confirm) return;

          try {
            final deleted = await deleteAccount();
            if (!deleted) {
              if (!mounted) return;
              showSnackbar(
                  context, 'Unable to delete account. Please try again.');
              return;
            }
            await authManager.signOut();
            if (!mounted) return;
            context.goNamed(
              SignInWidget.routeName,
              extra: <String, dynamic>{
                kTransitionInfoKey: TransitionStandards.modalTransition,
              },
            );
          } catch (e) {
            AppLog.d('Delete account failed: $e');
            if (!mounted) return;
            showSnackbar(
                context, 'Unable to delete account. Please try again.');
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppPhosphorIcons.trash,
                  color: AppColors.error, size: AppIconSize.md),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Delete Account',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT FIELD BUILDER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
    );
  }
}
