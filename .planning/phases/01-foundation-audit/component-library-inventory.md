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

Based on common UI patterns in Flutter apps, the library is missing:

#### High Priority
1. **AppTextField / AppTextInput** - Text input with variants (standard, outlined, filled)
2. **AppSwitch / AppToggle** - Toggle switches with design token styling
3. **AppCheckbox** - Checkboxes with brand styling
4. **AppRadioButton** - Radio buttons with brand styling
5. **AppDialog / AppModal** - Modal dialogs with variants
6. **AppBottomSheet** - Bottom sheet component
7. **AppSnackBar / AppToast** - Notification/feedback components
8. **AppBadge** - Badge/chip for counts/status
9. **AppAvatar** - Avatar component with variants (circular, square, sizes)
10. **AppDivider** - Divider with design token colors/spacing
11. **AppLoadingIndicator** - Loading spinners/skeletons with brand styling
12. **AppEmptyState** - Empty state placeholder with icon + message

#### Medium Priority
13. **AppList / AppListTile** - List item component with consistent styling
14. **AppTabs** - Tab navigation component
15. **AppChip** - Single chip component (not just groups)
16. **AppProgressBar** - Linear/circular progress indicators
17. **AppStepper** - Step indicator component
18. **AppSearchBar** - Search input with icon and clear button
19. **AppTag** - Tag/label component for categories

#### Lower Priority
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

---

## Recommendations for Phase 2

### Immediate Actions (High Impact)

1. **Deprecate Legacy Components**
   - Add deprecation warnings to AppButton, AppIconButton
   - Create migration guide to AppButtonEnhanced
   - Plan removal timeline (e.g., Phase 3)

2. **Standardize Missing Core Components**
   - Create **AppTextField** (highest priority - forms everywhere)
   - Create **AppDialog** (second priority - confirmations common)
   - Create **AppAvatar** (third priority - user profiles everywhere)
   - Create **AppLoadingIndicator** (fourth priority - async operations)

3. **Add Missing Tokens**
   - Create **border radius scale** (xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 20px, full: 9999px)
   - Create **elevation/shadow scale** (0-5 levels with predefined BoxShadow configs)
   - Create **icon size scale** (xs: 16px, sm: 20px, md: 24px, lg: 32px, xl: 40px)
   - Create **animation duration scale** (fast: 100ms, normal: 200ms, slow: 300ms)

4. **Refactor Partial Token Components**
   - **ProfileCardSection**: Use AppTypography instead of GoogleFonts.outfit directly
   - **BrandedGolfHeader**: Extract hardcoded sizes to variables, consider generalization
   - **ProfileHeroSection**: Extract hardcoded sizes to constants

### Medium Priority

5. **Generalize Specialized Components**
   - Extract reusable parts of BrandedGolfHeader → AppHeader base
   - Extract reusable parts of ProfileCardSection → SectionCard (already exists!) or unify
   - Consider if ProfileHeroSection patterns apply to other hero sections

6. **Standardize AppDropDown**
   - Create simplified **AppSelect** component with common use case (single select, standard styling)
   - Keep AppDropDown for advanced cases but document as "advanced use only"
   - Add design token integration to both

7. **Add AppCard Variants**
   - Semantic variants: `danger`, `warning`, `success`, `info`
   - Interactive variant: `pressable` with more pronounced press animation
   - Size variants: `compact`, `standard`, `spacious`

### Future Considerations

8. **Create Component Documentation**
   - Usage examples for all modern components
   - Migration guides from legacy components
   - Design token integration patterns

9. **Component Testing**
   - Visual regression tests for all variants
   - Interaction tests for animations/states
   - Accessibility tests

10. **Component Versioning**
    - Track breaking changes to component APIs
    - Maintain changelog for component library
