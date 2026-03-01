//
//  LogDetailView.swift
//  Aurae
//
//  Full-detail view for a single HeadacheLog. Pushed onto the NavigationStack
//  from HistoryView (list row tap) and from DayDetailSheet (calendar tap).
//
//  Sections:
//    1. Header — severity circle, onset date/time, duration, resolve button
//    2. At Onset — weather card and health card side-by-side (or stacked on narrow)
//    3. Your Notes — retrospective data grouped by category, or "Add details" CTA
//
//  The view observes the log directly. SwiftData's @Observable semantics mean
//  that mutations to log.isActive, log.retrospective, etc. automatically
//  invalidate the view without any additional wiring.
//

import SwiftUI
import SwiftData

struct LogDetailView: View {

    // -------------------------------------------------------------------------
    // MARK: Dependencies
    // -------------------------------------------------------------------------

    /// The log being displayed. Passed by reference — changes propagate live.
    let log: HeadacheLog

    @Environment(\.modelContext) private var modelContext

    // -------------------------------------------------------------------------
    // MARK: Sheet state
    // -------------------------------------------------------------------------

    @State private var showRetrospective: Bool = false
    @State private var showResolveAlert:  Bool = false

    // -------------------------------------------------------------------------
    // MARK: Navigation title (short date, e.g. "Feb 19")
    // -------------------------------------------------------------------------

