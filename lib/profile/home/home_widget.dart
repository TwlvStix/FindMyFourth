import '/core/widgets/app_icon_button.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/profile/main_profile/main_profile_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'Home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Align(
            alignment: AlignmentDirectional(-1.0, 0.0),
            child: Text(
              'Find My 4th',
              textAlign: TextAlign.center,
              style: AppTheme.of(context).headlineSmall.override(
                    font: GoogleFonts.outfit(
                      fontWeight:
                          AppTheme.of(context).headlineSmall.fontWeight,
                      fontStyle:
                          AppTheme.of(context).headlineSmall.fontStyle,
                    ),
                    color: AppTheme.of(context).primary,
                    letterSpacing: 0.0,
                    fontWeight:
                        AppTheme.of(context).headlineSmall.fontWeight,
                    fontStyle:
                        AppTheme.of(context).headlineSmall.fontStyle,
                  ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 15.0, 0.0),
              child: AppIconButton(
                borderColor: AppTheme.of(context).primaryBackground,
                borderRadius: 20.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: AppTheme.of(context).primaryBackground,
                icon: Icon(
                  Icons.person_outline_outlined,
                  color: AppTheme.of(context).primary,
                  size: 30.0,
                ),
                onPressed: () async {
                  context.pushNamed(
                    MainProfileWidget.routeName,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                        duration: Duration(milliseconds: 200),
                      ),
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
              child: AppIconButton(
                borderColor: AppTheme.of(context).primaryBackground,
                borderRadius: 20.0,
                borderWidth: 1.0,
                buttonSize: 40.0,
                fillColor: AppTheme.of(context).primaryBackground,
                icon: Icon(
                  Icons.search_sharp,
                  color: AppTheme.of(context).primary,
                  size: 26.0,
                ),
                onPressed: () async {
                  context.pushNamed(
                    TabFriendsWidget.routeName,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                        duration: Duration(milliseconds: 200),
                      ),
                    },
                  );
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 10.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0.0),
                  child: Image.asset(
                    'assets/images/igdownloader.com_3046829577184117896.jpg',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
