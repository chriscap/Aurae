# Aurae — Claude Code Project Instructions

> This file is the source of truth for Claude Code when working on the Aurae iOS app.
> Read this file at the start of every session before writing any code.

---

## What is Aurae?

Aurae is an iOS app that helps headache and migraine sufferers log, understand, and manage their condition. It automatically captures weather, Apple Health, and sleep data at the moment of headache onset, then uses on-device pattern analysis to surface personal triggers.

The full PRD is in `Aurae_PRD.md`. Always refer to it for feature detail, design specs, and scope decisions.

---

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI (no UIKit unless absolutely necessary)
- **Minimum iOS:** 16.0 (target: iOS 17)
- **Data:** SwiftData (preferred over CoreData)
- **Subscriptions:** RevenueCat + StoreKit 2
- **Weather:** Open-Meteo API (free, no key required)
- **Health:** HealthKit
- **Location:** CoreLocation (when-in-use only)
- **PDF:** PDFKit (on-device, no server)
- **Architecture:** MVVM

---

## Project Structure

```
Aurae/
├── App/
│   ├── AuraeApp.swift
│   └── ContentView.swift
├── Models/
│   ├── HeadacheLog.swift          # SwiftData model — primary log entry
│   ├── WeatherSnapshot.swift      # Weather at time of onset
│   ├── HealthSnapshot.swift       # HealthKit data at time of onset
│   └── RetrospectiveEntry.swift   # Post-headache detail fields
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── LogViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── InsightsViewModel.swift
│   └── ExportViewModel.swift
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift         # Main screen — log button + severity
│   │   └── LogConfirmationView.swift
│   ├── Retrospective/
│   │   ├── RetrospectiveView.swift
│   │   ├── FoodDrinkSection.swift
│   │   ├── LifestyleSection.swift
│   │   ├── MedicationSection.swift
│   │   └── EnvironmentSection.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   ├── CalendarView.swift
│   │   └── LogDetailView.swift
│   ├── Insights/
│   │   └── InsightsView.swift
│   ├── Export/
│   │   └── ExportView.swift
│   └── Onboarding/
│       └── OnboardingView.swift
├── Services/
│   ├── HealthKitService.swift     # All HealthKit reads
│   ├── WeatherService.swift       # Open-Meteo API calls
│   ├── LocationService.swift      # CoreLocation wrapper
│   ├── NotificationService.swift  # Local notifications
│   ├── PDFExportService.swift     # PDF generation via PDFKit
│   └── InsightsService.swift      # Pattern analysis logic
├── DesignSystem/
│   ├── Colors.swift               # Full palette (see below)
│   ├── Typography.swift           # Font definitions
│   └── Components/
│       ├── SeveritySelector.swift # Reusable severity picker
│       ├── AuraeButton.swift      # Primary CTA button style
│       └── LogCard.swift          # History list card
├── Utilities/
│   └── Extensions.swift
└── Resources/
    ├── Fonts/
    │   ├── DMSerifDisplay-Regular.ttf
    │   ├── DMSans-Regular.ttf
    │   ├── DMSans-Medium.ttf
    │   ├── DMSans-SemiBold.ttf
    │   └── DMSans-Bold.ttf
    └── Info.plist
```

---

## Design System

Always use the design system. Never hardcode colours, fonts, or spacing.

### Colors (`Colors.swift`)

```swift
extension Color {
    static let auraeNavy       = Color(hex: "0D1B2A") // Primary text, headings
    static let auraeSlate      = Color(hex: "1C2B3A") // Secondary headings
    static let auraeTeal       = Color(hex: "2D7D7D") // Brand accent, CTAs
    static let auraeSoftTeal   = Color(hex: "E8F4F4") // Premium highlights
    static let auraeLavender   = Color(hex: "EEF0F8") // Secondary surfaces
    static let auraeMidGray    = Color(hex: "6B7280") // Labels, metadata
    static let auraeBackground = Color(hex: "F5F6F8") // App background
    static let auraeBlush      = Color(hex: "FDF0EE") // Severity high
    static let auraeSage       = Color(hex: "D1EAD4") // Severity low
}
```

