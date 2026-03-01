# Aurae
## Headache Tracker & Trigger Intelligence
### Product Requirements Document

| | |
|---|---|
| **Document Type** | Product Requirements Document (PRD) |
| **Version** | 1.8 — In Development |
| **Date** | February 2026 (updated 28 Feb 2026) |
| **Platform** | iOS (iPhone-first) |
| **Stage** | In Development |
| **Monetization** | Freemium |

---

## 1. Executive Summary

Aurae is an iOS application that helps headache and migraine sufferers understand, track, and manage their condition through intelligent contextual logging. Unlike basic headache diaries that depend on manual recall, Aurae automatically captures environmental and physiological data at the moment of onset — then connects the dots across time to reveal personal patterns.

The app targets a broad audience ranging from casual headache sufferers to chronic migraine patients. A freemium model makes core logging free and accessible while unlocking on-device pattern analysis, advanced analytics, and clinical export tools for premium subscribers.

Design-forward and calming by intent, Aurae draws from the visual language of apps like Robinhood, Strava, Headspace, Lumy, Tiimo, and (Not Boring) Weather — bold typography, generous whitespace, and a palette that is never harsh on sensitive eyes.

---

## 2. Problem Statement

Headaches and migraines affect over 1 billion people globally. Despite their prevalence, most sufferers have limited insight into what causes their episodes. The core challenges are:

- **Recall bias** — by the time a headache subsides, users have forgotten meal timing, sleep quality, or the weather at onset.
- **Data fragmentation** — relevant context (sleep, heart rate, weather) lives across multiple apps with no unified view.
- **No actionable insight** — users who do log headaches rarely have the tools to identify meaningful patterns without clinical support.
- **Doctor communication gap** — patients struggle to summarise their headache history in a clinically useful format.

Aurae addresses all four by capturing the right data automatically at onset, supporting detailed retrospective enrichment, and surfacing a clear intelligence layer that benefits both users and their healthcare providers.

---

## 3. Goals & Success Metrics

### 3.1 Product Goals

- Enable fast, frictionless headache logging — under 10 seconds for a basic onset log.
- Auto-enrich each log with weather, Apple Health, and sleep data at the moment of onset.
- Support detailed retrospective entry once the headache has subsided.
- Surface trigger patterns and trends through on-device pattern analysis (paid tier).
- Produce clean, exportable PDF reports suitable for healthcare provider visits.
- Deliver a visually calming, design-forward experience with best-in-class accessibility.

### 3.2 Key Success Metrics

| Metric | Target (6 months post-launch) |
|---|---|
| Avg. onset log time | < 10 seconds |
| 7-day retention | > 55% |
| 30-day retention | > 30% |
| Free → Premium conversion | > 8% |
| App Store rating | ≥ 4.5 stars |
| Monthly active users | 50,000+ |
| PDF exports / month | > 10,000 |

---

## 4. Target Users

Aurae serves a broad spectrum of users unified by the experience of recurring headaches. Three primary personas drive the feature set:

### The Occasional Sufferer
Experiences headaches a few times a month and wants a simple log to understand what might be triggering them. Values speed and simplicity above all. Likely to use the free tier. Core need: one-tap logging with zero friction.

### The Migraine Patient
Experiences frequent, debilitating migraines — potentially with aura. Actively managed by a neurologist or headache specialist. Needs rich contextual data, pattern recognition, and printable reports for clinic visits. Core premium subscriber. Core need: clinical-grade export and trigger insights.

### The Chronic Condition Manager
Manages headaches alongside another condition such as fibromyalgia, hypertension, or hormonal disorders. Interested in correlating headache data with menstrual cycle, medication, and physiological signals. Core need: granular data fields and longitudinal trend analysis.

---

## 5. Core Features

### 5.1 Onset Logging — Home Screen

The home screen is the beating heart of Aurae. It must communicate calm, clarity, and instant action. Inspired by the minimal power of Headspace and the bold data presence of Strava and Robinhood, the home screen contains:

- A prominent **Log Headache** button — large, accessible, impossible to miss.
- A **severity selector**: three distinct tap targets (Mild / Moderate / Severe). Pills display word labels only — no numeric index. The control should feel tactile, not clinical.
- An ambient context triptych card summarising weather, sleep, and headache-free days from the most recent log.
- Minimal bottom tab bar with icon + label — Home, History, Insights, Export.

On tap, the app immediately records a timestamped event, pulls weather data, reads available Apple Health data (heart rate, HRV, SpO2, steps), and reads sleep data. The user receives confirmation within 1–2 seconds. The entire interaction should take under 10 seconds.

#### Active Headache State

The app maintains an explicit active/resolved state for each headache. While a headache is active, the home screen changes:

- The **Log Headache** button and severity selector are replaced by a **"Mark as Resolved"** CTA.
- An **elapsed duration banner** is displayed (e.g. "Headache ongoing — 2h 14m").
- This state persists until the user taps "Mark as Resolved" or manually resolves the log.

On resolution, the app transitions back to the standard home screen and prompts the retrospective entry flow.

### 5.2 Automatic Data Capture at Onset

At the moment of logging, Aurae silently attaches the following data to the event:

#### Weather Data
- Temperature, humidity, barometric pressure & trend (rising/falling), and UV index.
- Location is used only to query weather — not stored or shared.
- Weather is sourced from **Open-Meteo** (free, no API key required). Single `/forecast` endpoint returns temperature, humidity, barometric pressure, UV index, and WMO weather code. AQI is not available via this endpoint and is stored as nil.
- **V1 limitation:** Barometric pressure trend (rising/falling/stable) is a single-point heuristic derived from the current reading, not a rolling time-series trend. A true rolling trend is deferred to a future release.

#### Apple Health Integration
- Resting + current heart rate, HRV, SpO2 (stored as 0–100%), step count, and menstrual cycle phase.
- If HealthKit permission is denied, all health fields are silently stored as nil. This is by design per Apple's privacy policy. The app remains fully functional.

#### Sleep Data
- Previous night's duration and stages via Apple Health or connected services (Oura, Garmin, Fitbit).
- **Sleep capture window:** 10 PM the previous calendar day through 10 AM the current day. This matches Apple Health's own sleep window convention.
- If no automatic data is available, the user is prompted during the post-headache retrospective.

### 5.3 Post-Headache Retrospective

After a headache resolves, the user is invited to enrich the log with retrospective detail. All fields are optional, grouped into logical sections:

#### Headache Details
- Adjust severity and duration, headache type/location, and accompanying symptoms (nausea, light/sound sensitivity, aura, neck pain, visual disturbances).
- The headache type selector must display an inline note: "Select the type that best matches your experience. Self-reported — not clinically confirmed." This note is non-dismissible and rendered as a compact caption below the selector.

#### Food & Drink
- Recent meals (free text or trigger shortcuts: aged cheese, processed meat, MSG, citrus, chocolate, gluten (if sensitive)), alcohol, caffeine, hydration, and skipped meals.

#### Lifestyle Factors
- Sleep quality (manual 1–5 if not auto-filled), sleep hours, stress level (1–5 scale), and screen time.

#### Medication
- Medication taken (searchable list + free text), dose, timing, and effectiveness rating (1–5, labeled "How much did it help?").
- Each medication entry includes a classification toggle with two options: **"For headache relief"** (acute) and **"Daily as prescribed"** (preventive). This maps to the `medicationIsAcute: Bool?` field on `RetrospectiveEntry`. The toggle is shown immediately below the medication name field in the Medication section. Default state is unselected (nil). When nil, the entry is conservatively counted toward the acute total unless the medication name matches a known preventive list (implementation detail for engineering).
- **Clinical safety disclaimer:** A non-removable caption is displayed in the Medication section below the effectiveness field: "Medication records are for your reference and to support conversations with your care team. Do not adjust or stop any medication based on patterns observed in this app." This is a clinical advisor requirement and must not be removed without clinical and legal sign-off.
- **Medication overuse awareness warning:** An inline card appears in the Insights tab (ungated — visible to all users, free and premium) when the user has logged entries classified as acute in 10 or more distinct calendar days within the current month. The warning uses the following copy verbatim: "You've logged acute medication for headache relief more than 10 times this month. Frequent use of certain pain relievers may be associated with rebound headaches in some people. This is for your awareness only — not a diagnosis. It may be worth mentioning this pattern to your healthcare provider." The card includes a link to the "When to Seek Medical Care" screen. Only acute-classified medications (`medicationIsAcute == true`, or nil with conservative fallback) count toward this threshold. Preventive medications (`medicationIsAcute == false`) are explicitly excluded from the count.

#### Women's Health
- Menstrual cycle phase — auto-filled from Apple Health if available, otherwise manual entry.

#### Environment
- Manual weather override if the user was in a different location at onset.
- Environmental triggers: strong smells, bright lights, loud noise, screen glare.

### 5.4 Headache History & Calendar View

- Scrollable history with severity indicators, duration, and key attached data.
- Calendar view with headache days highlighted — colour-coded by severity.
- Tap into any log to view full detail of auto-captured and manually entered data.
- Search and filter by date range, severity, or trigger factor.

### 5.5 Trigger Insights (Premium)

After logging a minimum of 5 headaches, the app begins surfacing pattern analysis. Analysis runs entirely on-device via `InsightsService.swift` using algorithmic co-occurrence analysis — no AI/ML model, no Core ML, no server component, and no third-party AI service is involved. This feature must never be described as "AI-powered" in any user-facing copy. Approved copy variants: "on-device pattern analysis," "smart pattern recognition," "personal pattern insights."

#### Minimum Data Thresholds

Pattern analysis does not surface until sufficient data exists to avoid statistically meaningless or misleading output:

- **General frequency insights:** 5 resolved logs (existing threshold — unchanged)
- **Weather correlations:** 10 resolved logs minimum before any weather correlation is shown
- **Sleep correlations:** minimum 5 entries per comparison group before sleep correlation is shown
- No correlation result of any kind is surfaced below its respective minimum threshold. The Insights tab shows an encouraging progress state (e.g. "Keep logging — patterns will appear after a few more entries") until thresholds are met.

#### Correlation Language

`InsightsService.swift` must use frequency-based language only. Statistical correlation language is prohibited because the co-occurrence algorithm does not produce statistically valid correlation coefficients.

| Prohibited (remove) | Required (replace with) |
|---|---|
| "Strong correlation" | "Frequently present" |
| "Moderate correlation" | "Sometimes present" |
| "Weak correlation" | "Occasionally present" |

#### Insights Disclaimer

A compact disclaimer is displayed on the Insights tab. It is shown prominently on the user's first visit to Insights and may be dismissed after reading. After dismissal, a condensed single-line version ("For informational purposes only · Not medical advice") remains as a persistent footer at the bottom of the Insights tab on every visit.

Full disclaimer text (first-view): "Patterns are based on your logged data only. They are for informational purposes and do not constitute medical advice."

#### First Insights Educational Interstitial

When a user's 5th resolved log triggers the Insights threshold for the first time, an educational interstitial is shown before the Insights tab content is revealed. This screen:

- Explains that patterns take time and improve with more logs
- Explicitly states that these are co-occurrences, not proven causes
- Encourages the user to discuss any patterns with their clinician
- Has a single CTA: "Got it — show my patterns"

This interstitial is shown once only. It is not a paywall — it is an educational gate that sets accurate expectations before the user sees their first pattern analysis.

#### Patterns Computed

- **Top suspected triggers** — ranked by co-occurrence frequency (e.g. "You had a headache within 24 hours of poor sleep in 7 of your last 9 episodes"). A correlational disclaimer is displayed below trigger bars: "These patterns reflect associations in your logged data. They are not confirmed triggers and may change as you log more episodes. Share them with your care team to explore what they mean for you."
- **Weather correlation** — does barometric pressure drop or humidity spike precede your headaches? (Requires 10+ resolved logs.)
- **Day-of-week and time-of-day patterns** — frequency analysis across calendar dimensions.
- **Sleep correlation** — relationship between previous-night sleep duration/quality and headache onset. (Requires 5+ entries per group.)
- **Medication effectiveness trends** — what worked, and how quickly?
- **Streak and frequency trends** — headache-free streaks and rolling frequency over time.
- Weekly and monthly frequency charts with trend lines.
- **Episode count trust signal** — the full insights view displays "Based on your N logged episodes" as a caption at the top of the scroll view. This grounds the analysis in its actual data source and sets accurate user expectations.

Insights are presented in plain, empathetic language — not medical diagnoses. No health data leaves the device.

> **Build note:** Step 15 complete. Menstrual cycle correlation and cycle overlay chart are listed in the premium feature table but are not yet surfaced in the Insights UI — deferred to a future iteration. The first-insights educational interstitial and Insights disclaimer are required before public release.

### 5.6 PDF Export for Healthcare Providers

Users can generate a structured, print-ready PDF report suitable for sharing with a neurologist, GP, or headache clinic.

