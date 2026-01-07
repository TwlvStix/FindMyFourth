# Spacing System

Comprehensive spacing design tokens for the "Find My Fourth" golf app following "Elevated Country Club Modernism" aesthetic.

**Design Philosophy**: Generous, rhythmic spacing creates breathing room and visual hierarchy that feels sophisticated and refined—appropriate for a premium golf experience.

---

## Features

✅ **8-Point Grid System**: Mathematical progression for visual harmony
✅ **Semantic Naming**: cardPadding, screenPadding, buttonGap, etc.
✅ **Shortcuts**: Pre-configured EdgeInsets and SizedBox widgets
✅ **List Extensions**: Convenient spacing helpers for widget lists
✅ **Flexible Scale**: 4px to 64px covers all spacing needs
✅ **Type-Safe**: Const values, no magic numbers

---

## Base Spacing Scale

The spacing system uses an 8-point grid with 4px increments for flexibility:

| Token | Value | Usage |
|-------|-------|-------|
| `AppSpacing.xxs` | 4px | Minimum spacing, icon padding, micro adjustments |
| `AppSpacing.xs` | 8px | Tight spacing between closely related elements |
| `AppSpacing.sm` | 12px | Compact lists, chip gaps, small component padding |
| `AppSpacing.md` | 16px | **Default spacing**, comfortable element separation |
| `AppSpacing.lg` | 20px | Medium-large spacing, breathing room |
| `AppSpacing.xl` | 24px | Section spacing, card padding, list item padding |
| `AppSpacing.xxl` | 32px | Major section separation, screen margins |
| `AppSpacing.xxxl` | 48px | Large section breaks, hero padding |
| `AppSpacing.xxxxl` | 64px | Hero sections, full-screen padding |

**Choosing the Right Size:**
- **xxs-xs**: Micro spacing within components (icon + text)
- **sm-md**: Default spacing between related elements
- **lg-xl**: Sections and containers
- **xxl+**: Major page sections and hero areas

---

## Semantic Spacing

Named patterns for common use cases:

### Component Spacing
```dart
AppSpacing.cardPadding          // 20px - Padding inside cards
AppSpacing.cardGap              // 16px - Gap between cards
AppSpacing.buttonPadding        // 16px - Button internal padding
AppSpacing.buttonGap            // 12px - Gap between buttons
AppSpacing.iconTextGap          // 8px - Icon to text spacing
AppSpacing.chipGap              // 8px - Spacing in chip groups
```

### Layout Spacing
```dart
AppSpacing.screenPadding        // 20px - Default screen edge padding
AppSpacing.sectionHeaderGap     // 16px - Below section headers
AppSpacing.listItemGap          // 16px - Between list items
AppSpacing.listItemPadding      // 12px - Within list items
```

### Form Spacing
```dart
AppSpacing.formFieldGap         // 16px - Between form fields
AppSpacing.formFieldPadding     // 12px - Inside form fields
AppSpacing.modalPadding         // 24px - Around modals/dialogs
```

---

## EdgeInsets Shortcuts

Pre-configured EdgeInsets for common patterns:

### All Sides
```dart
AppSpacing.allXxs              // EdgeInsets.all(4)
AppSpacing.allXs               // EdgeInsets.all(8)
AppSpacing.allSm               // EdgeInsets.all(12)
AppSpacing.allMd               // EdgeInsets.all(16)
AppSpacing.allLg               // EdgeInsets.all(20)
AppSpacing.allXl               // EdgeInsets.all(24)
AppSpacing.allXxl              // EdgeInsets.all(32)
```

### Symmetric
```dart
// Horizontal only
AppSpacing.horizontalMd        // EdgeInsets.symmetric(horizontal: 16)
AppSpacing.horizontalLg        // EdgeInsets.symmetric(horizontal: 20)
AppSpacing.horizontalXl        // EdgeInsets.symmetric(horizontal: 24)

// Vertical only
AppSpacing.verticalXs          // EdgeInsets.symmetric(vertical: 8)
AppSpacing.verticalSm          // EdgeInsets.symmetric(vertical: 12)
AppSpacing.verticalMd          // EdgeInsets.symmetric(vertical: 16)
AppSpacing.verticalLg          // EdgeInsets.symmetric(vertical: 20)
AppSpacing.verticalXl          // EdgeInsets.symmetric(vertical: 24)
```