### Typography (`Typography.swift`)

```swift
// DM Serif Display — display typeface, 26pt minimum (single-weight serif)
// DM Sans — body, labels, UI, section prompts (Regular / Medium / SemiBold / Bold)
//
// Both from Colophon Foundry for Google — share underlying proportions.
// fraunces() and jakarta() aliases are kept for migration compatibility.
//
// Display serif rule: DM Serif Display ONLY at 26pt+. Its high stroke contrast
// causes thin strokes to vanish at smaller sizes on dark surfaces. Below 26pt,
// use DM Sans weight variants for hierarchy:
//   SemiBold (600) → structural headings    Medium (500) → prompts & secondary labels
//   Regular (400)  → body, captions

extension Font {
    static func dmSerifDisplay(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { ... }
    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { ... }

    // Legacy aliases (forward to DM fonts):
    static func fraunces(...) -> Font  // → dmSerifDisplay
    static func jakarta(...) -> Font   // → dmSans

    // Semantic scale
    static let auraeDisplay        = Font.dmSerifDisplay(44)             // Home screen hero numeral
    static let auraeH1             = Font.dmSans(26, weight: .semibold)  // Section titles
    static let auraeH2             = Font.dmSans(20, weight: .semibold)  // Subsections
    static let auraeSubhead        = Font.dmSans(18, weight: .semibold)  // Date labels, subtitles
    static let auraeSectionLabel   = Font.dmSans(17, weight: .medium)    // Section prompts, questions
    static let auraeSecondaryLabel = Font.dmSans(14, weight: .medium)    // Card sub-headings
    static let auraeBody           = Font.dmSans(16)                     // Reading copy
    static let auraeLabel          = Font.dmSans(13, weight: .semibold)  // Interactive labels
    static let auraeCaption        = Font.dmSans(12)                     // Metadata
}
```

### Layout Constants

```swift
enum Layout {
    static let screenPadding: CGFloat = 20
    static let cardRadius: CGFloat = 18
    static let cardShadowRadius: CGFloat = 8
    static let buttonHeight: CGFloat = 56
    static let minTapTarget: CGFloat = 44
    static let sectionSpacing: CGFloat = 32
}
```

---

## Core Data Model

### HeadacheLog (SwiftData)

```swift
@Model class HeadacheLog {
    var id: UUID
    var onsetTime: Date
    var resolvedTime: Date?
    var severity: Int              // 1–5
    var weather: WeatherSnapshot?
    var health: HealthSnapshot?
    var retrospective: RetrospectiveEntry?
    var isActive: Bool             // true while headache is ongoing
}
```

### WeatherSnapshot

```swift
@Model class WeatherSnapshot {
    var temperature: Double
    var humidity: Double
    var pressure: Double
    var pressureTrend: String      // "rising", "falling", "stable"
    var uvIndex: Double
    var aqi: Int?
    var condition: String          // "clear", "cloudy", "rain", etc.
    var capturedAt: Date
}
```

### RetrospectiveEntry

```swift
@Model class RetrospectiveEntry {
    // Food & drink
    var meals: [String]
    var alcohol: String?
    var caffeineIntake: Int?       // mg
    var hydrationGlasses: Int?
    var skippedMeal: Bool

    // Lifestyle
    var sleepHours: Double?
    var sleepQuality: Int?         // 1–5
    var stressLevel: Int?          // 1–5
    var screenTimeHours: Double?

    // Medication
    var medicationName: String?
    var medicationDose: String?
    var medicationEffectiveness: Int? // 1–5

    // Symptoms
    var symptoms: [String]         // ["nausea", "light_sensitivity", etc.]
    var headacheLocation: String?
    var headacheType: String?

    // Women's health
    var cyclePhase: String?

    // Environment
    var environmentalTriggers: [String]
    var notes: String?
}
```

---

## Key Behaviours & Rules

### Home Screen
- The Log Headache button must be the visual hero of the screen — large, teal, Fraunces label
- Severity selector always visible on home screen (not hidden behind the button)
- Logging must complete auto-capture in the background — never block the UI
- Show a calm confirmation animation after logging, not a modal alert