#### Free Tier
- Summary table with 7 columns: Date, Time, Severity, Duration, Weather (temperature + condition), Medication, Notes (truncated to 40 characters). Selectable date range. Generated on-device via PDFKit. A4 portrait, Aurae-branded header with teal accent bar, and "Generated by Aurae" footer.

#### Premium Tier
- All free content plus full contextual data per headache (weather, sleep, lifestyle, food, symptoms).
- Trigger pattern summary page with top suspected triggers.
- Charts: frequency over time, severity distribution, medication effectiveness, and menstrual cycle overlay.
- Clean, professional layout designed to be taken to a clinic appointment. All generation happens on-device.

> **Build note:** Step 16 (full premium PDF export) is not yet built — stub only. The premium export path is gated but will produce an incomplete report until Step 16 is complete.

---

## 6. Design System & Visual Language

Aurae's design must be simultaneously striking and gentle. Users are often in pain — the interface should never feel harsh, cluttered, or anxiety-inducing. Visual references: Robinhood (confident data typography), Strava (bold + clean dashboard), Lumy (soft palette, delightful interactions), Tiimo (calm, accessible), Headspace (approachable wellness), (Not Boring) Weather (playful but refined ambient UI).

### 6.1 Color Palette

The following palette is implemented in `DesignSystem/Colors.swift` and replaces all earlier draft swatches. Use token names only — never hardcode hex values.

| Role | Hex | Token | Usage |
|---|---|---|---|
| Soft Ink | `#3A3E4B` | `auraeNavy` | Primary text, headings |
| Slate | `#2E3240` | `auraeSlate` | Secondary headings |
| Aurae Teal | `#8AC4C1` | `auraeTeal` | Brand accent, CTA button fill — NOT used as text |
| Muted Mint | `#C6E2E0` | `auraeSoftTeal` | Premium highlights, tag fills |
| Cloud White | `#F6F7FA` | `auraeBackground` | Primary background |
| Pale Lavender | `#EDE8F4` | `auraeLavender` | Secondary surfaces |
| Mid Tone | `#6D717F` | `auraeMidGray` | Secondary text (WCAG AA 4.54:1) |
| Pale Blush | `#F5E8E8` | `auraeBlush` | Severity 5 surface |
| Mint Sage | `#D4EDE9` | `auraeSage` | Severity 1 surface |
| Deep Slate | `#1A1D24` | `auraeDeepSlate` | Dark mode primary background (L0) |
| Starlight | `#E8EAED` | `auraeStarlight` | Dark mode primary text |
| Soft Lavender | `#B6A6CA` | `auraeSoftLavender` | Premium UI fills/icons — NOT used as text |
| Text-safe Teal | `#3E7B78` | `auraeTealAccessible` | Teal as text on light backgrounds (4.55:1) |
| Text-safe Lavender | `#8064A2` | `auraeLavenderAccessible` | Lavender as text on light backgrounds (5.1:1) |
| Selected Label Dark | `#1C2826` | `auraeSeverityLabelSelected` | Text on teal fills — achieves ≥10:1 (AAA) |

**Key gradient:** `auraePrimaryGradient` — `#8AC4C1` → `#B6A6CA` at 45°. Restricted to: paywall hero, premium badge, logomark, and upgrade CTA. Do not use this gradient elsewhere.

**Brand mark gradient:** `auraeMarkGradient` — `#2D7D7D` → `#B3A8D9` (original brand teal to violet). Used exclusively for `AuraeLogoMark` and deliberate brand gradient moments. **Do not substitute with `auraePrimaryGradient`** — these are distinct color intentions. `auraeMarkGradient` uses the original brand palette; `auraePrimaryGradient` uses the functional UI palette.

**Dark mode surfaces:** Deep Slate `#1A1D24` (L0) / `#22262F` (L1) / Card Dark `#2A2E39` (L2).

**Accessibility note:** The primary CTA button label is rendered in `auraeSeverityLabelSelected` (`#1C2826`, dark ink) on the `auraeTeal` fill. White text on `#8AC4C1` fails WCAG AA (1.95:1) and must not be used. This is a firm accessibility-first decision — see D-12.

Reduce Motion and Increase Contrast accessibility settings must be honoured throughout.

### 6.2 Typography

Aurae uses two typefaces that together communicate editorial warmth and legibility:

- **DM Serif Display** — display and heading typeface for onboarding and editorial moments. Used via `dmSerifDisplay()` / `fraunces()` aliases. **Critical rule: DM Serif Display is only used at 26pt or larger.** Its high stroke contrast causes thin strokes to vanish at smaller sizes on dark surfaces. Below 26pt, use DM Sans weight variants for hierarchy.
- **DM Sans** — body and UI typeface. Used via `dmSans()` / `jakarta()` aliases. Handles all body copy, labels, navigation, table content, form fields, and all UI text below 26pt.

**Typography hierarchy below 26pt (DM Sans):**
- SemiBold (600) — structural headings, button labels, section titles
- Medium (500) — prompts, section labels, secondary UI text
- Regular (400) — body copy, captions, metadata

**Semantic type scale (implemented in `Typography.swift`):**
- `auraeDisplay` (44pt Bold) — home screen hero numerals (streak count)
- `auraeH1` (26pt SemiBold) — top-level section headings
- `auraeH2` (20pt SemiBold) — sub-section headings and card titles
- `auraeSectionLabel` (17pt Medium) — section prompts, questions
- `auraeSecondaryLabel` (14pt Medium) — card sub-headings, category names
- `auraeBody` (16pt Regular) — reading copy and form fields
- `auraeCaption` (12pt Regular) — timestamps, metadata, fine print

Dynamic Type support — all text must scale with iOS accessibility font sizes.

> **QA flag (open):** Validate DM Serif Display rendering under Dynamic Type / Accessibility Extra Large before App Store submission. High-stroke-contrast typefaces can degrade at extreme Dynamic Type sizes on dark surfaces.

### 6.3 Layout Principles

- Generous vertical spacing — the app should never feel packed or dense.
- Card-based surfaces with subtle shadow and 16–20px corner radius.
- Bottom-anchored primary actions — the Log Headache button lives in thumb reach.
- Haptic feedback on all key interactions — severity slider, log confirmation, report generation.
- Smooth spring-physics transitions — no abrupt cuts.
- Iconography: line-based, minimal, never cartoonish.

### 6.4 Icon Container System

All icon containers throughout the app use a consistent visual system:

- **Shape:** `RoundedRectangle` with `.continuous` style — not `Circle`. This applies to all icon badge containers in feature rows, stat cards, onboarding rows, and any other icon badge context.
- **Fill:** Icon color at `opacity(0.12)` — a subtle tinted surface that echoes the icon's semantic color without competing with it.
- **Symbol weight:** `.medium` for all SF Symbols inside icon containers. This matches the stroke weight of the surrounding UI and avoids over-bold icons that feel heavy against body text.
- **Size:** 44×44pt for primary feature rows (matching the minimum tap target); smaller variants (36×36, 40×40) are acceptable in dense contexts such as stat cards and compact layouts.

This system replaces the prior use of `Circle` fills for icon containers. Any view still using a `Circle` fill for an icon badge is a migration target.

### 6.5 Home Screen Layout

The home screen layers ambient brand presence and personal context beneath a clear logging action. From back to front and top to bottom:

**Background layer (non-interactive, accessibility hidden)**
- A static radial gradient wash in teal-to-clear at 8% opacity originates from the top-center of the screen. Provides ambient brand presence without adding visual noise. In dark mode the effective opacity reduces to approximately 5% due to the darker background surface.
- A large "A" character rendered in Fraunces Bold at 200pt, using the primary text color at 4% opacity, positioned in the top-right corner behind all content. Functions as a brand watermark / background texture.

**Header**
- Left: Greeting and date — e.g. "Good morning. Tuesday, 18 Feb." Set in Plus Jakarta Sans.
- Right: Streak numeral — when the user has been headache-free for 1 or more days, a large Fraunces Bold numeral (64pt) is displayed showing the count with a caption label ("days free" or "day free" for a count of 1). This is the single editorial use of Fraunces on the home screen outside of the brand watermark. When the streak count is 0, a small teal capsule chip reads "Headache-free today" in place of the numeral. When there is no streak data (active headache or no logs recorded), the right side of the header is empty. **Active headache rule:** While a headache is active (`isActive == true`), the streak numeral and chip are both hidden entirely — the right side of the header is empty. Displaying a stale days-free count during an active headache is factually misleading. The `HomeViewModel` must evaluate `isActive` state before computing streak display. Any code that surfaces `daysSinceLastHeadache` while an active headache exists is incorrect behavior (see D-29).

**Streak card**
When the user has a headache-free streak, a dedicated streak card appears above the log action card. The card uses the `circle.dotted.and.circle` SF Symbol (brand halo echo) inside a `RoundedRectangle` icon container with `auraePrimary.opacity(0.12)` fill. This symbol replaced `bolt.fill` to maintain visual consistency with the brand mark's concentric ring motif (see Section 18).

**Ambient context triptych card**
Replaces the former single-row weather card. A 3-column card is shown whenever at least one log exists. The card is always rendered in partial state if data is unavailable for individual columns — it is never hidden entirely due to a single column's data being absent.
- Column 1 — Weather: SF Symbol weather icon, temperature in degrees, condition label (e.g. "Partly cloudy"). Displays "—" for temperature and condition if weather data is nil (e.g., due to API failure or no location permission at time of logging). The weather icon is omitted when condition is nil.
- Column 2 — Sleep: moon icon, hours formatted as "7h 30m", label "SLEEP". Sourced from the most recent log's HealthKit health snapshot. Displays "—" if unavailable.
- Column 3 — Days headache-free: calendar icon, numeric count, label "DAYS FREE". Displays "—" if no resolved logs exist.

**Partial state rationale:** Hiding the entire card when weather is nil would suppress sleep and days-free data that may have loaded successfully. The "--" convention is already established for sleep and days-free columns; it is applied consistently to weather columns when that data is absent (see D-30).

Columns are separated by hairline dividers. The card uses `auraeAdaptiveCard` background with a subtle shadow. The full VoiceOver accessibility label combines all three data points into a single descriptive string, substituting "unavailable" for any "--" value.

**Empty states**
- **Recent Activity empty state:** Ghost `AuraeLogoMark` at 18% opacity centered in the card. Copy: "Your history will appear here as you log."
- **Quick Insights empty state:** Copy: "Log 5 or more episodes to start seeing your patterns."

**Logging controls**
- **"How are you feeling?"** section label above the severity selector.
- **Severity selector** — three rounded pill buttons: Mild, Moderate, Severe. Pills display the word label only — no numeric index. Must be operable one-handed.
- **Log Headache button** — large hero CTA. `auraeTeal` fill, dark ink label (`auraeSeverityLabelSelected` / `#1C2826`), generous tap target. White text must not be used — it fails WCAG AA on this fill.

**Navigation**
- Bottom tab bar — Home, History, Insights, Export. Icon + Jakarta label. There is no Profile tab in V1.
- Tab bar appearance: `configureWithTransparentBackground()` with an explicit `auraeAdaptiveCard` background color. Unselected tab items use `auraeTextSecondary` for both icon and label color.

No carousels. No promotional banners. No notifications surfaced on the home screen. The sole exception to the no-banner rule is the red-flag safety banner (see Section 7.1): when an active headache has red-flag symptoms, a safety banner must appear on the home screen and persist until the headache is resolved. This banner is a patient safety surface — not a notification or promotional element.

### 6.6 Accessibility

- WCAG 2.1 AA minimum contrast across all text and interactive elements.
- Dynamic Type and VoiceOver support across all screens.
- All interactive elements minimum 44×44pt tap targets.
- No information conveyed by colour alone — always paired with icon or label.
- Reduce Motion: disable parallax and auto-playing transitions.

**VoiceOver labels (implemented in v1.7):**
- `RetroStarRating` — per-star accessibility labels: "N out of 5, selected" (selected state) / "N out of 5" (unselected state), with appropriate hints.
- `RetroIntensityScale` — same per-item pattern as `RetroStarRating`.
- Medication effectiveness label changed from "Effectiveness" to "How much did it help?" — more natural language for screen reader users and general users alike.

---

## 7. Safety & Clinical Integrity

This section defines non-negotiable safety and clinical accuracy requirements for V1. These requirements were established following a formal clinical review of the app and PRD completed February 2026. They apply to all features shipped in V1 and must not be scoped out or deferred without explicit PM sign-off and a documented risk decision.

### 7.1 Red-Flag Symptom Escalation Pathway

The app must provide three complementary safety surfaces for users who log high-risk symptom combinations. All three surfaces are required in V1. The combination ensures that a user who logs red-flag symptoms and immediately closes the app still receives the escalation prompt.

#### Red-Flag Trigger Conditions

The banner triggers when any of the following high-risk combinations are detected in a single log entry.

**New field: `onsetSpeed` on `HeadacheLog`**

A new optional field captures onset speed at log time:

