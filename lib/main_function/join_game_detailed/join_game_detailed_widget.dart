import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/date_format_widget.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/utils/app_util.dart';
import '/core/widgets/app_button.dart';
import '/core/design_tokens/spacing.dart';
import '/main_function/join_game/join_game_widget.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
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

class JoinGameDetailedWidget extends StatefulWidget {
  const JoinGameDetailedWidget({
    super.key,
    this.gameRef,
  });

  final DocumentReference? gameRef;

  static String routeName = 'JoinGameDetailed';
  static String routePath = '/joinGameDetailed';

  @override
  State<JoinGameDetailedWidget> createState() => _JoinGameDetailedWidgetState();
}

class _JoinGameDetailedWidgetState extends State<JoinGameDetailedWidget> {
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

        final joinGameDetailedGamesRecord = snapshot.data!;

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
              'Join Game',
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
            child: AuthUserStreamWidget(
              builder: (context) {
                final isCreatorFriend =
                    currentUserDocument?.friends.contains(
                          joinGameDetailedGamesRecord.userRef,
                        ) ??
                        false;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branded header with abstract golf pattern
                      Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: BrandedGolfHeader(
                          username: joinGameDetailedGamesRecord.nameGame,
                          courseName: joinGameDetailedGamesRecord.coursePlay,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateFormatWidget(
                              date: joinGameDetailedGamesRecord.date,
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 10.0, 0.0, 0.0),
                              child: Text(
                                'Game Details:',
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
                                      color: Colors.white,
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
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .styleGame,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Betting\n',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .rulesSetting,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Rule\nStyle',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .gameType,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Game\nType',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .scoring,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Scoring\n',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .memberDiscount,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Member\nDiscount',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 12.0, 0.0, 12.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            width: 64.0,
                                            height: 64.0,
                                            decoration: BoxDecoration(
                                              color: AppTheme.of(context).primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    AppTheme.of(context)
                                                        .primaryBtnText,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Container(
                                              width: 64.0,
                                              height: 64.0,
                                              child: custom_widgets
                                                  .DynamicTextSize(
                                                width: 64.0,
                                                height: 64.0,
                                                text:
                                                    joinGameDetailedGamesRecord
                                                        .friendGame,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 8.0, 0.0, 0.0),
                                            child: Text(
                                              'Friends\nOnly?',
                                              textAlign: TextAlign.center,
                                              style: AppTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.lexendDeca(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                                    color: Colors.white,
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        AppTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                      .divide(SizedBox(width: 10.0))
                                      .addToStart(SizedBox(width: 10.0))
                                      .addToEnd(SizedBox(width: 10.0)),
                                ),
                              ),
                            ),
                            Divider(
                              height: 32.0,
                              thickness: 1.0,
                              color: AppTheme.of(context).alternate,
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 0.0),
                              child: Text(
                                'Players in this Group:',
                                style: AppTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontStyle: AppTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: AppTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 0.0, 8.0),
                        child: Container(
                          height: 120.0,
                          decoration: BoxDecoration(),
                          child: Builder(
                            builder: (context) {
                              final groupPlayers = joinGameDetailedGamesRecord
                                  .joinedPlayers
                                  .toList();
                              final guestPlayers = joinGameDetailedGamesRecord
                                  .guestPlayers
                                  .where((name) => name.trim().isNotEmpty)
                                  .toList();
                              final gameOwner =
                                  joinGameDetailedGamesRecord.userRef;
                              if (gameOwner != null &&
                                  !groupPlayers.contains(gameOwner)) {
                                groupPlayers.insert(0, gameOwner);
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    ...List.generate(groupPlayers.length,
                                        (groupPlayersIndex) {
                                      final groupPlayersItem =
                                          groupPlayers[groupPlayersIndex];
                                      return Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 12.0, 0.0, 12.0),
                                        child: StreamBuilder<UsersRecord>(
                                          stream: UsersRecord.getDocument(
                                              groupPlayersItem),
                                          builder: (context, snapshot) {
                                            // Customize what your widget looks like when it's loading.
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: SizedBox(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  child: SpinKitWanderingCubes(
                                                    color: AppTheme.of(context).secondary,
                                                    size: 50.0,
                                                  ),
                                                ),
                                              );
                                            }

                                            final friend1UsersRecord =
                                                snapshot.data!;

                                            return Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Container(
                                                  width: 64.0,
                                                  height: 64.0,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.of(context)
                                                            .info,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: AppTheme.of(context).tertiary,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(4.0),
                                                    child: InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        context.pushNamed(
                                                          ProfileUserWidget
                                                              .routeName,
                                                          queryParameters: {
                                                            'userRef':
                                                                serializeParam(
                                                              friend1UsersRecord,
                                                              ParamType.Document,
                                                            ),
                                                          }.withoutNulls,
                                                          extra: <String,
                                                              dynamic>{
                                                            'userRef':
                                                                friend1UsersRecord,
                                                            kTransitionInfoKey:
                                                                TransitionInfo(
                                                              hasTransition:
                                                                  true,
                                                              transitionType:
                                                                  PageTransitionType
                                                                      .bottomToTop,
                                                              duration: Duration(
                                                                  milliseconds:
                                                                      220),
                                                            ),
                                                          },
                                                        );
                                                      },
                                                      child: Container(
                                                        width: 70.0,
                                                        height: 70.0,
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Image.network(
                                                          valueOrDefault<String>(
                                                            friend1UsersRecord
                                                                .photoUrl,
                                                            'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                                                          ),
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                      stackTrace) =>
                                                                  Image.asset(
                                                            'assets/images/error_image.png',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 8.0, 0.0, 0.0),
                                                  child: Text(
                                                    friend1UsersRecord
                                                        .displayName,
                                                    textAlign: TextAlign.center,
                                                    style: AppTheme.of(context)
                                                        .bodySmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .lexendDeca(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                AppTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: Colors.white,
                                                          fontSize: 14.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                    ...guestPlayers.map(
                                      (guestName) => Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 12.0, 0.0, 12.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 64.0,
                                              height: 64.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    AppTheme.of(context).info,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.of(context).tertiary,
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'G',
                                                  style: AppTheme.of(context)
                                                      .titleMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.outfit(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              AppTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: Colors.white,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            AppTheme.of(
                                                                    context)
                                                                .titleMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 8.0, 0.0, 0.0),
                                              child: Text(
                                                guestName,
                                                textAlign: TextAlign.center,
                                                style: AppTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts
                                                          .lexendDeca(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            AppTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Colors.white,
                                                      fontSize: 14.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          AppTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
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
                            },
                          ),
                        ),
                      ),
                      if (joinGameDetailedGamesRecord.userRef !=
                          currentUserReference)
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 8.0),
                            child: AppButton(
                              onPressed: () async {
                                if ((joinGameDetailedGamesRecord.maxPlayers >
                                        (joinGameDetailedGamesRecord
                                                .joinedPlayers.length +
                                            joinGameDetailedGamesRecord
                                                .guestPlayers.length)) &&
                                    ((joinGameDetailedGamesRecord.friendGame ==
                                            'Public') ||
                                        ((joinGameDetailedGamesRecord
                                                    .friendGame ==
                                                'Friends') &&
                                            isCreatorFriend))) {
                                  await showModalBottomSheet(
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    enableDrag: false,
                                    context: context,
                                    builder: (context) {
                                      return Padding(
                                        padding:
                                            MediaQuery.viewInsetsOf(context),
                                        child: JoinGameWidget(
                                          gameRef: joinGameDetailedGamesRecord,
                                        ),
                                      );
                                    },
                                  ).then((value) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                } else {
                                  await showDialog(
                                    context: context,
                                    builder: (alertDialogContext) {
                                      return AlertDialog(
                                        title: Text('Sorry!'),
                                        content: Text(
                                            'You are not friends with the game creator or the group  is full.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                alertDialogContext),
                                            child: Text('Ok'),
                                          ),
                                        ],
                                        );
                                    },
                                  );
                                }
                              },
                              text: 'Reserve Spot',
                              options: AppButtonOptions(
                                width: 300.0,
                                height: 60.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: AppTheme.of(context).primary,
                                textStyle: AppTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: AppTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: AppTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      fontWeight: AppTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: AppTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                                elevation: 3.0,
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(40.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
