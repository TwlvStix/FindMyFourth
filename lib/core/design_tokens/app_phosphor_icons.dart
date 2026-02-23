import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Central Phosphor icon mapping for Find My Fourth.
///
/// ALL icon choices live here. Change an icon once → changes everywhere.
/// Browse the full catalog at https://phosphoricons.com
///
/// Conventions:
/// - Default: Regular weight (outlined, 1.5px stroke)
/// - Active/selected nav: Fill weight (solid)
/// - Name matches the concept, not the icon shape
///   (so if we swap "trophy" for "medal" later, call sites don't change)
///
/// Usage:
/// ```dart
/// AppIcon(
///   icon: AppPhosphorIcons.games,
///   size: AppIconSize.md,
///   color: AppColors.textSecondary,
/// )
/// ```
class AppPhosphorIcons {
  AppPhosphorIcons._();

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION — Regular (inactive) + Fill (active)
  // ══════════════════════════════════════════════════════════════════════════

  /// Games tab — flag
  static const games = PhosphorIconsRegular.flag;
  static const gamesFill = PhosphorIconsFill.flag;

  /// My Games tab — calendar
  static const myGames = PhosphorIconsRegular.calendarCheck;
  static const myGamesFill = PhosphorIconsFill.calendarCheck;

  /// Golfers tab — two people
  static const golfers = PhosphorIconsRegular.users;
  static const golfersFill = PhosphorIconsFill.users;

  /// Chat tab — message bubble
  static const chat = PhosphorIconsRegular.chatCircle;
  static const chatFill = PhosphorIconsFill.chatCircle;

  /// Profile tab — person
  static const profile = PhosphorIconsRegular.user;
  static const profileFill = PhosphorIconsFill.user;

  /// Notifications — bell
  static const notifications = PhosphorIconsRegular.bell;
  static const notificationsFill = PhosphorIconsFill.bell;

  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Back arrow
  static const back = PhosphorIconsRegular.arrowLeft;

  /// Search
  static const search = PhosphorIconsRegular.magnifyingGlass;

  /// Close / dismiss
  static const close = PhosphorIconsRegular.x;

  /// More options (vertical dots)
  static const more = PhosphorIconsRegular.dotsThreeVertical;

  /// Horizontal dots — secondary options / games list
  static const dots = PhosphorIconsRegular.dotsThreeOutline;

  /// Filter / funnel
  static const filter = PhosphorIconsRegular.funnel;

  /// Share
  static const share = PhosphorIconsRegular.shareFat;

  // ══════════════════════════════════════════════════════════════════════════
  // GAME SETUP & DETAILS
  // ══════════════════════════════════════════════════════════════════════════

  /// Betting / stakes — dollar sign
  static const betting = PhosphorIconsRegular.currencyDollar;

  /// Rule style — sliders
  static const ruleStyle = PhosphorIconsRegular.slidersHorizontal;

  /// Game type — golf hole (flag in ground)
  static const gameType = PhosphorIconsRegular.flagBanner;

  /// Scoring — chart / scorecard
  static const scoring = PhosphorIconsRegular.chartBar;

  /// Visibility — eye
  static const visibility = PhosphorIconsRegular.eye;

  /// Member discount — tag
  static const memberDiscount = PhosphorIconsRegular.tag;

  /// Tee time — clock
  static const teeTime = PhosphorIconsRegular.clock;

  /// Course — location pin
  static const course = PhosphorIconsRegular.mapPin;

  /// Add player — user plus
  static const addPlayer = PhosphorIconsRegular.userPlus;

  /// Public visibility — globe
  static const publicVisibility = PhosphorIconsRegular.globe;

  /// Friends only — lock
  static const friendsOnly = PhosphorIconsRegular.lockSimple;

  /// Confirm — check circle
  static const confirm = PhosphorIconsRegular.checkCircle;

  /// Calendar check
  static const calendarCheck = PhosphorIconsRegular.calendarCheck;

  // ══════════════════════════════════════════════════════════════════════════
  // GAME FORMATS & MODES
  // ══════════════════════════════════════════════════════════════════════════

  /// Stroke play — notepad / scorecard
  static const strokePlay = PhosphorIconsRegular.notepad;

  /// Match play — sword (head-to-head competition)
  static const matchPlay = PhosphorIconsRegular.sword;