### Auto-Capture on Log
Always fire all three captures concurrently using `async let`:
```swift
async let weather = WeatherService.capture(location: location)
async let health  = HealthKitService.snapshot()
async let sleep   = HealthKitService.lastNightSleep()
```
Never block logging if any capture fails — store nil and allow manual entry later.

### Permissions
- Request HealthKit permissions on first log attempt, not on launch
- Request location permission on first log attempt, not on launch
- Always explain why each permission is needed before the system prompt appears
- App must be fully functional if all permissions are denied

### Privacy
- Never send raw health data to any external service
- Location is used only for weather lookup — never persisted
- All PDF generation happens on-device via PDFKit

### Notifications
- Schedule a "How's your headache?" notification 1 hour after logging onset
- Make the notification delay configurable in Settings (30 min / 1 hr / 2 hrs)
- Cancel the notification automatically if the user marks the headache as resolved

### Freemium Gating
Gate the following behind RevenueCat entitlement check:
- Insights tab content (show locked state with preview for free users)
- Full contextual PDF export (free users get summary table only)
- Charts and trend visualisations
- CSV / JSON data export

Never hide gated features entirely — always show them in a locked state with a clear upgrade prompt.

---

## API Reference

### Weather — Open-Meteo
No API key required.
```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}
  &longitude={lon}
  &current=temperature_2m,relative_humidity_2m,surface_pressure,uv_index,weather_code
  &hourly=surface_pressure
```

### HealthKit — Key Identifiers
```swift
HKQuantityTypeIdentifier.heartRate
HKQuantityTypeIdentifier.heartRateVariabilitySDNN
HKQuantityTypeIdentifier.oxygenSaturation
HKQuantityTypeIdentifier.stepCount
HKQuantityTypeIdentifier.restingHeartRate
HKCategoryTypeIdentifier.sleepAnalysis
HKCategoryTypeIdentifier.menstrualFlow
```

---

## Build Order

Work through features in this sequence — don't skip ahead:

- [ ] 1. Design system (Colors, Typography, Layout constants)
- [ ] 2. SwiftData models
- [ ] 3. Home screen UI (button + severity selector)
- [ ] 4. HealthKit service (permissions + snapshot)
- [ ] 5. Weather service (Open-Meteo)
- [ ] 6. CoreLocation wrapper
- [ ] 7. Log flow end-to-end (tap → capture → confirm)
- [ ] 8. Local notifications
- [ ] 9. Retrospective entry screen
- [ ] 10. History list + calendar view
- [ ] 11. Log detail view
- [ ] 12. PDF export (free tier)
- [ ] 13. Onboarding flow
- [ ] 14. RevenueCat integration + paywall
- [ ] 15. Insights + pattern analysis (premium)
- [x] 16. Full PDF export (premium)
- [x] 17. Settings screen
- [ ] 18. Accessibility pass (Dynamic Type, VoiceOver, Reduce Motion)
- [ ] 19. Dark mode pass

---

## What's Out of Scope (Do Not Build)

- Android or web version
- Any backend server or user accounts
- Apple Watch app (Phase 2)
- Social or community features
- Drug interaction checking
- Medical diagnosis of any kind

---

## Open Questions (Decide Before Building)

- [ ] Should headache type taxonomy (tension / migraine / cluster) be included in V1 retrospective?
- [ ] PDF export: Aurae-branded or neutral clinical document style?
- [ ] Apple Watch logging: V1 or Phase 2?

---

*Keep this file updated as decisions are made. When an open question is resolved, move it to a `## Decisions Log` section at the bottom of this file.*

---

## Decisions Log

- **Weather API:** Open-Meteo (free, no API key required). WeatherService migrated from OpenWeatherMap to Open-Meteo on 2026-02-20. Single `current` endpoint returns temperature, humidity, pressure, UV index, and WMO weather code. AQI not available via this endpoint (stored as nil). `WeatherSnapshot.condition(fromWMOCode:)` used for condition mapping.

- **Minimum log count for Insights:** 5 logs required before pattern analysis activates. `InsightsService.minimumLogs = 5`.

