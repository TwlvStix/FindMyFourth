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

  /// Muted / silenced — bell slash (for muted threads)
  static const muted = PhosphorIconsRegular.bellSlash;

  /// Digest / inbox — envelope simple (for digest mode)
  static const digest = PhosphorIconsRegular.envelopeSimple;

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

  /// Clock — generic time indicator (cooldowns, timestamps)
  static const clock = PhosphorIconsRegular.clock;

  /// Course — location pin
  static const course = PhosphorIconsRegular.mapPin;

  /// Add player — user plus
  static const addPlayer = PhosphorIconsRegular.userPlus;

  /// Remove player — user minus
  static const removePlayer = PhosphorIconsRegular.userMinus;

  /// Public visibility — globe
  static const publicVisibility = PhosphorIconsRegular.globe;

  /// Friends only — lock
  static const friendsOnly = PhosphorIconsRegular.lockSimple;

  /// Fun game / just for fun — smiley (casual, friendly vibe)
  static const funGame = PhosphorIconsRegular.smiley;

  /// Confirm — check circle
  static const confirm = PhosphorIconsRegular.checkCircle;

  /// Calendar check
  static const calendarCheck = PhosphorIconsRegular.calendarCheck;

  /// Calendar (pick a date)
  static const calendar = PhosphorIconsRegular.calendar;

  /// Calendar note / event note
  static const calendarNote = PhosphorIconsRegular.calendarBlank;

  /// Label / tag (for game name, etc)
  static const label = PhosphorIconsRegular.tag;

  /// Golf course / golf hole
  static const golfCourse = PhosphorIconsRegular.golf;

  /// Golf hole — alias for golfCourse
  static const golfHole = PhosphorIconsRegular.golf;

  /// People / friends (group context)
  static const people = PhosphorIconsRegular.users;

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

  /// Shield — generic protection/trust icon
  static const shield = PhosphorIconsRegular.shield;

  /// Anchor — cornerstone/established badge tier
  static const anchor = PhosphorIconsRegular.anchor;

  /// Verified — seal check
  static const verified = PhosphorIconsRegular.sealCheck;

  /// Star / rating
  static const star = PhosphorIconsRegular.star;
  static const starFill = PhosphorIconsFill.star;

  /// Badge / medal
  static const badge = PhosphorIconsRegular.medal;

  /// Rounds completed — golf icon
  static const rounds = PhosphorIconsRegular.golf;

  /// Golf ball / handicap — golf icon (alias for profile stats)
  static const golf = PhosphorIconsRegular.golf;

  /// Flag checkered — for handicap/finish line contexts
  static const flagCheckered = PhosphorIconsRegular.flagCheckered;

  /// Users — alias for social contexts (friends count, etc.)
  static const users = PhosphorIconsRegular.users;

  /// Hosted — flag pennant
  static const hosted = PhosphorIconsRegular.flagPennant;

  /// Unique players — user focus
  static const uniquePlayers = PhosphorIconsRegular.userFocus;

  // ══════════════════════════════════════════════════════════════════════════
  // STATUS & ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Success / joined — check circle
  static const success = PhosphorIconsRegular.checkCircle;
  static const successFill = PhosphorIconsFill.checkCircle;

  /// Joined indicator — check circle (alias for success)
  static const joined = PhosphorIconsRegular.checkCircle;

  /// Cancel / dismissed — x circle
  static const cancel = PhosphorIconsRegular.xCircle;
  static const cancelFill = PhosphorIconsFill.xCircle;

  /// Error — warning circle
  static const error = PhosphorIconsRegular.warningCircle;

  /// Info
  static const info = PhosphorIconsRegular.info;

  /// Help — question mark
  static const help = PhosphorIconsRegular.question;

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

  /// Plain plus sign (for counters)
  static const plus = PhosphorIconsRegular.plus;

  /// Plain minus sign (for counters)
  static const minus = PhosphorIconsRegular.minus;

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

  /// Moon — night, quiet hours, do not disturb
  static const moon = PhosphorIconsRegular.moon;

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

  /// Arrow up — priority up, rank up
  static const arrowUp = PhosphorIconsRegular.arrowUp;

  /// Arrow right — forward navigation
  static const arrowRight = PhosphorIconsRegular.arrowRight;

  /// Lightbulb — tips, hints, ideas
  static const lightbulb = PhosphorIconsRegular.lightbulb;

  /// Circle — empty state, unchecked radio
  static const circle = PhosphorIconsRegular.circle;

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
  // BRAND LOGOS
  // ══════════════════════════════════════════════════════════════════════════

  /// Apple logo — for Sign in with Apple
  static const appleLogo = PhosphorIconsRegular.appleLogo;

  /// Music notes — for music preference
  static const music = PhosphorIconsRegular.musicNotes;

  /// Drinks — for drinking preference (martini glass)
  static const drinks = PhosphorIconsRegular.martini;

  /// Speed / pace — speedometer
  static const pace = PhosphorIconsRegular.gauge;

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

  /// Brain — AI / psychology / matching
  static const brain = PhosphorIconsRegular.brain;

  /// Insights / analytics — chart line up (for detailed breakdown)
  static const insights = PhosphorIconsRegular.chartLineUp;

  // ══════════════════════════════════════════════════════════════════════════
  // CHAT & MESSAGING
  // ══════════════════════════════════════════════════════════════════════════

  /// Reply — arrow bend up left
  static const reply = PhosphorIconsRegular.arrowBendUpLeft;

  /// Read receipt — double check / checks
  static const checks = PhosphorIconsRegular.checks;

  /// Broken image — failed to load
  static const imageBroken = PhosphorIconsRegular.imageBroken;

  /// Arrow down — scroll to bottom
  static const arrowDown = PhosphorIconsRegular.arrowDown;

  /// Photo library / gallery — images
  static const imageGallery = PhosphorIconsRegular.images;

  // ══════════════════════════════════════════════════════════════════════════
  // EMPTY STATES
  // ══════════════════════════════════════════════════════════════════════════

  /// Search off / no results — magnifying glass with minus
  static const searchOff = PhosphorIconsRegular.magnifyingGlassMinus;

  /// Inbox / tray — empty inbox state
  static const inbox = PhosphorIconsRegular.tray;

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL PROFILE & FORM ICONS
  // ══════════════════════════════════════════════════════════════════════════

  /// At sign / username — @
  static const atSign = PhosphorIconsRegular.at;

  /// Sparkle / auto-awesome — magic/AI features
  static const sparkle = PhosphorIconsRegular.sparkle;

  /// Message — alias for chat (direct messaging context)
  static const message = PhosphorIconsRegular.chatCircle;

  /// Tune / adjust — sliders (alias for filter/tune contexts)
  static const tune = PhosphorIconsRegular.slidersHorizontal;

  // ══════════════════════════════════════════════════════════════════════════
  // ADDITIONAL ALIASES & ICONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Person / user — alias for profile in avatar/person contexts
  static const person = PhosphorIconsRegular.user;

  /// Trophy — alias for competitive in achievement contexts
  static const trophy = PhosphorIconsRegular.trophy;

  /// External link / open in new — for "open settings" etc.
  static const externalLink = PhosphorIconsRegular.arrowSquareOut;

  /// Priority high / exclamation — for watch points
  static const priorityHigh = PhosphorIconsRegular.warningCircle;

  /// Expand less / chevron up — for collapsible sections
  static const expandLess = PhosphorIconsRegular.caretUp;

  /// Expand more / chevron down — for collapsible sections
  static const expandMore = PhosphorIconsRegular.caretDown;

  /// Hero size icon for empty states (alias for larger contexts)
  static const hero = PhosphorIconsRegular.warningCircle;

  // ══════════════════════════════════════════════════════════════════════════
  // PLAYER ELIGIBILITY
  // ══════════════════════════════════════════════════════════════════════════

  /// Open to all — users three (inclusive group)
  static const openToAll = PhosphorIconsRegular.usersThree;

  /// Women only — gender female
  static const womenOnly = PhosphorIconsRegular.genderFemale;

  /// Men only — gender male
  static const menOnly = PhosphorIconsRegular.genderMale;

  // ══════════════════════════════════════════════════════════════════════════
  // ARCHETYPE IDENTITY — Vibe style archetype icons
  // ══════════════════════════════════════════════════════════════════════════

  /// Target — The Grinder archetype
  static const target = PhosphorIconsRegular.target;

  /// Tree — The Purist archetype
  static const tree = PhosphorIconsRegular.tree;

  /// Binoculars — The Tourist archetype
  static const binoculars = PhosphorIconsRegular.binoculars;

  /// Flame — The Juggernaut archetype
  static const flame = PhosphorIconsRegular.flame;

  /// Diamond — The High Roller archetype
  static const diamond = PhosphorIconsRegular.diamond;

  /// Megaphone — The Mayor archetype
  static const megaphone = PhosphorIconsRegular.megaphone;

  /// Ghost — The Ghost archetype
  static const ghost = PhosphorIconsRegular.ghost;

  /// Crown — The Vibe King archetype
  static const crown = PhosphorIconsRegular.crown;

  /// Speaker HiFi — The DJ archetype
  static const speakerHifi = PhosphorIconsRegular.speakerHifi;

  /// Piggy Bank — The Hustler archetype
  static const piggyBank = PhosphorIconsRegular.piggyBank;

  // ══════════════════════════════════════════════════════════════════════════
  // DEBUG
  // ══════════════════════════════════════════════════════════════════════════

  /// Bug icon — debug mode only
  static const bug = PhosphorIconsRegular.bug;
}
