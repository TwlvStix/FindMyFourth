# Phase 1.7 — Card Widget APIs (LOCKED)

All open questions resolved. These are the interfaces Claude Code builds against.

---

## 1. AppInfoCard

```dart
enum AppInfoCardLayout {
  /// Icon left, label + value right (default — dense grids)
  horizontal,

  /// Icon top, label + value stacked below (Game Details style)
  vertical,
}

/// Compact info display: icon + label + value.
///
/// Used in grids (Game Details, game summary) for dense attribute display.
/// Icons are neutral (textSecondary) by default — use [badgeVariant] only
/// for trust/achievement/premium contexts.
///
/// Example:
/// ```dart
/// // Standard (no badge, horizontal)
/// AppInfoCard(
///   icon: AppPhosphorIcons.betting,
///   label: 'Betting',
///   value: 'Just for Fun',
/// )
///
/// // Vertical layout for Game Details grid
/// AppInfoCard(
///   icon: AppPhosphorIcons.scoring,
///   label: 'Scoring',
///   value: 'Stableford',
///   layout: AppInfoCardLayout.vertical,
/// )
///
/// // With badge (trust context only)
/// AppInfoCard(
///   icon: AppPhosphorIcons.trust,
///   label: 'Standing',
///   value: 'Gold',
///   badgeVariant: AppIconBadgeVariant.accent,
/// )
///
/// // Empty state
/// AppInfoCard(
///   icon: AppPhosphorIcons.betting,
///   label: 'Betting',
///   value: '--',
///   isEmpty: true,
/// )
/// ```
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.layout = AppInfoCardLayout.horizontal,
    this.onTap,
    this.isEmpty = false,
    this.badgeVariant,
  });

  /// Phosphor icon — from AppPhosphorIcons
  final PhosphorIconData icon;

  /// Attribute label (e.g., "Betting", "Rule Style")
  final String label;

  /// Attribute value (e.g., "Just for Fun", "Match Play")
  final String value;

  /// Layout direction for icon relative to text
  final AppInfoCardLayout layout;

  /// Makes the card tappable (rare for info cards)
  final VoidCallback? onTap;

  /// Shows value as "--" in textMuted
  final bool isEmpty;

  /// When null (default): plain icon, AppColors.textSecondary
  /// When provided: icon wrapped in AppIconBadge with this variant.
  /// Use ONLY for trust/achievement/premium contexts.
  final AppIconBadgeVariant? badgeVariant;
}
```

**Hardcoded tokens:**

| Property | Value |
|----------|-------|
| Background | `AppColors.navy` |
| Border | `1px AppColors.navyLight` |
| Radius | `AppBorderRadius.card` (12px) |
| Padding | `AppSpacing.cardPadding` (20px) |
| Icon (no badge) | `AppIconSize.listItem` (24px), `AppColors.textSecondary` |
| Icon (with badge) | Wrapped in `AppIconBadge` at `AppIconBadgeSize.medium` |
| Label | `AppTypography.labelSmall`, `AppColors.textMuted` |
| Value | `AppTypography.bodyMedium`, `AppColors.textPrimary`, w600 |
| Value (empty) | `AppTypography.bodyMedium`, `AppColors.textMuted`, shows "--" |
| Gap (icon → text) | `AppSpacing.sm` (12px) |
| Elevation | None (unless onTap, then `AppElevation.xs` on hover) |

---

## 2. AppStatCard

```dart
enum AppStatCardVariant {
  /// Navy background, standard padding, subtle border
  standard,

  /// Semi-transparent on dark backgrounds (glassSurface + glassBorder)
  glass,

  /// Smaller padding, smaller typography, no icon — for inline/dense layouts
  compact,
}

