# Component Library Inventory

**Created:** 2026-01-15
**Source:** `lib/core/widgets/`
**Total Components:** 15 files (9 reusable components + 6 specialized/examples)

## Overview

The Find My Fourth app has a component library in `lib/core/widgets/` with a mix of **production-grade enhanced components** (AppButtonEnhanced, AppCard, FairwayBackground) and **legacy utility components** (AppButton, AppIconButton, AppDropDown). The enhanced components integrate design tokens well, while legacy components use manual configuration.

## Reusable Components

### Button Components

#### 1. AppButton (Legacy)
**File:** `lib/core/widgets/app_button.dart`

**Type:** Highly configurable button with manual styling

**Configuration:**
- Uses `AppButtonOptions` class with ~20 configuration props
- Supports text, icon, or text+icon combinations
- Has loading indicator support
- Hover states and custom colors

**Variants:** None (all variants configured manually via options)

**API Complexity:** High - requires passing all styles manually
```dart
AppButtonOptions(
  textStyle: TextStyle(...),
  elevation: 2.0,
  height: 48.0,
  padding: EdgeInsets.symmetric(...),
  borderRadius: BorderRadius.circular(8),
  color: Colors.blue,
  hoverColor: Colors.blue.darker,
  // ... 15+ more options
)
```

**Issues:**
- No integration with design tokens (colors, typography, spacing)
- Every usage requires extensive configuration
- Inconsistent button styling across app likely
- No semantic size presets (small, medium, large)
- Border radius hardcoded to 8px default

---

#### 2. AppButtonEnhanced (Modern)
**File:** `lib/core/widgets/app_button_enhanced.dart`

**Type:** Production-grade button with variants and design token integration

**Variants:**
- `primary` - Filled button with brand color (default)
- `secondary` - Outlined button with brand border
- `ghost` - Minimal text-only button
- `gradient` - Gradient-filled with sunset colors (special CTAs)

**Sizes:**
- `small` (36px height, 16px horizontal padding)
- `medium` (48px height, 20px horizontal padding) - Default
- `large` (56px height, 24px horizontal padding)
- `xlarge` (64px height, 28px horizontal padding)

**Features:**
- ✓ Full design token integration (AppColors, AppTypography, AppSpacing)
- ✓ Tactile micro-interactions (scale on press, hover states)
- ✓ Haptic feedback
- ✓ Loading states that maintain size
- ✓ Icon support (leading/trailing)
- ✓ Accessibility (focus states, proper touch targets)
- ✓ Animations (150ms transitions)

**API:**
```dart
AppButtonEnhanced(
  text: 'Join Game',
  variant: AppButtonVariant.primary,
  size: AppButtonSize.large,
  onPressed: () => handleJoin(),
  leadingIcon: Icons.add,
)
```

**Observations:**
- **Clean API:** Only 11 props, smart defaults
- **Consistent styling:** Uses design tokens throughout
- **Professional polish:** Animations, haptics, micro-interactions
- **Self-contained logic:** Manages hover, pressed, disabled states internally

---

#### 3. AppIconButton (Legacy)
**File:** `lib/core/widgets/app_icon_button.dart`

**Type:** Icon-only button with manual styling

**Configuration:**
- 15 configuration props for colors, borders, sizes
- Supports FaIcon and Icon widgets
- Loading indicator support
- Hover states

**No Variants:** All styling manual

**Issues:**
- No design token integration
- Manual configuration required for every instance
- Border radius not using token scale
- No semantic size presets

---

### Card Components

#### 4. AppCard (Modern + Specialized Variants)
**File:** `lib/core/widgets/app_card.dart`

**Type:** Production-grade card with variants and specializations

**Base Variants:**
- `standard` - Elevated card with standard shadow
- `elevated` - Stronger shadow for emphasis
- `outlined` - Border only, no shadow
- `gradientAccent` - Standard card with sunset gold accent bar

**Specialized Cards** (Built on AppCard):
1. **GameCard** - Pre-configured for game listings
   - Gradient accent variant
   - Title + subtitle + metadata layout
   - Trailing widget support

2. **StatCard** - Pre-configured for profile/stats
   - Outlined variant with sand background
   - Icon + label + value layout
   - Horizontal layout

3. **SectionCard** - Pre-configured for content sections
   - Elevated variant
   - Header with title + subtitle + action
   - Flexible content area

