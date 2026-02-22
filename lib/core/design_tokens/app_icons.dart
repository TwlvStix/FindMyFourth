/// Golf App SVG Icon Assets
///
/// A unified icon system using custom SVG icons with consistent
/// 1.75px stroke weight, round caps/joins, and 24x24 grid.
///
/// All icons use `currentColor` for dynamic theming via colorFilter.
///
/// Usage:
/// ```dart
/// AppIcon(
///   assetPath: AppIcons.games,
///   size: AppIconSize.md,
///   color: AppColors.navy,
/// )
/// ```
///
/// TODO: These Material Icons are used in the codebase but need SVG equivalents:
/// - Icons.chevron_right_rounded → AppIcons.chevronRight (trailing navigation)
/// - Icons.error_outline → AppIcons.error (error state)
/// - Icons.star_rounded → AppIcons.star (favorite/rating)
/// - Icons.check_box_outlined → AppIcons.checkboxChecked (checkbox checked)
/// - Icons.check_box_outline_blank → AppIcons.checkboxUnchecked (checkbox unchecked)
/// - Icons.hourglass_top_rounded → (already have AppIcons.pending)
/// - Icons.pause_circle_outline_rounded → AppIcons.paused (paused state)
/// - Icons.block_rounded → AppIcons.blocked (blocked state)
/// - Icons.gpp_bad_rounded → AppIcons.securityWarning (security issue)
/// - Icons.golf_course_rounded → AppIcons.golfCourse (golf course icon)
/// - Icons.check_circle_outline_rounded → AppIcons.checkCircle (confirmed)
/// - Icons.sports_golf_rounded → AppIcons.golfBall (golf sport icon)
/// - Icons.flag_rounded → AppIcons.flag (flag marker)
/// - Icons.verified_rounded → AppIcons.verified (verified badge)
/// - Icons.warning_amber_rounded → AppIcons.warning (warning state)
class AppIcons {
  AppIcons._();

  static const String _basePath = 'assets/icon/golf-app-icons';

  // ════════════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Games tab - Flag with golf ball
  static const String games = '$_basePath/games_flag_ball.svg';

  /// My Games tab - Calendar
  static const String myGames = '$_basePath/my_games_calendar.svg';

  /// Golfers tab - Two people
  static const String golfers = '$_basePath/golfers_people.svg';

  /// Chat tab - Message bubble
  static const String chat = '$_basePath/chat_message.svg';

  /// Profile tab - Person silhouette
  static const String profile = '$_basePath/profile_person.svg';

  /// Notifications - Bell
  static const String notifications = '$_basePath/notifications_bell.svg';

  /// Back navigation - Left chevron arrow
  static const String back = '$_basePath/back_arrow.svg';

  /// Search - Magnifying glass
  static const String search = '$_basePath/search.svg';

  // ════════════════════════════════════════════════════════════════════════════
  // GAME SETUP & DETAILS
  // ════════════════════════════════════════════════════════════════════════════

  /// Betting/Stakes - Dollar sign
  static const String betting = '$_basePath/betting_stakes_dollar.svg';

  /// Rule Style - Sliders/settings
  static const String ruleStyle = '$_basePath/rule_style_sliders.svg';

  /// Game Type - Ball on tee
  static const String gameType = '$_basePath/game_type_tee_ball.svg';

  /// Scoring - Scorecard
  static const String scoring = '$_basePath/scoring_scorecard.svg';

  /// Visibility - Eye
  static const String visibility = '$_basePath/visibility_eye.svg';

  /// Member Discount - Price tag
  static const String memberDiscount = '$_basePath/member_discount_tag.svg';

  /// Tee Time - Clock
  static const String teeTime = '$_basePath/tee_time_clock.svg';

  /// Course - Location pin
  static const String course = '$_basePath/course_location_pin.svg';

  /// Add Player - Person with plus
  static const String addPlayer = '$_basePath/add_player.svg';

  /// Public Visibility - Globe
  static const String publicVisibility = '$_basePath/public_globe.svg';

  /// Confirm - Checkbox with checkmark
  static const String confirm = '$_basePath/confirm_checkbox.svg';

  /// Calendar Check - Calendar with checkmark
  static const String calendarCheck = '$_basePath/calendar_check.svg';

  // ════════════════════════════════════════════════════════════════════════════
  // FORMATS & GAME MODES
  // ════════════════════════════════════════════════════════════════════════════

  /// Stroke Play - Scorecard with columns
  static const String strokePlay = '$_basePath/stroke_play.svg';

  /// Match Play - VS badge (contains text element)
  static const String matchPlay = '$_basePath/match_play_vs.svg';

