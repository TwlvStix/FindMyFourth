import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/core/app_theme.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/typography.dart';
import '/core/navigation/app_router.dart';
import '/core/widgets/app_button_enhanced.dart';
import '/core/widgets/app_icon_button.dart';
import '/core/widgets/fairway_background.dart';
import '/models/vibe_profile.dart';
import '/providers/chat_provider.dart';
import '/services/vibe_matcher.dart';
import '/services/vibe_repository.dart';

class ProfileUserFirebaseWidget extends StatefulWidget {
  const ProfileUserFirebaseWidget({
    super.key,
    required this.userRef,
  });

  final DocumentReference userRef;

  @override
  State<ProfileUserFirebaseWidget> createState() =>
      _ProfileUserFirebaseWidgetState();
}

class _ProfileUserFirebaseWidgetState extends State<ProfileUserFirebaseWidget> {
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final VibeRepository _vibeRepository = VibeRepository();

  VibeMatchResult? _vibeMatchResult;
  VibeProfile? _myVibes;
  VibeProfile? _theirVibes;
  bool _isVibeMatchLoading = false;
  String? _vibeMatchUserId;

  DocumentReference? _currentUserRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Future<void> _openChatWithUser(DocumentReference userRef) async {
    final currentUserRef = _currentUserRef();
    if (currentUserRef == null) {
      return;
    }

    try {
      final chatRef = await context.read<ChatProvider>().createOrGetDirectChat(
            currentUid: currentUserRef.id,
            otherUid: userRef.id,
          );
      _openChat(chatRef.id);
    } catch (error, stackTrace) {
      context
          .read<ChatProvider>()
          .logError('createOrGetDirectChat failed', error, stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat. Please try again.'),
        ),
      );
    }
  }

  void _openChat(String chatId) {
    context.pushNamed(
      'ChatDetails',
      pathParameters: {
        'chatId': chatId,
      },
    );
  }

  void _ensureVibeMatch(DocumentSnapshot snapshot) {
    if (_isVibeMatchLoading) {
      return;
    }
    if (_vibeMatchResult != null && _vibeMatchUserId == snapshot.id) {
      return;
    }
    _vibeMatchUserId = snapshot.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadVibeMatch(snapshot);
    });
  }

  Future<void> _loadVibeMatch(DocumentSnapshot snapshot) async {
    setState(() {
      _isVibeMatchLoading = true;
      _vibeMatchResult = null;
    });
    try {
      final myVibes = await _vibeRepository.getMyVibesCached();
      final theirVibes = _vibeRepository.profileFromSnapshot(snapshot);
      final result = VibeMatcher.score(myVibes, theirVibes);
      if (!mounted) {
        return;
      }
      setState(() {
        _myVibes = myVibes;
        _theirVibes = theirVibes;
        _vibeMatchResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vibeMatchResult = null;
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVibeMatchLoading = false;
      });
    }
  }

  void _openVibeMatchSheet() {
    final result = _vibeMatchResult;
    final myVibes = _myVibes;
    final theirVibes = _theirVibes;
    if (result == null || myVibes == null || theirVibes == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: true,
      builder: (context) {
        final displayScore =
            (result.cappedScore ?? result.totalScore).round();
        final isCapped = result.cappedScore != null;
        final sheetNavigator = Navigator.of(context, rootNavigator: true);
        void closeSheet() => sheetNavigator.maybePop();
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pure,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Vibe Match',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.onyx,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: closeSheet,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.stone,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cloud,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '$displayScore%',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.fairwayDark,
                    ),
                  ),
                  if (isCapped || !result.isRecommended) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Not recommended',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ],
                  if (result.confidence == VibeConfidence.low) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Vibe score: $displayScore% (low confidence)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.stone,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (result.conflicts.isNotEmpty) ...[
                    Text(
                      'Potential conflicts',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.onyx,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...result.conflicts.map(
                      (conflict) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          _conflictSummary(conflict),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.stone,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    'Top differences',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.onyx,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: result.topDifferences.map((difference) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.cloud,
                          ),
                        ),
                        child: Text(
                          '${VibeLabels.titleFor(difference.category)} • gap ${difference.distance}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.slate,
                            letterSpacing: AppTypography.letterSpacingNormal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'You vs Them',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.onyx,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...VibeCategory.values.map((category) {
                    return _buildVibeComparisonRow(
                      category,
                      myVibes.preferenceFor(category),
                      theirVibes.preferenceFor(category),
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),
                  AppButtonEnhanced(
                    text: 'Close',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    fullWidth: true,
                    onPressed: closeSheet,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVibeComparisonRow(
    VibeCategory category,
    VibePreference mine,
    VibePreference theirs,
  ) {
    final myLabel =
        VibeLabels.labelFor(category, mine.value) ?? mine.value.toString();
    final theirLabel =
        VibeLabels.labelFor(category, theirs.value) ?? theirs.value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            VibeLabels.titleFor(category),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onyx,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _buildVibeValueChip('You', mine.value, myLabel),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildVibeValueChip('Them', theirs.value, theirLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVibeValueChip(String label, int value, String meaning) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cloud),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.stone,
              letterSpacing: AppTypography.letterSpacingNormal,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$value • $meaning',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }

  String _conflictSummary(VibeConflict conflict) {
    final title = VibeLabels.titleFor(conflict.category);
    final owner = _dealbreakerOwnerLabel(conflict.whoHasDealbreaker);
    return '$title: you ${conflict.myValue} vs them ${conflict.theirValue} '
        '($owner, threshold ${conflict.threshold})';
  }

  String _dealbreakerOwnerLabel(VibeDealbreakerOwner owner) {
    switch (owner) {
      case VibeDealbreakerOwner.me:
        return 'your dealbreaker';
      case VibeDealbreakerOwner.them:
        return 'their dealbreaker';
      case VibeDealbreakerOwner.both:
        return 'both dealbreakers';
    }
  }

  String _stringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  String _numValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];
    if (value is num) {
      return value.toString();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  Widget _buildVibeMatchRow() {
    final result = _vibeMatchResult;
    final displayScore = result == null
        ? '--'
        : '${(result.cappedScore ?? result.totalScore).round()}%';
    final label = 'Vibe Match $displayScore';
    final canOpenSheet = result != null;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        0.0,
        0.0,
        0.0,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.fairway.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.fairway.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.fairwayDark,
                    letterSpacing: AppTypography.letterSpacingNormal,
                  ),
                ),
                if (_isVibeMatchLoading) ...[
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.fairway,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: canOpenSheet ? _openVibeMatchSheet : null,
            child: Text(
              'Why?',
              style: AppTypography.bodySmall.copyWith(
                color: canOpenSheet
                    ? AppColors.fairwayDark
                    : AppColors.stone,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
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
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.userRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              key: scaffoldKey,
              backgroundColor: AppTheme.of(context).tertiary,
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final data =
              (snapshot.data!.data() as Map<String, dynamic>?) ??
                  <String, dynamic>{};
          _ensureVibeMatch(snapshot.data!);
          final photoUrl = _stringValue(
            data,
            'photo_url',
            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
          );
          final firstName = _stringValue(data, 'first_name', 'First');
          final lastName = _stringValue(data, 'last_name', 'Last');
          final displayName = _stringValue(data, 'display_name', 'Golfer');
          final phoneNumber = _stringValue(data, 'phone_number', '999-9999');
          final email = _stringValue(data, 'email', '@gmail.com');
          final homeCourse = _stringValue(data, 'home_course', 'TWLV');
          final handicap = _numValue(data, 'handicap', '6');
          final golfCanadaNumber =
              _stringValue(data, 'golf_canada_number', '-');

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: AppTheme.of(context).tertiary,
            appBar: AppBar(
              backgroundColor: AppTheme.of(context).tertiary,
              automaticallyImplyLeading: false,
              leading: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.of(context).maybePop();
                },
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.of(context).primaryBtnText,
                  size: 30.0,
                ),
              ),
              actions: const [],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: FairwayBackgroundDark(
              child: SizedBox(
                width: double.infinity,
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          width: 140.0,
                          child: Stack(
                            children: [
                              Align(
                                alignment:
                                    const AlignmentDirectional(0.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0,
                                    AppSpacing.sm,
                                    0.0,
                                    0.0,
                                  ),
                                  child: Container(
                                    width: 100.0,
                                    height: 100.0,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context)
                                          .secondaryBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(AppSpacing.xxs / 2),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(50.0),
                                        child: Image.network(
                                          photoUrl,
                                          width: 100.0,
                                          height: 100.0,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                            'assets/images/error_image.png',
                                            width: 100.0,
                                            height: 100.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            AppSpacing.xxxl,
                            0.0,
                            0.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                firstName,
                                style: AppTheme.of(context)
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
                                      color: AppTheme.of(context)
                                          .primaryBtnText,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  AppSpacing.xs,
                                  0.0,
                                  0.0,
                                  0.0,
                                ),
                                child: Text(
                                  lastName,
                                  style: AppTheme.of(context)
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
                                        color: AppTheme.of(context)
                                            .primaryBtnText,
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: AppTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            AppSpacing.md,
                            0.0,
                            AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayName,
                                style: AppTheme.of(context)
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
                                      color: AppTheme.of(context)
                                          .primaryBtnText,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  AppSpacing.xxxl,
                                  0.0,
                                  0.0,
                                  0.0,
                                ),
                                child: Text(
                                  phoneNumber,
                                  style: AppTheme.of(context)
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
                                        color: AppTheme.of(context)
                                            .primaryBtnText,
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: AppTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildVibeMatchRow(),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            0.0,
                            0.0,
                            AppSpacing.xxxl + AppSpacing.xxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                email,
                                style: AppTheme.of(context)
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
                                      color: AppTheme.of(context)
                                          .primaryBtnText,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            0.0,
                            0.0,
                            AppSpacing.xl,
                          ),
                          child: AppIconButton(
                            borderColor: AppTheme.of(context).primary,
                            borderRadius: AppSpacing.xl,
                            borderWidth: 1.0,
                            buttonSize: AppSpacing.xxxl,
                            fillColor: AppTheme.of(context).primary,
                            icon: const FaIcon(
                              FontAwesomeIcons.facebookMessenger,
                              color: Colors.white,
                              size: 20.0,
                            ),
                            onPressed: () => _openChatWithUser(widget.userRef),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            height: 400.0,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.of(context).secondaryBackground,
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 3.0,
                                  color: Color(0x33000000),
                                  offset: Offset(
                                    0.0,
                                    -1.0,
                                  ),
                                )
                              ],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(0.0),
                                bottomRight: Radius.circular(0.0),
                                topLeft: Radius.circular(16.0),
                                topRight: Radius.circular(16.0),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      AppSpacing.md,
                                      AppSpacing.md,
                                      AppSpacing.md,
                                      0.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                            0.0,
                                            0.0,
                                            0.0,
                                            AppSpacing.xs,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                  0.0,
                                                  AppSpacing.xs,
                                                  AppSpacing.md,
                                                  AppSpacing.xs,
                                                ),
                                                child: FaIcon(
                                                  FontAwesomeIcons
                                                      .mapMarkerAlt,
                                                  color:
                                                      AppTheme.of(context)
                                                          .secondaryText,
                                                  size: AppSpacing.xl,
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      EdgeInsetsDirectional
                                                          .fromSTEB(
                                                    0.0,
                                                    0.0,
                                                    AppSpacing.sm,
                                                    0.0,
                                                  ),
                                                  child: Text(
                                                    'Home Course',
                                                    textAlign:
                                                        TextAlign.start,
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts
                                                                  .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                            0.0,
                                            0.0,
                                            0.0,
                                            AppSpacing.xs,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      const AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      AppSpacing.sm,
                                                      0.0,
                                                    ),
                                                    child: Text(
                                                      homeCourse,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: AppTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            font:
                                                                GoogleFonts
                                                                    .outfit(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 18.0,
                                                            letterSpacing:
                                                                0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                            0.0,
                                            0.0,
                                            0.0,
                                            AppSpacing.xs,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                  0.0,
                                                  AppSpacing.xs,
                                                  AppSpacing.md,
                                                  AppSpacing.xs,
                                                ),
                                                child: FaIcon(
                                                  FontAwesomeIcons.golfBall,
                                                  color:
                                                      AppTheme.of(context)
                                                          .secondaryText,
                                                  size: AppSpacing.xl,
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      EdgeInsetsDirectional
                                                          .fromSTEB(
                                                    0.0,
                                                    0.0,
                                                    AppSpacing.sm,
                                                    0.0,
                                                  ),
                                                  child: Text(
                                                    'Handicap',
                                                    textAlign:
                                                        TextAlign.start,
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts
                                                                  .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      const AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      AppSpacing.sm,
                                                      0.0,
                                                    ),
                                                    child: Text(
                                                      handicap,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: AppTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            font:
                                                                GoogleFonts
                                                                    .outfit(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 18.0,
                                                            letterSpacing:
                                                                0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                            0.0,
                                            0.0,
                                            0.0,
                                            AppSpacing.xs,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                  0.0,
                                                  AppSpacing.xs,
                                                  AppSpacing.md,
                                                  AppSpacing.xs,
                                                ),
                                                child: Icon(
                                                  Icons.verified_rounded,
                                                  color:
                                                      AppTheme.of(context)
                                                          .secondaryText,
                                                  size: AppSpacing.xl,
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      EdgeInsetsDirectional
                                                          .fromSTEB(
                                                    0.0,
                                                    0.0,
                                                    AppSpacing.sm,
                                                    0.0,
                                                  ),
                                                  child: Text(
                                                    'Golf Canada #',
                                                    textAlign:
                                                        TextAlign.start,
                                                    style: AppTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts
                                                                  .outfit(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      const AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      AppSpacing.sm,
                                                      0.0,
                                                    ),
                                                    child: Text(
                                                      golfCanadaNumber,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: AppTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            font:
                                                                GoogleFonts
                                                                    .outfit(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontStyle:
                                                                  AppTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 18.0,
                                                            letterSpacing:
                                                                0.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
          );
        },
      ),
    );
  }
}