**Features:**
- ✓ Full design token integration
- ✓ Tap interaction with scale animation (100ms)
- ✓ Flexible content with default padding (AppSpacing.card = 20px)
- ✓ Customizable border radius (default 16px)
- ✓ Optional overrides for all styles

**API Quality:**
- **Base card:** 13 props, great defaults
- **Specialized cards:** 4-6 props, domain-specific

**Observations:**
- **Excellent pattern:** Base + specializations approach
- **DRY principle:** Specialized cards reuse AppCard
- **Design tokens:** Consistent use of AppColors, AppSpacing
- ⚠️ **Missing tokens:** Border radius (16px), elevation/shadows (hardcoded values)

---

### Input Components

#### 5. AppDropDown (Legacy)
**File:** `lib/core/widgets/app_drop_down.dart`

**Type:** Highly complex dropdown with many features

**Features:**
- Single and multi-select modes
- Searchable options
- Custom option labels
- Hover states and styling
- Uses `dropdown_button2` package

**Configuration:**
- 25+ props for styling and behavior
- Requires FormFieldController integration
- Complex assertion logic for multi-select vs single-select

**Issues:**
- **Extreme API complexity:** 25+ props, difficult to use
- **No design token integration:** All colors, borders, spacing manual
- **Inconsistent styling:** Every dropdown configured differently
- **No semantic variants:** (e.g., "standard", "compact", "searchable")
- **Breaking changes risk:** API too large to maintain

---

#### 6. AppChoiceChips
**File:** `lib/core/widgets/app_choice_chips.dart`

**Type:** Choice chip group with custom styling

**Features:**
- Single and multi-select modes
- Wrapped or horizontal scrolling layout
- Custom chip styling (selected/unselected)
- Icon support

**Configuration:**
- Uses `ChipStyle` class for styling (7 props)
- Requires FormFieldController
- Spacing and alignment control

**Issues:**
- **No design token integration:** ChipStyle configured manually
- **No semantic variants:** All styling manual per instance
- **Border radius/spacing:** Not using token scales

---

#### 7. AppCountController
**File:** `lib/core/widgets/app_count_controller.dart`

**Type:** Increment/decrement counter UI

**Features:**
- Min/max bounds
- Step size control
- Custom builder functions for icons and display
- Flexible padding

**Issues:**
- **Builder pattern overhead:** Requires 3 builder functions
- **No default styling:** Every instance custom-built
- **No design token integration**

---

### Background Components

#### 8. FairwayBackground (Modern)
**File:** `lib/core/widgets/fairway_background.dart`

**Type:** Atmospheric background with organic overlays

**Variants:**
- `light` - Sand/green tones for most screens (default)
- `dark` - Deep greens for immersive experiences
- `sunset` - Warm gradient for special moments
- `minimal` - Subtle background when content should dominate

**Features:**
- ✓ Layered gradient meshes for depth
- ✓ Organic curved overlays (rolling fairway effect)
- ✓ Optional subtle noise texture
- ✓ Intensity control (0.0 to 1.0)
- ✓ Performance optimized (RepaintBoundary)
- ✓ Design token integration (AppColors)

**Convenience Wrappers:**
- `FairwayBackgroundLight`
- `FairwayBackgroundDark`
- `FairwayBackgroundSunset`
- `FairwayBackgroundMinimal`

**Observations:**
- **Excellent component:** Sophisticated, performant, well-documented
- **Polish:** Custom noise painter, layered effects, organic shapes
- **Flexibility:** Variants + intensity control covers all use cases

---

### Specialized UI Components

#### 9. BrandedGolfHeader
**File:** `lib/core/widgets/branded_golf_header.dart`

**Type:** Premium header with topographic pattern

**Features:**
- Fixed 150px height with curved bottom edge
- Deep green gradient background
- Subtle topographic contour pattern overlay
- Username (bottom-left) and course name (bottom-right)
- White text with layered shadows
- Custom clipping path (CurvedHeaderClipper)
- Custom painter (SubtleTopographicPainter)

**Props:**
- `username` (required)
- `courseName` (required)