```swift
var onsetSpeed: OnsetSpeed? // nil if user did not answer or selected "Not sure"

enum OnsetSpeed: String, Codable {
    case gradual       // "Gradually, over 30 minutes or more"
    case moderate      // "Quickly, within about 1 to 30 minutes"
    case instantaneous // "Almost instantly, within seconds to about a minute"
}
```

- The `.instantaneous` case maps to the ICHD-3 definition of thunderclap headache (maximum intensity within 1 minute). The word "thunderclap" must not appear in any user-facing copy — it implies diagnostic classification.
- `onsetSpeed == nil` when the user selects "Not sure" or does not answer. A nil value triggers nothing.
- Severity alone is not sufficient to trigger the onset banner — onset speed is the primary clinical signal.

**Trigger conditions — two urgency tiers:**

**Primary (urgent) — banner fires immediately in `LogConfirmationView` AND persists on `HomeView` while the headache is active:**
- `onsetSpeed == .instantaneous` AND `severity >= 4`

**Secondary (advisory) — softer notice fires in `LogConfirmationView` only:**
- `onsetSpeed == .instantaneous` AND `severity < 4`

**Existing trigger (unaffected by D-33):**
- Aura AND visual disturbance logged in the same entry (see D-28)

#### Surface 1 — LogConfirmationView (Primary)
The red-flag banner must appear immediately on the LogConfirmationView screen shown after a triggering log is saved. This is the highest-certainty exposure point: the user is still in the app and has just completed logging. The banner appears within the confirmation screen, below the confirmation message and above any secondary actions. It must not replace or obscure the confirmation.

#### Surface 2 — HomeView (Persistent)
While the triggering headache remains active (`isActive == true` and the log has red-flag symptoms), the red-flag banner persists on the HomeView in the active headache banner area — below the elapsed duration display and above the "Mark as Resolved" CTA. The banner is removed automatically when the headache is resolved. This surface ensures the escalation prompt remains visible throughout the episode for users who close and reopen the app.

#### Surface 3 — InsightsView (Secondary Reminder)
The red-flag banner also appears in InsightsView as a secondary reminder surface for users who navigate to Insights while a red-flag headache is active. Retention of this surface is low-cost and provides an additional catch for users who might miss Surfaces 1 and 2.

#### Per-Log Dismiss State
The banner dismiss state must be tracked per log — not as a global `@AppStorage` boolean. The current implementation (`hasSeenRedFlagBanner` as a single global boolean) is incorrect and must be replaced. A user who dismisses the banner for one log must still see it for a future log that independently triggers red-flag criteria. Recommended implementation: store the dismiss state on `HeadacheLog` (e.g., `hasAcknowledgedRedFlag: Bool`) or keyed by log ID in UserDefaults (see D-31).

#### Banner Copy (verbatim — clinically reviewed, do not alter without clinical advisor and legal review)

**Primary urgent banner** (displayed on `LogConfirmationView` and persisting on `HomeView`):

> "This headache came on very suddenly and severely. Headaches that reach full intensity very quickly can sometimes be a sign of a serious condition that needs immediate medical attention. If this is the worst headache you have ever had, or if you have any other unusual symptoms, please seek emergency medical care now or call emergency services. This app cannot diagnose the cause of your headache."

**Secondary advisory notice** (displayed on `LogConfirmationView` only):

> "You noted this headache came on very quickly. Sudden-onset headaches can occasionally signal a condition that needs medical attention. If anything feels unusual or severe, please contact a healthcare provider. This app cannot diagnose the cause of your headache."

Both banners must include a "Learn more" action that opens the "When to Seek Medical Care" screen (`MedicalEscalationView`).

#### Banner Requirements
The banner must:
- Use clear, calm language consistent with the Aurae tone — urgent but not panicked
- Provide a "Learn more" inline action that opens the static informational screen (see below)
- Not block the user's ability to continue using the app
- Be accessible via VoiceOver with a clearly descriptive accessibility label
- Be available to all users (free and premium) — ungated

Final banner copy requires legal review before V1 release (OQ-01 — open).

#### Static "When to Seek Medical Care" Screen
A static informational screen must be accessible from:
- The conditional banner on any of the three surfaces (primary entry point)
- Settings (secondary persistent entry point)
- Profile > Support section — a dedicated "When to Seek Medical Care" row opens `MedicalEscalationView`

The screen covers: symptoms requiring emergency evaluation (e.g. "thunderclap" headache, first-ever aura, neurological symptoms), when to consult a GP or neurologist, and a clear disclaimer that Aurae is a tracking tool — not a diagnostic tool. Content is sourced from clinical advisor recommendations and reviewed by legal.

The screen must include a subsection on frequent medication use (see Section 7.2 below). This subsection is informational in tone — it is not a red-flag warning.

This screen must be available to all users (free and premium) and must not be gated.

### 7.2 Medication Overuse Awareness Warning

#### Clinical Context
Medication overuse headache (MOH), defined by ICHD-3 criteria, requires use of acute headache medication on 10 or more days per month for more than 3 months. The V1 implementation addresses only the 10-day-per-month frequency component — the 3-month duration component is intentionally absent and is noted here as a known limitation for internal documentation purposes. The warning is a pattern awareness prompt, not a MOH diagnosis. This distinction must be reflected in all copy.

#### Scope — Acute Medications Only
The overuse count applies exclusively to acute (as-needed) medications. Preventive medications taken on a daily prescribed schedule are explicitly excluded from the count. Including daily preventive medications would generate false positives for any user on a standard preventive regimen (e.g., daily topiramate) — a patient safety issue.

Classification is captured via the `medicationIsAcute: Bool?` field on `RetrospectiveEntry`:
- `true` — user selected "For headache relief" (acute)
- `false` — user selected "Daily as prescribed" (preventive) — excluded from count
- `nil` — unclassified; conservatively counted toward the acute total, unless the medication name matches a known preventive name list (engineering implementation detail)

#### Threshold
The warning triggers when the user has logged acute medication entries on 10 or more distinct calendar days within the current calendar month.

#### Warning Copy (verbatim — do not alter without clinical advisor and legal review)
"You've logged acute medication for headache relief more than 10 times this month. Frequent use of certain pain relievers may be associated with rebound headaches in some people. This is for your awareness only — not a diagnosis. It may be worth mentioning this pattern to your healthcare provider."

#### Placement and Gating
- Displayed as an inline card in the Insights tab.
- **Ungated — visible to all users, including free tier.** A user on a free plan who is at clinical risk of medication overuse must receive this awareness prompt. Gating this behind premium would be a patient safety failure.
- The card includes a link that opens the "When to Seek Medical Care" screen.

#### "When to Seek Medical Care" Screen Update
The screen must include a new subsection titled "Frequent Medication Use." This subsection is informational, not alarming in tone, and covers the association between frequent acute pain reliever use and rebound headaches. It reiterates that this information is for awareness only and encourages discussion with a healthcare provider. This subsection is not a red-flag escalation path.

#### Risk Assessment
Clinical risk of this implementation: Low, provided the acute/preventive distinction is correctly enforced and the copy accurately reflects "pattern awareness" rather than diagnosis. The known limitation (3-month ICHD-3 duration component absent) is acceptable for V1 awareness purposes and must be documented in internal records.

### 7.3 Accurate Product Copy — No "AI-Powered" Language

The term "AI-powered" must not appear in any user-facing copy in V1. Aurae's Insights feature uses algorithmic co-occurrence analysis running entirely on-device. This must be described accurately in all user-facing contexts.

**Prohibited:** "AI-powered," "artificial intelligence," "machine learning"

**Required (approved variants):**
- "On-device pattern analysis" (preferred for feature descriptions and onboarding)
- "Smart pattern recognition" (acceptable for marketing-adjacent copy)
- "Personal pattern insights" (acceptable for UI labels)

This applies to: onboarding screen 3, the premium features table (paywall), the Insights tab header, and any App Store or marketing copy.

### 7.4 Insights Data Integrity Requirements

The following requirements govern what the Insights feature may and may not present to users, independent of the user-facing language used.

#### Minimum Thresholds (enforced in `InsightsService.swift`)
- General frequency insights: 5 resolved logs (unchanged)
- Weather correlations: 10 resolved logs before any weather pattern is surfaced
- Sleep correlations: 5 entries per comparison group minimum

Below threshold: show a progress state, not a result. No partial or provisional correlation results may be shown below these thresholds.

#### Correlation Label Language (enforced in `InsightsService.swift`)
Frequency-based language only. Correlation language is prohibited.
- "Frequently present" replaces "Strong correlation"
- "Sometimes present" replaces "Moderate correlation"
- "Occasionally present" replaces "Weak correlation"

#### Insights Disclaimer (Insights Tab)
- On first visit to Insights: full disclaimer shown prominently; user may dismiss after reading
- On all subsequent visits: compact footer persists — "For informational purposes only · Not medical advice"
- Full disclaimer text: "Patterns are based on your logged data only. They are for informational purposes and do not constitute medical advice."

#### Triggers Correlational Disclaimer
The trigger bar chart in the full Insights view must display a correlational disclaimer below the bars: "These patterns reflect associations in your logged data. They are not confirmed triggers and may change as you log more episodes. Share them with your care team to explore what they mean for you." This is a clinical advisor requirement (implemented at commit `603ffed`).

#### First Insights Educational Interstitial
- Triggered once when the user's 5th resolved log is reached and they navigate to Insights for the first time
- Communicates: patterns take time to develop, co-occurrence is not causation, discuss findings with a clinician
- Single CTA: "Got it — show my patterns"
- Shown once; state persisted in UserDefaults

### 7.5 Onboarding Safety Screen (Screen 5 of 6)

A clinical safety screen is presented to every new user during onboarding, before the permissions screen. This screen is required by the clinical advisor and must not be removed or made skippable.

**Screen title:** "Before you start logging."

**Content:**
- Opening body copy: "Aurae is designed for recurring headaches you already know about."
- Four red-flag symptom rows (displayed as `FeatureRow` cards with warning-colored icons):
  1. A sudden, severe headache unlike any you've had before.
  2. Headache with fever, stiff neck, confusion, or vision changes.
  3. A headache following a head injury.
  4. New weakness, numbness, or difficulty speaking.
- Seek-care callout (blush background): "If you experience any of these, please seek medical care right away. These symptoms are not what this app is designed to track."
- Aura clarification (soft-teal background): "Aurae is designed for anyone who experiences recurring headaches, whether or not you experience aura or have a migraine diagnosis."

**Position in onboarding flow:** Screen 5 of 6. Adding this screen shifted the former Screen 5 (permissions) to Screen 6.

**Navigation:** Skip button behavior — "Skip" on screens 2–4 jumps to the Permissions screen (Screen 6), bypassing this Safety screen. This is intentional: users who actively skip onboarding content have demonstrated intent; the safety screen content is still available from Settings via "When to Seek Medical Care." The clinical advisor approved this Skip behavior.

**Page count:** Total onboarding screens is now 6 (was 5 at v1.5). The `pageCount` constant in `OnboardingView.swift` is 6.

### 7.6 Headache Type Self-Report Disclaimer

The headache type selector in the retrospective entry screen must display a non-dismissible inline note below the selector field:

"Select the type that best matches your experience. Self-reported — not clinically confirmed."

Rendered as a compact caption (`auraeCaption` style) in `auraeMidGray`. This requirement exists because the headache type taxonomy is user-selected and not clinically validated (see D-14).

### 7.7 Food Trigger Shortcut Accuracy

The `foodTriggerShortcuts` list must not present gluten as a universal trigger. The shortcut must be labeled "Gluten (if sensitive)" to make clear that this trigger is relevant only to users with diagnosed celiac disease or confirmed gluten sensitivity.

### 7.8 Copy Language Guardrails (Clinical Advisor)

The following language rules apply to all user-facing copy throughout the app, including onboarding, Insights, Profile, paywall, and App Store metadata. See Section 18.4 for the full copy standards reference.

**Forbidden words and phrases (never use as causal or factual claims):**
- triggers (as a causal fact — e.g. "your triggers," "find your triggers")
- diagnose / diagnosis
- cure / eliminate / fix / solve / prevent
- proven / clinically proven
- "find your triggers"

**Required approved language (use instead):**
- "may be associated with"
- "patterns you've noticed"
- "your data shows"
- "worth discussing with your care team"
- "associations you may not have noticed on your own"

These rules were established following clinical advisor review and are encoded in the onboarding copy, Insights locked-state body copy, and App Store description. Any new copy that touches the Insights, onboarding, or paywall must be reviewed against these guardrails before shipping.

### 7.9 Clinical Language Standards — Approved Replacements (v1.8)

These replacements were reviewed and signed off by the Migraine Clinical Advisor on 27 Feb 2026 (commit `41908b9`). They are binding across all user-facing copy. Any reversion requires re-approval by the clinical advisor.

#### Governance Rule

Copy that describes data findings, pattern summaries, or factor associations must use language that:
1. Positions findings as correlational observations, not causal facts.
2. Uses "around," "may be," "associated with," or "worth discussing with your care team" rather than definitive claims.
3. Directs users toward their care team for interpretation rather than implying the app provides clinical conclusions.

