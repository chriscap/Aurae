# Aurae
## Headache Tracker & Trigger Intelligence
### Product Requirements Document

| | |
|---|---|
| **Document Type** | Product Requirements Document (PRD) |
| **Version** | 1.6 — In Development |
| **Date** | February 2026 (updated 23 Feb 2026) |
| **Platform** | iOS (iPhone-first) |
| **Stage** | In Development |
| **Monetization** | Freemium |

---

## 1. Executive Summary

Aurae is an iOS application that helps headache and migraine sufferers understand, track, and manage their condition through intelligent contextual logging. Unlike basic headache diaries that depend on manual recall, Aurae automatically captures environmental and physiological data at the moment of onset — then connects the dots across time to reveal personal trigger patterns.

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
- Medication taken (searchable list + free text), dose, timing, and effectiveness rating (1–5).
- Each medication entry includes a classification toggle with two options: **"For headache relief"** (acute) and **"Daily as prescribed"** (preventive). This maps to the `medicationIsAcute: Bool?` field on `RetrospectiveEntry`. The toggle is shown immediately below the medication name field in the Medication section. Default state is unselected (nil). When nil, the entry is conservatively counted toward the acute total unless the medication name matches a known preventive list (implementation detail for engineering).
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

A compact disclaimer is displayed on the Insights tab. It is shown prominently on the user's first visit to Insights and may be dismissed after reading. After dismissal, a condensed single-line version ("Patterns are for informational purposes only — not medical advice.") remains as a persistent footer at the bottom of the Insights tab on every visit.

Full disclaimer text (first-view): "Patterns are based on your logged data only. For informational purposes only. Not a medical diagnosis. Discuss findings with your healthcare provider."

#### First Insights Educational Interstitial

When a user's 5th resolved log triggers the Insights threshold for the first time, an educational interstitial is shown before the Insights tab content is revealed. This screen:

- Explains that patterns take time and improve with more logs
- Explicitly states that these are co-occurrences, not proven causes
- Encourages the user to discuss any patterns with their clinician
- Has a single CTA: "Got it — show my patterns"

This interstitial is shown once only. It is not a paywall — it is an educational gate that sets accurate expectations before the user sees their first pattern analysis.

#### Patterns Computed

- **Top suspected triggers** — ranked by co-occurrence frequency (e.g. "You had a headache within 24 hours of poor sleep in 7 of your last 9 episodes").
- **Weather correlation** — does barometric pressure drop or humidity spike precede your headaches? (Requires 10+ resolved logs.)
- **Day-of-week and time-of-day patterns** — frequency analysis across calendar dimensions.
- **Sleep correlation** — relationship between previous-night sleep duration/quality and headache onset. (Requires 5+ entries per group.)
- **Medication effectiveness trends** — what worked, and how quickly?
- **Streak and frequency trends** — headache-free streaks and rolling frequency over time.
- Weekly and monthly frequency charts with trend lines.

Insights are presented in plain, empathetic language — not medical diagnoses. No health data leaves the device.

> **Build note:** Step 15 complete. Menstrual cycle correlation and cycle overlay chart are listed in the premium feature table but are not yet surfaced in the Insights UI — deferred to a future iteration. The first-insights educational interstitial and Insights disclaimer are required before public release.

### 5.6 PDF Export for Healthcare Providers

Users can generate a structured, print-ready PDF report suitable for sharing with a neurologist, GP, or headache clinic.

#### Free Tier
- Summary table with 7 columns: Date, Time, Severity, Duration, Weather (temperature + condition), Medication, Notes (truncated to 40 characters). Selectable date range. Generated on-device via PDFKit. A4 portrait, Aurae-branded header with teal accent bar, Fraunces title, and "Generated by Aurae" footer.

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

**Dark mode surfaces:** Deep Slate `#1A1D24` (L0) / `#22262F` (L1) / Card Dark `#2A2E39` (L2).

**Accessibility note:** The primary CTA button label is rendered in `auraeSeverityLabelSelected` (`#1C2826`, dark ink) on the `auraeTeal` fill. White text on `#8AC4C1` fails WCAG AA (1.95:1) and must not be used. This is a firm accessibility-first decision — see D-12.

Reduce Motion and Increase Contrast accessibility settings must be honoured throughout.

### 6.2 Typography

Aurae uses two typefaces that together communicate warmth, craft, and legibility:

- **Fraunces** — display and heading typeface. A variable "wonky" serif with optical size axes, inspired by old-style type with a contemporary twist. Used for all H1/H2 headings, the app name, and key display numbers.
- **Plus Jakarta Sans** — body and UI typeface. A geometric sans-serif with strong legibility at small sizes and a friendly, modern personality. Used for all body copy, labels, navigation, table content, and form fields.
- Type scale: Display (48pt+) for home screen hero elements, H1 (32pt) section headings, H2 (22pt) subsections, Body (16pt) reading copy, Caption (13pt) metadata.
- Dynamic Type support — all text must scale with iOS accessibility font sizes.

### 6.3 Layout Principles

- Generous vertical spacing — the app should never feel packed or dense.
- Card-based surfaces with subtle shadow and 16–20px corner radius.
- Bottom-anchored primary actions — the Log Headache button lives in thumb reach.
- Haptic feedback on all key interactions — severity slider, log confirmation, report generation.
- Smooth spring-physics transitions — no abrupt cuts.
- Iconography: line-based, minimal, never cartoonish.

### 6.4 Home Screen Layout

The home screen layers ambient brand presence and personal context beneath a clear logging action. From back to front and top to bottom:

**Background layer (non-interactive, accessibility hidden)**
- A static radial gradient wash in teal-to-clear at 8% opacity originates from the top-center of the screen. Provides ambient brand presence without adding visual noise. In dark mode the effective opacity reduces to approximately 5% due to the darker background surface.
- A large "A" character rendered in Fraunces Bold at 200pt, using the primary text color at 4% opacity, positioned in the top-right corner behind all content. Functions as a brand watermark / background texture.

**Header**
- Left: Greeting and date — e.g. "Good morning. Tuesday, 18 Feb." Set in Plus Jakarta Sans.
- Right: Streak numeral — when the user has been headache-free for 1 or more days, a large Fraunces Bold numeral (64pt) is displayed showing the count with a caption label ("days free" or "day free" for a count of 1). This is the single editorial use of Fraunces on the home screen outside of the brand watermark. When the streak count is 0, a small teal capsule chip reads "Headache-free today" in place of the numeral. When there is no streak data (active headache or no logs recorded), the right side of the header is empty. **Active headache rule:** While a headache is active (`isActive == true`), the streak numeral and chip are both hidden entirely — the right side of the header is empty. Displaying a stale days-free count during an active headache is factually misleading. The `HomeViewModel` must evaluate `isActive` state before computing streak display. Any code that surfaces `daysSinceLastHeadache` while an active headache exists is incorrect behavior (see D-29).

**Ambient context triptych card**
Replaces the former single-row weather card. A 3-column card is shown whenever at least one log exists. The card is always rendered in partial state if data is unavailable for individual columns — it is never hidden entirely due to a single column's data being absent.
- Column 1 — Weather: SF Symbol weather icon, temperature in degrees, condition label (e.g. "Partly cloudy"). Displays "—" for temperature and condition if weather data is nil (e.g., due to API failure or no location permission at time of logging). The weather icon is omitted when condition is nil.
- Column 2 — Sleep: moon icon, hours formatted as "7h 30m", label "SLEEP". Sourced from the most recent log's HealthKit health snapshot. Displays "—" if unavailable.
- Column 3 — Days headache-free: calendar icon, numeric count, label "DAYS FREE". Displays "—" if no resolved logs exist.

**Partial state rationale:** Hiding the entire card when weather is nil would suppress sleep and days-free data that may have loaded successfully. The "--" convention is already established for sleep and days-free columns; it is applied consistently to weather columns when that data is absent (see D-30).

Columns are separated by hairline dividers. The card uses `auraeAdaptiveCard` background with a subtle shadow. The full VoiceOver accessibility label combines all three data points into a single descriptive string, substituting "unavailable" for any "--" value.

**Logging controls**
- **"How are you feeling?"** section label above the severity selector.
- **Severity selector** — three rounded pill buttons: Mild, Moderate, Severe. Pills display the word label only — no numeric index. Must be operable one-handed.
- **Log Headache button** — large hero CTA. `auraeTeal` fill (`#8AC4C1`), dark ink Fraunces label (`auraeSeverityLabelSelected` / `#1C2826`), generous tap target. White text must not be used — it fails WCAG AA on this fill.

**Navigation**
- Bottom tab bar — Home, History, Insights, Export. Icon + Jakarta label. There is no Profile tab in V1.