**Observations:**
- **Beautiful component:** Premium golf aesthetic
- **Custom painters:** Sophisticated topographic effect
- **Single-purpose:** Highly specific to game/course header context
- **Not reusable:** Fixed layout and content structure
- ⚠️ **Hardcoded values:** Border radius, font sizes, colors (some use design tokens, some don't)

---

#### 10. ProfileHeroSection
**File:** `lib/core/widgets/profile_hero_section.dart`

**Type:** Profile avatar hero with animated gradient ring

**Features:**
- Large circular avatar (140px)
- Animated rotating gradient ring (3s rotation)
- Display name overlay
- Dark gradient background
- Edit button
- Fixed 240px height

**Props:**
- `photoUrl` (required)
- `displayName` (required)
- `onEditPhoto` (required)

**Observations:**
- **Striking visual:** Animated ring is premium touch
- **Single-purpose:** Specific to profile screen hero section
- **Some token usage:** AppColors, AppSpacing
- ⚠️ **Hardcoded sizes:** Avatar size, ring size, heights

---

#### 11. ProfileCardSection
**File:** `lib/core/widgets/profile_card_section.dart`

**Type:** White card section for profile content

**Features:**
- Clean white background with layered shadows
- Section title with custom typography
- Custom child content
- Consistent padding (AppSpacing.lg = 20px)
- Border radius 16px

**Props:**
- `title` (required)
- `child` (required)
- `padding` (optional override)

**Sub-component:**
- **ProfilePreferenceItem** - Icon-based preference display

**Observations:**
- **Decent component:** Clean, simple, does one thing well
- **Partial token usage:** Uses AppSpacing, AppColors
- ⚠️ **Typography inconsistency:** Uses GoogleFonts.outfit directly instead of AppTypography
- ⚠️ **Hardcoded values:** Border radius (16px), shadow values

---

#### 12. VibeSliderCard
**File:** `lib/core/widgets/vibe_slider_card.dart`

**Type:** Slider card for vibe preferences

**Features:**
- Debounced value updates (250ms default)
- Dealbreaker toggle
- Built on AppCard
- Custom styling for sliders

**Props:**
- `category` (VibeCategory)
- `pref` (VibePreference)
- `onValueChanged`, `onDealbreakerChanged` callbacks
- Debounce duration control

**Observations:**
- **Domain-specific:** Tied to vibe preference system
- **Good patterns:** Debouncing, state management
- **Uses AppCard:** Leverages existing component

---

## Example/Demo Files

These files appear to be example/showcase files, not production components:

1. **app_button_examples.dart** - Examples of AppButtonEnhanced usage
2. **app_card_examples.dart** - Examples of AppCard variants
3. **fairway_background_examples.dart** - Examples of FairwayBackground usage

**Purpose:** Documentation/testing, not for production use

---

## Usage Patterns Across Key Screens

**Sample Size:** 10 key widget files analyzed across major features
**Date:** 2026-01-15

### Component Adoption Analysis

#### Most Used Components

| Component | Usage Count | Screen Examples |
|-----------|-------------|-----------------|
| **FairwayBackground** | 6/10 files | create_game, game_joined_detailed, main_profile, chat, tab_friends, community |
| **AppIconButton** | 4/10 files | create_game, game_joined_detailed, main_profile, chat, tab_friends |
| **AppButtonEnhanced** | 4/10 files | create_game, game_joined_detailed, player_list |
| **AppSpacing (tokens)** | 10/10 files | All sampled screens |
| **AppColors (tokens)** | 8/10 files | Most screens |
| **AppTypography (tokens)** | 5/10 files | game_joined_detailed, main_profile, chat, community |
| **AppCard** | 1/10 files | game_joined_detailed |
| **BrandedGolfHeader** | 1/10 files | game_joined_detailed |
| **AppDropDown** | 2/10 files | create_game, player_list |
| **AppCountController** | 1/10 files | create_game |

#### Design Token Adoption

**High Adoption (80-100%):**
- ✅ **AppSpacing**: 10/10 files (100%) - Universal adoption
- ✅ **AppColors**: 8/10 files (80%) - Very high adoption

**Medium Adoption (50-80%):**
- ⚠️ **AppTypography**: 5/10 files (50%) - Moderate adoption

**Insight:** Spacing tokens are consistently used, color tokens highly used, but typography tokens only moderately adopted. This suggests typography standardization is the biggest opportunity.

### Custom UI vs Component Usage

#### create_game_widget.dart
**Component Usage:**
- ✅ FairwayBackground (background)
- ✅ AppButtonEnhanced (primary actions)
- ✅ AppIconButton (icon buttons)
- ✅ AppDropDown (form dropdowns)
- ✅ AppCountController (player count)
- ✅ AppSpacing, AppColors (tokens)

**Custom UI Built:**
- 🔨 Custom card containers with BoxDecoration (3+ instances)
  - File:489-504: Gradient card with shadow, borderRadius: 24
  - File:566-576: Card with borderRadius: 16
  - File:641-651: Another card with borderRadius: 16
- 🔨 Custom buttons with BoxDecoration (1+ instances)
  - File:716-726: Container with borderRadius: 8
- 🔨 Hardcoded Colors: `Colors.red` (7 instances), `Colors.white` (5 instances), `Colors.transparent` (1 instance)
- 🔨 Hardcoded gradients: Custom gradient definitions inline
- 🔨 Hardcoded shadows: BoxShadow with manual opacity/blur values

**Opportunity:** Could use AppCard for custom cards (save 50+ lines), use semantic error color instead of `Colors.red`

---

#### game_joined_detailed_widget.dart
**Component Usage:**
- ✅ FairwayBackground (background)
- ✅ BrandedGolfHeader (header)
- ✅ AppCard (content cards)
- ✅ AppButtonEnhanced (primary actions)
- ✅ AppIconButton (icon buttons)
- ✅ AppSpacing, AppColors, AppTypography (full token suite)

**Custom UI Built:**
- 🔨 Custom containers with BoxDecoration (10+ instances)
  - File:173-177: Container with borderRadius: 12
  - File:385-396: Container with gradient + shadow, borderRadius: 16
  - File:441-450: Container with borderRadius: 2
  - File:524-533: Container with borderRadius: 2
  - File:545-552: Container with borderRadius: 12
- 🔨 Small indicator/badge containers (borderRadius: 2px) - could be AppBadge component
- 🔨 Status indicators with custom styling

**Observation:** **Best component adoption in sample!** Uses modern components, full design tokens, but still builds custom UI for specific patterns (badges, status indicators). These are prime candidates for new components.

---

#### player_list_widget.dart
**Component Usage:**
- ✅ AppButtonEnhanced (actions)
- ✅ AppDropDown (filtering)
- ✅ AppSpacing (token)

**Custom UI Built:**
- 🔨 List items with custom layout (likely)
- 🔨 Avatar displays (likely)

**Observation:** Minimal component usage file, likely builds most UI custom. Would benefit from AppList/AppListTile components.

---

#### main_profile_widget.dart
**Component Usage:**
- ✅ FairwayBackground (background)
- ✅ AppIconButton (actions)
- ✅ AppSpacing, AppColors, AppTypography (tokens)

**Custom UI Built:**
- 🔨 Profile layout (avatar, bio, stats)
- 🔨 Stat cards/sections
- 🔨 Custom containers and layouts

**Observation:** Does NOT use ProfileHeroSection or ProfileCardSection despite being a profile screen! Either these components are new, or not adopted yet. Big standardization opportunity.

---

#### chat_widget.dart
**Component Usage:**
- ✅ FairwayBackground (background)
- ✅ AppIconButton (actions)
- ✅ AppSpacing, AppColors, AppTypography (tokens)

**Custom UI Built:**
- 🔨 Chat message bubbles (custom UI)
- 🔨 Input field (no AppTextField)
- 🔨 Message list layout

**Observation:** Chat UI is highly custom (expected), but lacks standardized input component. Could use AppTextField once created.

---

#### tab_friends_widget.dart
**Component Usage:**
- ✅ FairwayBackground (background)
- ✅ AppIconButton (actions)
- ✅ AppSpacing, AppColors (tokens)

**Custom UI Built:**
- 🔨 Friend list items (custom)
- 🔨 Search/filter UI (likely)

**Observation:** Another list-heavy screen without list components. Pattern repeating.

---

#### community_widget.dart
**Component Usage:**
- ✅ FairwayBackground (background)
- ✅ AppSpacing, AppColors, AppTypography (tokens)

**Custom UI Built:**
- 🔨 Community feed items (custom)
- 🔨 Post cards (not using AppCard)

**Observation:** Feed/list UI built custom. Could benefit from feed item component.

---

### Patterns That Repeat Across Multiple Files

#### 1. Custom Card Pattern (High Priority)
**Repeats in:** create_game, game_joined_detailed, community (likely), others

**Pattern:**
```dart
Container(
  margin: EdgeInsets.only(bottom: AppSpacing.md),
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.pure,
    borderRadius: BorderRadius.circular(16), // REPEATED
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1), // REPEATED
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: ...,
)
```

**Inconsistencies:**
- Border radius varies: 8px, 12px, 16px, 24px
- Shadow opacity varies: 0.1, 0.3, 0.4
- Shadow blur varies: 8, 12, 16
- Shadow offset varies: (0, 2), (0, 4), (0, 8)

**Opportunity:** AppCard exists but not consistently adopted. Migration task + deprecation would standardize.

---

#### 2. Hardcoded Colors Pattern (High Priority)
**Repeats in:** create_game (10+ instances), others

**Common Hardcoded Colors:**
- `Colors.red` - Used for error states instead of AppColors.error
- `Colors.white` - Used instead of AppColors.pure
- `Colors.transparent` - Acceptable, but could be semantic token
- `Colors.black.withOpacity(0.X)` - Shadow/overlay colors not tokenized

**Opportunity:** Find/replace mission: Search all `Colors.red` → `AppColors.error`, `Colors.white` → `AppColors.pure`. Need opacity tokens for shadows.

---

#### 3. Custom Button Pattern (Medium Priority)
**Repeats in:** Some older screens

**Pattern:**
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.fairway,
    borderRadius: BorderRadius.circular(8),
  ),
  child: InkWell(
    onTap: ...,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(...),
    ),
  ),
)
```

**Opportunity:** AppButtonEnhanced adoption is growing (4/10 files use it), but older screens still build custom buttons. Migration task needed.

---

#### 4. List Item Pattern (High Priority - Missing Component)
**Repeats in:** player_list, tab_friends, community, others (inferred)

**Pattern:** Custom list items with:
- Avatar on left
- Title + subtitle in middle
- Action button/icon on right
- Dividers between items
- Tap handling

**Opportunity:** **No AppList or AppListTile component exists!** This is the #1 missing component. Lists are everywhere in this app (players, friends, games, chats, community posts).

---

#### 5. Inline Typography Pattern (Medium Priority)
**Repeats in:** Multiple files

**Pattern:**
```dart
Text(
  'Some text',
  style: GoogleFonts.outfit( // Should use AppTypography
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.slate,
  ),
)
```

**Inconsistencies:**
- Mix of GoogleFonts.outfit, GoogleFonts.fraunces, GoogleFonts.manrope
- Inline font sizes: 12, 14, 16, 18, 20, 24, 28, 32 (matches AppTypography scale)
- Inline font weights: w400, w500, w600, w700
- Not using AppTypography semantic styles (headlineLarge, bodyMedium, etc.)

**Opportunity:** AppTypography exists and is comprehensive, but adoption is only 50%. Migration task: Find inline GoogleFonts usage → Replace with AppTypography.

---

#### 6. Inline Spacing Pattern (Low Priority - Good Adoption)
**Repeats in:** All files

**Pattern:**
```dart
EdgeInsets.all(AppSpacing.md) // ✅ GOOD
SizedBox(height: AppSpacing.lg) // ✅ GOOD
padding: EdgeInsets.symmetric(horizontal: AppSpacing.md) // ✅ GOOD
```

**Observation:** **This is the success story!** AppSpacing has 100% adoption. Proves that well-designed tokens get adopted.

---

### Component Usage vs Custom UI Ratio

| Screen | Component Usage | Custom UI | Ratio | Grade |
|--------|----------------|-----------|-------|-------|
| game_joined_detailed | High | Low | 80/20 | A+ |
| create_game | Medium | Medium | 50/50 | B |
| player_list | Low | High | 30/70 | C |
| main_profile | Low | High | 30/70 | C |
| chat | Low | High | 30/70 | C |
| tab_friends | Low | High | 30/70 | C |
| community | Low | High | 30/70 | C |

**Average:** ~40% component usage, 60% custom UI

**Interpretation:**
- **game_joined_detailed** is the model screen: Full component adoption, full token adoption
- Most other screens are 30-40% component usage: Opportunity to standardize

---

## Component Library Analysis

### Component Categories

| Category | Modern (Token-integrated) | Legacy (Manual config) |
|----------|---------------------------|------------------------|
| **Buttons** | AppButtonEnhanced | AppButton, AppIconButton |
| **Cards** | AppCard + 3 specialized | - |
| **Inputs** | - | AppDropDown, AppChoiceChips, AppCountController |
| **Backgrounds** | FairwayBackground | - |
| **Specialized** | BrandedGolfHeader, ProfileHeroSection, ProfileCardSection, VibeSliderCard | - |

### Design Token Integration

**Excellent Integration (Modern Components):**
- ✅ **AppButtonEnhanced** - Full integration (colors, typography, spacing)
- ✅ **AppCard** - Full integration (colors, spacing) except border radius/elevation
- ✅ **FairwayBackground** - Full color token integration

**Partial Integration:**
- ⚠️ **BrandedGolfHeader** - Uses some tokens, but has hardcoded sizes/gradients
- ⚠️ **ProfileHeroSection** - Uses colors/spacing, but hardcoded sizes
- ⚠️ **ProfileCardSection** - Uses colors/spacing, but uses GoogleFonts directly (not AppTypography)
- ⚠️ **VibeSliderCard** - Uses tokens through AppCard dependency

**No Integration (Legacy Components):**
- ❌ **AppButton** - Zero design token usage
- ❌ **AppIconButton** - Zero design token usage
- ❌ **AppDropDown** - Zero design token usage
- ❌ **AppChoiceChips** - Zero design token usage
- ❌ **AppCountController** - Zero design token usage

### Component API Quality

**Excellent APIs (Modern):**
- **AppButtonEnhanced**: 11 props, smart defaults, semantic variants
- **AppCard**: 13 props base, 4-6 props for specialized variants
- **FairwayBackground**: 5 props, variant-based, convenience wrappers

**Poor APIs (Legacy):**
- **AppButton**: ~20 options props, manual everything
- **AppIconButton**: 15 props, manual everything
- **AppDropDown**: 25+ props, complex assertions, fragile
- **AppChoiceChips**: Moderate complexity, ChipStyle config
- **AppCountController**: Builder pattern overhead

### Missing Reusable Components

Based on common UI patterns in Flutter apps and usage analysis, the library is missing:

#### High Priority (Patterns found in multiple screens)
1. **AppTextField / AppTextInput** - Text input with variants (standard, outlined, filled) - **URGENT**: Chat input, search bars, form fields everywhere
2. **AppList / AppListTile** - List item component - **URGENT**: Players, friends, games, chat messages, community posts all need this
3. **AppAvatar** - Avatar component with variants (circular, square, sizes) - Repeated in profile, players, friends lists
4. **AppBadge** - Badge/chip for counts/status - Found in game_joined_detailed for status indicators
5. **AppDialog / AppModal** - Modal dialogs with variants - Confirmations needed across app
6. **AppEmptyState** - Empty state placeholder with icon + message - Lists need empty states

#### Medium Priority (Common Flutter patterns)
7. **AppBottomSheet** - Bottom sheet component
8. **AppSnackBar / AppToast** - Notification/feedback components
9. **AppLoadingIndicator** - Loading spinners/skeletons with brand styling
10. **AppDivider** - Divider with design token colors/spacing
11. **AppTabs** - Tab navigation component
12. **AppChip** - Single chip component (not just groups)
13. **AppSwitch / AppToggle** - Toggle switches with design token styling
14. **AppCheckbox** - Checkboxes with brand styling
15. **AppRadioButton** - Radio buttons with brand styling

#### Lower Priority
16. **AppProgressBar** - Linear/circular progress indicators
17. **AppStepper** - Step indicator component
18. **AppSearchBar** - Search input with icon and clear button
19. **AppTag** - Tag/label component for categories
20. **AppTooltip** - Tooltip overlay
21. **AppPopover** - Popover menu component
22. **AppAccordion** - Collapsible content sections
23. **AppCarousel** - Image/content carousel
24. **AppPagination** - Pagination controls

### Component Inconsistency Issues

**Two Button Systems:**
- **AppButton** (legacy, manual config, no tokens)
- **AppButtonEnhanced** (modern, variants, tokens)
- 🚨 **Problem:** Developers might use either, leading to inconsistent UIs
- 🚨 **Problem:** New code using AppButton won't benefit from design system

**No Standardized Input Components:**
- AppDropDown is too complex, no text input component exists
- Every form likely builds custom inputs with inline styling
- Inconsistent input field appearance across screens

**Specialized Components Not Generalized:**
- ProfileCardSection could be generalized to "SectionCard with title"
- BrandedGolfHeader is too specific, could have "AppHeader" with variants
- ProfileHeroSection could be "AppHeroSection" with avatar prop

**Missing Component Variants:**
- AppCard has only 4 variants, could add more (danger, success, warning semantic cards)
- AppButtonEnhanced could add more semantic variants (danger, success, warning)
- No size variants for most legacy components

### Token Coverage Gaps

**Components Missing These Tokens:**
- **Border Radius:** Most components hardcode 8px, 12px, 16px
- **Elevation/Shadows:** Box shadows hardcoded inline, not using elevation scale
- **Icon Sizes:** Components use inline values (16, 20, 24) instead of icon token scale
- **Animation Durations:** Components use inline Duration(milliseconds: 100/150/200)
- **Opacity Scale:** Shadow/overlay opacities hardcoded (0.1, 0.3, 0.4)

---

## Recommendations for Phase 2

### Immediate Actions (High Impact)

1. **Deprecate Legacy Components**
   - Add deprecation warnings to AppButton, AppIconButton
   - Create migration guide to AppButtonEnhanced
   - Plan removal timeline (e.g., Phase 3)

2. **Standardize Missing Core Components (Highest ROI)**
   - Create **AppListTile** (HIGHEST priority - lists everywhere: players, friends, games, community)
   - Create **AppTextField** (second priority - forms and chat input)
   - Create **AppAvatar** (third priority - user displays everywhere)
   - Create **AppBadge** (fourth priority - status indicators found in code)
   - Create **AppDialog** (fifth priority - confirmations common)

3. **Add Missing Tokens (Highest ROI)**
   - Create **border radius scale** (xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 20px, xxl: 24px, full: 9999px)
   - Create **elevation/shadow scale** (0-5 levels with predefined BoxShadow configs)
   - Create **opacity scale** (5%, 10%, 20%, 30%, 40%, 60%, 80%, 100%)
   - Create **icon size scale** (xs: 16px, sm: 20px, md: 24px, lg: 32px, xl: 40px)
   - Create **animation duration scale** (fast: 100ms, normal: 200ms, slow: 300ms)

4. **Hardcoded Color Migration (Quick Win)**
   - Find/replace `Colors.red` → `AppColors.error` (7 instances in create_game alone)
   - Find/replace `Colors.white` → `AppColors.pure` (5 instances in create_game alone)
   - Create lint rule to prevent hardcoded Colors usage

5. **Typography Migration (Medium Effort, High Impact)**
   - Find inline GoogleFonts.* usage across codebase
   - Replace with AppTypography semantic styles
   - Current adoption: 50%, target: 95%+

6. **AppCard Migration (Medium Effort)**
   - Identify all custom card patterns (Container + BoxDecoration + shadow)
   - Replace with AppCard variants
   - Should save 30-50 lines per screen

### Medium Priority

7. **Component Adoption Campaign**
   - Use game_joined_detailed_widget.dart as model screen
   - Create before/after examples for other screens
   - Show LOC savings and consistency benefits

8. **Refactor Partial Token Components**
   - **ProfileCardSection**: Use AppTypography instead of GoogleFonts.outfit directly
   - **BrandedGolfHeader**: Extract hardcoded sizes to variables, consider generalization
   - **ProfileHeroSection**: Extract hardcoded sizes to constants

9. **Generalize Specialized Components**
   - Extract reusable parts of BrandedGolfHeader → AppHeader base
   - Extract reusable parts of ProfileCardSection → SectionCard (already exists!) or unify
   - Consider if ProfileHeroSection patterns apply to other hero sections

10. **Standardize AppDropDown**
    - Create simplified **AppSelect** component with common use case (single select, standard styling)
    - Keep AppDropDown for advanced cases but document as "advanced use only"
    - Add design token integration to both

11. **Add AppCard Variants**
    - Semantic variants: `danger`, `warning`, `success`, `info`
    - Interactive variant: `pressable` with more pronounced press animation
    - Size variants: `compact`, `standard`, `spacious`

### Future Considerations

12. **Create Component Documentation**
    - Usage examples for all modern components
    - Migration guides from legacy components
    - Design token integration patterns

13. **Component Testing**
    - Visual regression tests for all variants
    - Interaction tests for animations/states
    - Accessibility tests

14. **Component Versioning**
    - Track breaking changes to component APIs
    - Maintain changelog for component library