    private var navTitle: String {
        log.onsetTime.formatted(.dateTime.month(.abbreviated).day())
    }

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        ZStack {
            Color.auraeAdaptiveBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    headerSection
                    onsetDataSection
                    retrospectiveSection
                    Spacer(minLength: Layout.sectionSpacing)
                }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.top, Layout.itemSpacing)
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRetrospective) {
            RetrospectiveView(log: log, context: modelContext)
        }
        .alert("Mark as resolved?", isPresented: $showResolveAlert) {
            Button("Resolve") {
                log.resolve(at: .now)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your headache will be marked as resolved now, and any scheduled follow-up reminder will be cancelled.")
        }
    }

    // =========================================================================
    // MARK: - Header section
    // =========================================================================

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            HStack(alignment: .center, spacing: Layout.itemSpacing) {
                severityCircle
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedOnsetDate)
                        .font(.auraeH2)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    HStack(spacing: 8) {
                        // Duration / ongoing badge
                        durationBadge

                        // Severity label
                        Text(log.severityLevel.label)
                            .font(.auraeCaption)
                            .foregroundStyle(Color.severityAccent(for: log.severity))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.severitySurface(for: log.severity))
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(headerAccessibilityLabel)

            // Resolve button — only shown while headache is active
            if log.isActive {
                AuraeButton("Mark as Resolved", style: .secondary) {
                    showResolveAlert = true
                }
            }
        }
    }

    private var severityCircle: some View {
        ZStack {
            Circle()
                .fill(Color.severitySurface(for: log.severity))
                .frame(width: 60, height: 60)

            Circle()
                .strokeBorder(Color.severityAccent(for: log.severity), lineWidth: 2)
                .frame(width: 60, height: 60)

            Text(log.severityLevel.label)
                .font(.jakarta(11, weight: .semibold))
                .foregroundStyle(Color.severityAccent(for: log.severity))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
    }

    private var formattedOnsetDate: String {
        // "Wednesday, Feb 19 at 2:34 PM"
        let datePart = log.onsetTime.formatted(.dateTime
            .weekday(.wide)
            .month(.abbreviated)
            .day()
        )
        let timePart = log.onsetTime.formatted(.dateTime.hour().minute())
        return "\(datePart) at \(timePart)"
    }

    private var durationBadge: some View {
        let text: String
        let color: Color
        if log.isActive {
            text  = "Ongoing"
            color = Color.auraeTealAccessible
        } else if let d = log.formattedDuration {
            text  = d
            color = Color.auraeTextCaption
        } else {
            text  = "Duration not recorded"
            color = Color.auraeTextCaption
        }
        return Text(text)
            .font(.auraeCaption)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(log.isActive ? Color.auraeAdaptiveSoftTeal : Color.auraeAdaptiveSecondary)
            .clipShape(Capsule())
    }

    private var headerAccessibilityLabel: String {
        var parts: [String] = [
            "\(log.severityLevel.label) headache",
            formattedOnsetDate
        ]
        if log.isActive {
            parts.append("Ongoing")
        } else if let d = log.formattedDuration {
            parts.append("Duration: \(d)")
        }
        return parts.joined(separator: ". ")
    }

    // =========================================================================
    // MARK: - At Onset section
    // =========================================================================

    private var onsetDataSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            DetailSectionHeader(title: "WHEN IT STARTED")

            if log.weather == nil && log.health == nil {
                noDataPlaceholder
            } else {
                // Stack vertically — both cards need room for their content
                VStack(spacing: Layout.itemSpacing) {
                    if let weather = log.weather {
                        WeatherCard(snapshot: weather)
                    }
                    if let health = log.health {
                        HealthCard(snapshot: health)
                    }
                }
            }
        }
    }

    private var noDataPlaceholder: some View {
        HStack(spacing: 10) {
            // Decorative icon — the text below conveys the full meaning.
            Image(systemName: "cloud.slash")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.auraeMidGray)
                .accessibilityHidden(true)

            Text("Weather and health data was not captured for this entry. This can happen if location or Health access was unavailable at the time.")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextCaption)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    // =========================================================================
    // MARK: - Retrospective section
    // =========================================================================

    private var retrospectiveSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            HStack {
                DetailSectionHeader(title: "YOUR NOTES")
                Spacer()
                // Edit / Add button in the section header row
                Button {
                    showRetrospective = true
                } label: {
                    Text(log.retrospective?.hasAnyData == true ? "Edit notes" : "Add notes")
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeTealAccessible)
                }
                .accessibilityLabel(
                    log.retrospective?.hasAnyData == true
                        ? "Edit retrospective notes"
                        : "Add retrospective notes"
                )
            }

            if let retro = log.retrospective, retro.hasAnyData {
                RetrospectiveReadView(entry: retro)
            } else {
                emptyRetrospective
            }
        }
    }

    private var emptyRetrospective: some View {
        VStack(spacing: Layout.itemSpacing) {
            // Decorative illustration — empty state meaning conveyed by text below.
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.auraeMidGray)
                .accessibilityHidden(true)

            Text("No details added yet")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextCaption)

            // Secondary style so this CTA doesn't compete with the
            // primary "Mark as Resolved" action above. (REC-17)
            AuraeButton("Add notes", style: .secondary) {
                showRetrospective = true
            }
            .accessibilityHint("Opens the retrospective form to add notes about this headache")
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }
}

// =============================================================================
// MARK: - DetailSectionHeader
// =============================================================================

/// Uppercase section label in auraeLabel / auraeTextCaption used throughout
/// the detail view. Matches the design spec for section headers.
struct DetailSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.auraeLabel)
            .foregroundStyle(Color.auraeTextCaption)
            // Slightly expanded tracking makes all-caps section labels more
            // readable without relying on point-size increases. (REC-15)
            .tracking(1.0)
            .accessibilityAddTraits(.isHeader)
    }
}

// =============================================================================
// MARK: - WeatherCard
// =============================================================================

struct WeatherCard: View {

    let snapshot: WeatherSnapshot