No carousels. No promotional banners. No notifications surfaced on the home screen. The sole exception to the no-banner rule is the red-flag safety banner (see Section 7.1): when an active headache has red-flag symptoms, a safety banner must appear on the home screen and persist until the headache is resolved. This banner is a patient safety surface — not a notification or promotional element.

### 6.5 Accessibility

- WCAG 2.1 AA minimum contrast across all text and interactive elements.
- Dynamic Type and VoiceOver support across all screens.
- All interactive elements minimum 44×44pt tap targets.
- No information conveyed by colour alone — always paired with icon or label.
- Reduce Motion: disable parallax and auto-playing transitions.

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
- On all subsequent visits: compact footer persists — "Patterns are for informational purposes only — not medical advice."
- Full disclaimer text: "Patterns are based on your logged data only. For informational purposes only. Not a medical diagnosis. Discuss findings with your healthcare provider."

#### First Insights Educational Interstitial
- Triggered once when the user's 5th resolved log is reached and they navigate to Insights for the first time
- Communicates: patterns take time to develop, co-occurrence is not causation, discuss findings with a clinician
- Single CTA: "Got it — show my patterns"
- Shown once; state persisted in UserDefaults

### 7.5 Headache Type Self-Report Disclaimer

The headache type selector in the retrospective entry screen must display a non-dismissible inline note below the selector field:

"Select the type that best matches your experience. Self-reported — not clinically confirmed."

Rendered as a compact caption (`auraeCaption` style) in `auraeMidGray`. This requirement exists because the headache type taxonomy is user-selected and not clinically validated (see D-14).

### 7.6 Food Trigger Shortcut Accuracy

The `foodTriggerShortcuts` list must not present gluten as a universal trigger. The shortcut must be labeled "Gluten (if sensitive)" to make clear that this trigger is relevant only to users with diagnosed celiac disease or confirmed gluten sensitivity.

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

Onboarding is implemented as a 5-screen `TabView` flow with an animated capsule dot indicator. Screens 2–4 include a Skip button. There is no questionnaire or onboarding survey in V1.

1. **Welcome** — brand hero, value proposition, "Get Started" CTA.
2. **Auto-capture** — explains weather and Apple Health auto-capture at onset.
3. **Pattern insights** — preview of the trigger intelligence layer.
4. **Privacy & permissions** — explains what data is collected, how it is used, and why each permission is needed.
5. **Ready** — CTA leading into the main app.

**Permission philosophy:** HealthKit, Location, and Notifications are all requested on the user's first log attempt — never on launch. The Privacy screen (step 4) sets expectations before any system prompt appears. The app is fully functional with all three permissions denied; all health and weather fields degrade gracefully to nil or manual entry.

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
- **P1#3 — Medication overuse warning undefined:** CLOSED. Full spec in Section 5.3 and Section 7.6. See D-32.

### Closed at v1.6 (23 Feb 2026)

- **OQ-02 — Severity 5 onset definition:** CLOSED. Clinical advisor reviewed and approved the onset speed selector spec. `onsetSpeed: OnsetSpeed?` added to `HeadacheLog`. Two-tier trigger: primary urgent banner (`onsetSpeed == .instantaneous` AND `severity >= 4`); secondary advisory notice (`onsetSpeed == .instantaneous` AND `severity < 4`). Onset speed question added to primary logging flow after severity selection. See D-33.

### Remaining Open Questions