### Semantic Patterns
```dart
AppSpacing.screen              // EdgeInsets.all(20) - Screen padding
AppSpacing.screenHorizontal    // EdgeInsets.symmetric(horizontal: 20)
AppSpacing.screenVertical      // EdgeInsets.symmetric(vertical: 20)
AppSpacing.card                // EdgeInsets.all(20) - Card padding
AppSpacing.modal               // EdgeInsets.all(24) - Modal padding
```

---

## SizedBox Shortcuts

Pre-configured SizedBox widgets for spacing in Column/Row:

### Vertical Spacing
```dart
AppSpacing.verticalXxs         // SizedBox(height: 4)
AppSpacing.verticalXsBox       // SizedBox(height: 8)
AppSpacing.verticalSmBox       // SizedBox(height: 12)
AppSpacing.verticalMdBox       // SizedBox(height: 16)
AppSpacing.verticalLgBox       // SizedBox(height: 20)
AppSpacing.verticalXlBox       // SizedBox(height: 24)
AppSpacing.verticalXxlBox      // SizedBox(height: 32)
AppSpacing.verticalXxxlBox     // SizedBox(height: 48)
```

### Horizontal Spacing
```dart
AppSpacing.horizontalXxs       // SizedBox(width: 4)
AppSpacing.horizontalXsBox     // SizedBox(width: 8)
AppSpacing.horizontalSmBox     // SizedBox(width: 12)
AppSpacing.horizontalMdBox     // SizedBox(width: 16)
AppSpacing.horizontalLgBox     // SizedBox(width: 20)
AppSpacing.horizontalXlBox     // SizedBox(width: 24)
AppSpacing.horizontalXxlBox    // SizedBox(width: 32)
```

---

## List Extensions

Convenient helpers for adding spacing to widget lists:

### withVerticalSpacing
```dart
Column(
  children: [
    Widget1(),
    Widget2(),
    Widget3(),
  ].withVerticalSpacing(AppSpacing.md),
)

// Equivalent to:
Column(
  children: [
    Widget1(),
    SizedBox(height: 16),
    Widget2(),
    SizedBox(height: 16),
    Widget3(),
  ],
)
```

### withHorizontalSpacing
```dart
Row(
  children: [
    Button1(),
    Button2(),
    Button3(),
  ].withHorizontalSpacing(AppSpacing.buttonGap),
)

// Equivalent to:
Row(
  children: [
    Button1(),
    SizedBox(width: 12),
    Button2(),
    SizedBox(width: 12),
    Button3(),
  ],
)
```

### withSpacing (Both Directions)
```dart
Wrap(
  children: [
    Chip1(),
    Chip2(),
    Chip3(),
  ].withSpacing(AppSpacing.chipGap),
)
```

---

## Usage Patterns