    /// Locale-aware temperature formatter. Uses the system locale so US users
    /// see °F automatically; all other locales see °C. (REC-16)
    private static let tempFormatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = .temperatureWithoutUnit
        f.numberFormatter.maximumFractionDigits = 0
        f.unitStyle = .short
        return f
    }()

    private var formattedTemperature: String {
        let celsius = Measurement(value: snapshot.temperature, unit: UnitTemperature.celsius)
        // Convert to the user's preferred temperature unit automatically.
        let locale = Locale.current
        let usesMetric = locale.measurementSystem != .us
        let display = usesMetric
            ? celsius
            : celsius.converted(to: .fahrenheit)
        let unit = usesMetric ? "°C" : "°F"
        let formatted = Self.tempFormatter.string(from: display)
        // MeasurementFormatter with .temperatureWithoutUnit omits the symbol;
        // we append the correct unit label manually.
        return formatted + unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: condition icon + condition label.
            // Icon is decorative — WeatherCard combines all children. (A18-05)
            HStack(spacing: 10) {
                Image(systemName: conditionIcon(snapshot.condition))
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.auraeTeal)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                Text(snapshot.condition
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
                )
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Spacer()

                Text(formattedTemperature)
                    .font(.auraeH2)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
            }

            Divider().overlay(Color.auraeAdaptiveSecondary)

            // Metrics grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 10
            ) {
                WeatherMetricCell(
                    icon:  "humidity",
                    label: "Humidity",
                    value: "\(Int(snapshot.humidity))%"
                )
                WeatherMetricCell(
                    icon:  "gauge.medium",
                    label: "Pressure",
                    value: "\(Int(snapshot.pressure)) hPa \(pressureTrendSymbol)"
                )
                WeatherMetricCell(
                    icon:  "sun.max",
                    label: "UV Index",
                    value: uvLabel(snapshot.uvIndex)
                )
                if let aqi = snapshot.aqi {
                    WeatherMetricCell(
                        icon:  "aqi.medium",
                        label: "Air Quality",
                        value: aqiLabel(aqi)
                    )
                }
            }
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(snapshot.displaySummary)
    }

    // MARK: Helpers

    private var pressureTrendSymbol: String {
        switch snapshot.pressureTrendEnum {
        case .rising:  return "↑"
        case .falling: return "↓"
        case .stable:  return "→"
        }
    }

    private func uvLabel(_ uv: Double) -> String {
        switch uv {
        case ..<3:  return "\(Int(uv)) Low"
        case ..<6:  return "\(Int(uv)) Moderate"
        case ..<8:  return "\(Int(uv)) High"
        case ..<11: return "\(Int(uv)) Very High"
        default:    return "\(Int(uv)) Extreme"
        }
    }

    private func aqiLabel(_ aqi: Int) -> String {
        switch aqi {
        case ..<51:  return "\(aqi) Good"
        case ..<101: return "\(aqi) Moderate"
        case ..<151: return "\(aqi) Unhealthy"
        default:     return "\(aqi) Poor"
        }
    }

    private func conditionIcon(_ condition: String) -> String {
        switch condition.lowercased() {
        case "clear":                           return "sun.max.fill"
        case "partly_cloudy":                   return "cloud.sun.fill"
        case "cloudy", "overcast":              return "cloud.fill"
        case "drizzle":                         return "cloud.drizzle.fill"
        case "rain":                            return "cloud.rain.fill"
        case "snow":                            return "snowflake"
        case "storm":                           return "cloud.bolt.rain.fill"
        case "fog", "mist":                     return "cloud.fog.fill"
        case "haze":                            return "sun.haze.fill"
        default:                               return "cloud.fill"
        }
    }
}

// MARK: WeatherMetricCell

private struct WeatherMetricCell: View {
    let icon:  String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.auraeMidGray)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextCaption)
                Text(value)
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// =============================================================================
// MARK: - HealthCard
// =============================================================================

struct HealthCard: View {