- **Step 16 (Premium PDF):** Which additional charts and contextual sections should be included in the full clinical export? Format and section order to be confirmed before build begins. Owner: PM. Target: before Step 16 build begins.
- **Step 17 (Settings):** What is the full settings surface? Confirmed items: notification delay preference, "When to Seek Medical Care" screen accessible from Settings. Pending: data deletion flow, unit preferences (°C/°F), and any account-adjacent actions. Owner: PM. Target: before Step 17 build begins.
- **OQ-01 — Red-flag banner copy (legal review):** Clinical advisor copy for the conditional safety banner and "When to Seek Medical Care" screen (including the new frequent medication use subsection and the two-tier onset-speed banner copy added at v1.6) must be reviewed and approved by legal counsel before V1 release. Owner: PM. Target: before Step 16 build completion.
- **OQ-03 — Preventive medication name list:** Engineering requires a seed list of known preventive medication names to apply the conservative nil-classification fallback in the medication overuse count (Section 7.6). Who owns this list? Suggested approach: PM compiles an initial list from clinical advisor input; list is hardcoded in V1 and editable in a future release. Owner: PM + Clinical Advisor. Target: before red-flag banner and medication overuse warning implementation begins.

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
| D-15 | **PDF export: Aurae-branded format.** A4 portrait with teal accent bar, Fraunces title, and "Generated by Aurae" footer. Professional in tone but clearly Aurae-owned. | A branded export reinforces product identity at the clinic — a high-trust moment with healthcare providers. Neutral clinical styling was considered but rejected as a missed brand-building opportunity. The format reads as professional while still being distinctive. | Feb 2026 |
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
| D-29 | **Streak chip hidden entirely during active headache.** HomeViewModel must not surface `daysSinceLastHeadache` while `isActive == true`. Right side of header is empty. Closes OQ-C. | A frozen or dimmed stale streak count displayed during an active headache is factually misleading. The existing PRD spec (Section 6.4) already stated the header right side is empty during an active headache — this decision closes the implementation gap between the spec and the HomeViewModel behavior. | 23 Feb 2026 |
| D-30 | **Ambient context triptych card shows partial state with "--" for nil weather values. Card is never hidden due to a single column's data being absent.** Closes OQ-D. | Hiding the card entirely when weather data is nil would suppress sleep and days-free data that may have loaded successfully from HealthKit. The "--" convention is already established for sleep and days-free columns. Consistent partial-state rendering is preferable to a card that appears and disappears based on a single data failure. Weather icon is omitted when condition is nil. | 23 Feb 2026 |
| D-31 | **Red-flag banner dismiss state is tracked per log, not as a global boolean.** The current `hasSeenRedFlagBanner` global `@AppStorage` boolean is incorrect and must be replaced with per-log tracking (e.g., `hasAcknowledgedRedFlag: Bool` on `HeadacheLog`, or keyed by log ID). Closes OQ-E. | A global dismiss means a user who has new red-flag symptoms in a future episode will never see the escalation prompt again — a direct patient safety regression. The banner is contextual to a specific symptom combination in a specific log and must reset for each new triggering log. | 23 Feb 2026 |
| D-32 | **Medication overuse awareness warning: acute medications only, 10-day threshold, ungated, inline Insights card.** `medicationIsAcute: Bool?` added to `RetrospectiveEntry`. Classification toggle ("For headache relief" / "Daily as prescribed") added to Medication section. Clinical advisor copy used verbatim. Warning links to "When to Seek Medical Care" screen, which receives a new informational subsection on frequent medication use. Closes OQ-B and P1#3. | Preventive medications must be excluded from the overuse count — a daily topiramate user would receive a false warning every month, a patient safety issue. The clinical advisor confirmed 10 days/month is a defensible threshold for a conservative awareness prompt. The 3-month ICHD-3 duration component is absent in V1 (known limitation, documented). Warning is ungated: a free-tier user at clinical risk of medication overuse must receive the awareness prompt. Risk assessment: Low if acute/preventive distinction is correctly enforced and copy reflects pattern awareness, not diagnosis. | 23 Feb 2026 |
| D-33 | **Onset speed selector added to primary log flow. `onsetSpeed: OnsetSpeed?` field added to `HeadacheLog`. Two-tier red-flag trigger based on onset speed.** Option A (time-to-peak selector) selected over retrospective detection. Clinically approved `OnsetSpeed` enum: `.gradual` / `.moderate` / `.instantaneous`. "Not sure" maps to `nil` (no trigger). Trigger tiers: primary urgent banner (`onsetSpeed == .instantaneous` AND `severity >= 4`) fires on `LogConfirmationView` and persists on `HomeView`; secondary advisory notice (`onsetSpeed == .instantaneous` AND `severity < 4`) fires on `LogConfirmationView` only. Both surfaces link to `MedicalEscalationView` via "Learn more". The word "thunderclap" must not appear in any user-facing copy. Severity alone is not a sufficient trigger — onset speed is the primary clinical signal. Closes OQ-02. | Retrospective detection was rejected because it cannot activate the safety banner at log time — the primary requirement. An in-flow selector captures the signal while it is most accurate and enables the safety function to fire in `LogConfirmationView` at the highest-certainty exposure point. "Not sure" is required for users who were asleep at onset; without it, users would feel forced to guess, degrading data quality and potentially causing false positives. The `.instantaneous` case maps precisely to the ICHD-3 1-minute threshold, giving the trigger clinical defensibility. The two-tier design avoids over-alarming lower-severity users while still providing an advisory notice for any sudden-onset headache regardless of severity. All copy is clinically approved; legal review required before V1 release (OQ-01). | 23 Feb 2026 |

---

## 15. Build Status

