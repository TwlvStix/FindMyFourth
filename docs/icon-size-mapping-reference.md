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
| `AppIconSize.xxxl` | 60 | `AppIconSize.hero` — **NEW** (added for hero/empty-state/feedback icons) |

> **Note:** `xxxl` / `hero` is a new token added as part of this cleanup. It covers the ~11 instances of 56-72px icons used in hero sections, empty states, success confirmations, and peer rating screens. Before this token existed, these were all hardcoded to inconsistent values (56, 60, 64, 68, 72).

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

### Empty States, Hero Icons & Feedback
| Context | Token | Pixels | Notes |
|---------|-------|--------|-------|
| Empty state large icon | `AppIconSize.hero` | 60 | Central attention-drawing icon |
| Error state large icon | `AppIconSize.xxl` | 48 | Slightly smaller than hero — secondary emphasis |
| Success confirmation hero icon | `AppIconSize.hero` | 60 | e.g., checkmark on success page |
| Peer rating / feedback hero icon | `AppIconSize.hero` | 60 | e.g., thumbs up on rating screen. Replaces former 64px |
| Onboarding hero illustration icon | `AppIconSize.hero` | 60 | Large feature showcase |
| Small inline error icon | `AppIconSize.xxl` | 48 | Error icon in a content area (not full-page empty state) |

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
  10px → AppIconSize.xs (16px) — likely a decorative dot; verify it's truly an icon, not a decoration
  12px → AppIconSize.xs (16px) — accept 4px bump, or verify if this should be an icon at all
  14px → AppIconSize.xs (16px) — accept 2px visual bump, maintains system
  16px → AppIconSize.xs (16px)
  18px → AppIconSize.button (20px) — accept 2px bump, OR AppIconSize.xs (16px) if truly tiny context
  20px → AppIconSize.button (20px) or AppIconSize.sm (20px)
  22px → AppIconSize.md (24px) — accept 2px bump, OR AppIconSize.button (20px) if compact context
  24px → AppIconSize.md (24px)
  26px → AppIconSize.md (24px) — accept 2px reduction
  28px → AppIconSize.lg (32px) — accept 4px bump, OR AppIconSize.md (24px) if should be smaller
  30px → AppIconSize.lg (32px) — accept 2px bump
  32px → AppIconSize.lg (32px)
  36px → AppIconSize.xl (40px) — accept 4px bump
  40px → AppIconSize.xl (40px)
  48px → AppIconSize.xxl (48px)
  50px → AppIconSize.hero (60px) — accept 10px bump, OR AppIconSize.xxl (48px) if not a hero
  56px → AppIconSize.hero (60px) — accept 4px bump
  60px → AppIconSize.hero (60px)
  64px → AppIconSize.hero (60px) — accept 4px reduction
  68px → AppIconSize.hero (60px) — accept 8px reduction; verify visual impact
  72px → AppIconSize.hero (60px) — accept 12px reduction; verify visual impact
```

### Sizes 10-12px: Verify Before Migrating

The audit found some 10px and 12px sizes. These are unusually small for icons and may actually be:
- Decorative dots or indicators (not icons — leave as-is)
- Badge count text size (not an icon size — leave as-is)  
- Genuinely tiny icons (migrate to `AppIconSize.xs`)

Inspect each case before blindly migrating.

## Exception Cases

Some sizes may legitimately stay hardcoded:
- **Icons whose size comes from a parameter** (e.g., `size: iconSize` where iconSize is passed in): These are fine as long as the CALLER passes an AppIconSize token. Do not modify the parameter itself — fix the call site.
- **Third-party widget constraints**: If a widget like `InputDecoration` dictates icon sizing through its own system, and wrapping causes layout issues, document the exception.
- **Sizes 10-12px that aren't actually icons**: Decorative dots, badge indicators, or tiny visual elements that just happen to use an Icon widget. Leave these alone and add a `// Not an icon size — decorative element` comment.

Sizes that should NOT be exceptions anymore (now that `xxxl`/`hero` exists):
- ~~64px icons~~ → use `AppIconSize.hero` (60px)
- ~~56-60px icons~~ → use `AppIconSize.hero` (60px)
- ~~72px icons~~ → use `AppIconSize.hero` (60px), verify visually

## Notes on Near-Value Migrations

The audit found that 41% of hardcoded sizes are non-standard (don't match any existing token exactly). The most common non-standard values are 14, 18, 22, 26, and 56-72. Migrations to the nearest token will cause **minor visual changes** (typically 2-4px). This is intentional — it brings the app into a consistent grid.

**If a 2px change looks wrong in a specific spot**, adjust by picking the adjacent token, not by re-hardcoding a pixel value. The system has enough granularity (16, 20, 24, 32, 40, 48, 60) to handle virtually every UI context.
