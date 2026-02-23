# Phosphor Icon Migration Guide

## How It Works

**No downloads needed.** Phosphor is a font package — icons are referenced by name, not by file. The package `phosphor_flutter` bundles everything.

**Weight rule:** `PhosphorIconsRegular` everywhere. `PhosphorIconsFill` only for active nav states.

## File Locations

Drop these files into your project:

| File | Location |
|------|----------|
| `app_icon.dart` (updated) | `lib/core/widgets/app_icon.dart` |
| `app_phosphor_icons.dart` (new) | `lib/core/design_tokens/app_phosphor_icons.dart` |
| `app_icon_badge.dart` (updated) | `lib/core/widgets/app_icon_badge.dart` |
| `app_icon_button.dart` (updated) | `lib/core/widgets/app_icon_button.dart` |

Then add the import to your design tokens barrel file if you have one:
```dart
export 'app_phosphor_icons.dart';
```

---

## Migration Mapping: AppIcons (SVG) → AppPhosphorIcons

Use this table for find-and-replace. The left column is what's in the code now, the right is the replacement.

### Navigation
| Old (SVG) | New (Phosphor) |
|-----------|---------------|
| `AppIcons.games` | `AppPhosphorIcons.games` |
| `AppIcons.myGames` | `AppPhosphorIcons.myGames` |
| `AppIcons.golfers` | `AppPhosphorIcons.golfers` |
| `AppIcons.chat` | `AppPhosphorIcons.chat` |
| `AppIcons.profile` | `AppPhosphorIcons.profile` |
| `AppIcons.notifications` | `AppPhosphorIcons.notifications` |
| `AppIcons.back` | `AppPhosphorIcons.back` |
| `AppIcons.search` | `AppPhosphorIcons.search` |

### Game Setup & Details
| Old (SVG) | New (Phosphor) |
|-----------|---------------|
| `AppIcons.betting` | `AppPhosphorIcons.betting` |
| `AppIcons.ruleStyle` | `AppPhosphorIcons.ruleStyle` |
| `AppIcons.gameType` | `AppPhosphorIcons.gameType` |
| `AppIcons.scoring` | `AppPhosphorIcons.scoring` |
| `AppIcons.visibility` | `AppPhosphorIcons.visibility` |
| `AppIcons.memberDiscount` | `AppPhosphorIcons.memberDiscount` |
| `AppIcons.teeTime` | `AppPhosphorIcons.teeTime` |
| `AppIcons.course` | `AppPhosphorIcons.course` |
| `AppIcons.addPlayer` | `AppPhosphorIcons.addPlayer` |
| `AppIcons.publicVisibility` | `AppPhosphorIcons.publicVisibility` |
| `AppIcons.confirm` | `AppPhosphorIcons.confirm` |
| `AppIcons.calendarCheck` | `AppPhosphorIcons.calendarCheck` |

### Game Formats
| Old (SVG) | New (Phosphor) |
|-----------|---------------|
| `AppIcons.strokePlay` | `AppPhosphorIcons.strokePlay` |
| `AppIcons.matchPlay` | `AppPhosphorIcons.matchPlay` |
| `AppIcons.stableford` | `AppPhosphorIcons.stableford` |
| `AppIcons.skins` | `AppPhosphorIcons.skins` |
| `AppIcons.vegas` | `AppPhosphorIcons.vegas` |
| `AppIcons.nassau` | `AppPhosphorIcons.nassau` |
| `AppIcons.wolf` | `AppPhosphorIcons.wolf` |
| `AppIcons.teams2v2` | `AppPhosphorIcons.teams` |
| `AppIcons.handicap` | `AppPhosphorIcons.handicap` |
| `AppIcons.bbb` | `AppPhosphorIcons.bestBall` |
| `AppIcons.sixSixSix` | `AppPhosphorIcons.sixSixSix` |
| `AppIcons.otherCustom` | `AppPhosphorIcons.otherCustom` |

### Vibe & Stakes
| Old (SVG) | New (Phosphor) |
|-----------|---------------|
| `AppIcons.competitive` | `AppPhosphorIcons.competitive` |
| `AppIcons.casual` | `AppPhosphorIcons.casual` |
| `AppIcons.noMoney` | `AppPhosphorIcons.noMoney` |
| `AppIcons.lowStakes` | `AppPhosphorIcons.lowStakes` |
| `AppIcons.highStakes` | `AppPhosphorIcons.highStakes` |
| `AppIcons.gameVibe` | `AppPhosphorIcons.gameVibe` |
| `AppIcons.vibeMatch` | `AppPhosphorIcons.vibeMatch` |

### Profile & Settings
| Old (SVG) | New (Phosphor) |
|-----------|---------------|
| `AppIcons.editProfile` | `AppPhosphorIcons.editProfile` |
| `AppIcons.golfVibes` | `AppPhosphorIcons.golfVibes` |
| `AppIcons.camera` | `AppPhosphorIcons.camera` |
| `AppIcons.email` | `AppPhosphorIcons.email` |
| `AppIcons.phone` | `AppPhosphorIcons.phone` |
| `AppIcons.standing` | `AppPhosphorIcons.trust` |
| `AppIcons.logOut` | `AppPhosphorIcons.logOut` |
| `AppIcons.rounds` | `AppPhosphorIcons.rounds` |
| `AppIcons.hosted` | `AppPhosphorIcons.hosted` |
| `AppIcons.uniquePlayers` | `AppPhosphorIcons.uniquePlayers` |
| `AppIcons.requests` | `AppPhosphorIcons.requests` |
| `AppIcons.morning` | `AppPhosphorIcons.morning` |
| `AppIcons.afternoon` | `AppPhosphorIcons.afternoon` |
| `AppIcons.twilight` | `AppPhosphorIcons.twilight` |
| `AppIcons.joined` | `AppPhosphorIcons.success` |
| `AppIcons.owner` | `AppPhosphorIcons.owner` |
| `AppIcons.remove` | `AppPhosphorIcons.remove` |

