# Aurae — Figma Token Import Guide

How to get your design tokens into Figma and use them.

**Requirements:** Figma Professional plan (or higher) + Token Studio free plugin.

---

## Overview

We use **Token Studio** (free Figma plugin) to import `tokens.json` into Figma's native Variables system. Light/Dark mode switching is handled via **Figma's native Variable Modes** — no Token Studio Pro needed.

---

## Step 1 — Install Token Studio

1. In Figma, open your file → **Plugins → Browse plugins**
2. Search **"Token Studio for Figma"**
3. Click **Install**

---

## Step 2 — Import tokens.json

Token Studio v2 (2.x) has a redesigned UI. The welcome screen you see first is not the main workspace.

1. Open Token Studio: **Plugins → Token Studio for Figma**
2. On the welcome screen, click **"New empty file"** — this opens the main workspace
3. In the main workspace, look for the **"Load tokens"** or file menu option. In v2 this is typically accessible via:
   - A **file/folder icon** in the top toolbar, or
   - A **"..." (more) menu** or hamburger menu icon
   - Select **"Load from file / folder"** or **"Import"**
4. Select `figma/tokens.json` from the Aurae project folder
5. Confirm the import

> **Note:** Token Studio's v2 interface continues to evolve. If the exact option label differs, look for anything referencing "load", "import", or "JSON file" in the menus. The [Token Studio docs](https://docs.tokens.studio) have the latest v2 UI walkthrough if you get stuck.

You should see five token sets appear in the left panel:
- `Primitives`
- `Semantic/Light`
- `Semantic/Dark`
- `Typography`
- `Effects`

---

## Step 3 — Enable all token sets

In the Token Studio panel, make sure all five sets have their checkboxes enabled. This ensures all tokens are available when you export to Figma Variables.

---

## Step 4 — Push tokens to Figma Variables

1. In Token Studio, click **Styles & Variables** (bottom bar)
2. Click **Export to Figma**
3. In the export dialog enable:
   - ✅ **Create/update Variables**
   - ✅ **Color variables**
   - ✅ **Number variables** (spacing, radius, font sizes)
4. Click **Export**

Figma creates a Variable collection for each token set. Verify by opening **Edit → Variables** (`Cmd+Shift+V`). You should see `Primitives`, `Semantic/Light`, `Semantic/Dark`, `Typography`, and `Effects` as separate collections.

---

## Step 5 — Merge Semantic sets into one collection with two Modes

Figma's native Modes let you switch Light/Dark on any frame instantly. The goal is to collapse `Semantic/Light` and `Semantic/Dark` into a single `Semantic` collection with two modes.

1. Open **Edit → Variables** (`Cmd+Shift+V`)
2. Click the `Semantic/Light` collection to select it
3. At the top of the collection, click **+ Add mode** and name the new mode **Dark**
4. You now have two modes: **Light** (existing) and **Dark** (new, empty)
5. For each variable in the collection, click the **Dark** mode cell and enter the corresponding value from the `Semantic/Dark` collection

> **Shortcut:** If the variable list is long, you can duplicate a variable's Light value into Dark first, then edit only the ones that differ. The differences between Light and Dark are mostly surfaces and text — action colors are very similar.

**Key values to fill in for Dark mode:**

For each variable, click the Dark mode cell → click the variable icon → select the Primitive reference shown below. Using Primitive references (rather than raw hex) means token updates propagate automatically.

| Variable | Light (already set) | Dark — set to this Primitive |
|---|---|---|
| `surface/background` | `Primitives/color/neutral/50` | `Primitives/color/neutral/bg-dark` |
| `surface/card` | `Primitives/color/neutral/white` | `Primitives/color/neutral/card-dark` |
| `surface/secondary` | `Primitives/color/neutral/150` | `Primitives/color/neutral/secondary-dark` |
| `surface/subtle` | `Primitives/color/neutral/100` | `Primitives/color/neutral/card-dark` |
| `surface/elevated` | `Primitives/color/neutral/150` | `Primitives/color/neutral/elevated-dark` |
| `surface/input` | `Primitives/color/neutral/white` | `Primitives/color/neutral/secondary-dark` |
| `surface/soft-teal` | `Primitives/color/neutral/200` | `Primitives/color/neutral/secondary-dark` |
| `text/primary` | `Primitives/color/neutral/700` | `Primitives/color/neutral/800` |
| `text/secondary` | `Primitives/color/neutral/500` | `Primitives/color/neutral/400` |
| `text/caption` | `Primitives/color/neutral/500` | `Primitives/color/neutral/450` |
| `text/on-filled` | `Primitives/color/neutral/white` | `Primitives/color/neutral/bg-dark` |
| `action/primary` | `Primitives/color/blue/500` | `Primitives/color/blue/dark` |
| `action/accessible` | `Primitives/color/blue/600` | `Primitives/color/blue/400` |
| `action/hero-fill` | `Primitives/color/blue/500` | `Primitives/color/blue/dark` |
| `action/border` | `Primitives/color/blue/500` | `Primitives/color/blue/dark` |
| `action/destructive` | `Primitives/color/utility/destructive-light` | `Primitives/color/utility/destructive-dark` |
| `severity/mild-surface` | `Primitives/color/severity/mild-surface-light` | `Primitives/color/severity/mild-surface-dark` |
| `severity/moderate-surface` | `Primitives/color/severity/moderate-surface-light` | `Primitives/color/severity/moderate-surface-dark` |
| `severity/severe-surface` | `Primitives/color/severity/severe-surface-light` | `Primitives/color/severity/severe-surface-dark` |

