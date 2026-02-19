# Aurae
## Headache Tracker & Trigger Intelligence
### Product Requirements Document

| | |
|---|---|
| **Document Type** | Product Requirements Document (PRD) |
| **Version** | 1.1 — In Development |
| **Date** | February 2026 |
| **Platform** | iOS (iPhone-first) |
| **Stage** | In Development |
| **Monetization** | Freemium |

---

## 1. Executive Summary

Aurae is an iOS application that helps headache and migraine sufferers understand, track, and manage their condition through intelligent contextual logging. Unlike basic headache diaries that depend on manual recall, Aurae automatically captures environmental and physiological data at the moment of onset — then connects the dots across time to reveal personal trigger patterns.

The app targets a broad audience ranging from casual headache sufferers to chronic migraine patients. A freemium model makes core logging free and accessible while unlocking AI-powered insights, advanced analytics, and clinical export tools for premium subscribers.

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
- Surface trigger patterns and trends through AI-powered analysis (paid tier).
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
- A **severity selector**: five distinct tap targets (Mild / Moderate / Severe / Very Severe / Worst). The control should feel tactile, not clinical.
- A subtle ambient summary of recent activity — e.g. "Last headache: 4 days ago" or a soft 7-day calendar strip.
- Minimal bottom tab bar with icon + label — Home, History, Insights, Profile.

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
- Temperature, humidity, barometric pressure & trend (rising/falling), UV index, AQI, and general conditions.
- Location is used only to query weather — not stored or shared.
- Weather is sourced from **OpenWeatherMap** (Current Weather, UV Index, and Air Pollution endpoints). Requires an API key. The free tier covers all anticipated usage.
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

#### Food & Drink
- Recent meals (free text or trigger shortcuts: aged cheese, processed meat, MSG, citrus, chocolate), alcohol, caffeine, hydration, and skipped meals.

#### Lifestyle Factors
- Sleep quality (manual 1–5 if not auto-filled), sleep hours, stress level (1–5 scale), and screen time.

#### Medication
- Medication taken (searchable list + free text), dose, timing, and effectiveness rating (1–5).
- Medication overuse warning: a gentle, non-alarmist prompt if acute medication is logged more than 10 days in a month.

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

### 5.5 AI-Powered Trigger Insights (Premium)

After logging a minimum of 5 headaches, the app begins surfacing pattern analysis:

- **Top suspected triggers** — ranked by co-occurrence frequency (e.g. "You had a headache within 24hrs of poor sleep in 7 of your last 9 episodes").
- **Weather correlation** — does barometric pressure drop or humidity spike precede your headaches?
- **Cycle correlation** — pattern detection around menstrual cycle phase.
- **Medication effectiveness trends** — what worked, and how quickly?
- Weekly and monthly frequency charts with trend lines.

Insights are presented in plain, empathetic language — not medical diagnoses. No raw health data is sent to third-party AI services without explicit opt-in consent.

### 5.6 PDF Export for Healthcare Providers

Users can generate a structured, print-ready PDF report suitable for sharing with a neurologist, GP, or headache clinic.

#### Free Tier
- Summary table: date, time, duration, severity. Selectable date range and basic medication log.

#### Premium Tier
- All free content plus full contextual data per headache (weather, sleep, lifestyle, food, symptoms).
- Trigger pattern summary page with top suspected triggers.
- Charts: frequency over time, severity distribution, medication effectiveness, and menstrual cycle overlay.
- Clean, professional layout designed to be taken to a clinic appointment. All generation happens on-device.

---

## 6. Design System & Visual Language

Aurae's design must be simultaneously striking and gentle. Users are often in pain — the interface should never feel harsh, cluttered, or anxiety-inducing. Visual references: Robinhood (confident data typography), Strava (bold + clean dashboard), Lumy (soft palette, delightful interactions), Tiimo (calm, accessible), Headspace (approachable wellness), (Not Boring) Weather (playful but refined ambient UI).

### 6.1 Color Palette

| Role | Hex | Usage |
|---|---|---|
| Deep Navy | `#0D1B2A` | Primary text, headings, key actions |
| Soft Teal | `#2D7D7D` | Brand accent, CTA buttons, highlights |
| Fog White | `#F5F6F8` | Background, card surfaces |
| Mist Lavender | `#EEF0F8` | Secondary surfaces, selected states |
| Storm Gray | `#6B7280` | Secondary text, labels, metadata |
| Pale Blush | `#FDF0EE` | Severity High — warm, non-aggressive alert |
| Sage Green | `#D1EAD4` | Severity Low — calm, positive state |

Dark Mode is a first-class requirement. The palette inverts gracefully — Fog White becomes `#0A0F14`, Deep Navy becomes near-white, and Teal remains the constant brand anchor. Reduce Motion and Increase Contrast accessibility settings must be honoured.

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

The home screen is intentionally sparse, from top to bottom:

