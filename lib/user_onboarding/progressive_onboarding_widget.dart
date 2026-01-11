import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/core/custom_functions.dart' as functions;
import '/core/widgets/app_count_controller.dart';
import '/core/widgets/app_drop_down.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/spacing.dart';
import '/core/form_field_controller.dart';
import '/profile/main_profile/main_profile_widget.dart';
import '/user_auth/sign_in/sign_in_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressiveOnboardingWidget extends StatefulWidget {
  const ProgressiveOnboardingWidget({super.key});

  static String routeName = 'ProgressiveOnboarding';
  static String routePath = '/progressiveOnboarding';

  @override
  State<ProgressiveOnboardingWidget> createState() =>
      _ProgressiveOnboardingWidgetState();
}

class _ProgressiveOnboardingWidgetState
    extends State<ProgressiveOnboardingWidget> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  String? _homeCourseValue;
  FormFieldController<String>? _homeCourseController;
  int _handicapValue = 18;
  int _drinksValue = 2;
  int _musicValue = 2;
  int _playMoneyValue = 2;
  int _paceValue = 2;

  bool _isLoading = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _ensureUserRecord();
    _emailController.text = currentUserEmail;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (!RegExp(kTextValidatorUsernameRegex).hasMatch(value)) {
      return 'Must start with a letter and can only contain letters, digits and - or _.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(kTextValidatorEmailRegex).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Validate Step 2 fields
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _validateUsername(_usernameController.text) != null ||
        _validateEmail(_emailController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: AppTheme.of(context).error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final desiredUsername = functions.usernameCreator(_usernameController.text);
      // Update user record
      final userRef = currentUserReference;
      if (userRef != null) {
        final desiredEmail = _emailController.text.trim();
        if (desiredEmail.isNotEmpty && desiredEmail != currentUserEmail) {
          try {
            await authManager.updateEmail(
              email: desiredEmail,
              context: context,
            );
          } on FirebaseAuthException catch (e) {
            final needsReauth = e.code == 'requires-recent-login';
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    needsReauth
                        ? 'Email change requires you to sign in again.'
                        : 'Unable to update email. ${e.message}',
                  ),
                  backgroundColor: AppTheme.of(context).error,
                ),
              );
            }
            if (needsReauth && mounted) {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Re-authentication required'),
                  content: Text(
                      'To update your email, please sign in again and retry.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.goNamed(SignInWidget.routeName);
                      },
                      child: Text('Sign In'),
                    ),
                  ],
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }
        final usernamesRef = FirebaseFirestore.instance
            .collection('usernames')
            .doc(desiredUsername);

        var profileUpdated = false;
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final usernameSnap = await transaction.get(usernamesRef);
            if (usernameSnap.exists) {
              final existingRef =
                  usernameSnap.get('uid') as DocumentReference?;
              if (existingRef != null && existingRef.path != userRef.path) {
                throw StateError('username_taken');
              }
            } else {
              transaction.set(usernamesRef, {
                'uid': userRef,
                'created_at': FieldValue.serverTimestamp(),
              });
            }

            transaction.update(
              userRef,
              createUsersRecordData(
                displayName: desiredUsername,
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                phoneNumber: _phoneController.text,
                homeCourse: _homeCourseValue,
                handicap: _handicapValue,
                drinks: _drinksValue,
                music: _musicValue,
                playForMoney: _playMoneyValue,
                paceOfPlay: _paceValue,
              ),
            );
          });
          profileUpdated = true;
        } on StateError catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username already taken'),
              backgroundColor: AppTheme.of(context).error,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        try {
          if (!profileUpdated) {
            return;
          }
          await makeCloudCall(
            'completeOnboarding',
            {'userDocPath': userRef.path},
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to finish onboarding; please try again.'),
                backgroundColor: AppTheme.of(context).error,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        final recordReady = await _ensureUserRecord();
        if (!recordReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Finishing setup. Please wait a moment before continuing.',
              ),
              backgroundColor: AppTheme.of(context).error,
            ),
          );
          return;
        }
        context.goNamed(MainProfileWidget.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing onboarding: $e'),
            backgroundColor: AppTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _ensureUserRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    try {
      await maybeCreateUser(user);
      return true;
    } catch (error, stackTrace) {
      debugPrint('❌ PROGRESSIVE ONBOARDING: unable to ensure user doc exists: $error');
      debugPrint('❌ PROGRESSIVE ONBOARDING: Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.of(context).primaryBackground,
      body: FairwayBackgroundSunset(
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    _buildWelcomeStep(),
                    _buildBasicInfoStep(),
                    _buildGolfInfoStep(),
                    _buildPreferencesStep(),
                  ],
                ),
              ),
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _totalSteps,
          (index) => Container(
            width: 40.0,
            height: 4.0,
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: index <= _currentStep
                  ? AppTheme.of(context).primary
                  : AppTheme.of(context).primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to\nFind My Fourth',
            style: AppTheme.of(context).displaySmall.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontStyle: AppTheme.of(context).displaySmall.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: AppTheme.of(context).displaySmall.fontStyle,
                ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.sm),
            child: Text(
              'Connect with golfers, join games, and never play alone again.',
              style: AppTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.outfit(
                      fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                      fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                  ),
            ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _OnboardingFeature(
                  icon: Icons.golf_course_rounded,
                  title: 'Find games near you',
                  description:
                      'Browse available tee times and join rounds in your area.',
                ),
                _OnboardingFeature(
                  icon: Icons.people_alt_rounded,
                  title: 'Connect with players',
                  description:
                      'Meet new golfers and build your network on the course.',
                ),
                _OnboardingFeature(
                  icon: Icons.chat_bubble_outline,
                  title: 'Group messaging',
                  description:
                      'Coordinate games with built-in chat for every round.',
                ),
              ],
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Let\'s set up your profile',
              style: AppTheme.of(context).headlineMedium.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          AppTheme.of(context).headlineMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle: AppTheme.of(context).headlineMedium.fontStyle,
                  ),
            ),
            Padding(
              padding: AppSpacing.only(top: AppSpacing.xs),
              child: Text(
                'This helps other golfers find and connect with you.',
                style: AppTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.outfit(
                        fontWeight:
                            AppTheme.of(context).bodyMedium.fontWeight,
                        fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                      fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            // First Name
            TextFormField(
              controller: _firstNameController,
              focusNode: _firstNameFocus,
              autofocus: false,
              obscureText: false,
              decoration: InputDecoration(
                labelText: 'First Name',
                hintText: 'Enter your first name',
                labelStyle: AppTheme.of(context).labelMedium,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).alternate,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: AppTheme.of(context).secondaryBackground,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),
            // Last Name
            TextFormField(
              controller: _lastNameController,
              focusNode: _lastNameFocus,
              obscureText: false,
              decoration: InputDecoration(
                labelText: 'Last Name',
                hintText: 'Enter your last name',
                labelStyle: AppTheme.of(context).labelMedium,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).alternate,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: AppTheme.of(context).secondaryBackground,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),
            // Username
            TextFormField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              obscureText: false,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a unique username',
                labelStyle: AppTheme.of(context).labelMedium,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).alternate,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: AppTheme.of(context).secondaryBackground,
              ),
              validator: _validateUsername,
            ),
            SizedBox(height: AppSpacing.md),
            // Phone
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              obscureText: false,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: 'Enter your phone number',
                labelStyle: AppTheme.of(context).labelMedium,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).alternate,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: AppTheme.of(context).secondaryBackground,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            // Email
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              obscureText: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                labelStyle: AppTheme.of(context).labelMedium,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).alternate,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).primary,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.of(context).error,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: AppTheme.of(context).secondaryBackground,
              ),
              validator: _validateEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGolfInfoStep() {
    return SingleChildScrollView(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your golf profile',
            style: AppTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontStyle: AppTheme.of(context).headlineMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: AppTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.xs),
            child: Text(
              'Help us match you with the right players and games.',
              style: AppTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.outfit(
                      fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                      fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                    fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          // Home Course
          FutureBuilder<List<CourseRecord>>(
            future: queryCourseRecordOnce(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: SpinKitWanderingCubes(
                      color: AppTheme.of(context).primary,
                      size: 40.0,
                    ),
                  ),
                );
              }
              final courses = snapshot.data!;
              return AppDropDown<String>(
                controller: _homeCourseController ??=
                    FormFieldController<String>(null),
                options: courses.map((e) => e.name).toList(),
                onChanged: (val) => setState(() => _homeCourseValue = val),
                width: double.infinity,
                height: 56.0,
                textStyle: AppTheme.of(context).bodyMedium,
                hintText: 'Select your home course',
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.of(context).secondaryText,
                  size: 24.0,
                ),
                fillColor: AppTheme.of(context).secondaryBackground,
                elevation: 2.0,
                borderColor: AppTheme.of(context).alternate,
                borderWidth: 2.0,
                borderRadius: 12.0,
                margin: EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 16.0, 4.0),
                hidesUnderline: true,
                isOverButton: true,
                isSearchable: false,
                isMultiSelect: false,
              );
            },
          ),
          SizedBox(height: AppSpacing.xl),
          // Handicap
          Text(
            'Handicap',
            style: AppTheme.of(context).titleMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppTheme.of(context).alternate,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppCountController(
                decrementIconBuilder: (enabled) => Icon(
                  FontAwesomeIcons.minus,
                  color: enabled
                      ? AppTheme.of(context).primary
                      : AppTheme.of(context).secondaryText,
                  size: 20.0,
                ),
                incrementIconBuilder: (enabled) => Icon(
                  FontAwesomeIcons.plus,
                  color: enabled
                      ? AppTheme.of(context).primary
                      : AppTheme.of(context).secondaryText,
                  size: 20.0,
                ),
                countBuilder: (count) => Text(
                  count.toString(),
                  style: AppTheme.of(context).headlineSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight:
                              AppTheme.of(context).headlineSmall.fontWeight,
                          fontStyle:
                              AppTheme.of(context).headlineSmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            AppTheme.of(context).headlineSmall.fontWeight,
                        fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                      ),
                ),
                count: _handicapValue,
                updateCount: (count) =>
                    setState(() => _handicapValue = count),
                stepSize: 1,
                minimum: 0,
                maximum: 54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your play style',
            style: AppTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontStyle: AppTheme.of(context).headlineMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: AppTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          Padding(
            padding: AppSpacing.only(top: AppSpacing.xs),
            child: Text(
              'Rate your preferences from 0 (not at all) to 5 (very much).',
              style: AppTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.outfit(
                      fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                      fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight: AppTheme.of(context).bodyMedium.fontWeight,
                    fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                  ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          _buildPreferenceControl(
            'Music on the course',
            FontAwesomeIcons.music,
            _musicValue,
            (count) => setState(() => _musicValue = count),
          ),
          SizedBox(height: AppSpacing.lg),
          _buildPreferenceControl(
            'Drinks while playing',
            FontAwesomeIcons.beerMugEmpty,
            _drinksValue,
            (count) => setState(() => _drinksValue = count),
          ),
          SizedBox(height: AppSpacing.lg),
          _buildPreferenceControl(
            'Play for money',
            FontAwesomeIcons.dollarSign,
            _playMoneyValue,
            (count) => setState(() => _playMoneyValue = count),
          ),
          SizedBox(height: AppSpacing.lg),
          _buildPreferenceControl(
            'Pace of play',
            FontAwesomeIcons.gaugeHigh,
            _paceValue,
            (count) => setState(() => _paceValue = count),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceControl(
    String title,
    IconData icon,
    int value,
    Function(int) onUpdate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.of(context).primary,
              size: 20.0,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTheme.of(context).titleMedium.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                  ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppTheme.of(context).alternate,
              width: 2.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppCountController(
              decrementIconBuilder: (enabled) => Icon(
                FontAwesomeIcons.minus,
                color: enabled
                    ? AppTheme.of(context).primary
                    : AppTheme.of(context).secondaryText,
                size: 18.0,
              ),
              incrementIconBuilder: (enabled) => Icon(
                FontAwesomeIcons.plus,
                color: enabled
                    ? AppTheme.of(context).primary
                    : AppTheme.of(context).secondaryText,
                size: 18.0,
              ),
              countBuilder: (count) => Text(
                count.toString(),
                style: AppTheme.of(context).headlineSmall.override(
                      font: GoogleFonts.outfit(
                        fontWeight:
                            AppTheme.of(context).headlineSmall.fontWeight,
                        fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: AppTheme.of(context).headlineSmall.fontWeight,
                      fontStyle: AppTheme.of(context).headlineSmall.fontStyle,
                    ),
              ),
              count: value,
              updateCount: onUpdate,
              stepSize: 1,
              minimum: 0,
              maximum: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: AppSpacing.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButtonEnhanced(
                text: 'Back',
                onPressed: _previousStep,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                fullWidth: true,
              ),
            ),
          if (_currentStep > 0) SizedBox(width: AppSpacing.md),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: AppButtonEnhanced(
              text: _currentStep == _totalSteps - 1 ? 'Complete' : 'Next',
              onPressed: _isLoading ? null : _nextStep,
              variant: AppButtonVariant.gradient,
              size: AppButtonSize.medium,
              fullWidth: true,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingFeature extends StatelessWidget {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: AppTheme.of(context).primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Icon(
              icon,
              color: AppTheme.of(context).primary,
              size: 24.0,
            ),
          ),
          Expanded(
            child: Padding(
              padding: AppSpacing.only(left: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.of(context).titleMedium.override(
                          font: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontStyle:
                                AppTheme.of(context).titleMedium.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                          fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                        ),
                  ),
                  Padding(
                    padding: AppSpacing.only(top: AppSpacing.xxs),
                    child: Text(
                      description,
                      style: AppTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.outfit(
                              fontWeight:
                                  AppTheme.of(context).bodyMedium.fontWeight,
                              fontStyle:
                                  AppTheme.of(context).bodyMedium.fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight:
                                AppTheme.of(context).bodyMedium.fontWeight,
                            fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