  /// Stableford — star
  static const stableford = PhosphorIconsRegular.star;

  /// Skins — stack / layers
  static const skins = PhosphorIconsRegular.stack;

  /// Vegas — dice (gambling game)
  static const vegas = PhosphorIconsRegular.diceFive;

  /// Nassau — list numbers (three sections)
  static const nassau = PhosphorIconsRegular.listNumbers;

  /// Wolf — paw print
  static const wolf = PhosphorIconsRegular.pawPrint;

  /// Teams 2v2 — users four
  static const teams = PhosphorIconsRegular.usersFour;

  /// Handicap — chart line up
  static const handicap = PhosphorIconsRegular.chartLineUp;

  /// Best ball — circles three
  static const bestBall = PhosphorIconsRegular.circlesThree;

  /// 6-6-6 — grid four
  static const sixSixSix = PhosphorIconsRegular.gridFour;

  /// Other / custom — pencil
  static const otherCustom = PhosphorIconsRegular.pencilSimple;

  // ══════════════════════════════════════════════════════════════════════════
  // VIBE & STAKES
  // ══════════════════════════════════════════════════════════════════════════

  /// Competitive — trophy
  static const competitive = PhosphorIconsRegular.trophy;

  /// Casual — sun
  static const casual = PhosphorIconsRegular.sun;

  /// No money / just for fun — heart
  static const noMoney = PhosphorIconsRegular.heart;

  /// Low stakes — coin
  static const lowStakes = PhosphorIconsRegular.coin;

  /// High stakes — coins
  static const highStakes = PhosphorIconsRegular.coins;

  /// Game vibe — smiley
  static const gameVibe = PhosphorIconsRegular.smiley;

  /// Vibe match — target / crosshair
  static const vibeMatch = PhosphorIconsRegular.crosshair;

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE & SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  /// Edit profile — pencil
  static const editProfile = PhosphorIconsRegular.pencilSimpleLine;

  /// Golf vibes / preferences — sliders
  static const golfVibes = PhosphorIconsRegular.sliders;

  /// Camera
  static const camera = PhosphorIconsRegular.camera;

  /// Email — envelope
  static const email = PhosphorIconsRegular.envelope;

  /// Phone
  static const phone = PhosphorIconsRegular.phone;

  /// Settings — gear
  static const settings = PhosphorIconsRegular.gear;

  /// Log out — sign out
  static const logOut = PhosphorIconsRegular.signOut;

  /// Friends (profile context)
  static const friends = PhosphorIconsRegular.usersThree;

  /// Home course — map pin (same as course)
  static const homeCourse = PhosphorIconsRegular.mapPin;

  // ══════════════════════════════════════════════════════════════════════════
  // TRUST & ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Trust / standing — shield check
  static const trust = PhosphorIconsRegular.shieldCheck;

  /// Standing (alias for trust)
  static const standing = PhosphorIconsRegular.shieldCheck;

  /// Verified — seal check
  static const verified = PhosphorIconsRegular.sealCheck;

  /// Star / rating
  static const star = PhosphorIconsRegular.star;
  static const starFill = PhosphorIconsFill.star;

  /// Badge / medal
  static const badge = PhosphorIconsRegular.medal;

  /// Rounds completed — golf icon
  static const rounds = PhosphorIconsRegular.golf;

  /// Hosted — flag pennant
  static const hosted = PhosphorIconsRegular.flagPennant;

  /// Unique players — user focus
  static const uniquePlayers = PhosphorIconsRegular.userFocus;

  // ══════════════════════════════════════════════════════════════════════════
  // STATUS & ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Success / joined — check circle
  static const success = PhosphorIconsRegular.checkCircle;

  /// Joined indicator — check circle (alias for success)
  static const joined = PhosphorIconsRegular.checkCircle;

  /// Error — warning circle
  static const error = PhosphorIconsRegular.warningCircle;

  /// Info
  static const info = PhosphorIconsRegular.info;

  /// Warning — triangle
  static const warning = PhosphorIconsRegular.warning;

  /// Pending — hourglass
  static const pending = PhosphorIconsRegular.hourglass;

  /// Paused — pause circle
  static const paused = PhosphorIconsRegular.pauseCircle;

  /// Blocked — prohibit
  static const blocked = PhosphorIconsRegular.prohibit;