/// Hero metric display: large value + label + optional icon below value.
///
/// Example:
/// ```dart
/// AppStatCard(
///   value: '3',
///   label: 'Handicap',
///   icon: AppPhosphorIcons.handicap,
/// )
///
/// // Glass variant for dark backgrounds
/// AppStatCard(
///   value: '12',
///   label: 'Rounds',
///   icon: AppPhosphorIcons.rounds,
///   variant: AppStatCardVariant.glass,
/// )
///
/// // Compact (no icon)
/// AppStatCard(
///   value: '67%',
///   label: 'Win Rate',
///   variant: AppStatCardVariant.compact,
/// )
///
/// // Trust stat with gold glow
/// AppStatCard(
///   value: 'Gold',
///   label: 'Trust Tier',
///   icon: AppPhosphorIcons.trust,
///   variant: AppStatCardVariant.glass,
///   showPrestigeGlow: true,
/// )
/// ```
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.variant = AppStatCardVariant.standard,
    this.onTap,
    this.showPrestigeGlow = false,
  });

  /// The big number or short text: "3", "12", "67%", "Gold"
  final String value;

  /// What the value means: "Handicap", "Rounds", "Win Rate"
  final String label;

  /// Optional icon displayed BELOW the value
  /// Ignored in compact variant
  final PhosphorIconData? icon;

  /// Visual treatment variant
  final AppStatCardVariant variant;

  /// Makes tappable (e.g., tap handicap to see history)
  final VoidCallback? onTap;

  /// Adds AppElevation.glowGold — for trust/achievement stats ONLY
  final bool showPrestigeGlow;
}
```

**Layout (all variants — centered, vertical):**
```
┌─────────────────────────────────────────────────┐
│              [Large Value]                       │
│              [Label]                             │
│              [Icon]                              │
└─────────────────────────────────────────────────┘
```

**Token mapping per variant:**

| Property | standard | glass | compact |
|----------|----------|-------|---------|
| Background | `AppColors.navy` | `AppColors.glassSurface` | `AppColors.navy` |
| Border | `1px AppColors.navyLight` | `1px AppColors.glassBorder` | `1px AppColors.navyLight` |
| Radius | `AppBorderRadius.card` | `AppBorderRadius.card` | `AppBorderRadius.sm` |
| Padding | `AppSpacing.cardPadding` | `AppSpacing.cardPadding` | `AppSpacing.allSm` |
| Value | `headlineMediumSans`, `textPrimary` | `headlineMediumSans`, `textPrimary` | `titleLarge`, `textPrimary` |
| Label | `labelSmall`, `textMuted` | `labelSmall`, `textMuted` | `labelMicro`, `textMuted` |
| Icon size | `AppIconSize.section` (32px) | `AppIconSize.section` (32px) | N/A (no icon) |
| Icon color | `textSecondary` | `textSecondary` | N/A |
| Glow | None | None | None |
| Glow (prestige) | `AppElevation.glowGold` | `AppElevation.glowGold` | `AppElevation.glowGold` |

---

## 3. AppActionCard

```dart
/// Tappable destination card: optional icon + title + optional subtitle + chevron.
///
/// Always has a press state. Trailing chevron shown by default.
///
/// Example:
/// ```dart
/// // Standard with icon
/// AppActionCard(
///   icon: AppPhosphorIcons.editProfile,
///   title: 'Edit Profile',
///   subtitle: 'Update your info and photo',
///   onTap: () => context.push(EditProfileWidget.routePath),
/// )
///
/// // Minimal — text only, no icon
/// AppActionCard(
///   title: 'Terms of Service',
///   onTap: () => launchUrl(termsUrl),
/// )
///
/// // With custom trailing (toggle switch instead of chevron)
/// AppActionCard(
///   icon: AppPhosphorIcons.notifications,
///   title: 'Push Notifications',
///   trailing: Switch(value: enabled, onChanged: toggleNotifs),
///   showChevron: false,
///   onTap: () => toggleNotifs(!enabled),
/// )
/// ```
class AppActionCard extends StatelessWidget {
  const AppActionCard({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
  });

  /// Optional Phosphor icon — from AppPhosphorIcons
  final PhosphorIconData? icon;

  /// Primary text
  final String title;

  /// Required — action cards are always tappable
  final VoidCallback onTap;

  /// Optional secondary text
  final String? subtitle;

  /// Override trailing chevron with custom widget (badge, switch, count)
  final Widget? trailing;

  /// Show trailing chevron. Set false when using custom [trailing] widget.
  final bool showChevron;
}
```

**Hardcoded tokens:**

| Property | Value |
|----------|-------|
| Background | `AppColors.navy` |
| Border | `1px AppColors.navyLight` |
| Radius | `AppBorderRadius.card` (12px) |
| Padding | `AppSpacing.cardPadding` (20px) |
| Icon | `AppIconSize.listItem` (24px), `AppColors.textSecondary` |
| Title | `AppTypography.bodyMedium`, `AppColors.textPrimary` |
| Subtitle | `AppTypography.labelSmall`, `AppColors.textMuted` |
| Chevron | `AppPhosphorIcons.chevronRight`, `AppColors.textMuted` |
| Gap (icon → text) | `AppSpacing.sm` (12px) |
| Hover bg | `AppColors.navyLight` |
| Press bg | `AppColors.navyHovered` |
| Hover elevation | `AppElevation.xs` |

**Layout:**
```
With icon:
┌─────────────────────────────────────────────────┐
│  [Icon]  [Title]                            [›] │
│          [Subtitle]                             │
└─────────────────────────────────────────────────┘

Without icon:
┌─────────────────────────────────────────────────┐
│  [Title]                                    [›] │
│  [Subtitle]                                     │
└─────────────────────────────────────────────────┘
```

---

## When to Use Which

| Question | Card |
|----------|------|
| Showing a label + value with an icon? (read-only info) | `AppInfoCard` |
| Showing a big number/metric? (hero stat) | `AppStatCard` |
| User taps this to go somewhere or do something? | `AppActionCard` |

---

## File Locations

| Widget | Path |
|--------|------|
| `AppInfoCard` | `lib/core/widgets/app_info_card.dart` |
| `AppStatCard` | `lib/core/widgets/app_stat_card.dart` |
| `AppActionCard` | `lib/core/widgets/app_action_card.dart` |

All three import from `lib/core/design_tokens/` and `lib/core/widgets/`.
