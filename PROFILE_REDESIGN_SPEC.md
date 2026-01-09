# Profile Page Redesign Specification

## Design Philosophy: "Premium Golf Member Card"

A sophisticated, card-based profile design that feels like a premium golf membership with clean sections, visual hierarchy, and refined micro-interactions.

## Visual Structure

### 1. Hero Section (Profile Photo)
- Large 140px circular avatar centered at top
- Animated gradient ring (fairway green → sunset gold)
- Display name overlaid at bottom of avatar section
- "Edit Photo" button positioned elegantly
- Dark gradient background fading to transparent

### 2. Card Sections
All content organized in elevated white cards with subtle shadows:

#### Personal Information Card
- First Name / Last Name (side-by-side)
- Display Name / Phone (side-by-side)
- Email
- Home Course dropdown
- Clean form fields with focused states

#### Golf Preferences Card
**Icon-based grid layout**
- Handicap (with golf flag icon)
- Play for Money (dollar icon)
Visual counters with +/- buttons

#### Social Preferences Card
**Icon-based grid layout**
- Music (music note icon)
- Drinks (cocktail icon)
- Pace of Play (speedometer icon)
Visual counters with +/- buttons

### 3. Save Button
- Full-width prominent button
- Sunset gold color
- Elevated slightly

## Styling Details

### Colors
- Background: FairwayBackgroundDark with organic pattern
- Cards: Pure white (#FFFEFA) with subtle shadows
- Primary accent: Fairway green
- CTA accent: Sunset gold
- Text: Onyx/Slate greys

### Typography
- Section headers: 18px, semibold, fairway dark
- Labels: 14px, medium, stone grey
- Input text: 16px, regular, onyx
- Display name: 28px, bold, white (on hero)

### Spacing
- Card padding: 20px
- Section gaps: 24px
- Form field gaps: 16px
- Card border radius: 16px

### Shadows
Cards use layered shadows:
```
BoxShadow(
  color: Colors.black.withAlpha(0.04),
  blurRadius: 8,
  offset: Offset(0, 2),
),
BoxShadow(
  color: Colors.black.withAlpha(0.06),
  blurRadius: 16,
  offset: Offset(0, 4),
),
```

## Animations

- Hero avatar: Subtle scale on photo change
- Cards: Staggered fade-in on load (100ms delay between each)
- Form focus: Smooth border color transition
- Counter buttons: Scale on tap
- Save button: Subtle elevation change on press

## Responsive Behavior

- Max width: 600px (centered on tablets)
- Horizontal padding: 16px (mobile), 24px (tablet)
- Cards stack vertically always
- Form fields adjust flex for smaller screens

## Differences from Game Detail Page

1. **No BrandedGolfHeader** - Uses hero avatar section instead
2. **Card-based layout** - Not continuous scrolling sections
3. **Light cards on dark background** - Inverted from game detail
4. **More spacious** - Generous padding and whitespace
5. **Profile-centric** - Avatar is the visual anchor

## Implementation Files

This design will be implemented in:
- `create_profile_widget.dart` - New user profile creation
- `edit_profile_widget.dart` - Existing user profile editing

Both will share the same visual design with different data loading logic.