1. **Greeting / date strip** — e.g. "Good morning. Tuesday, 18 Feb." Set in Plus Jakarta Sans, Storm Gray.
2. **Recent activity indicator** — soft pill badge: "Last headache: 3 days ago" or a mini 7-day dot calendar.
3. **Log Headache button** — large hero CTA. Teal fill, white Fraunces label, generous tap target.
4. **Severity selector** — five rounded pill buttons or a smooth labelled slider. Must be operable one-handed.
5. **Bottom tab bar** — Home, History, Insights, Profile. Icon + Jakarta label.

No carousels. No banners. No notifications on the home screen. Just the action.

### 6.5 Accessibility

- WCAG 2.1 AA minimum contrast across all text and interactive elements.
- Dynamic Type and VoiceOver support across all screens.
- All interactive elements minimum 44×44pt tap targets.
- No information conveyed by colour alone — always paired with icon or label.
- Reduce Motion: disable parallax and auto-playing transitions.

---

## 7. Monetization — Freemium Model

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
| AI trigger pattern analysis | — | ✓ |
| Full contextual PDF export | — | ✓ |
| Charts & trend visualisations | — | ✓ |
| Medication effectiveness tracking | — | ✓ |
| Menstrual cycle correlation | — | ✓ |
| Weather correlation insights | — | ✓ |
| Custom report builder (clinics) | — | ✓ |
| Data export (CSV / JSON) | — | ✓ |

### 7.1 Pricing

- **Monthly:** $4.99 / month
- **Annual:** $34.99 / year (~$2.92/month, 42% saving)
- **Free trial:** 14 days of Premium, no credit card required

---

## 8. Technical Requirements

### 8.1 Platform

- iOS 17+ target, iOS 16 minimum. iPhone optimised; iPad as stretch goal post-launch.
- Native Swift / SwiftUI preferred for performance and Health framework access.

### 8.2 Integrations

| Integration | Purpose | Notes |
|---|---|---|
| Apple HealthKit | Sleep, HR, HRV, SpO2, cycle | Explicit user permission per data type. Permission denied handled silently with nil. |
| OpenWeatherMap | Temp, humidity, pressure, UV index, AQI | Current Weather + UV Index + Air Pollution endpoints. Requires API key. Free tier sufficient. |
| CoreLocation | Location at onset for weather | When-in-use only. Not stored. |
| PDFKit / renderer | PDF report generation | On-device — no server round-trip |
| RevenueCat / StoreKit 2 | Subscription management | RevenueCat recommended for analytics |
| Oura / Garmin / Fitbit | Sleep data fallback | Phase 2 — via HealthKit relay or OAuth |

### 8.3 Data & Privacy

- All health data stored on-device or in the user's private iCloud container (CloudKit). Never on Aurae servers.
- No raw health data sent to third-party AI services without explicit, granular consent.
- Pattern analysis runs on-device where possible (Core ML).
- GDPR and HIPAA compliance posture — a trust and brand decision even where not legally required.
- One-tap data deletion from within the app.

---

## 9. Key User Flows

### 9.1 First Launch & Onboarding

1. Welcome screen — app name, one-line value prop, CTA: "Get Started".
2. Optional quick questionnaire — headache frequency, existing diagnosis.
3. Home screen — ready to log. First-time tooltip on the Log button.

**Permission philosophy:** HealthKit, Location, and Notifications are all requested on the user's first log attempt — never on launch. Each permission prompt is preceded by an in-app explanation of why it is needed. The app is fully functional with all three permissions denied; all health and weather fields degrade gracefully to nil or manual entry.

### 9.2 Logging a Headache (Core Flow)

1. User opens app. Home screen visible.
2. User selects severity (optional — defaults to Moderate).
3. User taps "Log Headache". System prompts for permissions if this is the first log attempt. Haptic feedback. Auto-capture fires in background.
4. Confirmation: "Logged at 2:34 PM. Stay hydrated." with a calm animation.
5. Home screen transitions to active headache state — elapsed duration banner visible, "Mark as Resolved" CTA replaces the Log button.
6. Follow-up notification scheduled: "How's your headache? Tap to update." Delay is configurable in Settings: 30 minutes, 1 hour (default), or 2 hours.
7. User taps "Mark as Resolved". Active headache state clears. Notification cancelled automatically.
8. App prompts retrospective entry.
9. Retrospective completed (or skipped). Log is sealed.

### 9.3 Generating a PDF Report

1. User navigates to History or Profile > Export Report.
2. Selects date range and data to include.
3. Premium: selects report depth (summary vs. full clinical).
4. Taps "Generate Report" — PDF rendered on-device in < 3 seconds.
5. Share sheet: AirDrop, Mail, Save to Files, Print.

---

## 10. Out of Scope for V1