Steps are as defined in `CLAUDE.md`. Status as of 22 Feb 2026.

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
| 17 | Settings screen | Not built |
| 18 | Accessibility pass (Dynamic Type, VoiceOver, Reduce Motion) | Complete |
| 19 | Dark mode pass | Complete |

Steps 16 and 17 remain before public release evaluation. The following V1 clinical integrity requirements from the February 2026 clinical review must also be completed before release: red-flag symptom banner (D-18), "When to Seek Medical Care" static screen (D-18), "AI-powered" copy removal (D-19), `InsightsService.swift` threshold and label updates (D-20, D-21), Insights disclaimer and first-view interstitial (D-22, D-27), headache type inline disclaimer (D-24), gluten shortcut relabel (D-25). Step 18 (accessibility) and Step 19 (dark mode) were completed on 20 Feb 2026.

The following additional implementation items were added at v1.5 (23 Feb 2026) and must also be completed before release:
- **Red-flag banner placement correction (D-28):** Banner must appear on LogConfirmationView and HomeView (persistent while active) in addition to InsightsView. Requires updates to `LogConfirmationView.swift`, `HomeView.swift`, and `HomeViewModel.swift`.
- **Per-log red-flag dismiss state (D-31):** Replace `hasSeenRedFlagBanner` global `@AppStorage` boolean with per-log tracking. Requires a model change on `HeadacheLog` or a UserDefaults key-per-log-ID implementation.
- **Streak chip hidden during active headache (D-29):** `HomeViewModel` must gate streak display on `isActive == false`. Bug fix — spec was already correct in PRD Section 6.4.
- **Triptych card partial state for nil weather (D-30):** Confirm `HomeView` renders "--" for nil weather columns rather than hiding the card. Likely a minor view adjustment.
- **`medicationIsAcute: Bool?` field on `RetrospectiveEntry` (D-32):** New SwiftData field required. Classification toggle UI required in `MedicationSection.swift`.
- **Medication overuse warning card in InsightsView (D-32):** New ungated inline card in `InsightsView.swift`. Logic in `InsightsService.swift` or `InsightsViewModel.swift` to compute acute-day count for current month.
- **"When to Seek Medical Care" screen — frequent medication use subsection (D-32):** New informational subsection to be added to the static screen.

The following additional implementation items were added at v1.6 (23 Feb 2026) and must also be completed before release:
- **`onsetSpeed: OnsetSpeed?` field on `HeadacheLog` (D-33):** New optional SwiftData field. Add `OnsetSpeed` enum (`gradual` / `moderate` / `instantaneous`) as a `String`-backed `Codable` enum in `HeadacheLog.swift`. Requires a SwiftData migration.
- **Onset speed question UI in log flow (D-33):** New screen or step added to the log flow in `LogViewModel.swift` and the corresponding view, appearing after severity selection and before log confirmation. Four answer options rendered as tappable choices. "Not sure" maps to `nil`. The question must appear in the primary flow — not in an optional "more details" section.
- **Two-tier red-flag trigger logic (D-33):** Update red-flag evaluation logic (in `LogViewModel.swift` or wherever trigger conditions are evaluated) to replace the prior vague "Severity 5 with sudden onset" condition with: (a) primary urgent banner when `onsetSpeed == .instantaneous && severity >= 4`; (b) secondary advisory notice when `onsetSpeed == .instantaneous && severity < 4`. The aura + visual disturbance trigger is unaffected.
- **Two-tier banner copy in `LogConfirmationView.swift` and `HomeView.swift` (D-33):** Implement primary urgent banner using clinically approved copy (see Section 7.1). Implement secondary advisory notice using clinically approved copy (see Section 7.1). Both must include a "Learn more" action opening `MedicalEscalationView`. Primary banner persists on `HomeView` while headache is active; secondary notice appears in `LogConfirmationView` only and does not persist.

---

## 16. Appendix — Competitive Landscape

| App | Strengths | Weaknesses vs Aurae |
|---|---|---|
| Migraine Buddy | Large user base, detailed logging | Dated design, complex UX, no AI insights |
| Headache Log | Simple, fast | No auto-capture, no insights, minimal design |
| Bearable | Broad symptom tracking | Not headache-specific, overwhelming for new users |
| **Aurae** | Auto-capture + on-device pattern analysis + premium design + clinical PDF | New entrant — needs to build trust and data volume |

---

*Document prepared for internal product and engineering review. All specifications subject to iteration based on user research and technical feasibility assessments.*