#### Approved Replacements (P1/P2 — clinical advisor sign-off required)

| Location | Old copy | New copy | Rationale |
|---|---|---|---|
| HomeView — weather trigger card | "Weather Trigger" | "Weather Association" | "Trigger" implies confirmed causation. "Association" is accurate to the correlational method. |
| HomeView — weather trigger description | (used definitive "trigger" language) | Updated to use "around" and "may be worth discussing with your care team" | Softens from causal claim to observational note with care team prompt. |
| HomeView — sleep insight card | "followed nights with" | "preceded by" | Directional framing — "preceded by" is observationally accurate without implying the sleep pattern caused the headache. |
| HomeView — sleep insight card | (no care team prompt) | Added: "Sleep patterns may be worth discussing with your care team." | Consistent with the care-team-referral pattern now required on all pattern-finding surfaces. |
| OnboardingView | "your personal triggers" | "associations you may not have noticed" | Removes causal "trigger" framing from onboarding; aligns with Section 7.8 guardrails. |
| InsightsView — trigger card title | "Your Top Triggers" | "Frequently Logged Before Headaches" | Removes the word "Triggers" from a section header entirely. Describes the algorithm accurately (co-occurrence frequency). |
| InsightsView — medication card title | "What's Working" | "Your Medication Ratings" | "What's Working" implies efficacy conclusions. "Medication Ratings" is descriptive and neutral. Requires inline disclaimer — see below. |

#### Medication Ratings Inline Disclaimer (required)

When "Your Medication Ratings" card is shown in `InsightsView`, an inline disclaimer must appear directly below the card title:

"Your ratings reflect your own experience and are not a recommendation to use or stop any medication. Discuss medication changes with your care team."

This disclaimer is a clinical advisor requirement. It must not be removed without clinical and legal sign-off.

#### Quick Insights Section — Static Correlational Disclaimer (HomeView, Free Tier)

A static correlational disclaimer must appear below the Quick Insights section on `HomeView` for all users (free and premium). This surface was identified as a coverage gap: the Insights tab disclaimer (Section 7.4) does not apply to users who have not navigated to the Insights tab, and free-tier users may never see it.

Required disclaimer copy (displayed below Quick Insights cards on `HomeView`):

"Patterns are based on your logged data. For informational purposes only — not medical advice."

This disclaimer is ungated (shown to all users) and non-dismissible on this surface. It is distinct from the dismissible Insights tab first-view disclaimer (Section 7.4) and does not replace it.

---

## 8. Monetization — Freemium Model

Core logging is permanently free with no usage limits. Premium unlocks the intelligence and clinical layers. The gate is placed after users have seen genuine value from the free tier.

Gated features are never hidden. Free users always see locked premium features in a disabled/locked state with a clear upgrade prompt. This ensures discoverability and removes ambiguity about what premium offers.

| Feature | Free | Premium ✦ |
|---|:---:|:---:|
| Onset logging (unlimited) | ✓ | ✓ |
| Auto weather data capture | ✓ | ✓ |
| Auto Apple Health capture | ✓ | ✓ |
| Post-headache retrospective | ✓ | ✓ |
| History & calendar view | ✓ | ✓ |
| Basic PDF export (summary) | ✓ | ✓ |
| On-device trigger pattern analysis | — | ✓ |
| Full contextual PDF export | — | ✓ |
| Charts & trend visualisations | — | ✓ |
| Medication effectiveness tracking | — | ✓ |
| Menstrual cycle correlation | — | ✓ |
| Weather correlation insights | — | ✓ |
| Custom report builder (clinics) | — | ✓ |
| Data export (CSV / JSON) | — | ✓ |

### 8.1 Pricing

- **Monthly:** $4.99 / month
- **Annual:** $34.99 / year (~$2.92/month, 42% saving)
- **Free trial:** 14 days of Premium, no credit card required

> **QA flag (open):** Confirm "Try free for 14 days — no credit card needed." copy in `InsightsView` locked state matches the active RevenueCat config before App Store submission. If the RevenueCat trial configuration changes, this copy must be updated.

---

## 9. Technical Requirements

### 9.1 Platform

- iOS 17+ target, iOS 16 minimum. iPhone optimised; iPad as stretch goal post-launch.
- Native Swift / SwiftUI preferred for performance and Health framework access.

### 9.2 Integrations

| Integration | Purpose | Notes |
|---|---|---|
| Apple HealthKit | Sleep, HR, HRV, SpO2, cycle | Explicit user permission per data type. Permission denied handled silently with nil. |
| Open-Meteo | Temp, humidity, pressure, UV index | No API key required. Free. Single `/forecast` endpoint. AQI not available via this endpoint — stored as nil. |
| CoreLocation | Location at onset for weather | When-in-use only. Not stored. |
| PDFKit / renderer | PDF report generation | On-device — no server round-trip |
| RevenueCat / StoreKit 2 | Subscription management | Integrated. Entitlement name: `"pro"`. `EntitlementService` is a SwiftUI environment-injectable `@Observable` class. Paywall presented as `.sheet` via `RevenueCatUI.PaywallView`. Test Store API key active in development. |
| Oura / Garmin / Fitbit | Sleep data fallback | Phase 2 — via HealthKit relay or OAuth |

### 9.3 Data & Privacy

- All health data stored on-device or in the user's private iCloud container (CloudKit). Never on Aurae servers.
- No raw health data sent to third-party AI services without explicit, granular consent.
- Pattern analysis runs entirely on-device as algorithmic co-occurrence analysis (`InsightsService.swift`). No Core ML model and no server component.
- GDPR and HIPAA compliance posture — a trust and brand decision even where not legally required.
- One-tap data deletion from within the app.

---

## 10. Key User Flows

### 10.1 First Launch & Onboarding

Onboarding is implemented as a 6-screen `TabView` flow with an animated capsule dot indicator. Screens 2–5 include a Skip button (Skip jumps directly to Screen 6, the permissions screen). There is no questionnaire or onboarding survey in V1.

1. **Welcome** — `AuraeLogoMark(68)` + "aurae" wordmark, headline "Understand your patterns.", subtitle, "Get Started" CTA.
2. **How it works** — explains weather and Apple Health auto-capture at onset.
3. **Fill in the rest** — explains the retrospective entry flow.
4. **Discover your patterns** — premium Insights preview with locked mock card.
5. **Before you start logging** — safety screen: red-flag symptom rows, seek-care callout, aura clarification. (Clinical advisor requirement — see Section 7.5.)
6. **A few quick permissions** — explains HealthKit, Location, and Notifications; "Let's go" CTA leads into the main app.

**Permission philosophy:** HealthKit, Location, and Notifications are all requested on the user's first log attempt — never on launch. The Permissions screen (step 6) sets expectations before any system prompt appears. The app is fully functional with all three permissions denied; all health and weather fields degrade gracefully to nil or manual entry.

### 10.2 Logging a Headache (Core Flow)

1. User opens app. Home screen visible.
2. User selects severity (optional — defaults to Moderate).
3. User taps "Log Headache". System prompts for permissions if this is the first log attempt. Haptic feedback. Auto-capture fires in background.
3a. **Onset speed question** — immediately after severity selection and before the confirmation action, the user is shown the following question in the primary logging flow. This step must not be placed in an optional "more details" section; it must appear in the primary flow so the safety function can activate at log time.

   Question (verbatim): "How fast did this headache go from nothing to its worst?"

   Answer options (verbatim):
   - "Gradually, over 30 minutes or more" → `onsetSpeed = .gradual`
   - "Quickly, within about 1 to 30 minutes" → `onsetSpeed = .moderate`
   - "Almost instantly, within seconds to about a minute" → `onsetSpeed = .instantaneous`
   - "Not sure" → `onsetSpeed = nil`, no safety trigger fires

   The "Not sure" option is required to accommodate users who were asleep at onset or cannot recall. Skipping the question without answering is treated as "Not sure" (`nil`).

4. Confirmation: "Logged at 2:34 PM. Stay hydrated." with a calm animation.
   - If `onsetSpeed == .instantaneous` AND `severity >= 4`: primary urgent safety banner fires on `LogConfirmationView` (see Section 7.1).
   - If `onsetSpeed == .instantaneous` AND `severity < 4`: secondary advisory notice fires on `LogConfirmationView` (see Section 7.1).
