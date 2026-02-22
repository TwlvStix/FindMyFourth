# Figma MCP Design System Rules

This document provides structured design system rules for Figma MCP integration with the Find My Fourth Flutter codebase.

## Project Context

- **Framework**: Flutter/Dart
- **Styling**: Custom design token system in `lib/core/design_tokens/`
- **Component Library**: `lib/core/widgets/` (prefixed with `app_`)
- **Design Philosophy**: "The Clubhouse" — trust-first golf matchmaking aesthetic

---

## 1. Color System

### Token Location
`lib/core/design_tokens/colors.dart`

### Three-Role Color Architecture

When translating Figma designs, map colors to one of three roles:

| Role | Primary Color | Usage | Figma Layer Hint |
|------|---------------|-------|------------------|
| **Interactive** | Green (#3A8F65) | CTAs, buttons, links, active states | Any clickable element |
| **Structural** | Navy (#1B2E4A) | Headers, cards, navigation | Container backgrounds |
| **Premium** | Gold (#C49A3D) | Trust badges, achievements, upgrades | Accent highlights |

### Color Token Mapping

#### Primary Accent — Fairway Green
```dart
// Map Figma green fills to:
AppColors.green       // #3A8F65 — default interactive
AppColors.greenDark   // #2B7050 — pressed/active state
AppColors.greenLight  // #4EAD7E — hover/highlight
AppColors.greenHovered  // computed hover
AppColors.greenPressed  // computed pressed
```

#### Structural — Club Navy
```dart
// Map Figma navy/dark fills to:
AppColors.navy        // #1B2E4A — card headers, secondary buttons
AppColors.navyDark    // #0F1C30 — app bars, deep backgrounds
AppColors.navyLight   // #2B4A72 — borders, hover accents
```

#### Secondary Accent — Prestige Gold
```dart
// Map Figma gold/yellow fills to:
AppColors.gold        // #C49A3D — trust badges, premium CTAs
AppColors.goldDark    // #A6832F — pressed state
AppColors.goldLight   // #D4A84B — hover highlight
```

#### Neutrals (Warm-tinted)
```dart
// Map Figma grey/neutral fills to:
AppColors.pure   // #FFFFFF — pure white
AppColors.sand   // #FAF9F6 — off-white backgrounds
AppColors.cloud  // #F4F2EE — light sections
AppColors.mist   // #DDD8D0 — borders, dividers
AppColors.stone  // #8694A8 — secondary text, icons
AppColors.slate  // #556275 — primary body text
AppColors.onyx   // #141A24 — headings, dark text
```

#### Semantic Colors
```dart
AppColors.success  // #3A8F65 (= green)
AppColors.warning  // #C49A3D (= gold)
AppColors.error    // #D64545
AppColors.info     // #5B8DBE
```

#### Trust Tiers
```dart
// Each tier has foreground + background:
AppColors.trustPlatinumFg  // #4A6580 (text)
AppColors.trustPlatinumBg  // #E8EDF4 (background)
AppColors.trustGoldFg      // #9A7B1E
AppColors.trustGoldBg      // #FDF5E1
AppColors.trustSilverFg    // #6E7582
AppColors.trustSilverBg    // #EDEEF0
AppColors.trustBronzeFg    // #7D5520
AppColors.trustBronzeBg    // #F5EDE4
AppColors.trustCopperFg    // #8C4432
AppColors.trustCopperBg    // #F2E6DD
```

#### Glass/Overlay Effects
```dart
// For semi-transparent overlays in Figma:
AppColors.glassBorder        // white @ 20% opacity
AppColors.glassSurface       // white @ 10% opacity
AppColors.glassTextSecondary // white @ 70% opacity
AppColors.overlayDark        // black @ 40% opacity
AppColors.scrim              // black @ 60% opacity
```

#### Gradients
```dart
// Map Figma gradients to:
AppColors.navyGradient   // navyDark → navy (topLeft → bottomRight)
AppColors.greenGradient  // greenDark → green → greenLight
AppColors.goldGradient   // goldDark → gold → goldLight
```

---

## 2. Typography

### Token Location
`lib/core/design_tokens/typography.dart`

### Font Families

| Figma Font | Flutter Mapping | Usage |
|------------|-----------------|-------|
| **Fraunces** | `fontFamily: 'Fraunces'` | Headers, titles, display text |
| **Manrope** | `fontFamily: 'Manrope'` | Body text, UI labels, buttons |
| **DM Mono** | `fontFamily: 'DM Mono'` | Scores, numbers, data |

### Typography Scale Mapping

#### Display Styles (Fraunces)
```dart
// Large hero text in Figma:
AppTypography.displayXL     // 72px, black weight
AppTypography.displayLarge  // 56px, bold
AppTypography.displayMedium // 40px, bold
AppTypography.displaySmall  // 32px, semiBold
```

#### Headlines (Fraunces)
```dart
// Section headers in Figma:
AppTypography.headlineLarge  // 28px, semiBold
AppTypography.headlineMedium // 24px, semiBold — screen titles
AppTypography.headlineSmall  // 20px, medium
```

#### Titles (Manrope)
```dart
// Card/section titles in Figma:
AppTypography.titleLarge  // 20px, semiBold
AppTypography.titleMedium // 18px, semiBold — card titles
AppTypography.titleSmall  // 16px, semiBold
```

#### Body (Manrope)
```dart
// Paragraph text in Figma:
AppTypography.bodyLarge  // 18px, regular
AppTypography.bodyMedium // 16px, regular — default body
AppTypography.bodySmall  // 14px, regular — secondary
```

#### Labels (Manrope)
```dart
// Button text, labels in Figma:
AppTypography.labelLarge  // 16px, semiBold
AppTypography.labelMedium // 14px, semiBold
AppTypography.labelSmall  // 12px, semiBold — badges
```

#### Mono Styles (DM Mono)
```dart
// Score displays in Figma:
AppTypography.monoDisplay // 64px, bold — hero scores
AppTypography.monoLarge   // 48px, bold — game scores
AppTypography.monoMedium  // 20px, medium — stats
AppTypography.monoSmall   // 14px, regular — compact data
```

#### Semantic Getters (Recommended)
```dart
AppTypography.screenTitle    // headlineMedium (24px)
AppTypography.sectionHeader  // titleLarge (20px)
AppTypography.cardTitle      // titleMedium (18px)
AppTypography.cardSubtitle   // bodySmall (14px)
AppTypography.timestamp      // caption (12px)
AppTypography.badge          // labelSmall (12px)
AppTypography.button         // 16px semiBold
```

---

## 3. Spacing

### Token Location
`lib/core/design_tokens/spacing.dart`

### 8-Point Grid System

| Figma Spacing | Token | Value |
|---------------|-------|-------|
| 4px | `AppSpacing.xxs` | 4.0 |
| 8px | `AppSpacing.xs` | 8.0 |
| 12px | `AppSpacing.sm` | 12.0 |
| 16px | `AppSpacing.md` | 16.0 |
| 20px | `AppSpacing.lg` | 20.0 |
| 24px | `AppSpacing.xl` | 24.0 |
| 32px | `AppSpacing.xxl` | 32.0 |
| 48px | `AppSpacing.xxxl` | 48.0 |
| 64px | `AppSpacing.xxxxl` | 64.0 |

### Semantic Spacing

```dart
// Common Figma patterns:
AppSpacing.screenPadding   // 20px — edge padding
AppSpacing.cardPadding     // 20px — inside cards
AppSpacing.cardGap         // 16px — between cards
AppSpacing.buttonGap       // 12px — between buttons
AppSpacing.formFieldGap    // 16px — between form fields
AppSpacing.iconTextGap     // 8px — icon to text
AppSpacing.listItemGap     // 16px — between list items
```

### EdgeInsets Shortcuts
```dart
AppSpacing.card    // EdgeInsets.all(20)
AppSpacing.screen  // symmetric(horizontal: 20, vertical: 20)
AppSpacing.modal   // EdgeInsets.all(24)
```

---

## 4. Border Radius

### Token Location
`lib/core/design_tokens/border_radius.dart`

### Radius Scale

| Figma Radius | Token | Value |
|--------------|-------|-------|
| 2px | `AppBorderRadius.xxs` | 2.0 |
| 4px | `AppBorderRadius.xs` | 4.0 |
| 8px | `AppBorderRadius.sm` | 8.0 |
| 12px | `AppBorderRadius.md` | 12.0 |
| 16px | `AppBorderRadius.lg` | 16.0 |
| 24px | `AppBorderRadius.xl` | 24.0 |
| 999px | `AppBorderRadius.full` | 999.0 |

### Semantic Radius
```dart
AppBorderRadius.button  // 8px
AppBorderRadius.input   // 8px
AppBorderRadius.card    // 12px
AppBorderRadius.modal   // 16px
AppBorderRadius.avatar  // 999px (circular)
AppBorderRadius.chip    // 999px (pill)
```

---

## 5. Elevation/Shadows

### Token Location
`lib/core/design_tokens/elevation.dart`

### Shadow Levels

| Figma Shadow | Token | Blur | Opacity |
|--------------|-------|------|---------|
| Minimal | `AppElevation.xs` | 2px | 8% |
| Card | `AppElevation.sm` | 4px | 10% |
| Panel | `AppElevation.md` | 8px | 12% |
| Dropdown | `AppElevation.lg` | 16px | 15% |
| Modal | `AppElevation.xl` | 24px | 18% |

### Special Effects
```dart
AppElevation.glowGold   // Gold shadow for premium features
AppElevation.glowGreen  // Green shadow for success/active
```

### Semantic Shortcuts
```dart
AppElevation.button   // = sm
AppElevation.card     // = sm
AppElevation.modal    // = xl
AppElevation.dropdown // = lg
```

---

## 6. Icon System

### Token Location
`lib/core/design_tokens/app_icons.dart`
`lib/core/design_tokens/icon_size.dart`

### Icon Specifications
- **Grid**: 24x24px
- **Stroke**: 1.75px
- **Caps/Joins**: Round
- **Format**: SVG with `currentColor`

### Icon Size Scale

| Figma Size | Token | Value |
|------------|-------|-------|
| 16px | `AppIconSize.xs` | 16.0 |
| 20px | `AppIconSize.sm` | 20.0 |
| 24px | `AppIconSize.md` | 24.0 |
| 32px | `AppIconSize.lg` | 32.0 |
| 40px | `AppIconSize.xl` | 40.0 |
| 48px | `AppIconSize.xxl` | 48.0 |

### Semantic Sizes
```dart
AppIconSize.nav      // 24px — navigation icons
AppIconSize.button   // 20px — in buttons
AppIconSize.listItem // 24px — list item icons
AppIconSize.section  // 32px — section headers
AppIconSize.feature  // 40px — feature highlights
AppIconSize.avatar   // 48px — avatar fallbacks
```

### Available Icons
```dart
// Navigation
AppIcons.games, AppIcons.myGames, AppIcons.golfers
AppIcons.chat, AppIcons.profile, AppIcons.notifications
AppIcons.back, AppIcons.search, AppIcons.settings

// Game Setup
AppIcons.betting, AppIcons.ruleStyle, AppIcons.gameType
AppIcons.scoring, AppIcons.visibility, AppIcons.teeTime
AppIcons.course, AppIcons.addPlayer

// Game Formats
AppIcons.strokePlay, AppIcons.matchPlay, AppIcons.stableford
AppIcons.skins, AppIcons.vegas, AppIcons.nassau, AppIcons.wolf

// Vibe/Stakes
AppIcons.competitive, AppIcons.casual
AppIcons.noMoney, AppIcons.lowStakes, AppIcons.highStakes

// Profile/Status
AppIcons.editProfile, AppIcons.camera, AppIcons.logOut
AppIcons.joined, AppIcons.owner, AppIcons.pending
```

### Icon Usage
```dart
AppIcon(
  assetPath: AppIcons.games,
  size: AppIconSize.md,
  color: AppColors.navy,
  semanticLabel: 'Games',
)
```

---

## 7. Component Library Mapping

### Button Component
**File**: `lib/core/widgets/app_button_enhanced.dart`

| Figma Button Style | Flutter Variant |
|--------------------|-----------------|
| Filled green | `AppButtonVariant.primary` |
| Outlined | `AppButtonVariant.secondary` |
| Text only | `AppButtonVariant.ghost` |
| Gradient | `AppButtonVariant.gradient` |
| Red/destructive | `AppButtonVariant.destructive` |

| Figma Button Size | Flutter Size | Height |
|-------------------|--------------|--------|
| Small | `AppButtonSize.small` | 36px |
| Medium | `AppButtonSize.medium` | 48px |
| Large | `AppButtonSize.large` | 56px |
| XLarge | `AppButtonSize.xlarge` | 64px |

```dart
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  size: AppButtonSize.large,
  onPressed: () => {},
  leadingSvgPath: AppIcons.games,  // or leadingIcon: Icons.add
)
```

### Card Component
**File**: `lib/core/widgets/app_card.dart`

| Figma Card Style | Flutter Variant |
|------------------|-----------------|
| Standard shadow | `AppCardVariant.standard` |
| Strong shadow | `AppCardVariant.elevated` |
| Border only | `AppCardVariant.outlined` |
| Gradient accent bar | `AppCardVariant.gradientAccent` |
| Premium gold glow | `AppCardVariant.premium` |
| Glass effect | `AppCardVariant.glass` |

```dart
AppCard(
  variant: AppCardVariant.gradientAccent,
  padding: AppSpacing.card,
  onTap: () => {},
  child: Column(...),
)
```

### Badge Component
**File**: `lib/core/widgets/app_badge.dart`

| Figma Badge Color | Flutter Variant |
|-------------------|-----------------|
| Green | `AppBadgeVariant.success` |
| Gold | `AppBadgeVariant.warning` |
| Red | `AppBadgeVariant.error` |
| Blue | `AppBadgeVariant.info` |
| Brand green | `AppBadgeVariant.primary` |
| Grey | `AppBadgeVariant.subtle` |

```dart
AppBadge(
  label: 'Confirmed',
  variant: AppBadgeVariant.success,
  size: AppBadgeSize.medium,
  icon: Icons.check_circle,
)
```

### Text Component
**File**: `lib/core/widgets/app_text.dart`

```dart
// Named constructors for common patterns:
AppText.screenTitle('Games')      // 24px Fraunces
AppText.sectionHeader('Details')  // 20px Manrope
AppText.cardTitle('Game Name')    // 18px Manrope
AppText.body('Description')       // 16px Manrope
AppText.caption('2h ago')         // 12px Manrope
AppText.button('Submit')          // 16px semiBold
```

### Section Header
**File**: `lib/core/widgets/app_section_header.dart`

```dart
AppSectionHeader(
  title: 'Recent Games',
  subtitle: 'Last 30 days',
  actionText: 'See All',
  onActionTap: () => {},
  leadingSvgPath: AppIcons.games,
)
```

### Input Field
**File**: `lib/core/widgets/app_text_field.dart`

```dart
AppTextField(
  hintText: 'Search golfers...',
  value: controller.text,
  onChanged: (v) => {},
  svgIconPath: AppIcons.search,
)
```

---

## 8. Motion/Animation

### Token Location
`lib/core/motion/motion_tokens.dart`

### Duration Tokens

| Animation Type | Enter | Exit |
|----------------|-------|------|
| Route transition | 200ms | 170ms |
| Bottom sheet | 260ms | 220ms |
| Dialog | 200ms | 170ms |
| Backdrop fade | — | 160ms |
| Content reveal | 160ms | — |
| Micro-interaction | 100ms | 100ms |

### Curves
```dart
MotionTokens.curveEnter  // Curves.easeOutCubic (arrive smooth)
MotionTokens.curveExit   // Curves.easeInCubic (depart snappy)
```

### Scale Values
```dart
MotionTokens.pageScaleStart   // 0.985 (subtle)
MotionTokens.dialogScaleStart // 0.97 (noticeable)
```

### Stagger Animation
```dart
MotionTokens.staggerDelay    // 24ms between items
MotionTokens.staggerMaxItems // 8 items max
```

---

## 9. Premium UI Patterns

### Location
`lib/core/design_patterns/premium_ui_patterns.dart`

### Glass Card
```dart
GlassCard(
  child: Text('Stats'),
  padding: AppSpacing.card,
  opacity: 0.3,
)
```

### Gradient Icon Box
```dart
GradientIconBox(
  icon: Icons.sports_golf,  // or svgPath
  gradientColors: [AppColors.gold, AppColors.goldLight],
  size: 48,
  iconSize: 24,
)
```

### Animated Avatar Ring
```dart
AnimatedAvatarRing(
  imageUrl: user.photoUrl,
  size: 132,
  onEditTap: () => {},
)
```

---

## 10. Code Generation Guidelines

When generating Flutter code from Figma designs:

### Color Mapping
1. Identify color role (interactive/structural/premium)
2. Map to appropriate `AppColors.*` token
3. Use interaction state variants for hover/pressed

### Typography Mapping
1. Match font family (Fraunces/Manrope/DM Mono)
2. Find closest size in scale
3. Use `AppTypography.*` constant

### Spacing Mapping
1. Round to nearest 8px grid value
2. Use `AppSpacing.*` token
3. For 20px, prefer semantic `screenPadding` or `cardPadding`

### Component Selection
1. Check if `lib/core/widgets/app_*.dart` component exists
2. Use existing component with appropriate variant
3. Only create custom widget if no match

### Layout Pattern
```dart
Container(
  padding: AppSpacing.card,
  decoration: BoxDecoration(
    color: AppColors.pure,
    borderRadius: BorderRadius.circular(AppBorderRadius.card),
    boxShadow: [AppElevation.card],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText.cardTitle('Title'),
      SizedBox(height: AppSpacing.xs),
      AppText.body('Content'),
    ],
  ),
)
```

---

## 11. Asset Management

### Image Assets
- **Location**: `assets/images/`
- **Caching**: Use `CachedNetworkImage` for remote images
- **Fallbacks**: Provide placeholder widgets

### Icon Assets
- **Location**: `assets/icon/golf-app-icons/`
- **Format**: SVG
- **Access**: Via `AppIcons.*` constants

### Font Assets
- **Location**: `assets/fonts/`
- **Families**: Fraunces, Manrope, DM Mono

---

## 12. Responsive Design

### Breakpoints (Not formalized)
- Mobile-first design
- Max content width considerations handled per-screen

### Safe Areas
- Use `SafeArea` widget
- Account for notches/dynamic islands
- Bottom nav clearance via `bottomNavigationBarHeight`

---

## Quick Reference Card

```dart
// COLORS
AppColors.green        // #3A8F65 — CTAs
AppColors.navy         // #1B2E4A — Structural
AppColors.gold         // #C49A3D — Premium

// TYPOGRAPHY
AppTypography.headlineMedium  // Screen titles
AppTypography.bodyMedium      // Body text
AppTypography.monoLarge       // Scores

// SPACING
AppSpacing.md    // 16px
AppSpacing.card  // EdgeInsets.all(20)

// RADIUS
AppBorderRadius.card  // 12px

// ELEVATION
AppElevation.card  // Standard card shadow

// ICONS
AppIcon(assetPath: AppIcons.games, size: AppIconSize.md)

// MOTION
duration: MotionTokens.microInteraction  // 100ms
curve: MotionTokens.curveEnter           // easeOutCubic
```