  /// Security warning — shield warning
  static const securityWarning = PhosphorIconsRegular.shieldWarning;

  /// Add / plus
  static const add = PhosphorIconsRegular.plus;

  /// Remove / minus circle
  static const remove = PhosphorIconsRegular.minusCircle;

  /// Owner — crown
  static const owner = PhosphorIconsRegular.crown;

  /// Requests — tray arrow down
  static const requests = PhosphorIconsRegular.trayArrowDown;

  /// Lock
  static const lock = PhosphorIconsRegular.lock;

  /// Groups — users three
  static const groups = PhosphorIconsRegular.usersThree;

  // ══════════════════════════════════════════════════════════════════════════
  // TIME OF DAY
  // ══════════════════════════════════════════════════════════════════════════

  /// Morning — sun horizon (sunrise)
  static const morning = PhosphorIconsRegular.sunHorizon;

  /// Afternoon — sun
  static const afternoon = PhosphorIconsRegular.sun;

  /// Twilight — cloud sun
  static const twilight = PhosphorIconsRegular.cloudSun;

  // ══════════════════════════════════════════════════════════════════════════
  // CHEVRONS & ARROWS
  // ══════════════════════════════════════════════════════════════════════════

  /// Chevron right — trailing navigation
  static const chevronRight = PhosphorIconsRegular.caretRight;

  /// Chevron left
  static const chevronLeft = PhosphorIconsRegular.caretLeft;

  /// Chevron down — dropdown / expand
  static const chevronDown = PhosphorIconsRegular.caretDown;

  /// Chevron up — collapse
  static const chevronUp = PhosphorIconsRegular.caretUp;

  // ══════════════════════════════════════════════════════════════════════════
  // CHECKBOX (replaces Material checkbox icons)
  // ══════════════════════════════════════════════════════════════════════════

  /// Checkbox checked
  static const checkboxChecked = PhosphorIconsRegular.checkSquare;
  static const checkboxCheckedFill = PhosphorIconsFill.checkSquare;

  /// Checkbox unchecked
  static const checkboxUnchecked = PhosphorIconsRegular.square;

  // ══════════════════════════════════════════════════════════════════════════
  // FORM & INPUT (commonly used in text fields)
  // ══════════════════════════════════════════════════════════════════════════

  /// Eye — show password / visibility on
  static const eye = PhosphorIconsRegular.eye;

  /// Eye slash — hide password / visibility off
  static const eyeSlash = PhosphorIconsRegular.eyeSlash;

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS (common UI actions)
  // ══════════════════════════════════════════════════════════════════════════

  /// Send — paper plane
  static const send = PhosphorIconsRegular.paperPlaneTilt;

  /// Trash / delete
  static const trash = PhosphorIconsRegular.trash;

  /// Check — standalone checkmark
  static const check = PhosphorIconsRegular.check;

  /// X circle — cancel / dismiss
  static const xCircle = PhosphorIconsRegular.xCircle;

  /// Plus circle — add
  static const plusCircle = PhosphorIconsRegular.plusCircle;

  /// Minus circle — (alias for remove)
  static const minusCircle = PhosphorIconsRegular.minusCircle;

  /// Refresh / retry
  static const refresh = PhosphorIconsRegular.arrowClockwise;

  /// Copy / clipboard
  static const copy = PhosphorIconsRegular.copy;

  /// Edit / pencil (generic)
  static const edit = PhosphorIconsRegular.pencilSimple;

  // ══════════════════════════════════════════════════════════════════════════
  // MEDIA
  // ══════════════════════════════════════════════════════════════════════════

  /// Image / photo
  static const image = PhosphorIconsRegular.image;

  // ══════════════════════════════════════════════════════════════════════════
  // SOCIAL / FEEDBACK
  // ══════════════════════════════════════════════════════════════════════════

  /// Thumbs up
  static const thumbsUp = PhosphorIconsRegular.thumbsUp;

  /// Thumbs down
  static const thumbsDown = PhosphorIconsRegular.thumbsDown;

  /// Heart fill — favorites
  static const heartFill = PhosphorIconsFill.heart;

  /// Lightning — energy / active
  static const lightning = PhosphorIconsRegular.lightning;

  /// Handshake — social / meet
  static const handshake = PhosphorIconsRegular.handshake;
}
