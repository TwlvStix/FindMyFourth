import '/core/button_tabbar.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/chat_group/chat/chat_widget.dart';
import '/newsfeed/newsfeed/newsfeed_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityWidget extends StatefulWidget {
  const CommunityWidget({super.key});

  static String routeName = 'Community';
  static String routePath = '/community';

  @override
  State<CommunityWidget> createState() => _CommunityWidgetState();
}

class _CommunityWidgetState extends State<CommunityWidget>
    with TickerProviderStateMixin {
  TabController? _tabBarController;
  int get tabBarCurrentIndex =>
      _tabBarController != null ? _tabBarController!.index : 0;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabBarController?.dispose();
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
        backgroundColor: AppTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Community',
            style: AppTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                  ),
                  color: AppTheme.of(context).primary,
                  fontSize: 24.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: AppTheme.of(context).headlineLarge.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Share updates and connect with your golf community',
                  style: AppTheme.of(context).labelMedium.override(
                        font: GoogleFonts.outfit(
                          fontWeight: AppTheme.of(context).labelMedium.fontWeight,
                          fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: AppTheme.of(context).labelMedium.fontWeight,
                        fontStyle: AppTheme.of(context).labelMedium.fontStyle,
                      ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment(-1.0, 0),
                      child: AppButtonTabBar(
                        useToggleButtonStyle: false,
                        labelStyle: AppTheme.of(context).titleMedium.override(
                              font: GoogleFonts.outfit(
                                fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                                fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                              ),
                              fontSize: 16.0,
                              letterSpacing: 0.0,
                              fontWeight: AppTheme.of(context).titleMedium.fontWeight,
                              fontStyle: AppTheme.of(context).titleMedium.fontStyle,
                            ),
                        unselectedLabelStyle: TextStyle(),
                        labelColor: AppTheme.of(context).primaryBtnText,
                        unselectedLabelColor: AppTheme.of(context).secondaryText,
                        backgroundColor: AppTheme.of(context).primary,
                        unselectedBackgroundColor: AppTheme.of(context).alternate,
                        borderColor: AppTheme.of(context).primary,
                        unselectedBorderColor: AppTheme.of(context).alternate,
                        borderWidth: 2.0,
                        borderRadius: 8.0,
                        elevation: 0.0,
                        labelPadding: EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.sm, 0.0, AppSpacing.sm, 0.0),
                        buttonMargin: EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.xs, 0.0, AppSpacing.xs, 0.0),
                        padding: AppSpacing.allXxs,
                        tabs: [
                          Tab(text: 'Feed'),
                          Tab(text: 'Chats'),
                        ],
                        controller: _tabBarController,
                        onTap: (i) async {
                          [() async {}, () async {}][i]();
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabBarController,
                        children: [
                          // Feed Tab
                          KeepAliveWidgetWrapper(
                            builder: (context) => NewsfeedWidget(),
                          ),
                          // Chats Tab
                          KeepAliveWidgetWrapper(
                            builder: (context) => ChatWidget(),
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
    );
  }
}

// Keep alive widget wrapper to preserve tab state
class KeepAliveWidgetWrapper extends StatefulWidget {
  final Widget Function(BuildContext) builder;

  const KeepAliveWidgetWrapper({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<KeepAliveWidgetWrapper> createState() =>
      _KeepAliveWidgetWrapperState();
}

class _KeepAliveWidgetWrapperState extends State<KeepAliveWidgetWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context);
  }
}