    let snapshot: HealthSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                // Decorative icon — card combines all children into one element.
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Color.severityAccent(for: 4))
                    .accessibilityHidden(true)

                Text("Apple Health")
                    .font(.auraeH2)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
            }

            Divider().overlay(Color.auraeAdaptiveSecondary)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 10
            ) {
                HealthMetricCell(
                    icon:  "heart",
                    label: "Heart Rate",
                    value: snapshot.heartRate.map { "\(Int($0)) bpm" }
                )
                HealthMetricCell(
                    icon:  "waveform.path.ecg",
                    label: "HRV",
                    value: snapshot.hrv.map { "\(Int($0)) ms" }
                )
                HealthMetricCell(
                    icon:  "lungs",
                    label: "SpO2",
                    value: snapshot.oxygenSaturation.map { "\(Int($0))%" }
                )
                HealthMetricCell(
                    icon:  "heart.text.square",
                    label: "Resting HR",
                    value: snapshot.restingHeartRate.map { "\(Int($0)) bpm" }
                )
                HealthMetricCell(
                    icon:  "figure.walk",
                    label: "Steps",
                    value: snapshot.stepCount.map { stepStr($0) }
                )
                HealthMetricCell(
                    icon:  "moon.zzz",
                    label: "Sleep",
                    value: snapshot.formattedSleepDuration
                )
            }
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(snapshot.displaySummary)
    }

    private func stepStr(_ steps: Int) -> String {
        steps >= 1000
            ? String(format: "%.1fk", Double(steps) / 1000)
            : "\(steps)"
    }
}

// MARK: HealthMetricCell

private struct HealthMetricCell: View {
    let icon:  String
    let label: String
    let value: String?   // nil = "—"

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.auraeMidGray)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextCaption)
                Text(value ?? "—")
                    .font(.auraeLabel)
                    .foregroundStyle(value != nil ? Color.auraeAdaptivePrimaryText : Color.auraeTextCaption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value ?? "not available")")
    }
}

// =============================================================================
// MARK: - RetrospectiveReadView
// =============================================================================

/// Read-only display of a filled-in RetrospectiveEntry.
/// Only renders fields that have data — empty fields are suppressed entirely.
struct RetrospectiveReadView: View {

    let entry: RetrospectiveEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            foodSection
            lifestyleSection
            medicationSection
            environmentSection
            notesSection
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Food & Drink
    // -------------------------------------------------------------------------

