import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/spacing.dart';
import '/main_function/games_list/games_list_widget.dart';
import '/profile/profile_user/profile_user_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom clipper for elegant curved bottom edge
class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.lineTo(0, 0);

    // Line across the top
    path.lineTo(size.width, 0);

    // Line down the right side
    path.lineTo(size.width, size.height - 20);

    // Create elegant concave curve along bottom
    // Curve dips down slightly in center for modern feel
    path.quadraticBezierTo(
      size.width * 0.5, // Control point X (center)
      size.height + 15,  // Control point Y (dips down)
      0,                 // End point X (left edge)
      size.height - 20,  // End point Y (back up)
    );

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Refined topographic contour painter - atmospheric and subtle
class SubtleTopographicPainter extends CustomPainter {
  final Color color;
  final double opacity;

  SubtleTopographicPainter({
    required this.color,
    this.opacity = 0.12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8; // Very thin lines for subtlety

    // Create organic, flowing contour lines
    // These mimic real golf course elevation maps

    // Upper elevation band
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.2,
      controlPoints: [
        [size.width * 0.25, size.height * 0.18],
        [size.width * 0.5, size.height * 0.22],
        [size.width * 0.75, size.height * 0.19],
        [size.width + 50, size.height * 0.21],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.25,
      controlPoints: [
        [size.width * 0.25, size.height * 0.23],
        [size.width * 0.5, size.height * 0.27],
        [size.width * 0.75, size.height * 0.24],
        [size.width + 50, size.height * 0.26],
      ],
    );

    // Middle elevation band
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.5,
      controlPoints: [
        [size.width * 0.3, size.height * 0.48],
        [size.width * 0.6, size.height * 0.53],
        [size.width * 0.85, size.height * 0.49],
        [size.width + 50, size.height * 0.52],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.56,
      controlPoints: [
        [size.width * 0.3, size.height * 0.54],
        [size.width * 0.6, size.height * 0.59],
        [size.width * 0.85, size.height * 0.55],
        [size.width + 50, size.height * 0.58],
      ],
    );

    // Lower elevation band
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.75,
      controlPoints: [
        [size.width * 0.2, size.height * 0.73],
        [size.width * 0.5, size.height * 0.78],
        [size.width * 0.8, size.height * 0.74],
        [size.width + 50, size.height * 0.77],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: -50,
      startY: size.height * 0.82,
      controlPoints: [
        [size.width * 0.2, size.height * 0.80],
        [size.width * 0.5, size.height * 0.85],
        [size.width * 0.8, size.height * 0.81],
        [size.width + 50, size.height * 0.84],
      ],
    );

    // Add occasional shorter accent contours
    _drawContourLine(
      canvas,
      paint,
      size,
      startX: size.width * 0.1,
      startY: size.height * 0.35,
      controlPoints: [
        [size.width * 0.3, size.height * 0.33],
        [size.width * 0.5, size.height * 0.36],
      ],
    );

    _drawContourLine(
      canvas,
      paint,
      size,
      startX: size.width * 0.5,
      startY: size.height * 0.65,
      controlPoints: [
        [size.width * 0.7, size.height * 0.63],
        [size.width * 0.9, size.height * 0.66],
      ],
    );
  }

  void _drawContourLine(
    Canvas canvas,
    Paint paint,
    Size size, {
    required double startX,
    required double startY,
    required List<List<double>> controlPoints,
  }) {
    final path = Path();
    path.moveTo(startX, startY);

    // Create smooth flowing curves through all control points
    for (int i = 0; i < controlPoints.length - 1; i += 2) {
      if (i + 1 < controlPoints.length) {
        path.quadraticBezierTo(
          controlPoints[i][0],
          controlPoints[i][1],
          controlPoints[i + 1][0],
          controlPoints[i + 1][1],
        );
      } else {
        // If odd number of points, just line to the last one
        path.lineTo(controlPoints[i][0], controlPoints[i][1]);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SubtleTopographicPainter oldDelegate) => false;
}

/// Premium branded header widget - refined and sleek
class BrandedGolfHeader extends StatelessWidget {
  final String username;
  final String courseName;

  const BrandedGolfHeader({
    Key? key,
    required this.username,
    required this.courseName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CurvedHeaderClipper(),
      child: Container(
        height: 150, // Reduced from 200px for sleeker look
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B3A2F), // Deep forest green
              Color(0xFF2D5F4C), // Rich medium green
              Color(0xFF1E4438), // Accent darker tone
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle topographic pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: SubtleTopographicPainter(
                  color: Colors.white,
                  opacity: 0.12, // Very subtle, atmospheric
                ),
              ),
            ),

            // Subtle radial gradient overlay for depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Text content - positioned for new height
            Positioned(
              bottom: 20, // Adjusted for new curved bottom
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Username - bottom left
                  Flexible(
                    flex: 2,
                    child: Text(
                      username,
                      style: TextStyle(
                        fontSize: 26, // Slightly smaller for compact header
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(width: 12),

                  // Course name - bottom right
                  Flexible(
                    flex: 3,
                    child: Text(
                      courseName,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15, // Slightly smaller for compact header
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.2,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle highlight along top edge
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameJoinedDetailedWidget extends StatefulWidget {
  const GameJoinedDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'GameJoinedDetailed';
  static String routePath = '/gameJoinedDetailed';

  @override
  State<GameJoinedDetailedWidget> createState() =>
      _GameJoinedDetailedWidgetState();
}

class _GameJoinedDetailedWidgetState extends State<GameJoinedDetailedWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GamesRecord>(
      stream: GamesRecord.getDocument(widget.gameRef!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTheme.of(context).secondaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: SpinKitWanderingCubes(
                  color: AppTheme.of(context).secondary,
                  size: 50.0,
                ),
              ),
            ),
          );
        }

        final gameJoinedDetailedGamesRecord = snapshot.data!;

        return Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                } else {
                  router.go('/');
                }
              },
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.of(context).primary,
                size: 32.0,
              ),
            ),
            title: Text(
              'Joined Game',
              style: AppTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          AppTheme.of(context).headlineSmall.fontStyle,
                    ),
                    color: AppTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        AppTheme.of(context).headlineSmall.fontStyle,
                  ),
            ),
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: FairwayBackgroundDark(
            showOrganic: true,
            showTexture: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branded header with abstract golf pattern
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: BrandedGolfHeader(
                      username: gameJoinedDetailedGamesRecord.nameGame,
                      courseName: gameJoinedDetailedGamesRecord.coursePlay,
                    ),
                  ),
                  // Date/Time Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.fairway.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.fairwayLight.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '📅',
                            style: TextStyle(fontSize: 24.0),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _formatDateTime(gameJoinedDetailedGamesRecord.date),
                              style: AppTheme.of(context).bodyLarge.override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: AppTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: AppTheme.of(context)
                                        .bodyLarge
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.md),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Game Details Section Header
                        Text(
                          'Game Details',
                          style: AppTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .headlineSmall
                                    .fontStyle,
                              ),
                        ),
                        SizedBox(height: AppSpacing.sm),

                        // 2x3 Grid of Info Cards
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 2.5,
                          children: [
                            _buildInfoCard(
                              context,
                              icon: '💰',
                              label: 'Betting',
                              value: gameJoinedDetailedGamesRecord.styleGame,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '📋',
                              label: 'Rule Style',
                              value: gameJoinedDetailedGamesRecord.rulesSetting,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '⛳',
                              label: 'Game Type',
                              value: gameJoinedDetailedGamesRecord.gameType,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '📊',
                              label: 'Scoring',
                              value: gameJoinedDetailedGamesRecord.scoring,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '💬',
                              label: 'Member Discount',
                              value: gameJoinedDetailedGamesRecord.memberDiscount,
                            ),
                            _buildInfoCard(
                              context,
                              icon: '👥',
                              label: 'Friends Only',
                              value: gameJoinedDetailedGamesRecord.friendGame,
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.lg),

                        // Players Section Header
                        Text(
                          'Players (${_getPlayerCount(gameJoinedDetailedGamesRecord)}/4)',
                          style: AppTheme.of(context).headlineSmall.override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .headlineSmall
                                    .fontStyle,
                              ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                  // Players horizontal cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Builder(
                      builder: (context) {
                        final groupPlayers = gameJoinedDetailedGamesRecord
                            .joinedPlayers
                            .toList();
                        final guestPlayers = gameJoinedDetailedGamesRecord
                            .guestPlayers
                            .where((name) => name.trim().isNotEmpty)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Registered players
                            ...List.generate(groupPlayers.length,
                                (groupPlayersIndex) {
                              final groupPlayersItem =
                                  groupPlayers[groupPlayersIndex];
                              return Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: StreamBuilder<UsersRecord>(
                                  stream: UsersRecord.getDocument(
                                      groupPlayersItem),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 40.0,
                                          height: 40.0,
                                          child: SpinKitWanderingCubes(
                                            color: AppTheme.of(context).secondary,
                                            size: 40.0,
                                          ),
                                        ),
                                      );
                                    }

                                    final friend1UsersRecord = snapshot.data!;

                                    return InkWell(
                                      onTap: () async {
                                        context.pushNamed(
                                          ProfileUserWidget.routeName,
                                          queryParameters: {
                                            'userRef': serializeParam(
                                              friend1UsersRecord,
                                              ParamType.Document,
                                            ),
                                          }.withoutNulls,
                                          extra: <String, dynamic>{
                                            'userRef': friend1UsersRecord,
                                            kTransitionInfoKey: TransitionInfo(
                                              hasTransition: true,
                                              transitionType:
                                                  PageTransitionType.bottomToTop,
                                              duration:
                                                  Duration(milliseconds: 220),
                                            ),
                                          },
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: AppColors.fairway.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.fairwayLight.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 48.0,
                                              height: 48.0,
                                              decoration: BoxDecoration(
                                                color: AppColors.fairwayLight,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.sunsetGold,
                                                  width: 2.0,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Image.network(
                                                friend1UsersRecord.photoUrl != ''
                                                    ? friend1UsersRecord.photoUrl
                                                    : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Image.asset(
                                                  'assets/images/error_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: AppSpacing.sm),
                                            // Name and ready status
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    friend1UsersRecord.displayName,
                                                    style: AppTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          font: GoogleFonts.outfit(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                AppTheme.of(context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    'Ready',
                                                    style: AppTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts.outfit(
                                                            fontWeight:
                                                                FontWeight.normal,
                                                            fontStyle:
                                                                AppTheme.of(context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: AppColors.sunsetGold,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Checkmark icon
                                            Icon(
                                              Icons.check_circle,
                                              color: AppColors.sunsetGold,
                                              size: 24.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                            // Guest players
                            ...guestPlayers.map(
                              (guestName) => Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.fairway.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.fairwayLight.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar placeholder
                                      Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: AppColors.fairwayLight.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'G',
                                            style: AppTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  font: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Colors.white,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: AppTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      // Name and guest label
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              guestName,
                                              style: AppTheme.of(context)
                                                  .bodyLarge
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodyLarge
                                                            .fontStyle,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Guest',
                                              style: AppTheme.of(context)
                                                  .bodySmall
                                                  .override(
                                                    font: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white.withValues(alpha: 0.7),
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(context)
                                                            .bodySmall
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
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  // Leave game button (for non-owner)
                  if (gameJoinedDetailedGamesRecord.userRef !=
                      currentUserReference)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButton(
                        onPressed: () async {
                          await widget.gameRef!.update({
                            ...mapToFirestore(
                              {
                                'joined_players': FieldValue.arrayRemove(
                                    [currentUserReference]),
                              },
                            ),
                          });
                          await showDialog(
                            context: context,
                            builder: (alertDialogContext) {
                              return AlertDialog(
                                title: Text('Success'),
                                content: Text('Leave the game successfully'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(alertDialogContext),
                                    child: Text('Ok'),
                                  ),
                                ],
                              );
                            },
                          );

                          context.pushNamed(GamesListWidget.routeName);
                        },
                        text: 'Leave game',
                        options: AppButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsets.zero,
                          iconPadding: EdgeInsets.zero,
                          color: Colors.transparent,
                          textStyle: AppTheme.of(context)
                              .bodyLarge
                              .override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                                color: AppColors.error,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  // Cancel game button (for owner)
                  if (gameJoinedDetailedGamesRecord.userRef ==
                      currentUserReference)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppButton(
                        onPressed: () async {
                          var confirmDialogResponse = await showDialog<bool>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: Text('Are  you sure?'),
                                    content: Text(
                                        'Do you really cancel the game?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            alertDialogContext, false),
                                        child: Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            alertDialogContext, true),
                                        child: Text('Yes'),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                          if (confirmDialogResponse) {
                            await widget.gameRef!
                                .update(createGamesRecordData(
                              isCancelled: true,
                            ));
                            if (gameJoinedDetailedGamesRecord.chatRef !=
                                    null &&
                                currentUserReference != null) {
                              final gameName =
                                  gameJoinedDetailedGamesRecord.nameGame;
                              final cancelMessage = (gameName != null &&
                                      gameName.trim().isNotEmpty)
                                  ? 'Game "$gameName" has been cancelled.'
                                  : 'This game has been cancelled.';
                              await ChatMessagesRecord.collection.add(
                                createChatMessagesRecordData(
                                  user: currentUserReference,
                                  chat: gameJoinedDetailedGamesRecord.chatRef,
                                  text: cancelMessage,
                                  timestamp: getCurrentTimestamp,
                                ),
                              );
                            }
                            await showDialog(
                              context: context,
                              builder: (alertDialogContext) {
                                return AlertDialog(
                                  title: Text('Success'),
                                  content:
                                      Text('Game cancelled successfully'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(alertDialogContext),
                                      child: Text('Ok'),
                                    ),
                                  ],
                                );
                              },
                            );

                            context.pushNamed(GamesListWidget.routeName);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        text: 'Cancel game',
                        options: AppButtonOptions(
                          width: double.infinity,
                          height: 56.0,
                          padding: EdgeInsets.zero,
                          iconPadding: EdgeInsets.zero,
                          color: Colors.transparent,
                          textStyle: AppTheme.of(context)
                              .bodyLarge
                              .override(
                                font: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: AppTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                                color: AppColors.error,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: AppTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                          elevation: 0.0,
                          borderSide: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to format date/time
  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Date not set';
    final formatter = DateFormat('EEEE, MMMM d • HH:mm');
    return formatter.format(date);
  }

  // Helper method to build info card
  Widget _buildInfoCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fairway.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fairwayLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.of(context).labelSmall.override(
                        font: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              AppTheme.of(context).labelSmall.fontStyle,
                        ),
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            AppTheme.of(context).labelSmall.fontStyle,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: AppTheme.of(context).bodyMedium.fontStyle,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to get player count
  int _getPlayerCount(GamesRecord gameRecord) {
    final joinedCount = gameRecord.joinedPlayers.length;
    final guestCount = gameRecord.guestPlayers
        .where((name) => name.trim().isNotEmpty)
        .length;
    return joinedCount + guestCount;
  }
}