Severity accent colors (`mild-accent`, `moderate-accent`, `severe-accent`) are the same in both modes — no change needed.

6. Once complete, you can delete the now-redundant `Semantic/Dark` collection — all its values live in the `Semantic` collection's Dark mode.

---

## Step 6 — Using tokens in designs

### Colors
1. Select any shape or text layer
2. In the right panel, click the color swatch
3. Click the **Variable icon** (grid icon, top-right of color picker)
4. Navigate to the `Semantic` collection → pick your token (e.g. `surface/card`)

### Spacing and Radius
1. Select an auto-layout frame
2. Click any padding or gap number field
3. Press `=` to open the variable picker
4. Select from `Primitives → spacing/*` or `Primitives → radius/*`

### Typography
Figma doesn't import typography tokens as native Text Styles automatically. Create them once manually:

1. In the right panel, click the text style icon (four squares) → **+**
2. Name the style (e.g. `body`) and set:
   - Font: `SF Pro Text` / `SF Pro Display` (20pt+)
   - Size and weight from `figma-design-system-rules.md`
3. Repeat for each scale entry

---

## Step 7 — Switching between Light and Dark

1. Select any top-level frame (your screen)
2. In the right panel under **Variables**, you'll see the `Semantic` collection listed
3. Click the mode name next to it — toggle between **Light** and **Dark**

The entire frame updates instantly. This is how you design and QA both modes from a single set of screens.

---

## Keeping tokens in sync

When a color or spacing value changes in the Swift codebase, Claude updates `figma/tokens.json`. To re-sync Figma:

1. Open Token Studio → **Settings → Import from file** → re-import `tokens.json`
2. **Styles & Variables → Export to Figma** to push updates to Variables
3. Re-enter any changed Dark mode values in the `Semantic` collection if the semantic layer changed

---

## Connecting Figma components to Swift code (Code Connect)

Once you've built Figma components (e.g. `LogCard`, `SeverityPill`, `AuraeButton`), Claude can create Code Connect mappings so that inspecting a Figma component shows the actual Swift source.

To set this up:
1. Share the Figma file URL with Claude
2. Say "set up Code Connect for [component name]"
3. Claude will map each Figma component to its Swift file

---

## Fonts in Figma

The app uses **SF Pro** (iOS system font). Figma includes SF Pro — use:
- `SF Pro Text` for sizes below 20pt
- `SF Pro Display` for 20pt and above

The logo wordmark "aurae" uses **DM Serif Display Regular**:
1. Install it locally from `Aurae/Resources/Fonts/DMSerifDisplay-Regular.ttf`
2. Restart Figma — it appears in the font picker as "DM Serif Display"

---

## File structure

```
figma/
├── tokens.json                  ← Import this into Token Studio
├── figma-design-system-rules.md ← Full token reference and component notes
└── FIGMA-IMPORT-GUIDE.md        ← This file
```

---

## Quick reference — most-used tokens

| Designing | Token |
|---|---|
| Screen background | `surface/background` |
| Card surface | `surface/card` |
| Pill / chip background | `surface/secondary` |
| Primary body text | `text/primary` |
| Metadata / labels | `text/secondary` |
| Caption text (12pt) | `text/caption` |
| CTA button fill | `action/hero-fill` |
| Card border | `action/border` @ 20% opacity (light) / 15% (dark) |
| Mild headache indicator | `severity/mild-accent` + `severity/mild-surface` |
| Moderate headache | `severity/moderate-accent` + `severity/moderate-surface` |
| Severe headache | `severity/severe-accent` + `severity/severe-surface` |
