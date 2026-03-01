import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '/core/design_tokens/app_phosphor_icons.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import '/core/navigation/app_router.dart';
import '/core/widgets/app_icon.dart';
import '/friends/tab_friends/tab_friends_widget.dart';
import '/main_function/community/community_widget.dart';
import '/main_function/games_joined/games_joined_widget.dart';
import '/main_function/games_list/games_list_widget.dart';

import '/profile/main_profile/main_profile_widget.dart';

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'GamesList';
  late Widget? _currentPage;

  // ✅ PERFORMANCE: Create tab widgets once, reuse via IndexedStack
  late final List<Widget> _tabs = [
    GamesListWidget(),
    GamesJoinedWidget(),
    TabFriendsWidget(),
    CommunityWidget(),
    MainProfileWidget(),
  ];

  // Map tab names to indices for backward compatibility
  static const Map<String, int> _tabIndices = {
    'GamesList': 0,
    'GamesJoined': 1,
    'Golfers': 2,
    'Community': 3,
    'Profile': 4,
  };

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabIndices[_currentPageName] ?? 0;

    // Only show FAB on GamesList and GamesJoined (My Games) tabs
    final shouldShowFab =
        _currentPageName == 'GamesList' || _currentPageName == 'GamesJoined';

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      // ✅ PERFORMANCE: IndexedStack preserves state and avoids rebuilds
      body: _currentPage ??
          IndexedStack(
            index: currentIndex,
            children: _tabs,
          ),
      floatingActionButton: shouldShowFab
          ? FloatingActionButton(
              onPressed: () {
                context.pushCreateGame();
              },
              backgroundColor: AppColors.navyDark,
              elevation: 8.0,
              child: AppIcon(
                icon: AppPhosphorIcons.add,
                color: AppColors.pure,
                size: AppIconSize.lg,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: GNav(
        selectedIndex: currentIndex,
        onTabChange: (i) {
          if (mounted) {
            setState(() {
              _currentPage = null;
              // ✅ PERFORMANCE: Direct index to name mapping
              _currentPageName = _tabIndices.keys.elementAt(i);
            });
          }
        },
        backgroundColor: AppColors.navyDark,
        color: AppColors.textMuted,
        activeColor: AppColors.green,
        tabBackgroundColor: Colors.transparent,
        tabBorderRadius: 0.0,
        tabMargin: EdgeInsets.all(AppSpacing.xxs),
        padding: EdgeInsets.all(AppSpacing.sm),
        gap: 0.0,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        duration:
            Duration.zero, // Instant tab switching per premium motion system
        haptic: false,
        tabs: [
          GButton(
            leading: AppNavIcon(
              icon: AppPhosphorIcons.games,
              iconFill: AppPhosphorIcons.gamesFill,
              size: AppIconSize.lg,
              isActive: currentIndex == 0,
              activeColor: AppColors.green,
              inactiveColor: AppColors.textMuted,
            ),
            icon: AppPhosphorIcons.games, // Fallback (hidden)
            iconSize: 0, // Hide default icon
          ),
          GButton(
            leading: AppNavIcon(
              icon: AppPhosphorIcons.myGames,
              iconFill: AppPhosphorIcons.myGamesFill,
              size: AppIconSize.lg,
              isActive: currentIndex == 1,
              activeColor: AppColors.green,
              inactiveColor: AppColors.textMuted,
            ),
            icon: AppPhosphorIcons.myGames, // Fallback (hidden)
            iconSize: 0, // Hide default icon
          ),
          GButton(
            leading: AppNavIcon(
              icon: AppPhosphorIcons.golfers,
              iconFill: AppPhosphorIcons.golfersFill,
              size: AppIconSize.lg,
              isActive: currentIndex == 2,
              activeColor: AppColors.green,
              inactiveColor: AppColors.textMuted,
            ),
            icon: AppPhosphorIcons.golfers, // Fallback (hidden)
            iconSize: 0, // Hide default icon
          ),
          GButton(
            leading: AppNavIcon(
              icon: AppPhosphorIcons.chat,
              iconFill: AppPhosphorIcons.chatFill,
              size: AppIconSize.lg,
              isActive: currentIndex == 3,
              activeColor: AppColors.green,
              inactiveColor: AppColors.textMuted,
            ),
            icon: AppPhosphorIcons.chat, // Fallback (hidden)
            iconSize: 0, // Hide default icon
          ),
          GButton(
            leading: AppNavIcon(
              icon: AppPhosphorIcons.profile,
              iconFill: AppPhosphorIcons.profileFill,
              size: AppIconSize.lg,
              isActive: currentIndex == 4,
              activeColor: AppColors.green,
              inactiveColor: AppColors.textMuted,
            ),
            icon: AppPhosphorIcons.profile, // Fallback (hidden)
            iconSize: 0, // Hide default icon
          )
        ],
      ),
    );
  }
}
