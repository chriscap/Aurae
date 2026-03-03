# Aurae — Figma Token Import Guide

How to get your design tokens into Figma and use them.

---

## Overview

We use **Token Studio** (free Figma plugin) to import `tokens.json` into Figma's native Variables system. This gives you:
- Live color, typography, spacing, and radius tokens in the Figma Variables panel
- Light + Dark mode switching built in
- Any token change here syncs back to the JSON, which Claude can read to stay in sync

---

## Step 1 — Install Token Studio

1. In Figma, open a file → **Plugins → Browse plugins**
2. Search **"Token Studio for Figma"** (by Figmatokens.com)
3. Click **Install**

---

## Step 2 — Import tokens.json

1. Open Token Studio: **Plugins → Token Studio for Figma**
2. In the Token Studio panel, click the **Settings** gear (bottom-left)
3. Select **Import / Export → Import from file**
4. Select `figma/tokens.json` from the Aurae project folder
5. Click **Load tokens**

You should now see four token sets in the left panel:
- `Primitives`
- `Semantic/Light`
- `Semantic/Dark`
- `Typography`
- `Effects`

---

## Step 3 — Configure themes (Light / Dark)

Token Studio uses **Themes** to switch between `Semantic/Light` and `Semantic/Dark`.

1. In Token Studio, click **Themes** (top of panel)
2. Click **+ New theme**
3. Create theme **"Light"**:
   - Enable: `Primitives` ✅
   - Enable: `Semantic/Light` ✅
   - Enable: `Typography` ✅
   - Enable: `Effects` ✅
   - Disable: `Semantic/Dark` ✗
4. Create theme **"Dark"**:
   - Enable: `Primitives` ✅
   - Enable: `Semantic/Dark` ✅
   - Enable: `Typography` ✅
   - Enable: `Effects` ✅
   - Disable: `Semantic/Light` ✗

You can now switch between Light and Dark instantly using the theme toggle at the top of the Token Studio panel.

---

## Step 4 — Push tokens to Figma Variables

This step converts Token Studio tokens into native Figma Variables so you can use them directly in the design tool without opening the plugin for every value.

1. In Token Studio, click **Styles & Variables** (bottom bar)
2. Click **Export to Figma**
3. In the export dialog:
   - ✅ **Create/update Variables**
   - ✅ **Color variables**
   - ✅ **Number variables** (for spacing, radius, font sizes)
   - ✅ **String variables** (for font weights)
4. Click **Export**

Figma will create a **Variable collection** for each token set. You'll see them in:
**Edit → Variables** (or press `Ctrl/Cmd + Shift + V` on Mac)

---

## Step 5 — Using tokens in Figma designs

### Colors
1. Select any shape or text layer
2. In the right panel, click the color swatch
3. In the color picker, click the **Variable icon** (grid icon, top right)
4. Navigate to `Semantic` → `Light` → `surface/card` (or whichever token)
5. Select it — the color is now token-linked

### Typography
1. Select a text layer
2. In the right panel, click the **text style** icon
3. You can create text styles manually using the type scale values:
   - Name: `body`, Size: 16, Weight: Regular
   - Name: `h2`, Size: 20, Weight: SemiBold
   - (Repeat for each scale entry in `figma-design-system-rules.md`)

> **Tip:** Figma doesn't yet support importing typography tokens as native Text Styles via Token Studio automatically — you create them manually once using the scale, then they stay linked.

### Spacing and Radius
- When setting padding on auto-layout frames, click the number field and type `=` to open the variable selector, then pick from `Primitives → spacing/*`
- For corner radius, same approach: `=` → `Primitives → radius/*`

---

## Step 6 — Setting up Light/Dark mode switching

Once variables are exported to Figma:

1. Select your frame/screen
2. In the right panel, find **Variables**
3. You'll see the collection listed — click the mode selector next to it
4. Switch between **Light** and **Dark** to preview the full mode change instantly

This is how you'll design both modes from one set of frames.

---

## Keeping tokens in sync

When design decisions change in the app (e.g., a color token is updated in `Colors.swift`), Claude will update `figma/tokens.json`. To re-sync Figma:

1. Open Token Studio
2. **Settings → Import from file** → re-import the updated `tokens.json`
3. Click **Styles & Variables → Export to Figma** again

The update is non-destructive — only changed values will be overwritten.

---

## Connecting Figma components to Swift code (Code Connect)

Once you've built Figma components (e.g., a `LogCard` component, a `SeverityPill` component), Claude can create **Code Connect** mappings. These mean that when you inspect a Figma component, Figma shows you the actual Swift source code for that component.

To set this up later:
1. Share the Figma file URL with Claude
2. Say "set up Code Connect for [component name]"
3. Claude will map each Figma component to its Swift file

---

## File structure reference

```
figma/
├── tokens.json                  ← Import this into Token Studio
├── figma-design-system-rules.md ← Full token reference and component notes
└── FIGMA-IMPORT-GUIDE.md        ← This file
```

---

## Fonts in Figma

The app uses **SF Pro** (system font). Figma has SF Pro built in — use:
- `SF Pro Display` for 20pt and above
- `SF Pro Text` for below 20pt

The logo wordmark uses **DM Serif Display Regular**. To use it in Figma:
1. Install it locally from `Aurae/Resources/Fonts/DMSerifDisplay-Regular.ttf`
2. Restart Figma — it will appear in the font picker as "DM Serif Display"

---

## Quick reference — most-used tokens

| What you're designing | Token to use |
|---|---|
| Screen background | `surface/background` |
| Any card | `surface/card` |
| Pill / chip background | `surface/secondary` |
| Primary body text | `text/primary` |
| Metadata / labels | `text/secondary` |
| Caption text (12pt) | `text/caption` |
| CTA button fill | `action/hero-fill` |
| Card border | `action/border` @ 20% opacity |
| Mild headache | `severity/mild-accent` + `severity/mild-surface` |
| Moderate headache | `severity/moderate-accent` + `severity/moderate-surface` |
| Severe headache | `severity/severe-accent` + `severity/severe-surface` |
