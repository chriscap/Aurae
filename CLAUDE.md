# Aurae — Claude Code Project Instructions

> This file is the source of truth for Claude Code when working on the Aurae iOS app.
> Read this file at the start of every session before writing any code.

---

## What is Aurae?

Aurae is an iOS app that helps headache and migraine sufferers log, understand, and manage their condition. It automatically captures weather, Apple Health, and sleep data at the moment of headache onset, then uses AI-powered pattern analysis to surface personal triggers.

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
    │   ├── Fraunces_72pt-Regular.ttf
    │   ├── Fraunces_72pt-Bold.ttf
    │   ├── PlusJakartaSans-Regular.ttf
    │   └── PlusJakartaSans-SemiBold.ttf
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
// Fraunces — headings and display
// Plus Jakarta Sans — body, labels, UI

extension Font {
    static func fraunces(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(weight == .bold ? "Fraunces72pt-Bold" : "Fraunces72pt-Regular", size: size)
    }
    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(weight == .semibold ? "PlusJakartaSans-SemiBold" : "PlusJakartaSans-Regular", size: size)
    }

    // Semantic scale
    static let auraeDisplay  = Font.fraunces(48, weight: .bold)   // Home screen hero
    static let auraeH1       = Font.fraunces(32, weight: .bold)   // Section titles
    static let auraeH2       = Font.fraunces(22)                   // Subsections
    static let auraeBody     = Font.jakarta(16)                    // Reading copy
    static let auraeLabel    = Font.jakarta(13, weight: .semibold) // Labels
    static let auraeCaption  = Font.jakarta(12)                    // Metadata
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
- [ ] 16. Full PDF export (premium)
- [ ] 17. Settings screen
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

- [ ] Weather API: Open-Meteo vs WeatherKit — confirm before building WeatherService
- [ ] Should headache type taxonomy (tension / migraine / cluster) be included in V1 retrospective?
- [ ] Minimum log count before Insights tab activates (suggested: 5)
- [ ] PDF export: Aurae-branded or neutral clinical document style?
- [ ] Apple Watch logging: V1 or Phase 2?

---

*Keep this file updated as decisions are made. When an open question is resolved, move it to a `## Decisions Log` section at the bottom of this file.*