- **Variable font setup 2026-02-22:** Replaced `Fraunces_72pt-Regular.ttf` + `Fraunces_72pt-Bold.ttf` with single `Fraunces-Variable.ttf` (wght axis: Thin → Black). PostScript names use `Fraunces-9pt{Weight}` pattern. `fraunces()` helper updated to map `Font.Weight` to named instances. New tokens: `auraeSectionLabel` (17pt regular Fraunces) and `auraeSecondaryLabel` (14pt regular Fraunces). `severityPillHeight` reduced from 48 → 36. `AuraeButton` primary fill changed from `auraeSignatureGradient` → flat `Color.auraeTeal`. Brand watermark removed from HomeView.

- **UI designer full polish pass 2026-02-23 (30 issues addressed):**
  - `AuraeButtonStyle.hero` added: 64pt height (`heroButtonHeight`), 24pt radius (`heroButtonRadius`), Fraunces SemiBold 19pt label, `auraeGlowTeal` shadow. Log Headache uses `.hero`; all other CTAs retain `.primary` at 56pt.
  - Severity pills redesigned: fill-based (was border-only). Selected = `severityPillFill(for:)` + `auraeSeverityLabelSelected`. Unselected = `auraeAdaptiveSecondary` + `auraeTextSecondary`. Border removed. `severityPillHeight` raised 36→44.
  - OnsetSpeed pills redesigned: fill-based. Selected = `auraeAdaptiveSoftTeal` + `auraeTealAccessible`. Unselected = `auraeAdaptiveSecondary` + `auraeTextSecondary`. QA-flagged accessibility violations fixed (was using WCAG-failing `auraeTeal` text and `opacity(0.60)` labels). Sublabel: `jakarta(10)` → `jakarta(11, relativeTo: .caption2)`. Divider added between 3-pill row and "Not sure".
  - Active headache banner: background `auraeAdaptiveSecondary` → `auraeAdaptiveBlush`. Left accent bar added (3pt, `severityAccent(for: severity)`). Heading `.auraeLabel` → `.auraeH2`. Severity dot removed (expressed through surface + accent bar).
  - Ambient triptych card: `cornerRadius: 20` → `Layout.cardRadius`. Shadow uses Layout constants. Column labels upgraded to `auraeCaptionEmphasis` + `auraeTextSecondary`. "Days free" column is now dominant (26pt Jakarta, `auraeTeal`). Weather/sleep values 22→20pt.
  - Activity strip: background `auraeNavy.opacity(0.05)` → `auraeAdaptiveSubtle`. `cornerRadius: 12` → `Layout.cardRadius`. Leading severity dot added.
  - Header: greeting `.auraeBody` → `.auraeCaption`. Date `.jakarta(18)` → `.auraeSubhead`. Days-free numeral: removed `.opacity(0.80)`, now uses `.auraeDisplay` token (updated to 64pt).
  - Severity section VStack spacing 12→16pt. Onset speed gap `itemSpacing`→`sectionSpacing`.
  - Background: replaced radial glow with two atmospheric layers: top linear teal wash (0→40% height, 6% opacity) + bottom-trailing violet bloom (auraeSoftViolet, 5% opacity, radius 200pt).
  - New design system tokens: `Layout.heroButtonHeight=64`, `Layout.heroButtonRadius=24`, `Font.auraeSubhead`, `Color.auraeAdaptiveSubtle`, `Color.auraeCtaTeal`. `auraeDisplay` updated to 64pt.

