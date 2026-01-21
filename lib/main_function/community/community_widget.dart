import '/core/button_tabbar.dart';
import '/core/widgets/fairway_background.dart';
import '/core/app_theme.dart';
import '/core/design_tokens/spacing.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/chat_group/chat/chat_widget.dart';
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
      length: 1,
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Chats',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 56),
                // Header section with glass effect
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.fairway.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    'Group chats and DMs with golfers',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                // Tabs with glass morphism style
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.fairway.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: AppButtonTabBar(
                      useToggleButtonStyle: false,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: AppTypography.labelMedium,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      backgroundColor: AppColors.sunsetGold,
                      unselectedBackgroundColor: Colors.transparent,
                      borderColor: AppColors.sunsetGold,
                      unselectedBorderColor: Colors.transparent,
                      borderWidth: 0,
                      borderRadius: 10.0,
                      elevation: 0.0,
                      labelPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      buttonMargin: EdgeInsets.all(AppSpacing.xxs),
                      padding: AppSpacing.allXxs,
                      tabs: [
                        Tab(text: 'Chats'),
                      ],
                      controller: _tabBarController,
                      onTap: (i) async {
                        [() async {}][i]();
                      },
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                // Content area
                Expanded(
                  child: TabBarView(
                    controller: _tabBarController,
                    children: [
                      // Chats Tab
                      KeepAliveWidgetWrapper(
                        builder: (context) => ChatWidget(isEmbedded: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