### Utility
| Old (SVG) | New (Phosphor) |
|-----------|---------------|
| `AppIcons.settings` | `AppPhosphorIcons.settings` |
| `AppIcons.close` | `AppPhosphorIcons.close` |
| `AppIcons.lock` | `AppPhosphorIcons.lock` |
| `AppIcons.pending` | `AppPhosphorIcons.pending` |
| `AppIcons.groups` | `AppPhosphorIcons.groups` |

---

## Material Icons TODO List — Now Resolved

These were listed in `app_icons.dart` as needing SVG equivalents. Phosphor covers all of them:

| Material Icon | Phosphor Replacement |
|--------------|---------------------|
| `Icons.chevron_right_rounded` | `AppPhosphorIcons.chevronRight` |
| `Icons.error_outline` | `AppPhosphorIcons.error` |
| `Icons.star_rounded` | `AppPhosphorIcons.star` |
| `Icons.check_box_outlined` | `AppPhosphorIcons.checkboxChecked` |
| `Icons.check_box_outline_blank` | `AppPhosphorIcons.checkboxUnchecked` |
| `Icons.hourglass_top_rounded` | `AppPhosphorIcons.pending` |
| `Icons.pause_circle_outline_rounded` | `AppPhosphorIcons.paused` |
| `Icons.block_rounded` | `AppPhosphorIcons.blocked` |
| `Icons.gpp_bad_rounded` | `AppPhosphorIcons.securityWarning` |
| `Icons.golf_course_rounded` | `AppPhosphorIcons.gameType` |
| `Icons.check_circle_outline_rounded` | `AppPhosphorIcons.confirm` |
| `Icons.sports_golf_rounded` | `AppPhosphorIcons.gameType` |
| `Icons.flag_rounded` | `AppPhosphorIcons.games` |
| `Icons.verified_rounded` | `AppPhosphorIcons.verified` |
| `Icons.warning_amber_rounded` | `AppPhosphorIcons.warning` |

---

## Syntax Change: `assetPath:` → `icon:`

The key API change when migrating a call site:

```dart
// BEFORE (SVG):
AppIcon(
  assetPath: AppIcons.betting,       // String path to SVG file
  size: AppIconSize.listItem,
  color: AppColors.textSecondary,
)

// AFTER (Phosphor):
AppIcon(
  icon: AppPhosphorIcons.betting,    // PhosphorIconData
  size: AppIconSize.listItem,
  color: AppColors.textSecondary,
)
```

The ONLY change is `assetPath:` → `icon:` and `AppIcons.xxx` → `AppPhosphorIcons.xxx`. Size and color tokens stay exactly the same.

For `AppNavIcon`:
```dart
// BEFORE:
AppNavIcon(assetPath: AppIcons.games, isActive: true)

// AFTER:
AppNavIcon(
  icon: AppPhosphorIcons.games,
  iconFill: AppPhosphorIcons.gamesFill,
  isActive: true,
)
```

For `AppIconBadge`:
```dart
// BEFORE:
AppIconBadge(svgPath: AppIcons.standing, variant: AppIconBadgeVariant.accent)

// AFTER:
AppIconBadge(phosphorIcon: AppPhosphorIcons.trust, variant: AppIconBadgeVariant.accent)
```

---

## Bulk Migration Strategy

### Option A: Claude Code (fastest)

Paste this prompt into Claude Code from your project root:

> Migrate all AppIcons SVG references to AppPhosphorIcons Phosphor icons.
> Use the mapping in `docs/phosphor-migration.md`.
> For each file: change `assetPath: AppIcons.xxx` to `icon: AppPhosphorIcons.xxx`.
> Add `import '/core/design_tokens/app_phosphor_icons.dart';` where needed.
> Keep the SVG AppIcons file — don't delete it yet.

### Option B: Manual grep-and-fix

```bash
# Find all SVG icon usage to migrate
grep -rn "assetPath: AppIcons\." lib/ --include="*.dart" | wc -l
# ^ This tells you how many call sites to update

# Find them grouped by file
grep -rln "assetPath: AppIcons\." lib/ --include="*.dart"

# Find remaining Material Icons to replace
grep -rn "Icons\." lib/ --include="*.dart" | grep -v "AppIcons" | grep -v "import" | grep -v "//" | head -30
```

### Option C: Gradual (screen by screen)

Both SVG and Phosphor work simultaneously — `AppIcon` accepts either. So you can migrate one screen at a time without breaking anything. Start with Game Details and Profile (the worst offenders), then work outward.

---

## After Migration

Once all screens are on Phosphor, you can:

1. Remove the SVG asset files from `assets/icon/golf-app-icons/`
2. Remove `AppIcons` class from `app_icons.dart` (or keep as reference)
3. Remove the `assetPath` parameter from `AppIcon` (breaking change — only when fully migrated)
4. Update `CLAUDE.md` to reference `AppPhosphorIcons` instead of `AppIcons`
5. Remove `flutter_svg` dependency if no other SVGs remain
