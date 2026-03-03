# Aurae — Figma Design System Rules

> For use with Figma MCP and Token Studio plugin.
> Source of truth: `Colors.swift`, `Typography.swift` in `Aurae/DesignSystem/`

---

## Stack

- **Platform:** iOS (SwiftUI, minimum iOS 16)
- **Fonts:** SF Pro (system font — Figma equivalent: `SF Pro Display` / `SF Pro Text`)
- **Logo mark font:** DM Serif Display Regular — used at 26pt+ only (bundle file: `DMSerifDisplay-Regular.ttf`)
- **Color mode:** Fully adaptive light + dark. Design all screens in both modes.

---

## Token Structure

Tokens are organized in three layers:

| Layer | Purpose | Figma Collection |
|---|---|---|
| `Primitives` | Raw hex values — never used directly in components | `Primitives` |
| `Semantic/Light` + `Semantic/Dark` | Mode-aware semantic aliases | `Semantic` (two modes) |
| `Typography` | Type scale | `Typography` |

Always reference **Semantic** tokens in components, never Primitive hex values directly.

---

## Color Tokens — Key Semantic Aliases

### Surfaces (backgrounds, cards)
| Token | Light | Dark | Usage |
|---|---|---|---|
| `surface/background` | `#FAFBFC` | `#121B28` | App background |
| `surface/card` | `#FFFFFF` | `#1A2332` | All card surfaces |
| `surface/secondary` | `#EFF6FC` | `#1E2A38` | Pill fills, chips, unselected states |
| `surface/subtle` | `#F3F4F6` | `#1A2332` | Activity strips, annotation bg |
| `surface/elevated` | `#EFF6FC` | `#253545` | Sheets, modals above card level |

### Text
| Token | Light | Dark | Usage |
|---|---|---|---|
| `text/primary` | `#1F2937` | `#E1E9F2` | All primary body copy |
| `text/secondary` | `#6B7280` | `#8A9BAD` | Labels, metadata, secondary info |
| `text/caption` | `#6B7280` | `#9CAEBE` | 12–13pt caption/label text (WCAG AA) |
| `text/on-filled` | `#FFFFFF` | `#121B28` | Text sitting on filled action buttons |

### Actions
| Token | Light | Dark | Usage |
|---|---|---|---|
| `action/primary` | `#5B8EBF` | `#6FA8DC` | CTAs, links, active icons, tints |
| `action/accessible` | `#3D6A96` | `#7BA8D1` | Blue text on light/dark surfaces (passes AA) |
| `action/hero-fill` | `#5B8EBF` | `#6FA8DC` | Log Headache hero button fill |
| `action/border` | `#5B8EBF @20%` | `#6FA8DC @15%` | Card hairline borders |
| `action/destructive` | `#EF4444` | `#D87A7A` | Delete, error states |

### Severity (3-level scale)
| Token | Value | Usage |
|---|---|---|
| `severity/mild-accent` | `#6EBF9E` | Mild severity indicator bar, pill fill |
| `severity/moderate-accent` | `#C4935A` | Moderate severity |
| `severity/severe-accent` | `#B85C5C` | Severe severity |
| `severity/mild-surface` | Light: `#D8F0E8` / Dark: `#152A22` | Card tint for mild entries |
| `severity/moderate-surface` | Light: `#F2E4D0` / Dark: `#2A2012` | Card tint for moderate entries |
| `severity/severe-surface` | Light: `#F0D8D8` / Dark: `#2E1A1A` | Card tint for severe entries |

---

## Typography Scale

All type uses **SF Pro** (system font). Figma: use `SF Pro Display` for 20pt+ and `SF Pro Text` for below 20pt.

The logo wordmark "aurae" uses **DM Serif Display Regular** — available in the Fonts folder.