5. Home screen transitions to active headache state — elapsed duration banner visible, "Mark as Resolved" CTA replaces the Log button. If the primary urgent banner fired in step 4, it persists on `HomeView` until the headache is resolved.
6. Follow-up notification scheduled: "How's your headache? Tap to update." Delay is configurable in Settings: 30 minutes, 1 hour (default), or 2 hours. The notification includes two action buttons implemented as `UNNotificationAction` categories: **"Mark as Resolved"** (resolves the headache directly from the notification) and **"Snooze"** (delays the follow-up by the user's preferred interval).
7. User taps "Mark as Resolved". Active headache state clears. Notification cancelled automatically.
8. App prompts retrospective entry.
9. Retrospective completed (or skipped). Log is sealed.

### 10.3 Generating a PDF Report

PDF export is accessed via the **Export tab** in the main tab bar — not via Profile or a nested menu.

1. User taps the **Export** tab.
2. Selects a date range.
3. Premium users may select report depth (summary vs. full clinical). Free users see the summary option only.
4. Taps "Export PDF" — PDF rendered on-device via PDFKit in < 3 seconds.
5. Share sheet: AirDrop, Mail, Save to Files, Print.

> **Build note:** Step 16 (full premium PDF export) is not yet built. The Export tab is present and the free summary path is functional. The premium full-export path is stubbed and gated.

---

## 11. Out of Scope for V1

- Android version
- Web dashboard or companion app
- Direct EHR / medical record integration
- Community or social features
- In-app telemedicine or doctor referral
- Custom medication database or drug interaction checking
- Apple Watch native app (Phase 2)
- Multi-user / family accounts

---

## 12. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| HealthKit permissions denied | High | All health data optional. App fully functional without it. |
| Weather API downtime | Medium | Cache last-known weather. Fallback to manual entry. |
| Low free→premium conversion | Medium | Ensure free tier is genuinely valuable. Test paywall placement. |
| Medical liability | Medium | Clear in-app disclaimers. Tracking tool, not diagnostic. Legal review. |
| Drop-off after first log | High | Strong retrospective UX. Educational interstitial at 5th log primes expectation before first Insights view. |
| Privacy concerns | Medium | On-device storage. Transparent permissions. Privacy-first marketing. |

---

## 13. Open Questions

### Closed at v1.5 (23 Feb 2026)

The following UX design review open questions (OQ-A through OQ-E) and P1 issues were resolved at v1.5. Decisions are recorded in the Decision Log (D-28 through D-32).

- **OQ-A — Red-flag banner entry points:** CLOSED. All three surfaces required: LogConfirmationView, HomeView, InsightsView. See D-28.
- **OQ-B — Medication overuse scope:** CLOSED. Acute medications only. `medicationIsAcute: Bool?` added to `RetrospectiveEntry`. Classification toggle in Medication section. See D-29 (note: D-29 covers streak chip; medication overuse is D-32).
- **OQ-C — Streak chip during active headache:** CLOSED. Hidden entirely while headache is active. See D-29.
- **OQ-D — Triptych card partial state:** CLOSED. Show partial state with "--" for nil weather values. Card never hidden due to single-column data absence. See D-30.
- **OQ-E — Red-flag banner dismiss scope:** CLOSED. Per-log, not global. `hasSeenRedFlagBanner` global boolean replaced with per-log tracking. See D-31.
- **P1#1 — Post-resolve retrospective never prompted:** CLOSED. CTO wired `.sheet(item: $viewModel.logPendingRetrospective)` in HomeView. No PRD update needed.
- **P1#2 — Red-flag banner only in InsightsView:** CLOSED. Banner now specified for LogConfirmationView (primary), HomeView (persistent), InsightsView (secondary). See D-28 and Section 7.1.
- **P1#3 — Medication overuse warning undefined:** CLOSED. Full spec in Section 5.3 and Section 7.2. See D-32.

### Closed at v1.6 (23 Feb 2026)

- **OQ-02 — Severity 5 onset definition:** CLOSED. Clinical advisor reviewed and approved the onset speed selector spec. `onsetSpeed: OnsetSpeed?` added to `HeadacheLog`. Two-tier trigger: primary urgent banner (`onsetSpeed == .instantaneous` AND `severity >= 4`); secondary advisory notice (`onsetSpeed == .instantaneous` AND `severity < 4`). Onset speed question added to primary logging flow after severity selection. See D-33.

### Closed at v1.7 (27 Feb 2026)

- **OQ-04 — Onboarding safety screen content and placement:** CLOSED. Safety screen ("Before you start logging") implemented as Screen 5 of 6 in the onboarding flow. Four red-flag symptom rows, seek-care callout, aura clarification. Clinical advisor approved. Skip button bypasses to Permissions screen (Screen 6). See D-34.
- **OQ-05 — Onboarding headline copy (clinical advisor sign-off):** CLOSED. Screen 1 headline changed from "Understand your headaches." → "Understand your patterns." Screen 4 (InsightsPage) headline changed from "Discover your triggers." → "Discover your patterns." Both changes approved by clinical advisor. "triggers" as a causal claim removed from all onboarding copy. See D-35.
- **OQ-06 — Brand mark direction:** CLOSED. Brand mark adopted as three concentric ellipses (`AuraeLogoMark`) in `auraeMarkGradient` (#2D7D7D → #B3A8D9). Wordmark "aurae" in DM Sans SemiBold. `AuraeLogoMark` and `AuraeLogoLockup` components shipped. See D-36.
- **OQ-07 — Icon container shape system:** CLOSED. All icon containers use `RoundedRectangle`, `opacity(0.12)` fill, `.medium` SF Symbol weight. `Circle` fills are migration targets. See D-37.
- **OQ-08 — Onboarding typography rule:** CLOSED. DM Serif Display at ≥26pt retained for onboarding headlines. `fraunces()` / `dmSerifDisplay()` at ≥26pt returns `Font.custom("DMSerifDisplay-Regular", ...)`. Below 26pt uses system font. See D-38.

### Closed at v1.8 (28 Feb 2026)

- **Step 17 (Settings):** CLOSED. Settings consolidated into `ProfileView` — four sections (PREFERENCES, SUBSCRIPTION, DATA, SUPPORT). `SettingsView.swift` deleted. Gear icon removed from `HomeView`. See D-46.
- **Rolling window label ("This Month" vs. precise label):** CLOSED. All aggregate labels changed from "This Month" to "Last 30 Days" to reflect the rolling 30-day calculation already in use. Resolves a latent mismatch between label and logic. See D-47.
- **Retrospective read-mode label conventions:** CLOSED. Canonical labels established: "Add notes" / "Edit notes" / "Your Notes" for all notes entry points across `RetrospectiveView`. Chip containers removed from read-mode tag rows. See D-48 and D-49.

### Remaining Open Questions

- **Step 16 (Premium PDF):** Which additional charts and contextual sections should be included in the full clinical export? Format and section order to be confirmed before build begins. Owner: PM. Target: before Step 16 build begins.
- **Step 17 (Settings — CLOSED at v1.8):** Settings surface consolidated into `ProfileView`. `SettingsView.swift` deleted. All settings content now lives in the Profile tab across four sections: PREFERENCES, SUBSCRIPTION, DATA, SUPPORT. Gear icon and settings sheet removed from `HomeView`. See D-46.
- **OQ-01 — Red-flag banner copy (legal review):** Clinical advisor copy for the conditional safety banner and "When to Seek Medical Care" screen (including the new frequent medication use subsection and the two-tier onset-speed banner copy added at v1.6) must be reviewed and approved by legal counsel before V1 release. Owner: PM. Target: before Step 16 build completion.
- **OQ-03 — Preventive medication name list:** Engineering requires a seed list of known preventive medication names to apply the conservative nil-classification fallback in the medication overuse count (Section 7.2). Who owns this list? Suggested approach: PM compiles an initial list from clinical advisor input; list is hardcoded in V1 and editable in a future release. Owner: PM + Clinical Advisor. Target: before red-flag banner and medication overuse warning implementation begins.

---

## 14. Decision Log

Decisions made during development that closed previously open questions or established constraints with product-level implications. Logged in the order resolved.

| # | Decision | Rationale | Date |
|---|---|---|---|
| D-01 | **Weather provider: Open-Meteo** (single `/forecast` endpoint). Replaces OpenWeatherMap. No API key required. Free. | Open-Meteo provides all required weather fields (temperature, humidity, pressure, UV index, WMO weather code) at no cost and with no API key. AQI is not available via this endpoint and is stored as nil. OpenWeatherMap was deprioritised: the free tier required an API key and added integration complexity with no material benefit for V1. | Feb 2026 |
| D-02 | **Apple Watch logging: Phase 2.** Not included in V1. | Scope control. V1 priority is the core iPhone logging loop. Watch support adds significant surface area without validating the core product hypothesis. | Feb 2026 |
| D-03 | **Pressure trend is a single-point heuristic in V1.** Rising/falling/stable is derived from the current reading, not a rolling window. | Building a true rolling trend requires time-series storage and a secondary API call cadence. This complexity is not justified for V1. Limitation is documented; a true trend can be added in a later release. | Feb 2026 |
| D-04 | **Sleep capture window: 10 PM (previous day) → 10 AM (current day).** | Matches Apple Health's own sleep window convention, ensuring consistency with Health app data and reducing edge-case mismatches for users who sleep late. | Feb 2026 |
| D-05 | **SpO2 stored as 0–100%.** | Display-friendly format. Avoids floating-point fraction storage and simplifies UI rendering. Consistent with how HealthKit surfaces the value to users. | Feb 2026 |
| D-06 | **HealthKit read-denial is silent by design.** All HealthKit fields degrade to nil when permission is denied. No error shown to the user. | Apple's privacy policy prevents the app from detecting whether a denial is a true denial or simply no data. Surfacing an error would be misleading. Nil fields are handled gracefully throughout the app. | Feb 2026 |
| D-07 | **Follow-up notification delay: configurable at 30 min / 1 hr / 2 hrs via Settings.** Default is 1 hour. | 1 hour is a reasonable default for most headaches, but sufferers with rapid-onset resolution or long-duration episodes need flexibility. Three fixed options reduce decision fatigue without requiring a freeform picker. | Feb 2026 |
| D-08 | **Active headache state machine on home screen.** While a headache is active, the Log button and severity selector are replaced by an elapsed duration banner and "Mark as Resolved" CTA. | Prevents duplicate logging. Makes the ongoing state explicit. Ensures the user knows a headache is being tracked without needing to navigate to History. | Feb 2026 |
| D-09 | **Permission requests deferred to first log attempt.** HealthKit, Location, and Notifications are not requested on launch. | Requesting permissions before demonstrating value reduces grant rates and creates a negative first impression. Requesting at the moment of need — with inline explanation — produces higher acceptance and clearer context. | Feb 2026 |
| D-10 | **Gated features always visible in locked state.** Premium features are never hidden from free users. | Hiding features removes discoverability and weakens the upgrade value proposition. Showing locked states with upgrade prompts communicates premium value and supports conversion. | Feb 2026 |
| D-11 | **Trigger analysis: fully on-device, algorithmic only. No Core ML, no server component.** `InsightsService.swift` implements co-occurrence analysis, weather correlation, day-of-week/time-of-day patterns, sleep correlation, medication effectiveness, streak tracking, and frequency trends. | Eliminates privacy risk from server-side processing. Avoids Core ML model maintenance overhead. Algorithmic co-occurrence is sufficient to surface meaningful personal patterns for V1. | Feb 2026 |
| D-12 | **CTA button label: dark ink (`#1C2826`) on Aurae Teal fill. White text is prohibited on this surface.** | White text on `#8AC4C1` achieves only 1.95:1 contrast — fails WCAG AA. Dark ink (`auraeSeverityLabelSelected`) achieves ≥10:1 (AAA). This is a non-negotiable accessibility constraint, not a stylistic preference. Applies to all primary CTA buttons and any label placed on a teal fill. | Feb 2026 |
| D-13 | **V1 tab bar: Home, History, Insights, Export. No Profile tab.** PDF export is a top-level tab. A Settings screen is planned for Step 17 but will not be surfaced as a tab — likely accessed via a navigation bar icon. | Export is a primary user goal (doctor visits, healthcare communication). Elevating it to a tab reduces friction. Profile is not yet a meaningful screen without account infrastructure. Settings as a tab would be disproportionate to the settings surface area in V1. | Feb 2026 |
| D-14 | **Headache type taxonomy (tension / migraine / cluster / sinus) deferred to V2.** V1 captures headache type as a free-form location/type field in `RetrospectiveEntry`. | A structured taxonomy requires clinical validation and localisation. Free-form capture preserves the data without constraining users prematurely. Taxonomy can be layered on in V2 using existing free-text data as training signal. | Feb 2026 |
| D-15 | **PDF export: Aurae-branded format.** A4 portrait with teal accent bar and "Generated by Aurae" footer. Professional in tone but clearly Aurae-owned. | A branded export reinforces product identity at the clinic — a high-trust moment with healthcare providers. Neutral clinical styling was considered but rejected as a missed brand-building opportunity. The format reads as professional while still being distinctive. | Feb 2026 |
| D-16 | **Severity selector reduced from 5 levels to 3: Mild (rawValue 1), Moderate (rawValue 3), Severe (rawValue 5).** Pills display word labels only — no numeric index. Raw values 1, 3, 5 are preserved in the data model. | Reduces cognitive load at the moment of pain. Aligns with common clinical severity scales (mild / moderate / severe). Simplifies the UI without losing meaningful clinical gradation. Raw values 1, 3, 5 preserve spread across the existing 5-point color scale and maintain backwards compatibility with any stored logs. | Feb 2026 |
| D-17 | **Home screen ambient enrichment: four elements added** — radial gradient background wash, brand watermark, Fraunces streak numeral in header, and ambient context triptych card. | The prior home screen was visually sparse between the header and the CTA. These additions provide personal context (streak numeral, triptych card), brand presence (watermark, gradient wash), and emotional connection without adding logging friction or visual noise. All four elements are non-interactive or passive; none compete with the primary Log Headache action. Agreed following design director and UI designer review. | Feb 2026 |
| D-18 | **Red-flag symptom escalation pathway: accepted for V1.** Conditional safety banner on high-risk symptom combinations + static "When to Seek Medical Care" screen accessible from banner and Settings. | Patient safety requirement. The combination of aura + visual disturbance or sudden severe-onset headache warrants a clear escalation path in a medical-adjacent app. Low complexity, high liability consequence if omitted. Clinical advisor copy to be used verbatim pending legal review (see OQ-01). | 22 Feb 2026 |
| D-19 | **"AI-powered" language prohibited in all user-facing copy.** Replaced with approved variants: "on-device pattern analysis," "smart pattern recognition," "personal pattern insights." | Aurae uses algorithmic co-occurrence analysis — not AI. "AI-powered" is materially inaccurate in a health context and creates false impressions about insight quality and provenance. Applies to onboarding, paywall, Insights tab, and all marketing copy. | 22 Feb 2026 |
| D-20 | **Minimum log thresholds raised: weather correlations require 10 resolved logs; sleep correlations require 5 entries per group.** General frequency insights threshold unchanged at 5 logs. | Three data points is not a sufficient basis for surfacing a weather pattern to a user who may act on it. Raising thresholds to defensible minimums prevents clinically misleading output. Change is isolated to `InsightsService.swift`. | 22 Feb 2026 |
| D-21 | **Correlation label language replaced with frequency language in `InsightsService.swift`.** "Strong/Moderate/Weak correlation" → "Frequently/Sometimes/Occasionally present." | The co-occurrence algorithm does not produce statistically valid correlation coefficients. Language implying statistical correlation is inaccurate and misleading. Frequency-based language is honest, still actionable, and consistent with how the algorithm actually works. | 22 Feb 2026 |
| D-22 | **Insights disclaimer: once-dismissible on first view; persistent compact footer on all subsequent visits.** Full disclaimer on first visit; single-line footer permanently thereafter. | A permanently non-dismissible banner degrades the Insights UX for returning premium subscribers and undermines the value proposition. The compromise — full disclaimer on first view, persistent compact footer — satisfies the legal protection requirement without penalising returning users. | 22 Feb 2026 |
| D-23 | **Headache phase tracking (prodrome + postdrome): deferred to V1.1.** | Clinically valuable but medium complexity. Requires new `RetrospectiveEntry` fields, a new symptom multi-select UI component, `InsightsService` logic, and PDF export changes. Steps 16 and 17 are still outstanding. Defer until post-launch validation confirms the core product hypothesis. | 22 Feb 2026 |
| D-24 | **Headache type selector inline disclaimer: accepted for V1.** Non-dismissible caption below selector: "Select the type that best matches your experience. Self-reported — not clinically confirmed." | Consistent with D-14, which deferred a validated headache taxonomy precisely because self-selection is not clinical confirmation. The UI should reflect that ambiguity to the user. Trivial implementation cost; meaningful trust and liability signal. | 22 Feb 2026 |
| D-25 | **Gluten food trigger shortcut relabeled "Gluten (if sensitive)".** Not removed. | Gluten is a legitimate trigger for users with celiac disease or gluten sensitivity. Removing it reduces utility for that population. Relabeling contextualizes it appropriately without adding friction for unaffected users. Single string change in `foodTriggerShortcuts`. | 22 Feb 2026 |
| D-26 | **Medication timing field (`medicationTimingMinutes`): deferred to V1.1.** | Time-to-first-dose is clinically meaningful, particularly for triptans. However, it requires a new `RetrospectiveEntry` field, a time picker in the Medication section, and `InsightsService` analysis logic. Deferred alongside prodrome/postdrome (D-23) for a single retrospective enrichment release in V1.1. | 22 Feb 2026 |
| D-27 | **First Insights educational interstitial: accepted for V1.** Shown once when the user's 5th resolved log is reached and they navigate to Insights for the first time. | Replaces the prior "First Insight after 3 entries" note in the Risks table. The interstitial is better calibrated (aligns with the existing 5-log threshold), sets accurate expectations about correlation vs. causation, and directly reduces liability by prompting users to discuss patterns with their clinician. State persisted in UserDefaults. | 22 Feb 2026 |
| D-28 | **Red-flag banner must appear on all three surfaces: LogConfirmationView (primary), HomeView (persistent while headache is active), InsightsView (secondary).** Closes OQ-A and P1#2. | A banner surfaced only in InsightsView (a premium-gated tab) fails to reach users who log and close the app. LogConfirmationView provides guaranteed exposure at the highest-certainty moment. HomeView persistence ensures the prompt remains visible throughout the episode. InsightsView retention is a low-cost secondary catch. All three are required. Section 7.1 updated with full placement spec. | 23 Feb 2026 |
| D-29 | **Streak chip hidden entirely during active headache.** HomeViewModel must not surface `daysSinceLastHeadache` while `isActive == true`. Right side of header is empty. Closes OQ-C. | A frozen or dimmed stale streak count displayed during an active headache is factually misleading. The existing PRD spec (Section 6.5) already stated the header right side is empty during an active headache — this decision closes the implementation gap between the spec and the HomeViewModel behavior. | 23 Feb 2026 |
| D-30 | **Ambient context triptych card shows partial state with "--" for nil weather values. Card is never hidden due to a single column's data being absent.** Closes OQ-D. | Hiding the card entirely when weather data is nil would suppress sleep and days-free data that may have loaded successfully from HealthKit. The "--" convention is already established for sleep and days-free columns. Consistent partial-state rendering is preferable to a card that appears and disappears based on a single data failure. Weather icon is omitted when condition is nil. | 23 Feb 2026 |
| D-31 | **Red-flag banner dismiss state is tracked per log, not as a global boolean.** The current `hasSeenRedFlagBanner` global `@AppStorage` boolean is incorrect and must be replaced with per-log tracking (e.g., `hasAcknowledgedRedFlag: Bool` on `HeadacheLog`, or keyed by log ID). Closes OQ-E. | A global dismiss means a user who has new red-flag symptoms in a future episode will never see the escalation prompt again — a direct patient safety regression. The banner is contextual to a specific symptom combination in a specific log and must reset for each new triggering log. | 23 Feb 2026 |
| D-32 | **Medication overuse awareness warning: acute medications only, 10-day threshold, ungated, inline Insights card.** `medicationIsAcute: Bool?` added to `RetrospectiveEntry`. Classification toggle ("For headache relief" / "Daily as prescribed") added to Medication section. Clinical advisor copy used verbatim. Warning links to "When to Seek Medical Care" screen, which receives a new informational subsection on frequent medication use. Closes OQ-B and P1#3. | Preventive medications must be excluded from the overuse count — a daily topiramate user would receive a false warning every month, a patient safety issue. The clinical advisor confirmed 10 days/month is a defensible threshold for a conservative awareness prompt. The 3-month ICHD-3 duration component is absent in V1 (known limitation, documented). Warning is ungated: a free-tier user at clinical risk of medication overuse must receive the awareness prompt. Risk assessment: Low if acute/preventive distinction is correctly enforced and copy reflects pattern awareness, not diagnosis. | 23 Feb 2026 |
| D-33 | **Onset speed selector added to primary log flow. `onsetSpeed: OnsetSpeed?` field added to `HeadacheLog`. Two-tier red-flag trigger based on onset speed.** Option A (time-to-peak selector) selected over retrospective detection. Clinically approved `OnsetSpeed` enum: `.gradual` / `.moderate` / `.instantaneous`. "Not sure" maps to `nil` (no trigger). Trigger tiers: primary urgent banner (`onsetSpeed == .instantaneous` AND `severity >= 4`) fires on `LogConfirmationView` and persists on `HomeView`; secondary advisory notice (`onsetSpeed == .instantaneous` AND `severity < 4`) fires on `LogConfirmationView` only. Both surfaces link to `MedicalEscalationView` via "Learn more". The word "thunderclap" must not appear in any user-facing copy. Severity alone is not a sufficient trigger — onset speed is the primary clinical signal. Closes OQ-02. | Retrospective detection was rejected because it cannot activate the safety banner at log time — the primary requirement. An in-flow selector captures the signal while it is most accurate and enables the safety function to fire in `LogConfirmationView` at the highest-certainty exposure point. "Not sure" is required for users who were asleep at onset; without it, users would feel forced to guess, degrading data quality and potentially causing false positives. The `.instantaneous` case maps precisely to the ICHD-3 1-minute threshold, giving the trigger clinical defensibility. The two-tier design avoids over-alarming lower-severity users while still providing an advisory notice for any sudden-onset headache regardless of severity. All copy is clinically approved; legal review required before V1 release (OQ-01). | 23 Feb 2026 |
| D-34 | **Onboarding safety screen added as Screen 5 of 6.** "Before you start logging" — four red-flag symptom rows, seek-care callout, aura clarification. Former Screen 5 (permissions) shifted to Screen 6. `pageCount` updated to 6 in `OnboardingView.swift`. Skip behavior on screens 2–4 jumps to Screen 6 (permissions), not Screen 5. Clinical advisor requirement. Closes OQ-04. | Every new user should encounter a one-time, lightweight safety orientation before logging begins. The onboarding context is the highest-attention moment in the user journey and the most appropriate point to set expectations about which symptoms are outside the app's intended use. A dedicated screen avoids burying this information in fine print. The Skip behavior was retained for the 2–4 range to avoid forcing safety content on users who actively opt out of onboarding; the content remains accessible from Settings. | 27 Feb 2026 |
| D-35 | **Onboarding headline copy updated per clinical advisor sign-off. Screen 1: "Understand your patterns." Screen 4: "Discover your patterns."** "triggers" removed from both headlines. Closes OQ-05. | "Find your triggers" and "Discover your triggers" imply a causal relationship that the co-occurrence algorithm cannot establish. "Patterns" is accurate, honest, and still compelling. This change aligns onboarding copy with the product's technical approach and the broader copy language guardrails (Section 7.8, Section 18.4). | 27 Feb 2026 |
| D-36 | **Brand mark direction adopted: `AuraeLogoMark` (three concentric ellipses, `auraeMarkGradient` #2D7D7D → #B3A8D9) + `AuraeLogoLockup` (mark + "aurae" wordmark in DM Sans SemiBold).** `auraeMarkGradient` token added to `Colors.swift`. Components shipped in `DesignSystem/Components/AuraeLogoMark.swift`. Applied across: WelcomePage (68pt mark), Insights locked state (52pt, 70% opacity + lock icon overlay), Home empty states (ghost mark, 18% opacity), Profile footer (24pt, 2-ring lockup + brand statement). Closes OQ-06. | The three concentric ellipses evoke the "aura" concept — the defining perceptual experience of the migraine patient persona — without any literal medical illustration. The teal-to-violet gradient (`auraeMarkGradient`) uses the original brand palette, distinct from the functional UI blue (`auraePrimary`). The separation between brand gradient (warm teal/violet) and functional gradient (blue) is intentional and must be maintained. | 27 Feb 2026 |
| D-37 | **Icon container system: all icon badges use `RoundedRectangle`, `opacity(0.12)` fill, `.medium` SF Symbol weight.** `Circle` fills replaced throughout onboarding feature rows, Insights stat cards, and onboarding locked state. Closes OQ-07. | The `RoundedRectangle` container with a 12pt radius reads as modern, neutral, and slightly more grounded than a circle — appropriate for a health utility. The 0.12 opacity ensures the container echoes the icon's semantic color without dominating the surrounding text. Consistency across all icon badge contexts reduces visual noise and strengthens the system feel. | 27 Feb 2026 |
| D-38 | **DM Serif Display restored for onboarding headlines at ≥26pt.** `fraunces()` / `dmSerifDisplay()` at ≥26pt returns `Font.custom("DMSerifDisplay-Regular", ...)`. Below 26pt falls back to system font (safety against thin-stroke collapse on dark surfaces). Closes OQ-08. | The Design Director's preferred option (Option A) was restoration of DM Serif Display for onboarding headlines to preserve editorial warmth at the brand's highest-attention entry point. The ≥26pt rule ensures the typeface is only used where stroke contrast is legible. Below 26pt, DM Sans (via system font aliases) handles all UI text. This rule is enforced in `Typography.swift` and must not be overridden without Design Director sign-off. | 27 Feb 2026 |
| D-39 | **Medication section: clinical safety disclaimer added.** Non-removable caption displayed in `MedicationSection.swift` below the effectiveness field: "Medication records are for your reference and to support conversations with your care team. Do not adjust or stop any medication based on patterns observed in this app." | Clinical advisor requirement. The disclaimer prevents any interpretation of medication effectiveness data as a recommendation to alter a prescribed regimen. Implementation cost: negligible (single `Text` view). Safety value: high — directly addresses a category of potential harm unique to medication-tracking features in health apps. | 27 Feb 2026 |
| D-40 | **Insights triggers correlational disclaimer added.** Plain-text disclaimer displayed below the trigger bar chart in `InsightsView.swift` full state: "These patterns reflect associations in your logged data. They are not confirmed triggers and may change as you log more episodes. Share them with your care team to explore what they mean for you." | Clinical advisor requirement. The trigger bar chart is the highest-risk Insights surface — it most closely resembles a diagnostic claim ("you are triggered by X"). The disclaimer reframes it as associative data, not causal fact, and prompts care team discussion. | 27 Feb 2026 |
| D-41 | **Insights full state: episode count trust signal added.** "Based on your N logged episodes" caption displayed at the top of the full Insights scroll view. | Grounds the pattern analysis in its actual data source. Users who have few logs should understand that patterns derived from 6 episodes are less reliable than patterns derived from 60. The caption sets accurate expectations without hiding the feature or requiring a minimum to show it. | 27 Feb 2026 |
| D-42 | **Streak card icon changed from `bolt.fill` → `circle.dotted.and.circle`.** Brand halo echo — the concentric ring pattern echoes the `AuraeLogoMark` motif. Applied to `HomeView.swift` streak card icon container. | Visual coherence between the brand mark and a key motivational UI element. The `circle.dotted.and.circle` symbol in SF Symbols most closely approximates the concentric ring visual vocabulary established by the brand mark. `bolt.fill` had no connection to the Aurae visual system. | 27 Feb 2026 |
| D-43 | **Tab bar: `configureWithTransparentBackground()` + explicit `auraeAdaptiveCard` background; unselected items use `auraeTextSecondary`.** Applied in `ContentView.swift` `init()`. | The transparent tab bar background caused the tab bar to appear to float over content without a clear surface on dark mode. The explicit card surface creates a grounded separation between content and navigation. `auraeTextSecondary` for unselected items provides a clear selected/unselected distinction that meets WCAG contrast requirements. | 27 Feb 2026 |
| D-44 | **VoiceOver accessibility improvements shipped across retrospective components.** `RetroStarRating`: per-star labels "N out of 5, selected" / "N out of 5" with hints. `RetroIntensityScale`: same pattern. Medication effectiveness label: "Effectiveness" → "How much did it help?". | Screen reader users navigating star ratings need both the numeric value and the selection state. The previous implementation provided neither. "How much did it help?" is more conversational and natural for VoiceOver reading than "Effectiveness" — it also benefits sighted users reading the label. | 27 Feb 2026 |
| D-45 | **`RetroIntensityScale` extracted as a reusable standalone component from `LifestyleSection`.** Display name input fix applied. Star rating unselected color fix applied. | Reusability: `RetroIntensityScale` now serves both stress level (LifestyleSection) and any future intensity-scale contexts without copy-paste. The display name input fix resolved a SwiftUI `TextField` focus state bug. The unselected star color fix corrected a regression where unselected stars rendered in the teal accent color instead of `auraeAdaptiveSecondary`. | 27 Feb 2026 |
| D-46 | **Settings consolidated into ProfileView. `SettingsView.swift` deleted. Gear icon removed from HomeView.** ProfileView restructured into four sections: PREFERENCES, SUBSCRIPTION, DATA, SUPPORT. "Patterns Found" stat removed from Profile header. Closes Step 17 open question. | A dedicated Settings view was a separate file with duplicate navigation surface (gear icon on HomeView) for a very small settings footprint. Consolidation into Profile follows the established iOS health app pattern and reduces top-level navigation complexity. "Patterns Found" was premium-only data displayed in a free-accessible context — creating a misleading or empty state for free users. | 28 Feb 2026 |
| D-47 | **Rolling window label standardised: "This Month" → "Last 30 Days" across all aggregate views.** Affects HomeView, InsightsView, HistoryView, and any other aggregate label previously reading "This Month." | The underlying calculation has always been a rolling 30-day window, not a calendar-month window. "This Month" was a label mismatch that would produce confusing behavior at month boundaries (e.g. a user logging on March 1 would see January data excluded from "This Month" even though it was within 30 days). "Last 30 Days" is precise, honest, and unambiguous. Single string change across call sites — zero logic change. | 28 Feb 2026 |
| D-48 | **Canonical retrospective notes labels established: "Add notes" (empty state CTA), "Edit notes" (populated state CTA), "Your Notes" (section header when notes exist).** Applied consistently across all notes entry points in `RetrospectiveView.swift`. | Prior copy was inconsistent ("Add Note," "Edit Note," "Notes," "Your note") across different states of the same UI element. Canonical labels eliminate variation, reduce QA surface area, and produce a consistent VoiceOver experience. The CTA form ("Add notes" / "Edit notes") is action-oriented; the header form ("Your Notes") is possession-oriented — the distinction reflects the different UI role of each label. | 28 Feb 2026 |
| D-49 | **Chip/pill containers removed from retrospective read-mode tag rows (`RetroReadTagRow`). Replaced with plain inline text joined by " · " separator.** `RetroReadCard` header: `.tracking(1.0)` added, spacing 10→12pt. `RetroReadRow` layout changed from horizontal HStack (12pt label + 16pt body) to vertical VStack (12pt caption above, 13pt SemiBold value below). | Chip/pill containers signal interactive affordance in iOS design conventions. In a display-only read context, chip containers create a false affordance — users expect to tap or remove them. Plain inline text with a separator communicates read-only status correctly. The VStack layout for `RetroReadRow` aligns with the established `WeatherMetricCell`/`HealthMetricCell` pattern used elsewhere in the app — consistency over local variation. The `.tracking(1.0)` on section headers matches the section label treatment used across other card headers. | 28 Feb 2026 |
| D-50 | **Clinical language: five P1/P2 copy replacements approved by Migraine Clinical Advisor.** "Weather Trigger" → "Weather Association"; sleep insight "followed nights with" → "preceded by" + care team prompt added; onboarding "your personal triggers" → "associations you may not have noticed"; InsightsView "Your Top Triggers" → "Frequently Logged Before Headaches"; InsightsView "What's Working" → "Your Medication Ratings" + inline disclaimer added. Full spec in Section 7.9. | All five replacements address copy that used causal language ("trigger," "what's working") not supported by the co-occurrence algorithm. The clinical advisor reviewed each replacement and confirmed the new language accurately reflects the correlational nature of the underlying analysis. These are P1/P2 items — they must ship before V1 release. The medication ratings inline disclaimer is an additive clinical requirement that accompanies the rename. | 28 Feb 2026 |
| D-51 | **Quick Insights section on HomeView: static correlational disclaimer added below section (free and premium, ungated, non-dismissible).** Required copy: "Patterns are based on your logged data. For informational purposes only — not medical advice." | Free-tier users who never navigate to the Insights tab are not covered by the Insights tab disclaimer (Section 7.4). HomeView Quick Insights cards surface pattern data (weather associations, streak, sleep correlation snippets) to all users — this surface needed its own disclaimer. The disclaimer is non-dismissible on this surface because it is persistent context for a persistent UI element, unlike the once-dismissible Insights tab modal which is a one-time educational moment. | 28 Feb 2026 |
| D-52 | **`auraeTextCaption` semantic color token introduced. Governance rule: `auraeTextCaption` for all readable caption text; `auraeMidGray` restricted to decorative icons, chart fills, and opacity-modified de-emphasis.** 37 call sites migrated. Full spec in Section 18.6. | On Dark Matter surfaces, `auraeMidGray` dark (`#6B7280` equivalent in dark mode context) does not achieve WCAG AA contrast for 12pt caption text. The new `auraeTextCaption` token provides an elevated dark-mode value (`#9CAEBE`) that meets WCAG AA while leaving the decorative token unchanged. In light mode both tokens are currently equivalent (`#6B7280`) — the governance rule is applied now to ensure the tokens don't converge back through future edits. Migrating 37 call sites in one pass creates a clean separation. | 28 Feb 2026 |

---

## 15. Build Status

Steps are as defined in `CLAUDE.md`. Status as of 28 Feb 2026.

| Step | Description | Status |
|---|---|---|
| 1 | Design system (Colors, Typography, Layout) | Complete |
| 2 | SwiftData models | Complete |
| 3 | Home screen UI | Complete |
| 4 | HealthKit service | Complete |
| 5 | Weather service | Complete |
| 6 | CoreLocation wrapper | Complete |
| 7 | Log flow end-to-end | Complete |
| 8 | Local notifications | Complete |
| 9 | Retrospective entry screen | Complete |
| 10 | History list + calendar view | Complete |
| 11 | Log detail view | Complete |
| 12 | PDF export (free tier) | Complete |
| 13 | Onboarding flow | Complete |
| 14 | RevenueCat integration + paywall | Complete |
| 15 | Insights + pattern analysis (premium) | Complete |
| 16 | Full PDF export (premium) | Not built — stub only |
| 17 | Settings screen | Complete — consolidated into ProfileView (D-46) |
| 18 | Accessibility pass (Dynamic Type, VoiceOver, Reduce Motion) | Complete |
| 19 | Dark mode pass | Complete |

Step 16 remains before public release evaluation. The following V1 clinical integrity requirements from the February 2026 clinical review must also be completed before release: red-flag symptom banner (D-18), "When to Seek Medical Care" static screen (D-18), "AI-powered" copy removal (D-19), `InsightsService.swift` threshold and label updates (D-20, D-21), Insights disclaimer and first-view interstitial (D-22, D-27), headache type inline disclaimer (D-24), gluten shortcut relabel (D-25). Step 18 (accessibility) and Step 19 (dark mode) were completed on 20 Feb 2026.

The following items shipped at v1.8 (28 Feb 2026) — confirmed complete:
- **Settings / Profile consolidation (D-46):** `SettingsView.swift` deleted. `ProfileView` restructured into four sections (PREFERENCES, SUBSCRIPTION, DATA, SUPPORT) in `ContentView.swift`. Gear icon and settings sheet removed from `HomeView`. "Patterns Found" stat removed from Profile header.
- **Content audit — 28 P2/P3 copy fixes (commit `5e65c24`):** "This Month" → "Last 30 Days" everywhere (D-47). Active headache timer "so far" removed. Streak label updated. Medical disclaimer expanded with headache-specific care team language. Onboarding, permission copy, Insights labels, Export, History, LogDetail, Retrospective, and Profile copy updated. Full list in commit `5e65c24`.
- **Clinical language fixes — 5 P1/P2 items, clinical advisor approved (D-50, D-51) (commit `41908b9`):** "Weather Trigger" → "Weather Association". Sleep insight "followed nights with" → "preceded by" + care team prompt. Onboarding "your personal triggers" → "associations you may not have noticed." InsightsView "Your Top Triggers" → "Frequently Logged Before Headaches." InsightsView "What's Working" → "Your Medication Ratings" + inline disclaimer. Static correlational disclaimer added below Quick Insights section on HomeView.
- **Log detail read-mode visual refinement (D-49) (commit `cd2bae0`):** `RetroReadTagRow` pill/chip containers replaced with plain inline text joined by " · " separator. `RetroReadRow` layout changed from horizontal HStack to vertical VStack (12pt caption above, 13pt SemiBold value below). `RetroReadCard` header tracking 1.0 added, spacing 10→12pt.
- **`auraeTextCaption` design system token (D-52) (commits `950dd66`, `be33c9e`):** New semantic color token defined in `Colors.swift`. 37 call sites migrated from `auraeMidGray` to `auraeTextCaption` across HistoryView, RetrospectiveView, OnboardingView, ExportView, LogConfirmationView, LifestyleSection, MedicationSection, EnvironmentSection, MedicalEscalationView, CalendarView, LogDetailView, InsightsView. Governance rule documented in Section 18.6.
- **Canonical retrospective notes labels (D-48):** "Add notes" / "Edit notes" / "Your Notes" applied consistently across all notes entry points in `RetrospectiveView.swift`.

The following additional implementation items were added at v1.5 (23 Feb 2026) and must also be completed before release:
- **Red-flag banner placement correction (D-28):** Banner must appear on LogConfirmationView and HomeView (persistent while active) in addition to InsightsView. Requires updates to `LogConfirmationView.swift`, `HomeView.swift`, and `HomeViewModel.swift`.
- **Per-log red-flag dismiss state (D-31):** Replace `hasSeenRedFlagBanner` global `@AppStorage` boolean with per-log tracking. Requires a model change on `HeadacheLog` or a UserDefaults key-per-log-ID implementation.
- **Streak chip hidden during active headache (D-29):** `HomeViewModel` must gate streak display on `isActive == false`. Bug fix — spec was already correct in PRD Section 6.5.
- **Triptych card partial state for nil weather (D-30):** Confirm `HomeView` renders "--" for nil weather columns rather than hiding the card. Likely a minor view adjustment.
- **`medicationIsAcute: Bool?` field on `RetrospectiveEntry` (D-32):** New SwiftData field required. Classification toggle UI required in `MedicationSection.swift`.
- **Medication overuse warning card in InsightsView (D-32):** New ungated inline card in `InsightsView.swift`. Logic in `InsightsService.swift` or `InsightsViewModel.swift` to compute acute-day count for current month.
- **"When to Seek Medical Care" screen — frequent medication use subsection (D-32):** New informational subsection to be added to the static screen.

The following additional implementation items were added at v1.6 (23 Feb 2026) and must also be completed before release:
- **`onsetSpeed: OnsetSpeed?` field on `HeadacheLog` (D-33):** New optional SwiftData field. Add `OnsetSpeed` enum (`gradual` / `moderate` / `instantaneous`) as a `String`-backed `Codable` enum in `HeadacheLog.swift`. Requires a SwiftData migration.
- **Onset speed question UI in log flow (D-33):** New screen or step added to the log flow in `LogViewModel.swift` and the corresponding view, appearing after severity selection and before log confirmation. Four answer options rendered as tappable choices. "Not sure" maps to `nil`. The question must appear in the primary flow — not in an optional "more details" section.
- **Two-tier red-flag trigger logic (D-33):** Update red-flag evaluation logic (in `LogViewModel.swift` or wherever trigger conditions are evaluated) to replace the prior vague "Severity 5 with sudden onset" condition with: (a) primary urgent banner when `onsetSpeed == .instantaneous && severity >= 4`; (b) secondary advisory notice when `onsetSpeed == .instantaneous && severity < 4`. The aura + visual disturbance trigger is unaffected.
- **Two-tier banner copy in `LogConfirmationView.swift` and `HomeView.swift` (D-33):** Implement primary urgent banner using clinically approved copy (see Section 7.1). Implement secondary advisory notice using clinically approved copy (see Section 7.1). Both must include a "Learn more" action opening `MedicalEscalationView`. Primary banner persists on `HomeView` while headache is active; secondary notice appears in `LogConfirmationView` only and does not persist.

The following items shipped at v1.7 (27 Feb 2026) — confirmed complete:
- **Brand mark system (D-36):** `AuraeLogoMark.swift` and `AuraeLogoLockup` components shipped. Applied to WelcomePage, Insights locked state, Home empty states, Profile footer.
- **`auraeMarkGradient` token (D-36):** Added to `Colors.swift`.
- **Onboarding headline copy updates (D-35):** "Understand your patterns." (Screen 1), "Discover your patterns." (Screen 4).
- **Onboarding safety screen (D-34):** Screen 5 of 6 implemented in `OnboardingView.swift`. `pageCount` updated to 6.
- **Medication section clinical disclaimer (D-39):** Added to `MedicationSection.swift`.
- **Insights triggers correlational disclaimer (D-40):** Added to `InsightsView.swift` triggers card.
- **Insights episode count trust signal (D-41):** "Based on your N logged episodes" caption added to full Insights scroll view.
- **Streak card icon updated (D-42):** `bolt.fill` → `circle.dotted.and.circle` in `HomeView.swift`.
- **Icon container system (D-37):** `RoundedRectangle` containers with `opacity(0.12)` fill applied across onboarding feature rows, stat cards, and onboarding locked state.
- **Tab bar appearance (D-43):** `configureWithTransparentBackground()` + explicit card-surface background + `auraeTextSecondary` unselected items in `ContentView.swift`.
- **VoiceOver accessibility improvements (D-44):** `RetroStarRating`, `RetroIntensityScale` per-item labels. Medication effectiveness label updated.
- **`RetroIntensityScale` component extraction (D-45):** Extracted from `LifestyleSection`. Display name input fix. Unselected star color fix.
- **DM Serif Display restored for onboarding headlines (D-38):** `Typography.swift` updated. `fraunces()` / `dmSerifDisplay()` at ≥26pt returns `Font.custom("DMSerifDisplay-Regular", ...)`.
- **Profile footer:** Version string replaced with `AuraeLogoLockup` + brand statement "Your patterns, privately yours." + subtle v1.0.0 in `ContentView.swift`.
- **Onboarding WelcomePage subtitle:** Clinical claim removed. Subtitle updated to "Track what happens before, during, and after each headache — and find patterns that may be unique to you."
- **Insights locked state body copy:** "triggers" as stated fact removed → "associations you may not have noticed on your own."
- **Home empty state copy updates:** Recent Activity → "Your history will appear here as you log." Quick Insights → "Log 5 or more episodes to start seeing your patterns."
- **When to Seek Medical Care — Profile entry point:** "When to Seek Medical Care" row added to Profile > Support section, opening `MedicalEscalationView`.

---

## 16. Appendix — Competitive Landscape

| App | Strengths | Weaknesses vs Aurae |
|---|---|---|
| Migraine Buddy | Large user base, detailed logging | Dated design, complex UX, no AI insights |
| Headache Log | Simple, fast | No auto-capture, no insights, minimal design |
| Bearable | Broad symptom tracking | Not headache-specific, overwhelming for new users |
| **Aurae** | Auto-capture + on-device pattern analysis + premium design + clinical PDF | New entrant — needs to build trust and data volume |

---

## 17. App Store Metadata

*Locked 2026-02-26. Source: PM review of brand direction (senior-product-manager agent ad518f4) and brand identity spec (ios-health-brand-designer agent a83dcd0), with clinical advisor modifications (ios-migraine-clinical-advisor agent a08495c).*

### Category
**Health & Fitness** (not Medical). Rationale: Aurae makes no diagnostic or treatment claims; Medical category invites regulatory scrutiny and slower review. Competitors (Migraine Buddy, Bearable) operate in Health & Fitness, where target search traffic lives.

### App Name
Aurae

### Subtitle (30 chars max)
`Migraine & headache tracker`
*(28 chars. Contains highest-volume search terms. "Tracker" is functional and makes no clinical claim.)*

### Description — Opening (first 255 chars, indexed by App Store)
"Aurae captures what happens in the hours before and during a headache or migraine — sleep, weather, and what you notice about how you feel — and surfaces patterns that may be unique to you. There are no accounts. All of your data stays on your device, private by design, available whenever you need it for a conversation with your care team."

*Clinical constraints: No "triggers," "prevent," "diagnose," "cure," "AI-powered," "clinically proven," or outcome promises. "Migraine" added to sentence one for ASO indexing (clinical advisor confirmed no additional claim risk).*

### Keywords (100 chars — to be finalized before submission)
`migraine,headache,tracker,diary,journal,log,trigger,pattern,sleep,weather,health,pain,aura`
*(94 chars. Do not include words already in the app name or subtitle — Apple deduplicates.)*

### Age Rating
4+ (no objectionable content)

### Privacy Nutrition Label (required)
- Data Not Collected (all data is on-device, no analytics, no crash reporting in production)
- Confirm with engineering before submission that no third-party SDKs collect identifiers

---

## 18. Brand Identity

*Established at v1.7 (27 Feb 2026) following brand designer + design director sessions. Expanded at v1.8 (28 Feb 2026) with `auraeTextCaption` token (Section 18.6) and Profile/Settings consolidation (Section 18.7).*

### 18.1 Brand Mark — AuraeLogoMark

The Aurae brand mark is a set of three concentric ellipses rendered in the brand mark gradient, evoking an aura halo. It is implemented as `AuraeLogoMark` in `/Aurae/DesignSystem/Components/AuraeLogoMark.swift`.

**Visual anatomy:**
- Three concentric ellipses (rings) centered on a common origin
- Outer ring: full `markSize` frame, `auraeMarkGradient` fill, 14% opacity
- Middle ring: 71% of `markSize`, `auraeMarkGradient` fill, 35% opacity
- Inner ellipse: 41% of `markSize`, `auraeMarkGradient` fill, 100% opacity
- The layered opacity creates a natural radial luminosity — lightest at the perimeter, most vivid at the center

**Gradient:** `auraeMarkGradient` — `#2D7D7D` (original brand teal) → `#B3A8D9` (violet), top-leading to bottom-trailing. This gradient is **distinct from `auraePrimaryGradient`** (the functional blue gradient) and must not be substituted.

**Ring count:** At sizes below 40pt, use `ringCount: 2` to drop the faint outer ring, which becomes visually indistinct at small sizes.

**Component API:**
```swift
AuraeLogoMark(markSize: 68)                   // Full mark, 3 rings
AuraeLogoMark(markSize: 52, opacity: 0.70)    // Locked/dimmed state
AuraeLogoMark(markSize: 32, ringCount: 2)     // Small contexts
AuraeLogoMark(markSize: 32, opacity: 0.18)    // Ghost watermark
```

**Accessibility:** `AuraeLogoMark` is always `accessibilityHidden(true)` — it is purely decorative. When used in a lockup, the surrounding `AuraeLogoLockup` provides the "Aurae" accessibility label.

### 18.2 Wordmark & Lockup — AuraeLogoLockup

The Aurae wordmark is the text "aurae" — intentionally all lowercase. This casing choice is deliberate brand voice: lowercase signals calm, approachable confidence, not a typographic error. It is rendered in DM Sans SemiBold.

**`AuraeLogoLockup`** is a horizontal lockup combining the brand mark and wordmark:
- `AuraeLogoMark` on the left
- "aurae" text in `Font.system(size: wordmarkSize, weight: .semibold)` on the right
- 8pt default horizontal gap between mark and wordmark
- VoiceOver accessibility: the entire lockup reads as "Aurae" via `.accessibilityLabel("Aurae")` on the combined element

**Do not use uppercase "AURAE" in the wordmark.** All-caps is reserved for acronym contexts only. The canonical form is always "aurae" (all lowercase).

**Standard usage sizes:**
| Context | Mark size | Wordmark size | Ring count |
|---|---|---|---|
| Onboarding welcome hero | 68pt | 26pt | 3 |
| Profile / settings footer | 24pt | 13pt | 2 |
| PDF export header | 40pt | 17pt | 2 |

### 18.3 Icon Container System

All icon badge containers in the app use a consistent visual system. This is enforced throughout `OnboardingView.swift`, `HomeView.swift`, `InsightsView.swift`, and all retrospective section views.

**Rules:**
- **Shape:** `RoundedRectangle(cornerRadius: 12, style: .continuous)` — never `Circle`
- **Fill:** Icon's semantic color at `opacity(0.12)` — creates a subtle tinted surface
- **Symbol weight:** `.medium` for all SF Symbols inside containers
- **Standard sizes:** 44×44pt (primary rows, minimum tap target); 36×36pt (compact contexts); 40×40pt (mid-density)
- **Accessibility:** Icon badge containers are always `accessibilityHidden(true)` — the surrounding text carries semantic meaning

Any `Circle` fill remaining in the codebase for icon badge purposes is a migration target and should be updated to `RoundedRectangle` in the next design pass.

### 18.4 Copy Language Guardrails

These rules apply to all user-facing copy. Any new onboarding, Insights, paywall, or marketing copy must be reviewed against this list before shipping.

**Forbidden words and phrases** (as causal or definitive claims):

| Forbidden | Why | Approved alternative |
|---|---|---|
| "your triggers" / "find your triggers" | Implies causal relationship the algorithm cannot establish | "your patterns" / "patterns in your data" |
| "triggers" as a noun claim (e.g. "coffee is a trigger") | Same as above | "coffee frequently precedes your headaches" |
| "diagnose" | Regulatory and liability risk | "track," "log," "understand" |
| "cure" / "eliminate" / "fix" / "solve" | Outcome claim | "manage," "support," "understand" |
| "prevent" | Clinical claim | "track," "notice patterns" |
| "proven" / "clinically proven" | Requires RCT evidence | (no substitute — reframe the value prop) |
| "AI-powered" | Technically inaccurate — Aurae uses co-occurrence algorithms | "on-device pattern analysis" |

**Approved language patterns:**
- "may be associated with" — for pattern findings
- "patterns you've noticed" — for user-framed insights
- "your data shows" — for factual data display
- "worth discussing with your care team" — for clinical suggestions
- "associations you may not have noticed on your own" — for locked Insights value prop

**Onboarding copy compliance (v1.7):**
- Screen 1 headline: "Understand your patterns." (not "Understand your headaches." — the latter was clinically neutral but the new version is stronger)
- Screen 1 subtitle: "Track what happens before, during, and after each headache — and find patterns that may be unique to you."
- Screen 4 headline: "Discover your patterns." (not "Discover your triggers.")
- Insights locked state: "associations you may not have noticed on your own" (not "triggers")

### 18.5 Brand Gradient vs. Functional Gradient

Aurae maintains two distinct gradient tokens with separate semantic roles. Mixing them is a brand integrity violation.

| Token | Colors | Role | Where used |
|---|---|---|---|
| `auraeMarkGradient` | `#2D7D7D` → `#B3A8D9` | Brand identity | `AuraeLogoMark`, deliberate brand moments |
| `auraePrimaryGradient` | `#8AC4C1` → `#B6A6CA` | Premium/upgrade UI | Paywall hero, premium badge, upgrade CTA |

The brand mark gradient uses the original Aurae teal (#2D7D7D) — a deeper, more saturated teal than the functional UI teal. The intentional distinction between these gradients should be preserved across all design iterations.

### 18.6 Semantic Color Token — `auraeTextCaption`

*Introduced at v1.8 (28 Feb 2026) by the Design System Expert. Commits `950dd66`, `be33c9e`.*

#### Token Specification

| Mode | Hex | Notes |
|---|---|---|
| Light | `#6B7280` | Identical to `auraeMidGray` light value — zero visual change in light mode at introduction |
| Dark | `#9CAEBE` | Elevated from `auraeMidGray` dark value — improves WCAG AA compliance on Dark Matter surfaces |

#### Governance Rule

`auraeTextCaption` and `auraeMidGray` are now distinct tokens with distinct semantic roles. They must not be used interchangeably.

| Token | Use | Must NOT be used for |
|---|---|---|
| `auraeTextCaption` | All caption and metadata text that a user must be able to read — timestamps, disclaimers, metadata labels, section subtitles, empty state copy | Decorative icons, chart fills, opacity-modified de-emphasis layers |
| `auraeMidGray` | Decorative icons, chart fill colors, opacity-modified de-emphasis only (e.g. `auraeMidGray.opacity(0.4)` for ghosted elements) | Any text the user is expected to read |

The rationale: on Dark Matter surfaces, `auraeMidGray` dark does not achieve WCAG AA contrast for readable text. `auraeTextCaption` was introduced to provide an accessible caption color without altering the decorative token. In light mode both tokens currently resolve to the same hex — this equivalence may diverge in future palette iterations, so the governance rule must be applied now to prevent future regressions.

#### Migrated Call Sites (v1.8)

37 call sites migrated from `auraeMidGray` to `auraeTextCaption` across the following files:

- `HistoryView.swift`
- `RetrospectiveView.swift`
- `OnboardingView.swift`
- `ExportView.swift`
- `LogConfirmationView.swift`
- `LifestyleSection.swift`
- `MedicationSection.swift`
- `EnvironmentSection.swift`
- `MedicalEscalationView.swift`
- `CalendarView.swift`
- `LogDetailView.swift` (first-pass, earlier session)
- `InsightsView.swift` (first-pass, earlier session)

Any new caption or metadata text added to these or other files must use `auraeTextCaption`, not `auraeMidGray`.

### 18.7 Profile / Settings Consolidation

*Implemented at v1.8 (28 Feb 2026), commit `f3ef8e3`.*

`SettingsView.swift` has been deleted. All settings content is now consolidated into `ProfileView` within `ContentView.swift`. The gear icon and settings sheet previously present on `HomeView` have been removed.

**ProfileView section structure (four sections):**

| Section | Contents |
|---|---|
| PREFERENCES | Notification delay (30 min / 1 hr / 2 hrs), unit preferences (°C/°F) |
| SUBSCRIPTION | Subscription status, manage subscription, upgrade CTA for free users |
| DATA | Export data (CSV/JSON, premium), delete all data |
| SUPPORT | Help & FAQ (email link), When to Seek Medical Care (opens `MedicalEscalationView`), privacy policy |

**Rationale:** A dedicated Settings tab was disproportionate to the settings surface area for a V1 app with no account infrastructure. Embedding settings within the Profile view follows established iOS patterns (Health, Strava, Headspace) and reduces tab bar complexity. The gear icon on HomeView was a navigation inconsistency — settings are now reached via a single canonical path (Profile tab).

**"Patterns Found" stat removed:** The stat previously shown in the Profile header has been removed. It was derived from pattern-analysis data only available on the premium tier, making it misleading or empty for free users and adding clutter for premium users who can view the same information on the Insights tab.

---

*Document prepared for internal product and engineering review. All specifications subject to iteration based on user research and technical feasibility assessments.*