### Basic Screen Layout
```dart
class GameListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FairwayBackgroundLight(
        child: Padding(
          padding: AppSpacing.screen,  // 20px all sides
          child: Column(
            children: [
              SectionHeader(),
              AppSpacing.verticalMdBox,  // 16px
              GameCard(),
              AppSpacing.verticalMdBox,  // 16px
              GameCard(),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Card with Internal Spacing
```dart
Container(
  padding: AppSpacing.card,  // 20px all sides
  decoration: BoxDecoration(
    color: AppColors.pure,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Game Title', style: AppTypography.headlineMedium),
      AppSpacing.verticalXsBox,  // 8px
      Text('Details', style: AppTypography.bodyMedium),
      AppSpacing.verticalSmBox,  // 12px
      ActionButtons(),
    ],
  ),
)
```

### Form Layout
```dart
Column(
  children: [
    TextField(
      decoration: InputDecoration(
        contentPadding: AppSpacing.allSm,  // 12px
      ),
    ),
    AppSpacing.verticalMdBox,  // 16px between fields
    TextField(
      decoration: InputDecoration(
        contentPadding: AppSpacing.allSm,
      ),
    ),
    AppSpacing.verticalXlBox,  // 24px before button
    AppButtonEnhanced(
      text: 'Submit',
      onPressed: () => submit(),
    ),
  ],
)
```

### Button Row
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    AppButtonEnhanced(
      text: 'Cancel',
      variant: AppButtonVariant.ghost,
      onPressed: () => cancel(),
    ),
    AppSpacing.horizontalSmBox,  // 12px between buttons
    AppButtonEnhanced(
      text: 'Save',
      variant: AppButtonVariant.primary,
      onPressed: () => save(),
    ),
  ],
)

// Or using extension:
Row(
  children: [
    CancelButton(),
    SaveButton(),
  ].withHorizontalSpacing(AppSpacing.buttonGap),
)
```

### List Items
```dart
ListView.separated(
  itemCount: games.length,
  separatorBuilder: (context, index) =>
      SizedBox(height: AppSpacing.listItemGap),  // 16px between items
  itemBuilder: (context, index) => Container(
    padding: AppSpacing.allLg,  // 20px inside item
    child: GameListItem(games[index]),
  ),
)
```

### Modal/Dialog
```dart
Dialog(
  child: Padding(
    padding: AppSpacing.modal,  // 24px all sides
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Confirm Action', style: AppTypography.headlineMedium),
        AppSpacing.verticalMdBox,  // 16px
        Text('Are you sure?', style: AppTypography.bodyMedium),
        AppSpacing.verticalXlBox,  // 24px
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CancelButton(),
            ConfirmButton(),
          ].withHorizontalSpacing(AppSpacing.buttonGap),
        ),
      ],
    ),
  ),
)
```

### Hero Section
```dart
Container(
  padding: AppSpacing.allXxxl,  // 48px padding
  child: Column(
    children: [
      Text(
        'Find Your Fourth',
        style: AppTypography.displayLarge,
      ),
      AppSpacing.verticalXlBox,  // 24px
      Text(
        'Connect with golfers',
        style: AppTypography.bodyLarge,
      ),
      AppSpacing.verticalXxlBox,  // 32px
      AppButtonEnhanced(
        text: 'Get Started',
        size: AppButtonSize.xlarge,
        onPressed: () => navigate(),
      ),
    ],
  ),
)
```

---

## Utility Methods

### Custom Spacing
```dart
// Custom EdgeInsets
AppSpacing.only(left: 20, top: 16)
AppSpacing.symmetric(horizontal: 24, vertical: 16)

// Custom SizedBox
AppSpacing.vertical(100)  // SizedBox(height: 100)
AppSpacing.horizontal(80)  // SizedBox(width: 80)
```

---

## Best Practices

### 1. Use Semantic Names First
```dart
// Good - Semantic
padding: AppSpacing.card

// Acceptable - Base scale
padding: AppSpacing.allLg

// Avoid - Magic numbers
padding: EdgeInsets.all(20)
```

### 2. Maintain Visual Rhythm
```dart
// Good - Consistent spacing between similar elements
Column(
  children: [
    ListItem1(),
    AppSpacing.verticalMdBox,  // 16px
    ListItem2(),
    AppSpacing.verticalMdBox,  // 16px
    ListItem3(),
  ],
)

// Better - Use list extension
Column(
  children: [
    ListItem1(),
    ListItem2(),
    ListItem3(),
  ].withVerticalSpacing(AppSpacing.listItemGap),
)
```

### 3. Create Visual Hierarchy with Spacing
```dart
Column(
  children: [
    // Title section
    SectionTitle(),
    AppSpacing.verticalSmBox,  // 12px - Tight with subtitle
    SectionSubtitle(),

    AppSpacing.verticalXlBox,  // 24px - Separate sections

    // Content section
    ContentCard(),
    AppSpacing.verticalMdBox,  // 16px - Between cards
    ContentCard(),
  ],
)
```