- Android version
- Web dashboard or companion app
- Direct EHR / medical record integration
- Community or social features
- In-app telemedicine or doctor referral
- Custom medication database or drug interaction checking
- Apple Watch native app (Phase 2)
- Multi-user / family accounts

---

## 11. Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| HealthKit permissions denied | High | All health data optional. App fully functional without it. |
| Weather API downtime | Medium | Cache last-known weather. Fallback to manual entry. |
| Low free→premium conversion | Medium | Ensure free tier is genuinely valuable. Test paywall placement. |
| Medical liability | Medium | Clear in-app disclaimers. Tracking tool, not diagnostic. Legal review. |
| Drop-off after first log | High | Strong retrospective UX. "First Insight" after 3 entries. |
| Privacy concerns | Medium | On-device storage. Transparent permissions. Privacy-first marketing. |

---

## 12. Open Questions

- Will trigger analysis run fully on-device (Core ML) or involve a server component?
- Should the app include a headache type taxonomy (tension, migraine, cluster, sinus) in V1 retrospective?
- What is the minimum viable data set for the AI to surface a meaningful first insight? (Working assumption: 5 logged headaches.)
- Should the PDF export be Aurae-branded or a neutral clinical document style?

---

## 13. Decision Log

Decisions made during development that closed previously open questions or established constraints with product-level implications. Logged in the order resolved.

| # | Decision | Rationale | Date |
|---|---|---|---|
| D-01 | **Weather provider: OpenWeatherMap** (Current Weather, UV Index, Air Pollution endpoints). Replaces Open-Meteo. Requires API key. | OpenWeatherMap provides AQI via the Air Pollution endpoint and UV Index as a separate endpoint, covering all required data fields. Free tier covers all anticipated usage. Open-Meteo was deprioritised due to AQI coverage gaps. | Feb 2026 |
| D-02 | **Apple Watch logging: Phase 2.** Not included in V1. | Scope control. V1 priority is the core iPhone logging loop. Watch support adds significant surface area without validating the core product hypothesis. | Feb 2026 |
| D-03 | **Pressure trend is a single-point heuristic in V1.** Rising/falling/stable is derived from the current reading, not a rolling window. | Building a true rolling trend requires time-series storage and a secondary API call cadence. This complexity is not justified for V1. Limitation is documented; a true trend can be added in a later release. | Feb 2026 |
| D-04 | **Sleep capture window: 10 PM (previous day) → 10 AM (current day).** | Matches Apple Health's own sleep window convention, ensuring consistency with Health app data and reducing edge-case mismatches for users who sleep late. | Feb 2026 |
| D-05 | **SpO2 stored as 0–100%.** | Display-friendly format. Avoids floating-point fraction storage and simplifies UI rendering. Consistent with how HealthKit surfaces the value to users. | Feb 2026 |
| D-06 | **HealthKit read-denial is silent by design.** All HealthKit fields degrade to nil when permission is denied. No error shown to the user. | Apple's privacy policy prevents the app from detecting whether a denial is a true denial or simply no data. Surfacing an error would be misleading. Nil fields are handled gracefully throughout the app. | Feb 2026 |
| D-07 | **Follow-up notification delay: configurable at 30 min / 1 hr / 2 hrs via Settings.** Default is 1 hour. | 1 hour is a reasonable default for most headaches, but sufferers with rapid-onset resolution or long-duration episodes need flexibility. Three fixed options reduce decision fatigue without requiring a freeform picker. | Feb 2026 |
| D-08 | **Active headache state machine on home screen.** While a headache is active, the Log button and severity selector are replaced by an elapsed duration banner and "Mark as Resolved" CTA. | Prevents duplicate logging. Makes the ongoing state explicit. Ensures the user knows a headache is being tracked without needing to navigate to History. | Feb 2026 |
| D-09 | **Permission requests deferred to first log attempt.** HealthKit, Location, and Notifications are not requested on launch. | Requesting permissions before demonstrating value reduces grant rates and creates a negative first impression. Requesting at the moment of need — with inline explanation — produces higher acceptance and clearer context. | Feb 2026 |
| D-10 | **Gated features always visible in locked state.** Premium features are never hidden from free users. | Hiding features removes discoverability and weakens the upgrade value proposition. Showing locked states with upgrade prompts communicates premium value and supports conversion. | Feb 2026 |

---

## 14. Appendix — Competitive Landscape

| App | Strengths | Weaknesses vs Aurae |
|---|---|---|
| Migraine Buddy | Large user base, detailed logging | Dated design, complex UX, no AI insights |
| Headache Log | Simple, fast | No auto-capture, no insights, minimal design |
| Bearable | Broad symptom tracking | Not headache-specific, overwhelming for new users |
| **Aurae** | Auto-capture + AI + premium design + clinical PDF | New entrant — needs to build trust and data volume |

---

*Document prepared for internal product and engineering review. All specifications subject to iteration based on user research and technical feasibility assessments.*