- **Design director polish pass 2026-02-23 (P1–P5):**
  - P1: `InsightCard` title font upgraded from `.auraeCaptionEmphasis` (12pt Jakarta SemiBold) → `.auraeSectionLabel` (17pt Fraunces Regular) for more editorial presence.
  - P2: Primary CTA button fill changed from `auraeTeal (#8AC4C1)` → `auraeCtaTeal (#4A9E9A)`. New token `auraeCtaTeal` added to `Colors.swift`. Dark-ink label (#1C2826) gives 7.4:1 contrast (WCAG AAA).
  - P3: All `Color(.systemBackground)` references in `InsightCard`, `StatCard`, and `mockCard` replaced with `Color.auraeAdaptiveCard` for correct dark-mode rendering.
  - P4: `.tracking(1.2)` added to ambient triptych column labels (SLEEP, DAYS FREE, weather condition) in `HomeView`.
  - P5: `Layout.cardShadowOpacity` raised from `0.07` → `0.10`; `Layout.cardShadowY` reduced from `4` → `3`. Applies app-wide via the shared `Layout` constants.
  - Bonus: Home screen ambient teal glow expanded from `endRadius: 320` → `450` and opacity `0.08` → `0.12` for a warmer, more enveloping brand presence.

- **Dark Matter design direction adopted 2026-02-23:** User expressed preference for a darker, more premium palette. Design director evaluated four directions (Quiet Clinical, Dark Matter, Warm Archive, Signal Depth) and recommended Direction 02 "Dark Matter" (Premium 9, Calm 8). Changes applied:
  - `AuraeApp.swift`: `.preferredColorScheme(.dark)` forces dark appearance app-wide regardless of device setting. This is the correct "dark-first" strategy for a premium health app.
  - `Colors.swift`: Five adaptive dark-mode surface values updated to Dark Matter spec. Background: `#0D1426` → `#0D0E11` (pure near-black neutral). Card: `#1A2235` → `#131420`. Secondary (pills): `#1A2240` → `#1B1C2E`. Subtle (strips): `#171B26` → `#111218`. Elevated (sheets): `#1F2A4A` → `#1E1F32`. Three new tokens: `auraeVioletPrimary (#B3A8D9)`, `auraeAdaptiveHeroFill` (violet dark / teal light), `auraeAdaptiveHeroGlow` (violet glow dark / teal glow light).
  - `Typography.swift`: `auraeDisplay` scaled from 64pt → 44pt for a more restrained, premium hero numeral.
  - `AuraeButton.swift`: Hero button fill uses `auraeAdaptiveHeroFill` (violet in dark, teal in light). Hero bloom shadow uses `auraeAdaptiveHeroGlow`.
  - `HomeView.swift`: Sequential disclosure — onset speed question starts at 25% opacity and fully reveals (with easeInOut 0.4s) after user interacts with severity selector. Onset speed blocks touch input until severity is touched. Background teal wash: 6% → 8% opacity. Violet bloom: 5% → 12% opacity, radius 200 → 260pt. Brand watermark (ghosted 200pt Fraunces "A", 3% opacity) restored to top-right background layer.

- **Build steps 18–19 completed 2026-02-20:**
  - Step 18 (Accessibility pass): `RetroStarRating` outer group now exposes `accessibilityValue`. `HistoryView` empty-state decorative icon marked `accessibilityHidden`. `SleepStatTile` combines value + label into a single VoiceOver element.
  - Step 19 (Dark mode pass): All static `Color.auraeLavender` → `Color.auraeAdaptiveSecondary`, `Color.auraeBackground` → `Color.auraeAdaptiveBackground`, and `Color.auraeSoftTeal` → `Color.auraeAdaptiveSoftTeal` across all view files.

- **Display serif rule adopted 2026-02-24:** DM Serif Display restricted to 26pt+ only. Its high stroke contrast caused thin strokes to vanish at smaller sizes on Dark Matter surfaces, hurting readability for section prompts and labels. Changes:
  - `auraeSectionLabel`: 17pt DM Serif Display → 17pt DM Sans Medium. Affects HomeView severity/onset prompts, InsightCard titles.
  - `auraeSecondaryLabel`: 14pt DM Serif Display → 14pt DM Sans Medium. Affects MedicalEscalationView labels.
  - `AuraeButton.hero` font: 19pt DM Serif Display → 17pt DM Sans SemiBold. Matches `.primary` weight for consistency.
  - InsightsView stat card numerals: 22pt DM Serif Display → 26pt DM Serif Display. Bumped above threshold to keep editorial presence.
  - Onboarding headlines (28–52pt) and `auraeDisplay` (44pt) unchanged — already above threshold.
  - Weight hierarchy below 26pt: SemiBold (600) = structural headings, Medium (500) = prompts/labels, Regular (400) = body/captions.