  /// Stableford - Star
  static const String stableford = '$_basePath/stableford_star.svg';

  /// Skins - Stacked layers
  static const String skins = '$_basePath/skins_layers.svg';

  /// Vegas - Dice
  static const String vegas = '$_basePath/vegas_dice.svg';

  /// Nassau - Three sections (F9/B9/18, contains text elements)
  static const String nassau = '$_basePath/nassau.svg';

  /// Wolf - Wolf ears silhouette
  static const String wolf = '$_basePath/wolf.svg';

  /// Teams 2v2 - Four dots with divider
  static const String teams2v2 = '$_basePath/teams_2v2.svg';

  /// Handicap - Chart/graph
  static const String handicap = '$_basePath/handicap_chart.svg';

  /// BBB (Best Ball) - Three balls
  static const String bbb = '$_basePath/bbb_three_balls.svg';

  /// 6-6-6 - Grid pattern
  static const String sixSixSix = '$_basePath/six_six_six_grid.svg';

  /// Dots - Five dots pattern
  static const String dots = '$_basePath/dots.svg';

  /// Other/Custom - Pencil edit
  static const String otherCustom = '$_basePath/other_custom_edit.svg';

  // ════════════════════════════════════════════════════════════════════════════
  // VIBE & STAKES
  // ════════════════════════════════════════════════════════════════════════════

  /// Competitive - Trophy
  static const String competitive = '$_basePath/competitive_trophy.svg';

  /// Casual - Sunshine
  static const String casual = '$_basePath/casual_sunshine.svg';

  /// No Money - Heart
  static const String noMoney = '$_basePath/no_money_heart.svg';

  /// Low Stakes - Single dollar sign
  static const String lowStakes = '$_basePath/low_stakes_dollar.svg';

  /// High Stakes - Double dollar sign
  static const String highStakes = '$_basePath/high_stakes_double_dollar.svg';

  /// Game Vibe - Smiley face
  static const String gameVibe = '$_basePath/game_vibe_face.svg';

  /// Vibe Match - Target/crosshair
  static const String vibeMatch = '$_basePath/vibe_match_target.svg';

  // ════════════════════════════════════════════════════════════════════════════
  // PROFILE & SETTINGS
  // ════════════════════════════════════════════════════════════════════════════

  /// Edit Profile - Person with pencil
  static const String editProfile = '$_basePath/edit_profile.svg';

  /// Golf Vibes/Preferences - Horizontal sliders
  static const String golfVibes = '$_basePath/golf_vibes_preferences.svg';

  /// Camera - Camera icon
  static const String camera = '$_basePath/camera.svg';

  /// Email - Envelope
  static const String email = '$_basePath/email.svg';

  /// Phone - Phone handset
  static const String phone = '$_basePath/phone.svg';

  /// Standing/Trust - Shield with checkmark
  static const String standing = '$_basePath/standing_trust_shield.svg';

  /// Golf Canada Badge - Medal/badge
  static const String golfCanada = '$_basePath/golf_canada_badge.svg';

  /// Log Out - Exit arrow
  static const String logOut = '$_basePath/log_out.svg';

  /// Rounds Completed - Circle with 18 (contains text element)
  static const String rounds = '$_basePath/rounds_completed_18.svg';

  /// Hosted - Flag with plus
  static const String hosted = '$_basePath/hosted_flag_plus.svg';

  /// Unique Players - Person in diamond
  static const String uniquePlayers = '$_basePath/unique_players_diamond.svg';

  /// Requests - Inbox with arrow
  static const String requests = '$_basePath/requests_inbox.svg';

  /// Morning - Sunrise
  static const String morning = '$_basePath/morning_sunrise.svg';

  /// Afternoon - Sun
  static const String afternoon = '$_basePath/afternoon_sun.svg';

  /// Twilight - Sunset
  static const String twilight = '$_basePath/twilight_sunset.svg';

  /// Joined/Success - Circle with checkmark
  static const String joined = '$_basePath/joined_success.svg';

  /// Owner - Filled star
  static const String owner = '$_basePath/owner_star.svg';

  /// Remove - Circle with minus
  static const String remove = '$_basePath/remove_minus.svg';

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY
  // ════════════════════════════════════════════════════════════════════════════

  /// Settings - Gear
  static const String settings = '$_basePath/settings_gear.svg';

  /// Close - X mark
  static const String close = '$_basePath/close_x.svg';

  /// Lock - Padlock
  static const String lock = '$_basePath/lock.svg';

  /// Pending - Hourglass
  static const String pending = '$_basePath/pending_hourglass.svg';

  /// Groups - Multiple people
  static const String groups = '$_basePath/groups.svg';
}