    @ViewBuilder
    private var foodSection: some View {
        let hasFood = !entry.meals.isEmpty
            || entry.alcohol != nil
            || entry.caffeineIntake != nil
            || entry.hydrationGlasses != nil
            || entry.skippedMeal

        if hasFood {
            RetroReadCard(title: "FOOD & DRINK") {
                if !entry.meals.isEmpty {
                    RetroReadTagRow(tags: entry.meals)
                }
                if let alcohol = entry.alcohol {
                    RetroReadRow(label: "Alcohol", value: alcohol)
                }
                if let caffeine = entry.caffeineIntake {
                    RetroReadRow(label: "Caffeine", value: "\(caffeine) mg")
                }
                if let water = entry.hydrationGlasses {
                    RetroReadRow(
                        label: "Water",
                        value: water == 1 ? "1 glass" : "\(water) glasses"
                    )
                }
                if entry.skippedMeal {
                    RetroReadRow(label: "Skipped a meal", value: "Yes")
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Lifestyle
    // -------------------------------------------------------------------------

    @ViewBuilder
    private var lifestyleSection: some View {
        let hasLifestyle = entry.sleepHours != nil
            || entry.sleepQuality != nil
            || entry.stressLevel != nil
            || entry.screenTimeHours != nil

        if hasLifestyle {
            RetroReadCard(title: "LIFESTYLE") {
                if let sleep = entry.sleepHours {
                    let h = Int(sleep)
                    let m = Int((sleep - Double(h)) * 60)
                    let sleepStr = m == 0 ? "\(h)h" : "\(h)h \(m)m"
                    RetroReadRow(label: "Sleep", value: sleepStr)
                }
                if let quality = entry.sleepQuality {
                    RetroReadStars(label: "Sleep quality", rating: quality)
                }
                if let stress = entry.stressLevel {
                    RetroReadRow(label: "Stress level", value: stressLabel(stress))
                }
                if let screen = entry.screenTimeHours, screen > 0 {
                    let h = Int(screen)
                    let m = Int((screen - Double(h)) * 60)
                    let screenStr = m == 0 ? "\(h)h" : "\(h)h \(m)m"
                    RetroReadRow(label: "Screen time", value: screenStr)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Medication
    // -------------------------------------------------------------------------

    @ViewBuilder
    private var medicationSection: some View {
        if let medName = entry.medicationName {
            RetroReadCard(title: "MEDICATION") {
                RetroReadRow(label: "Medication", value: medName)
                if let dose = entry.medicationDose {
                    RetroReadRow(label: "Dose", value: dose)
                }
                if let eff = entry.medicationEffectiveness {
                    RetroReadStars(label: "Effectiveness", rating: eff)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Environment & Symptoms
    // -------------------------------------------------------------------------

    @ViewBuilder
    private var environmentSection: some View {
        let hasTriggers = !entry.environmentalTriggers.isEmpty
            || !entry.symptoms.isEmpty
            || entry.headacheLocation != nil
            || entry.headacheType != nil
            || entry.cyclePhase != nil

        if hasTriggers {
            RetroReadCard(title: "ENVIRONMENT & SYMPTOMS") {
                if !entry.symptoms.isEmpty {
                    RetroReadTagRow(
                        tags: entry.symptoms.map { symptomLabel($0) }
                    )
                }
                if !entry.environmentalTriggers.isEmpty {
                    RetroReadTagRow(
                        tags: entry.environmentalTriggers.map { triggerLabel($0) }
                    )
                }
                if let location = entry.headacheLocation {
                    RetroReadRow(label: "Location", value: location)
                }
                if let type = entry.headacheType {
                    RetroReadRow(
                        label: "Type",
                        value: type.capitalized
                    )
                }
                if let phase = entry.cyclePhase {
                    RetroReadRow(
                        label: "Cycle Phase",
                        value: cyclePhaseLabel(phase)
                    )
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Notes
    // -------------------------------------------------------------------------

    @ViewBuilder
    private var notesSection: some View {
        if let notes = entry.notes, !notes.isEmpty {
            RetroReadCard(title: "NOTES") {
                Text(notes)
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Label helpers
    // -------------------------------------------------------------------------

    private func stressLabel(_ level: Int) -> String {
        switch level {
        case 1: return "1 — Very low"
        case 2: return "2 — Low"
        case 3: return "3 — Moderate"
        case 4: return "4 — High"
        case 5: return "5 — Very high"
        default: return "\(level)"
        }
    }

    private func symptomLabel(_ key: String) -> String {
        switch key {
        case "nausea":            return "Nausea"
        case "light_sensitivity": return "Light sensitivity"
        case "sound_sensitivity": return "Sound sensitivity"
        case "aura":              return "Visual aura"
        case "neck_pain":         return "Neck stiffness"
        case "visual_disturbance":return "Visual disturbance"
        case "vomiting":          return "Vomiting"
        case "dizziness":         return "Dizziness"
        default:                  return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func triggerLabel(_ key: String) -> String {
        switch key {
        case "bright_light":   return "Bright light"
        case "loud_noise":     return "Loud noise"
        case "strong_smell":   return "Strong smell"
        case "screen_glare":   return "Screen glare"
        case "weather_change": return "Weather change"
        case "altitude":       return "High altitude"
        case "heat":           return "Heat"
        case "cold":           return "Cold"
        default:               return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func cyclePhaseLabel(_ key: String) -> String {
        switch key {
        case "menstrual":  return "Menstrual"
        case "follicular": return "Follicular"
        case "ovulatory":  return "Ovulation"
        case "luteal":     return "Luteal"
        default:           return key.capitalized
        }
    }
}

// =============================================================================
// MARK: - Retrospective read primitives
// =============================================================================

// MARK: RetroReadCard

/// Titled card container for a group of retrospective read rows.
private struct RetroReadCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeTextCaption)
                .tracking(1.0)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
    }
}

// MARK: RetroReadRow

/// A single label + value row inside a RetroReadCard.
/// Vertical stacking (caption label above, semibold value below) matches WeatherMetricCell
/// and HealthMetricCell — avoids jarring horizontal scale jump between 12pt label and 16pt value.
private struct RetroReadRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextCaption)

            Text(value)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: RetroReadStars

/// Read-only star rating display (1–5 filled stars).
private struct RetroReadStars: View {
    let label: String
    let rating: Int

    var body: some View {
        HStack(alignment: .center) {
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextCaption)
                .frame(minWidth: 100, alignment: .leading)

            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { star in
                    // Decorative read-only star — parent combine carries the label. (A18-05)
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            star <= rating ? Color.auraeTeal : Color.auraeMidGray.opacity(0.35)
                        )
                        .accessibilityHidden(true)
                }
                Text("\(rating)/5")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextCaption)
                    .padding(.leading, 4)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(rating) out of 5 stars")
    }
}

// MARK: RetroReadTagRow

/// Read-only display of logged items — plain inline text joined with a centered dot separator.
/// No pill/chip containers in display mode: containers signal interactive affordance (toggle state),
/// which is misleading in a read-only context. Plain text communicates settled, logged fact.
private struct RetroReadTagRow: View {
    let tags: [String]

    private var displayText: String {
        tags.joined(separator: "  ·  ")
    }

    var body: some View {
        Text(displayText)
            .font(.auraeBody)
            .foregroundStyle(Color.auraeAdaptivePrimaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tags.joined(separator: ", "))
    }
}

// =============================================================================
// MARK: - Previews
// =============================================================================

private struct LogDetailPreviewWrapper: View {
    private let container: ModelContainer
    private let log: HeadacheLog

    init(withWeatherAndHealth: Bool, withRetrospective: Bool, isActive: Bool = false) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container  = try! ModelContainer(
            for: HeadacheLog.self, WeatherSnapshot.self,
                HealthSnapshot.self, RetrospectiveEntry.self,
            configurations: config
        )

        let weather: WeatherSnapshot? = withWeatherAndHealth ? WeatherSnapshot(
            temperature:   18.5,
            humidity:      72,
            pressure:      1012,
            pressureTrend: "falling",
            uvIndex:       4,
            aqi:           43,
            condition:     "partly_cloudy"
        ) : nil

        let health: HealthSnapshot? = withWeatherAndHealth ? HealthSnapshot(
            heartRate:        82,
            hrv:              38,
            oxygenSaturation: 97,
            restingHeartRate: 62,
            stepCount:        4200,
            sleepHours:       6.5
        ) : nil

        let retro: RetrospectiveEntry? = withRetrospective ? RetrospectiveEntry(
            meals:                   ["Coffee", "Chocolate"],
            caffeineIntake:          200,
            sleepHours:              6.5,
            sleepQuality:            2,
            stressLevel:             4,
            medicationName:          "Ibuprofen",
            medicationDose:          "400 mg",
            medicationEffectiveness: 3,
            symptoms:                ["nausea", "light_sensitivity"],
            headacheLocation:        "Front",
            headacheType:            "tension",
            environmentalTriggers:   ["bright_light", "loud_noise"],
            notes:                   "Started after two coffees and a stressful meeting."
        ) : nil

        let onset = Date.now.addingTimeInterval(-7200)
        log = HeadacheLog(
            onsetTime:     onset,
            severity:      4,
            weather:       weather,
            health:        health,
            retrospective: retro
        )
        if !isActive { log.resolve(at: onset.addingTimeInterval(3600 * 2.5)) }
        container.mainContext.insert(log)
    }

    var body: some View {
        NavigationStack {
            LogDetailView(log: log)
        }
        .modelContainer(container)
    }
}

#Preview("Full data — resolved") {
    LogDetailPreviewWrapper(withWeatherAndHealth: true, withRetrospective: true)
}

#Preview("No capture data") {
    LogDetailPreviewWrapper(withWeatherAndHealth: false, withRetrospective: false)
}

#Preview("Active headache") {
    LogDetailPreviewWrapper(
        withWeatherAndHealth: true,
        withRetrospective:    false,
        isActive:             true
    )
}