| Token | Size | Weight | Usage |
|---|---|---|---|
| `caption2` | 10 | Regular | Smallest text — use sparingly |
| `caption` | 12 | Regular | Timestamps, metadata |
| `caption-emphasis` | 12 | SemiBold | Section headers in cards |
| `label` | 13 | SemiBold | Interactive labels, tab bar |
| `callout` | 14 | Regular | Supporting text |
| `secondary-label` | 14 | Medium | Card sub-headings |
| `body` | 16 | Regular | Primary reading copy |
| `section-label` | 17 | Medium | Section prompts, form labels |
| `subhead` | 18 | SemiBold | Secondary headings |
| `h2` | 20 | SemiBold | Sub-section headings, card titles |
| `h1` | 26 | SemiBold | Section headings |
| `title1` | 28 | Bold | Modal / sheet titles |
| `large-title` | 34 | Bold | Nav bar large titles (History, Insights, Profile) |
| `display` | 44 | Bold | Hero numerals (streak count, large metrics) |
| `hero` | 48 | Bold | Largest screen titles |

---

## Spacing Scale (AuraeSpacing)

| Token | Value | Usage |
|---|---|---|
| `xxxs` | 2pt | Tight internal gaps |
| `xxs` | 4pt | Icon-to-label spacing |
| `xs` | 8pt | Small insets, chip padding |
| `sm` | 12pt | Compact section gaps |
| `md` | 16pt | Standard row padding |
| `lg` | 20pt | Screen horizontal padding |
| `xl` | 24pt | Section gap, card padding |
| `xxl` | 32pt | Top-level section spacing |
| `xxxl` | 48pt | Large vertical separation |
| `huge` | 64pt | Hero button, full-bleed gaps |

---

## Radius Scale (AuraeRadius)

| Token | Value | Applied to |
|---|---|---|
| `xs` | 8pt | Icon wells (32×32 squares in settings rows) |
| `sm` | 12pt | Buttons, input fields |
| `md` | 16pt | Cards, section group containers |
| `lg` | 20pt | Large cards |
| `xl` | 24pt | Hero cards |
| `full` | 9999pt | Severity pills, status badges, capsule chips |

### Corner radius rule
- **Sharp / `Rectangle()`** → static display containers (stat panels, info cards, the active headache card, export preview)
- **Rounded (`md` = 16pt)** → interactive containers (LogCard rows, Profile section groups, any container the user can tap)
- **Rounded (`sm` = 12pt)** → buttons, input fields
- **`full`** → pills, tags, badges

---

## Component Notes

### Log Headache button (hero)
- Fill: `action/hero-fill`
- Height: 56pt
- Radius: `sm` (12pt)
- Label: `label` (13pt SemiBold), color `text/on-filled`
- Shadow: `#5B8EBF` at 20–30% opacity, blur 16, y 6

### Severity pills (SeveritySelector)
- Height: 44pt
- Radius: `full` (capsule)
- Selected: `severity/*-accent` fill + white label
- Unselected: `surface/secondary` fill + `text/secondary` label

### LogCard (history list)
- Background: `surface/card`
- Radius: `md` (16pt) — tappable, navigates to detail
- Left severity bar: 5pt wide, `severity/*-accent` color, radius 3pt
- Border: `action/border` at 12% opacity, 0.5pt

### Profile section groups
- Background: `surface/card`
- Radius: `md` (16pt) — contain interactive rows
- Border: `action/border` at 1pt

### AuraeLogoMark
- Three concentric ellipses: outer 100%, middle 71%, inner 41% of `markSize`
- Opacity: outer 14%, middle 35%, inner 100%
- Gradient: `#2D7D7D` → `#B3A8D9` (topLeading → bottomTrailing)

---

## Layout Constants

| Constant | Value |
|---|---|
| Screen horizontal padding | 24pt |
| Card inner padding | 20pt |
| Section spacing | 24pt |
| Item spacing | 12pt |
| Min tap target | 44pt |
| Card shadow | black 5%, radius 8, y 2 |

---

## Grid (iPhone)

Design at **390×844** (iPhone 14 base). Safe areas: top 59pt, bottom 34pt.
Content width = 390 − (24 × 2) = **342pt**.

---

## Gradient Reference

| Name | Stops | Direction |
|---|---|---|
| Brand mark | `#2D7D7D` → `#B3A8D9` | Top-left → Bottom-right |
| Primary gradient | `#5B8EBF` → `#7BA8D1` | Top-left → Bottom-right |
| Signature gradient | `#5B8EBF` → `#7BA8D1` → `#9B8EC4` | Top-left → Bottom-right |