### 4. Don't Mix Spacing Systems
```dart
// Avoid - Mixing spacing tokens with magic numbers
Column(
  children: [
    Widget1(),
    SizedBox(height: 15),  // ❌ Not in scale
    Widget2(),
    AppSpacing.verticalMdBox,  // ✅ Correct
    Widget3(),
  ],
)

// Good - Consistent use of tokens
Column(
  children: [
    Widget1(),
    AppSpacing.verticalSmBox,  // ✅ 12px
    Widget2(),
    AppSpacing.verticalMdBox,  // ✅ 16px
    Widget3(),
  ],
)
```

### 5. Responsive Spacing (Future Enhancement)
```dart
// For now, use consistent spacing
// Later: Add responsive helpers for different screen sizes
final screenWidth = MediaQuery.of(context).size.width;
final padding = screenWidth > 600
    ? AppSpacing.xxl  // Tablet/Desktop
    : AppSpacing.lg;   // Mobile
```

---

## Migration Guide

### From Hardcoded Values
```dart
// Before
Padding(
  padding: EdgeInsets.all(20),
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: 16),
      Widget2(),
    ],
  ),
)

// After
Padding(
  padding: AppSpacing.card,
  child: Column(
    children: [
      Widget1(),
      AppSpacing.verticalMdBox,
      Widget2(),
    ],
  ),
)
```

### From EdgeInsetsDirectional.fromSTEB
```dart
// Before
EdgeInsetsDirectional.fromSTEB(20.0, 16.0, 20.0, 0.0)

// After
AppSpacing.only(left: 20, top: 16, right: 20)
// Or
EdgeInsets.only(
  left: AppSpacing.lg,
  top: AppSpacing.md,
  right: AppSpacing.lg,
)
```

---

## Integration with Other Design Tokens

The spacing system works seamlessly with colors, typography, and other design tokens:

```dart
Container(
  padding: AppSpacing.card,  // Spacing token
  decoration: BoxDecoration(
    color: AppColors.pure,  // Color token
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    children: [
      Text(
        'Game Title',
        style: AppTypography.headlineMedium  // Typography token
            .withColor(AppColors.fairwayDark),
      ),
      AppSpacing.verticalXsBox,  // Spacing token
      Text(
        'Details',
        style: AppTypography.bodyMedium
            .withColor(AppColors.slate),
      ),
    ],
  ),
)
```

---

## Troubleshooting

### Spacing Feels Too Tight
```dart
// Increase to next step in scale
AppSpacing.sm  →  AppSpacing.md  (12px → 16px)
AppSpacing.md  →  AppSpacing.lg  (16px → 20px)
AppSpacing.lg  →  AppSpacing.xl  (20px → 24px)
```

### Spacing Feels Too Loose
```dart
// Decrease to previous step
AppSpacing.xl  →  AppSpacing.lg  (24px → 20px)
AppSpacing.lg  →  AppSpacing.md  (20px → 16px)
AppSpacing.md  →  AppSpacing.sm  (16px → 12px)
```

### Need In-Between Value
```dart
// Use the 4px increments
AppSpacing.xxs  // 4px
AppSpacing.xs   // 8px
AppSpacing.sm   // 12px - Perfect for between 8px and 16px
```

---

## Component Checklist

- [x] Base spacing scale (xxs to xxxxl)
- [x] Semantic spacing names
- [x] EdgeInsets shortcuts
- [x] SizedBox shortcuts
- [x] List extension helpers
- [x] Utility methods
- [x] Comprehensive documentation
- [ ] Apply to existing screens
- [ ] Apply to new components
- [ ] Responsive spacing helpers

---

**Last Updated**: 2026-01-07
**Component**: `lib/core/design_tokens/spacing.dart`
**Design System**: Elevated Country Club Modernism
**Status**: Production Ready ✅
