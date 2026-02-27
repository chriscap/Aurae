# Aurae Design System Reference

Version: 1.1
Last Updated: 2026-02-19
Source of Truth: `/Aurae/DesignSystem/` Swift files

This document is the human-readable reference for the Aurae iOS design system. Every value here maps directly to a Swift token in the codebase. Never use raw hex values, hardcoded sizes, or unlisted fonts in any Aurae view. Always reference the corresponding Swift constant.

---

## Table of Contents

1. [Color Palette](#1-color-palette)
2. [Severity Color Scale](#2-severity-color-scale)
3. [Typography Scale](#3-typography-scale)
4. [Layout Constants](#4-layout-constants)
5. [Component Specs — AuraeButton](#5-component-specs--auraebutton)
6. [Component Specs — SeveritySelector](#6-component-specs--severityselector)
7. [Component Specs — LogCard](#7-component-specs--logcard)
8. [Usage Rules](#8-usage-rules)

---

## 1. Color Palette

All colors are defined in `Colors.swift` as static `Color` extensions. Use the Swift token name everywhere. Never reference hex values directly in views.

### Primary Palette

| Token Name | Hex | Role | Swift Reference |
|---|---|---|---|
| `auraeNavy` | `#3A3E4B` | Primary text, headings (Soft Ink) | `Color.auraeNavy` |
| `auraeSlate` | `#2E3240` | Secondary headings, dark surfaces | `Color.auraeSlate` |
| `auraeTeal` | `#8AC4C1` | Brand accent, CTA button fill, active states, chart lines — **do not use as text** | `Color.auraeTeal` |
| `auraeSoftTeal` | `#C6E2E0` | Muted mint surface: premium highlights, tag fills, active status badge fill | `Color.auraeSoftTeal` |

### Surface Palette

| Token Name | Hex | Role | Swift Reference |
|---|---|---|---|
| `auraeBackground` | `#F6F7FA` | Cloud White. Primary app background (light mode) | `Color.auraeBackground` |
| `auraeLavender` | `#EDE8F4` | Pale Lavender. Secondary surfaces, selected states, subtle dividers | `Color.auraeLavender` |

### Text Palette

| Token Name | Hex | Role | Swift Reference |
|---|---|---|---|
| `auraeMidGray` | `#6D717F` | Secondary text, labels, metadata, unselected pill labels. 4.54:1 WCAG AA on Cloud White. | `Color.auraeMidGray` |

### Accessibility-Safe Text Variants

> **Rule:** Never use `auraeTeal` (`#8AC4C1`) or `auraeSoftLavender` (`#B6A6CA`) directly as text or icon foreground colour on light backgrounds — they fail WCAG AA. Use these darker variants instead.

| Token Name | Hex | Contrast vs Cloud White | Role | Swift Reference |
|---|---|---|---|---|
| `auraeTealAccessible` | `#3E7B78` | 4.55:1 (AA ✓) | Teal text/icons on light backgrounds: secondary button labels, links, `auraeTeal`-coloured captions | `Color.auraeTealAccessible` |
| `auraeLavenderAccessible` | `#8064A2` | 5.1:1 (AA ✓) | Lavender text/icons on light backgrounds | `Color.auraeLavenderAccessible` |
| `auraeSeverityLabelSelected` | `#1C2826` | ≥ 10:1 on teal (AAA ✓) | Text on severity pill fills and primary CTA button label — dark ink readable on every accent colour | `Color.auraeSeverityLabelSelected` |

### Severity Base Colors

| Token Name | Hex | Role | Swift Reference |
|---|---|---|---|
| `auraeBlush` | `#F5E8E8` | Severity 5 surface — warm, non-aggressive alert | `Color.auraeBlush` |
| `auraeSage` | `#D4EDE9` | Severity 1 surface — calm, positive (Mint Sage) | `Color.auraeSage` |

### Dark Mode Surface Tokens

| Token Name | Hex | Level | Swift Reference |
|---|---|---|---|
| `auraeDeepSlate` | `#1A1D24` | L0 — primary background | `Color.auraeDeepSlate` |
| `auraeSecondaryBackgroundDark` | `#22262F` | L1 — secondary background | `Color.auraeSecondaryBackgroundDark` |
| `auraeCardDark` | `#2A2E39` | L2 — elevated card surface | `Color.auraeCardDark` |
| `auraeStarlight` | `#E8EAED` | Dark mode primary text | `Color.auraeStarlight` |
| `auraeSoftInk` | `#3A3E4B` | Light mode primary text alias | `Color.auraeSoftInk` |
| `auraeSoftLavender` | `#B6A6CA` | Premium/AI accent — fills and icons only, not text | `Color.auraeSoftLavender` |

### Gradient Tokens

> **Rule:** Apply `auraePrimaryGradient` only on: paywall hero, premium badge, logomark renders, upgrade CTA. Never on body text or data charts.

| Token Name | From | To | Angle | Swift Reference |
|---|---|---|---|---|
| `auraePrimaryGradient` | `#8AC4C1` | `#B6A6CA` | 45° | `Color.auraePrimaryGradient` |
| `auraeSubtleGradient` | `#8AC4C1` | `#C6E2E0` | 180° | `Color.auraeSubtleGradient` |

### Categorical / Chart Accent Colors

These are used exclusively for chart data series and onboarding icons. Do not use them for UI chrome.

| Token Name | Hex | Role | Swift Reference |
|---|---|---|---|
| `auraeIndigo` | `#7B6BA0` | Health/HRV data, calm/neutral chart accent | `Color.auraeIndigo` |
| `auraeAmber` | `#C4894A` | Weather/environmental data, warm-risk chart accent | `Color.auraeAmber` |
| `auraeDarkSage` | `#5A9E9A` | Selected states, chart lines, positive lifestyle data | `Color.auraeDarkSage` |

---

## 2. Severity Color Scale

The severity system maps integer values 1–5 to both a surface (background) and an accent (foreground/indicator) color. These are computed via static functions in `Colors.swift`. Never hardcode these hex values; call the functions.

### Surface Colors (Backgrounds)

| Level | Name | Hex | Swift Call |
|---|---|---|---|
| 1 — Mild | Mint Sage | `#D4EDE9` | `Color.severitySurface(for: 1)` |
| 2 — Moderate-Low | Muted Mint | `#C6E2E0` | `Color.severitySurface(for: 2)` |
| 3 — Moderate | Pale Lavender | `#EDE8F4` | `Color.severitySurface(for: 3)` |
| 4 — Severe | Pale Purple-Rose | `#EDE0F0` | `Color.severitySurface(for: 4)` |
| 5 — Very Severe | Pale Blush | `#F5E8E8` | `Color.severitySurface(for: 5)` |

### Accent Colors (Foreground / Indicators)

These are used as **fill backgrounds** on selected severity pills and as severity bar/indicator fills. Use `auraeSeverityLabelSelected` (#1C2826) for text on top of these fills.

| Level | Name | Hex | Swift Call |
|---|---|---|---|
| 1 — Mild | Dark Teal | `#5A9E9A` | `Color.severityAccent(for: 1)` |
| 2 — Moderate-Low | Mid Teal | `#7ABAB7` | `Color.severityAccent(for: 2)` |
| 3 — Moderate | Mid Lavender | `#8A7AB8` | `Color.severityAccent(for: 3)` |
| 4 — Severe | Deeper Lavender-Purple | `#9B6CA8` | `Color.severityAccent(for: 4)` |
| 5 — Very Severe | Muted Rose-Red | `#C47A7A` | `Color.severityAccent(for: 5)` |

### Severity Level Labels

| Int Value | Enum Case | Full Label | Short Label (compact) |
|---|---|---|---|
| 1 | `.mild` | Mild | 1 |
| 2 | `.moderate` | Moderate | 2 |
| 3 | `.severe` | Severe | 3 |
| 4 | `.verySevere` | Very Severe | 4 |
| 5 | `.worst` | Worst | 5 |

---

## 3. Typography Scale

Defined in `Typography.swift`. Two typefaces are used across the entire app. Never introduce a third typeface.

### Typefaces

| Family | PostScript Name (Regular) | PostScript Name (Variant) | Role |
|---|---|---|---|
| Fraunces | `Fraunces72pt-Regular` | `Fraunces72pt-Bold` | Display and heading typeface. Emotive, editorial. |
| Plus Jakarta Sans | `PlusJakartaSans-Regular` | `PlusJakartaSans-SemiBold` | Body and UI typeface. Clear, functional. |

Font files are declared in `Info.plist` under "Fonts provided by application" and stored in `Resources/Fonts/`.

### Semantic Type Scale

All scale tokens support Apple Dynamic Type via `relativeTo:` scaling. The base size is the size at the default content size category (Large).

| Token | Typeface | Weight | Base Size | Line Height | Dynamic Type Style | Usage |
|---|---|---|---|---|---|---|
| `auraeDisplay` | Fraunces | Bold | 48pt | 56pt | `.largeTitle` | Home screen hero numbers, app name |
| `auraeH1` | Fraunces | Bold | 32pt | 40pt | `.title` | Top-level section headings |
| `auraeH2` | Fraunces | Regular | 22pt | 28pt | `.title2` | Sub-section headings, card titles |
| `auraeBody` | Plus Jakarta Sans | Regular | 16pt | 24pt | `.body` | Primary reading copy, form fields |
| `auraeLabel` | Plus Jakarta Sans | SemiBold | 13pt | 18pt | `.caption` | Interactive labels, tab bar, pill text, secondary/destructive button labels |
| `auraeCaption` | Plus Jakarta Sans | Regular | 12pt | 16pt | `.caption2` | Timestamps, metadata, fine print, badge labels |

### Button Typography (Not in semantic scale)

The primary button uses a distinct font size not shared with other scale tokens.

| Context | Typeface | Weight | Size |
|---|---|---|---|
| Primary button label | Fraunces | Bold | 18pt (relativeTo: `.body`) |
| Secondary / Destructive button label | Plus Jakarta Sans | SemiBold | 16pt (relativeTo: `.body`) |

### Swift Usage

```swift
Text("Log Headache")
    .font(.auraeDisplay)

Text("Your History")
    .font(.auraeH1)

Text("March 2026")
    .font(.auraeH2)

Text("Some description text.")
    .font(.auraeBody)

Text("Label")
    .font(.auraeLabel)

Text("3 hours ago")
    .font(.auraeCaption)
```

---

## 4. Layout Constants

Defined in `Typography.swift` under `enum Layout`. Use these constants in all views. Never hardcode numeric spacing or sizing values.

| Constant | Value | Type | Usage |
|---|---|---|---|
| `Layout.screenPadding` | 20pt | `CGFloat` | Horizontal padding applied to full-screen edges |
| `Layout.cardRadius` | 18pt | `CGFloat` | Corner radius for all card and surface containers |
| `Layout.cardShadowRadius` | 8pt | `CGFloat` | Blur radius for card drop shadows |
| `Layout.cardShadowOpacity` | 0.07 | `Double` | Opacity for card drop shadows |
| `Layout.cardShadowY` | 4pt | `CGFloat` | Vertical offset for card drop shadows |
| `Layout.buttonHeight` | 56pt | `CGFloat` | Fixed height of the primary CTA button |
| `Layout.buttonRadius` | 16pt | `CGFloat` | Corner radius of the primary CTA button |
| `Layout.minTapTarget` | 44pt | `CGFloat` | Minimum accessible tap target (Apple HIG / WCAG 2.1 AA) |
| `Layout.sectionSpacing` | 32pt | `CGFloat` | Vertical space between top-level page sections |
| `Layout.itemSpacing` | 12pt | `CGFloat` | Vertical space between items within a section or card |
| `Layout.cardPadding` | 16pt | `CGFloat` | Inner padding for card surfaces |
| `Layout.severityPillHeight` | 44pt | `CGFloat` | Height of each severity pill. Meets minimum tap target. |
| `Layout.severityPillRadius` | 12pt | `CGFloat` | Corner radius of severity pill buttons |

### Swift Usage

```swift
.padding(.horizontal, Layout.screenPadding)
.cornerRadius(Layout.cardRadius)
.shadow(
    color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
    radius: Layout.cardShadowRadius,
    x: 0,
    y: Layout.cardShadowY
)
```

---

## 5. Component Specs — AuraeButton

File: `Components/AuraeButton.swift`

`AuraeButton` is the single button component for all CTA actions in Aurae. It supports three variants via the `AuraeButtonStyle` enum.

### Variants

| Variant | Enum Case | Fill | Label Color | Border | Use When |
|---|---|---|---|---|---|
| Primary | `.primary` | `auraeTeal` (`#8AC4C1`) | `auraeSeverityLabelSelected` (`#1C2826`) dark ink — ≥ 10:1 contrast | None | Single most important action per screen |
| Secondary | `.secondary` | Transparent | `auraeTealAccessible` (`#3E7B78`) — 4.55:1 contrast | `auraeTealAccessible` 1.5pt | A supporting second CTA is required |
| Destructive | `.destructive` | Transparent | `#B03A2E` muted red | `#B03A2E` 1.5pt | Irreversible or delete actions |

### States

| State | Visual Treatment |
|---|---|
| Default | Full opacity, no scale transform |
| Pressed | Scale 0.97 with spring animation (`response: 0.3, dampingFraction: 0.6`). Scale is 1.0 when Reduce Motion is enabled. |
| Loading | Label replaced with `ProgressView`. Action blocked. |
| Disabled | Opacity 0.5. Interaction blocked. |

### Sizing

| Property | Value | Token Reference |
|---|---|---|
| Height | 56pt | `Layout.buttonHeight` |
| Width | Full-width (`maxWidth: .infinity`) | — |
| Corner radius | 16pt | `Layout.buttonRadius` |
| Primary font | Fraunces Bold 18pt | `.fraunces(18, weight: .bold, relativeTo: .body)` |
| Secondary/Destructive font | Plus Jakarta Sans SemiBold 16pt | `.jakarta(16, weight: .semibold, relativeTo: .body)` |

### Interaction Behavior

- Haptic feedback: `UIImpactFeedbackGenerator(style: .medium)` fires on every valid tap.
- Press animation: `easeIn(duration: 0.08)` on press down; spring release on lift.
- Reduce Motion: Scale effect replaced with `pressedScale = 1.0` (no visual scale).

### Accessibility

- `accessibilityLabel`: Set to the button `title` string.
- `accessibilityHint`: Set to `"Loading, please wait."` when `isLoading` is true.
- Minimum tap target: 56pt height exceeds the 44pt minimum.

### Swift Usage

```swift
// Primary CTA
AuraeButton("Log Headache") { logHeadache() }

// With loading state
AuraeButton("Log Headache", isLoading: isCapturing) { logHeadache() }

// Secondary action
AuraeButton("View Insights", style: .secondary) { openInsights() }

// Destructive action
AuraeButton("Delete All Data", style: .destructive) { deleteAll() }

// Disabled
AuraeButton("Log Headache", isDisabled: true) {}
```

---

## 6. Component Specs — SeveritySelector

File: `Components/SeveritySelector.swift`

`SeveritySelector` renders a horizontal row of five labelled pill buttons bound to a `SeverityLevel` value via `@Binding`. It includes a compact mode for use in constrained containers.

### Modes

| Mode | Parameter | Label Style | Horizontal Padding |
|---|---|---|---|
| Default | `compact: false` | Full label text (e.g., "Moderate") | 10pt |
| Compact | `compact: true` | Numeric short label (e.g., "2") | 8pt |

### Pill Anatomy

| Property | Value | Token Reference |
|---|---|---|
| Height | 44pt | `Layout.severityPillHeight` |
| Width | Equal-width (`.maxWidth: .infinity`) | — |
| Corner radius | 12pt | `Layout.severityPillRadius` |
| Row gap | 8pt | — |
| Font | Plus Jakarta Sans SemiBold 13pt | `.auraeLabel` |
| Minimum scale factor | 0.7 | — |

### Pill States

**Unselected:**
- Background: `Color.severitySurface(for: level.rawValue)`
- Label: `Color.auraeMidGray`
- Border: `Color.severityAccent(for: level.rawValue)` at 20% opacity, 1.5pt stroke
- Shadow: None

**Selected:**
- Background: `Color.severityAccent(for: level.rawValue)`
- Label: `Color.auraeSeverityLabelSelected` (`#1C2826`) — dark ink, NOT white. White fails WCAG AA on levels 1, 2, and 5.
- Border: `Color.severityAccent(for: level.rawValue)` at 100% opacity, 1.5pt stroke
- Shadow: Severity accent color at 25% opacity, radius 4, y-offset 2

### Pill State Color Reference

| Level | Unselected Background | Unselected Border | Selected Background | Selected Label | Selected Border |
|---|---|---|---|---|---|
| 1 — Mild | `#D4EDE9` | `#5A9E9A` at 20% | `#5A9E9A` | `#1C2826` | `#5A9E9A` |
| 2 — Moderate-Low | `#C6E2E0` | `#7ABAB7` at 20% | `#7ABAB7` | `#1C2826` | `#7ABAB7` |
| 3 — Moderate | `#EDE8F4` | `#8A7AB8` at 20% | `#8A7AB8` | `#1C2826` | `#8A7AB8` |
| 4 — Severe | `#EDE0F0` | `#9B6CA8` at 20% | `#9B6CA8` | `#1C2826` | `#9B6CA8` |
| 5 — Very Severe | `#F5E8E8` | `#C47A7A` at 20% | `#C47A7A` | `#1C2826` | `#C47A7A` |

### Interaction Behavior

- Haptic feedback: `UIImpactFeedbackGenerator(style: .light)` fires on each selection change.
- Selection animation: Spring (`response: 0.25, dampingFraction: 0.7`). Disabled when Reduce Motion is on.
- Re-tapping the current selection fires no action and no haptic.

### Accessibility

- The selector is wrapped with `.accessibilityElement(children: .contain)` and labeled "Severity selector".
- Each pill receives `.accessibilityLabel("Severity N of 5 — Label")` (e.g., "Severity 3 of 5 — Severe").
- The selected pill receives `.accessibilityAddTraits(.isSelected)`.
- All pills meet the 44pt minimum tap target via `Layout.severityPillHeight`.

### Swift Usage

```swift
@State private var severity = SeverityLevel.moderate

// Default (full labels)
SeveritySelector(selected: $severity)

// Compact (numeric labels, e.g., inside a LogCard)
SeveritySelector(selected: $severity, compact: true)
```

---

## 7. Component Specs — LogCard

File: `Components/LogCard.swift`

`LogCard` renders a single headache log entry for use in the History list. It is driven by `LogCardViewModel`, a plain struct with no SwiftData dependency.

### Card Anatomy

The card is composed of two main regions in a horizontal stack:

1. **Severity Bar** — a thin 5pt-wide vertical bar on the left edge, filled with `Color.severityAccent(for: severity)`, corner radius 3pt.
2. **Content Column** — a vertical stack with 6pt spacing containing:
   - Top row: severity label (`auraeH2`, `auraeNavy`) + status badge (right-aligned)
   - Onset time (`auraeCaption`, `auraeMidGray`)
   - Context row: weather and/or heart rate chips (shown only if data exists)
   - Retrospective indicator: teal checkmark + "Retrospective complete" caption (shown only if `hasRetrospective` is true)

### Card Container

| Property | Value | Token Reference |
|---|---|---|
| Background | `Color(.systemBackground)` (adaptive white/dark) | — |
| Corner radius | 18pt | `Layout.cardRadius` |
| Inner padding | 16pt all sides | `Layout.cardPadding` |
| HStack spacing | 12pt | `Layout.itemSpacing` |
| Shadow color | `auraeNavy` at 7% opacity | `Layout.cardShadowOpacity` |
| Shadow radius | 8pt | `Layout.cardShadowRadius` |
| Shadow y-offset | 4pt | `Layout.cardShadowY` |

### Status Badge

Appears in the top-right of the card header row.

| State | Background | Text Color |
|---|---|---|
| Active (ongoing) | `auraeSoftTeal` (`#C6E2E0`) | `auraeTealAccessible` (`#3E7B78`) — text-safe teal |
| Inactive (resolved) | `auraeLavender` (`#EDE8F4`) | `auraeMidGray` (`#6D717F`) |

- Shape: Capsule (full radius pill)
- Padding: 8pt horizontal, 4pt vertical
- Font: `auraeCaption` (12pt Plus Jakarta Sans Regular)

### Context Chips

Small icon + label pairs showing weather and heart rate data. Rendered in an HStack with 10pt spacing. Each chip has 4pt spacing between icon and label text.

| Property | Value |
|---|---|
| Icon size | 10pt system font |
| Icon color | `auraeMidGray` |
| Label font | `auraeCaption` |
| Label color | `auraeMidGray` |

### Retrospective Indicator

| Property | Value |
|---|---|
| Icon | `checkmark.circle.fill` at 11pt system font size |
| Icon color | `auraeTealAccessible` (`#3E7B78`) — text-safe teal |
| Label | "Retrospective complete" |
| Label font | `auraeCaption` |
| Label color | `auraeTealAccessible` (`#3E7B78`) — text-safe teal |
| Internal spacing | 4pt |

### Accessibility

- The entire card is wrapped with `.accessibilityElement(children: .combine)`.
- A synthesized accessibility label is generated in this order: onset time, severity label, status (ongoing or duration), weather condition, heart rate.
- Example: "Headache on Mar 15, 2026, 9:30 AM. Severe severity. Duration: 2h. Weather: Cloudy. Heart rate: 82 bpm."

### Swift Usage

```swift
let viewModel = LogCardViewModel(
    id: UUID(),
    onsetTime: Date(),
    resolvedTime: nil,
    severity: 4,
    isActive: true,
    weatherCondition: "Cloudy",
    weatherTemp: 14.5,
    heartRate: 82,
    hasRetrospective: false
)

LogCard(viewModel: viewModel)
```

---

## 8. Usage Rules

These rules are enforced as governance decisions by the design system. Violations must be corrected before code merges.

### Colors

- **Never hardcode hex values in a view.** All colors must reference a `Color` extension token (e.g., `Color.auraeTeal`) or a severity function (e.g., `Color.severityAccent(for: level)`).
- **Never use a raw `Color(hex:)` call outside of `Colors.swift`.** The hex initializer is an internal utility, not a public API for views.
- **Never introduce a new color without adding it to `Colors.swift`** with a descriptive token name and comment.
- **All new colors must support dark mode.** Use SwiftUI's adaptive `Color` initializer if a dark-mode variant is needed.

### Typography

- **Never hardcode a font name or size in a view.** Use the semantic scale tokens (`.auraeH1`, `.auraeBody`, etc.) or the constructor extensions (`.fraunces()`, `.jakarta()`).
- **Never introduce a third typeface.** Fraunces is for headings and display; Plus Jakarta Sans is for all UI and body text.
- **All custom font usage must use `relativeTo:` for Dynamic Type compatibility.**

### Spacing and Sizing

- **Never use a magic number for spacing, padding, or corner radius.** Reference `Layout.*` constants.
- **All interactive elements must meet the 44pt minimum tap target** defined by `Layout.minTapTarget`.

### Components

- **Exhaust composition options before proposing a new component.** Check whether an existing component can be extended with a new variant or state first.
- **All component states must be accounted for** before a component is considered complete: default, pressed, loading, disabled, error, empty, success.

### Accessibility

- **All text must scale with Dynamic Type.** Never use `.fixedSize()` in a way that breaks text scaling.
- **Contrast ratios must meet WCAG 2.1 AA:** 4.5:1 for text, 3:1 for UI elements.
- **All animations must have a Reduce Motion alternative.** Check `@Environment(\.accessibilityReduceMotion)` and disable or simplify animations accordingly.
- **All interactive elements must have an explicit `accessibilityLabel`.** Never rely solely on the visible label for VoiceOver.
