# Icon Size Mapping Reference

This document defines which `AppIconSize` token to use for every icon context in the app. When migrating hardcoded icon sizes, use this reference to choose the correct token.

## Token Values

| Token | Pixels | Semantic Aliases |
|-------|--------|-----------------|
| `AppIconSize.xs` | 16 | — |
| `AppIconSize.sm` | 20 | `AppIconSize.button` |
| `AppIconSize.md` | 24 | `AppIconSize.nav`, `AppIconSize.listItem` |
| `AppIconSize.lg` | 32 | `AppIconSize.section` |
| `AppIconSize.xl` | 40 | `AppIconSize.feature` |
| `AppIconSize.xxl` | 48 | `AppIconSize.avatar` |

## Context → Token Mapping

### Navigation & App Shell
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Bottom nav bar icons | `AppIconSize.nav` | 24 | Used by AppNavIcon in main.dart |
| App bar back/close button | `AppIconSize.md` | 24 | Standard dismiss affordance |
| App bar action icons | `AppIconSize.md` | 24 | — |
| Drawer / menu icons | `AppIconSize.md` | 24 | — |

### Buttons & Interactive Elements
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Icon inside a button (CTA) | `AppIconSize.button` | 20 | Matches app_button_enhanced |
| Icon-only button (IconButton) | `AppIconSize.md` | 24 | Tap target should still be 48px via padding |
| FAB inner icon | `AppIconSize.md` | 24 | — |
| Close/dismiss "X" icon | `AppIconSize.md` | 24 | — |
| Chip / tag icon | `AppIconSize.xs` | 16 | Small inline context |

### Form Fields
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Text field prefix icon | `AppIconSize.button` | 20 | Inside input decoration |
| Text field suffix icon | `AppIconSize.button` | 20 | Inside input decoration |
| Search icon in search bar | `AppIconSize.button` | 20 | — |
| Dropdown arrow / chevron | `AppIconSize.button` | 20 | — |

### Cards & List Items
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Leading icon in list tile | `AppIconSize.listItem` | 24 | Standard list context |
| Trailing icon in list tile (chevron) | `AppIconSize.button` | 20 | Secondary, should be smaller |
| Icon in card header | `AppIconSize.listItem` | 24 | — |
| Icon in info row / stat row | `AppIconSize.button` | 20 | Compact data display |
| Icon inside a gradient circle on a card | `AppIconSize.button` | 20 | Icon is visually framed by the circle |

### Detail Pages & Sections
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Section header icon | `AppIconSize.section` | 32 | Larger for visual hierarchy |
| Icon in a gradient badge (detail hero) | `AppIconSize.button` | 20 | If badge is small (28-32px container) |
| Icon in a gradient badge (detail hero) | `AppIconSize.listItem` | 24 | If badge is larger (36-40px container) |
| Icon in an info/stat pill | `AppIconSize.xs` | 16 | Very compact context |

### Trust & Badge System
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Trust badge chip icon | `AppIconSize.xs` | 16 | Tiny inline badge. Closest token for current 14px |
| Trust section header icon | `AppIconSize.listItem` | 24 | — |
| Trust tier icon in circle | `AppIconSize.listItem` | 24 | Inside a gradient circle |
| Restriction banner icon | `AppIconSize.listItem` | 24 | Closest token for current 22px |
| Warning/cancellation small icon | `AppIconSize.xs` | 16 | Inline warnings |

### Empty States & Feedback
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Empty state large icon | `AppIconSize.xxl` | 48 | Central attention-drawing icon |
| Error state icon | `AppIconSize.xxl` | 48 | — |
| Success confirmation large icon | `AppIconSize.xxl` | 48 | Closest token. For truly large (64px), consider adding a token or using xxl |
| Rating / feedback icon | `AppIconSize.xxl` | 48 | — |

### Chat
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Chat input bar send button icon | `AppIconSize.md` | 24 | — |
| Chat input bar attachment icon | `AppIconSize.md` | 24 | — |
| Chat bubble reaction icon | `AppIconSize.xs` | 16 | Tiny inline |
| Chat header action icon | `AppIconSize.md` | 24 | — |
| Chat close/dismiss | `AppIconSize.md` | 24 | Use md (24) not 30px |

### Onboarding
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Onboarding step icon (in circle) | `AppIconSize.section` | 32 | Prominent feature showcase |
| Onboarding CTA button icon | `AppIconSize.button` | 20 | — |
| Increment/decrement stepper icon | `AppIconSize.md` | 24 | — |

### Profile
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Profile action button icon | `AppIconSize.button` | 20 | — |
| Profile info row icon | `AppIconSize.button` | 20 | — |
| Profile section icon (in circle) | `AppIconSize.listItem` | 24 | — |
| Camera/edit avatar overlay | `AppIconSize.md` | 24 | — |
| Profile placeholder person icon | `AppIconSize.listItem` | 24 | Closest token for current 26px |

## Migration Decision Guide

When you encounter a hardcoded size, use this decision tree:

```
Hardcoded value → Find matching context above → Use that token

If no exact context match:
  14px → AppIconSize.xs (16px) — accept 2px visual bump, maintains system
  16px → AppIconSize.xs (16px)
  18px → AppIconSize.button (20px) — accept 2px bump, OR AppIconSize.xs if truly tiny
  20px → AppIconSize.button (20px) or AppIconSize.sm (20px)
  22px → AppIconSize.md (24px) — accept 2px bump, OR AppIconSize.button if compact
  24px → AppIconSize.md (24px)
  26px → AppIconSize.md (24px) — accept 2px reduction
  28px → AppIconSize.lg (32px) — accept 4px bump, OR AppIconSize.md if should be smaller
  30px → AppIconSize.lg (32px) — accept 2px bump
  32px → AppIconSize.lg (32px)
  36px → AppIconSize.xl (40px) — accept 4px bump
  40px → AppIconSize.xl (40px)
  48px → AppIconSize.xxl (48px)
  64px → AppIconSize.xxl (48px) — NOTE: significant reduction. Consider if this should stay custom.
```

## Exception Cases

Some sizes may legitimately stay hardcoded:
- **64px icons** (e.g., peer_rating_screen.dart thumbs up): If 48px is too small, this may warrant adding an `AppIconSize.xxxl` token. Flag these for review rather than forcing to 48.
- **Icons whose size comes from a parameter** (e.g., `size: iconSize` where iconSize is passed in): These are fine as long as the CALLER passes an AppIconSize token.
- **Third-party widget constraints**: If a widget like `InputDecoration` dictates icon sizing through its own system, and wrapping causes layout issues, document the exception.

## Notes on Near-Value Migrations

Several current sizes (14, 18, 22, 26) don't have exact token matches. The migrations to the nearest token will cause **minor visual changes** (1-2px). This is intentional — it brings the app into a consistent 4px-increment grid. If any specific case looks wrong after migration, adjust by picking the adjacent token, not by re-hardcoding a pixel value.
