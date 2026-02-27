# Aurae Design Tokens — Figma Import Guide

This directory contains the Aurae design system tokens in Tokens Studio for Figma JSON format.

File: `tokens.json`

---

## Prerequisites

- Figma desktop app or browser (figma.com)
- The **Tokens Studio for Figma** plugin (formerly Figma Tokens)
  - Plugin page: https://www.figma.com/community/plugin/843461159747178978/tokens-studio-for-figma
  - Tokens Studio docs: https://docs.tokens.studio

---

## Step 1 — Install the Tokens Studio Plugin

1. Open Figma.
2. In the top menu bar, select **Plugins > Manage plugins**.
3. Search for **Tokens Studio for Figma**.
4. Click **Install**.
5. Once installed, open any Figma file and launch the plugin via **Plugins > Tokens Studio for Figma**.

---

## Step 2 — Load the tokens.json File

### Option A — Load from a local file (simplest for solo use)

1. Open the Tokens Studio panel in Figma.
2. On the **Tokens** tab, click the settings icon (gear) in the bottom toolbar.
3. Select **Load from file/folder or preset**.
4. In the dialog that appears, choose **Load from file**.
5. Select the `tokens.json` file from this directory.
6. Click **Open**. The tokens will load into the plugin under the `global` token set.

### Option B — Paste JSON directly

1. Open the Tokens Studio panel in Figma.
2. Click the settings icon (gear) in the bottom toolbar.
3. Select **Edit token file directly (JSON)**.
4. Delete any existing content in the editor.
5. Paste the full contents of `tokens.json`.
6. Click **Save**. The token tree will update immediately.

### Option C — Sync via GitHub (recommended for teams)

1. In Tokens Studio, click the settings icon and select **Sync providers**.
2. Choose **GitHub** and authenticate.
3. Point the sync to the repository and branch containing this file.
4. Set the token file path to `DesignSystem/tokens.json`.
5. Click **Save**. Changes pushed to the repository will sync automatically.

---

## Step 3 — Verify the Token Structure

After loading, the Tokens Studio panel should display a `global` token set containing the following groups:

```
global
  color
    palette
      auraeNavy
      auraeSlate
      auraeTeal
      auraeSoftTeal
      auraeLavender
      auraeMidGray
      auraeBackground
      auraeBlush
      auraeSage
      auraeIndigo
      auraeAmber
      auraeDarkSage
      white
    severity
      surface (level1 through level5)
      accent (level1 through level5)
    semantic
      primaryText
      secondaryText
      invertedText
      backgroundPrimary
      backgroundSecondary
      backgroundElevated
      interactivePrimary
      interactiveDestructive
      interactiveDisabled
      dataPositive
      dataNeutral
      dataWarning
      dataNegative
      statusActive
      statusInactive
  typography
    fontFamily
    fontSize
    fontWeight
    lineHeight
    scale
      auraeDisplay
      auraeH1
      auraeH2
      auraeBody
      auraeLabel
      auraeCaption
  spacing
    screenPadding
    sectionSpacing
    itemSpacing
    cardPadding
    buttonHeight
    minTapTarget
    severityPillHeight
    (and additional spacing values)
  borderRadius
    cardRadius
    buttonRadius
    severityPillRadius
    severityBarRadius
    statusBadgeRadius
  shadow
    card
    severityPillSelected
  component
    button (primary, secondary, destructive)
    severitySelector (pill, unselected, selected per level)
    logCard
```

If the structure is missing or malformed, re-paste the JSON from `tokens.json` using Option B above.

---

## Step 4 — Apply Tokens as Figma Styles

Tokens Studio can export your tokens directly to native Figma Styles (color styles, text styles, effect styles). This allows other designers on the team to use the tokens without the plugin.

1. In the Tokens Studio panel, click the settings icon.
2. Select **Export to Figma**.
3. In the export dialog:
   - Enable **Color styles** to create Figma color swatches from all `color` tokens.
   - Enable **Text styles** to create Figma text styles from the `typography.scale` tokens.
   - Enable **Effect styles** to create Figma shadow styles from the `shadow` tokens.
4. Click **Export**.
5. Open the Figma **Assets panel** (left sidebar) and select **Local styles** to confirm the styles have been created.

After export, the following Figma styles will be available:

- **Color styles**: `global/color/palette/auraeNavy`, `global/color/palette/auraeTeal`, and all other palette and semantic tokens.
- **Text styles**: `global/typography/scale/auraeDisplay`, `global/typography/scale/auraeBody`, etc.
- **Effect styles**: `global/shadow/card`.

---

## Step 5 — Apply Tokens to Figma Layers

With the tokens loaded, you can apply any token to any Figma layer:

1. Select a layer or group in Figma.
2. Open the Tokens Studio panel.
3. Browse to the token you want to apply (e.g., `global > color > palette > auraeTeal`).
4. Right-click the token and select the appropriate property:
   - **Fill** — applies the color as a fill.
   - **Stroke** — applies the color as a border.
   - **Background** — applies to the background fill.
5. For spacing tokens, select **Padding**, **Gap**, **Width**, or **Height** as appropriate.
6. For border radius tokens, select **Border radius**.

Applied tokens are shown in the Tokens Studio panel as active (with a highlight) whenever that layer is selected.

---

## Step 6 — Keep Tokens in Sync

Whenever the Swift design system is updated, re-export `tokens.json` from the source-of-truth Swift files and reload it into Figma using one of the methods in Step 2. If you are using GitHub sync (Option C), the update happens automatically on push.

To keep Figma styles current after a token update:
1. Reload the new `tokens.json`.
2. Repeat **Export to Figma** (Step 4) to update the native Figma styles.

---

## Token Reference

For the full description of every token — including hex values, font names, sizes, usage rules, and component specs — see the companion reference document:

`aurae-design-system.md`

---

## Font Setup in Figma

The Aurae design system uses two custom typefaces that must be installed on your machine for Figma to render text styles correctly.

| Font Family | Weights Used | Source |
|---|---|---|
| Fraunces | Regular, Bold | Google Fonts / included in Xcode project under `Resources/Fonts/` |
| Plus Jakarta Sans | Regular, SemiBold | Google Fonts / included in Xcode project under `Resources/Fonts/` |

To install the fonts:
1. Locate the `.ttf` files in the Xcode project at `Aurae/Resources/Fonts/`.
2. Double-click each file and click **Install Font** in Font Book (macOS).
3. Restart Figma (desktop app only; browser Figma uses Figma Font Helper).

If you are using Figma in the browser, install the **Figma Font Helper** browser extension and ensure the fonts are installed on your system. The extension makes locally installed fonts available to browser Figma.

Once fonts are installed and Figma is restarted, text styles exported from Tokens Studio will render with the correct Fraunces and Plus Jakarta Sans typefaces.
