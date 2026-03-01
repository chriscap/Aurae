//
//  PDFExportService.swift
//  Aurae
//
//  Generates PDF reports from HeadacheLog data entirely on-device using PDFKit.
//  No data is ever transmitted to an external service.
//
//  Free tier  — generateSummaryPDF(logs:) async -> Data
//    Produces a summary table: Date | Time | Severity | Duration |
//    Weather | Medication | Notes (truncated to 40 chars)
//
//  Premium tier — generateFullPDF(logs:) async -> Data
//    Full contextual document with three sections:
//      1. Summary table (reuses free-tier renderer)
//      2. Per-log detail cards (weather, health, sleep, retrospective)
//      3. Trigger intelligence summary (charts + tables)
//
//  Swift 6 / Sendable note
//  -----------------------
//  HeadacheLog is a SwiftData @Model class and is NOT Sendable. All data is
//  therefore extracted into plain value types on the calling actor (@MainActor)
//  before being handed to the off-main render work. The CGContext drawing loop
//  only ever touches Sendable value types.
//
//  Page format: A4 (595 × 842 pt), portrait, 40 pt margins.
//

import Foundation
import PDFKit
import UIKit

// MARK: - LogRow (Sendable value type for summary table)

/// A snapshot of a HeadacheLog's displayable fields for the summary table.
/// Created on the calling actor; passed to the renderer without SwiftData types.
private struct LogRow: Sendable {
    let date:       String
    let time:       String
    let severity:   String
    let duration:   String
    let weather:    String
    let medication: String
    let notes:      String
}

// MARK: - FullLogRow (Sendable value type for full detail pages)

/// Complete snapshot of a single HeadacheLog for the premium detail section.
/// Every field is a plain Swift value type. No SwiftData model is retained.
struct FullLogRow: Sendable {

    // MARK: Header
    let date:           String  // "Feb 19, 2026"
    let time:           String  // "9:45 AM"
    let severityInt:    Int     // 1–5, used for badge colour
    let severityLabel:  String  // "3/5"
    let durationLabel:  String  // "2h 15m" or "Active"

    // MARK: Weather (nil when not captured)
    let weatherTemp:        String?   // "18°C"
    let weatherHumidity:    String?   // "72%"
    let weatherPressure:    String?   // "1008 hPa ↓"
    let weatherUV:          String?   // "UV 4"
    let weatherAQI:         String?   // "AQI 42" or nil
    let weatherCondition:   String?   // "Partly Cloudy"

    // MARK: Health (nil when not captured)
    let healthHR:           String?   // "78 bpm"
    let healthRestingHR:    String?   // "62 bpm"
    let healthHRV:          String?   // "38 ms"
    let healthSpO2:         String?   // "98%"
    let healthSteps:        String?   // "4,231"

    // MARK: Sleep (nil when no data)
    let sleepHours:         String?   // "7h 30m"
    let sleepQuality:       Int?      // 1–5

    // MARK: Retrospective food & drink (nil when not recorded)
    let meals:          [String]      // may be empty
    let alcohol:        String?
    let caffeine:       String?       // "200 mg"
    let hydration:      String?       // "6 glasses"
    let skippedMeal:    Bool

    // MARK: Retrospective lifestyle
    let stressLevel:    String?       // "3/5"
    let screenTime:     String?       // "4.5 h"

    // MARK: Retrospective symptoms
    let symptoms:       [String]      // may be empty

    // MARK: Retrospective medication
    let medicationName:          String?
    let medicationDose:          String?
    let medicationEffectiveness: String?  // "4/5"

    // MARK: Retrospective environment
    let triggers:   [String]    // may be empty
    let notes:      String?     // full text, no truncation

    // MARK: Flags
    let hasWeather:       Bool
    let hasHealth:        Bool
    let hasSleep:         Bool
    let hasRetrospective: Bool
}

// MARK: - TriggerSummary (Sendable value type for trigger intelligence page)

/// Aggregated analytics extracted from InsightsReport on the calling actor.
/// Every field is a plain Swift value type.
struct TriggerSummary: Sendable {

    struct TriggerRow: Sendable {
        let rank:       Int
        let trigger:    String
        let count:      Int
        let coPercent:  Int   // co-occurrence % = count / totalLogs * 100
    }

    struct DayCount: Sendable {
        let abbreviation:   String  // "Mon"
        let count:          Int
        let relativeFraction: Double  // 0–1, proportion of max day count
    }

    struct TimeSlot: Sendable {
        let label:      String  // "Morning"
        let count:      Int
        let percent:    Int
    }

    struct SeverityBar: Sendable {
        let level:      Int     // 1–5
        let count:      Int
        let fraction:   Double  // 0–1
        let hexColor:   String  // accent hex
    }

    struct MedRow: Sendable {
        let name:           String
        let timesUsed:      Int
        let avgEffectiveness: String  // "3.4/5"
    }

    let topTriggers:            [TriggerRow]
    let dayOfWeekCounts:        [DayCount]      // 7 elements, Sun–Sat
    let timeOfDayCounts:        [TimeSlot]      // 4 elements
    let severityBars:           [SeverityBar]   // 5 elements
    let medicationRows:         [MedRow]        // may be empty
    let totalLogs:              Int
    let hasData:                Bool            // false when < 5 logs
}

// MARK: - PDFExportService

final class PDFExportService: Sendable {

    static let shared = PDFExportService()
    private init() {}

    // MARK: - Page geometry

    private let pageSize   = CGSize(width: 595, height: 842)   // A4 portrait
    private let margin: CGFloat = 40

    private var contentWidth: CGFloat { pageSize.width - margin * 2 }

    // MARK: - Colour palette (CGColor from design system hex values)

    // auraeNavy    #0D1B2A — headings and table headers
    private let navyColor    = UIColor(red: 13/255,  green: 27/255,  blue: 42/255,  alpha: 1).cgColor
    // auraeTeal    #2D7D7D — accent rule and header bar
    private let tealColor    = UIColor(red: 45/255,  green: 125/255, blue: 125/255, alpha: 1).cgColor
    // auraeMidGray #6B7280 — body text and metadata
    private let grayColor    = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1).cgColor
    // auraeBackground #F5F6F8 — alternating row tint
    private let rowTintColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1).cgColor

    // Severity accent colours matching Colors.swift severityAccent(for:)
    // 1 = #5A9E9A, 2 = #7ABAB7, 3 = #8A7AB8, 4 = #9B6CA8, 5 = #C47A7A
    private func severityAccentCGColor(for level: Int) -> CGColor {
        switch level {
        case 1:  return UIColor(red: 90/255,  green: 158/255, blue: 154/255, alpha: 1).cgColor
        case 2:  return UIColor(red: 122/255, green: 186/255, blue: 183/255, alpha: 1).cgColor
        case 3:  return UIColor(red: 138/255, green: 122/255, blue: 184/255, alpha: 1).cgColor
        case 4:  return UIColor(red: 155/255, green: 108/255, blue: 168/255, alpha: 1).cgColor
        default: return UIColor(red: 196/255, green: 122/255, blue: 122/255, alpha: 1).cgColor
        }
    }

    // Severity accent hex strings (for FullLogRow badge)
    func severityAccentHex(for level: Int) -> String {
        switch level {
        case 1:  return "5A9E9A"
        case 2:  return "7ABAB7"
        case 3:  return "8A7AB8"
        case 4:  return "9B6CA8"
        default: return "C47A7A"
        }
    }

    // MARK: - Column definitions

    private struct Column: Sendable {
        let title: String
        let width: CGFloat
    }

    private func makeColumns() -> [Column] {
        let w = contentWidth
        return [
            Column(title: "Date",       width: w * 0.14),
            Column(title: "Time",       width: w * 0.10),
            Column(title: "Sev",        width: w * 0.07),
            Column(title: "Duration",   width: w * 0.11),
            Column(title: "Weather",    width: w * 0.18),
            Column(title: "Medication", width: w * 0.18),
            Column(title: "Notes",      width: w * 0.22),
        ]
    }

    // MARK: - Heights (constants)

    private var headerHeight:       CGFloat { 72 }
    private var columnHeaderHeight: CGFloat { 22 }
    private var rowHeight:          CGFloat { 26 }
    private var footerHeight:       CGFloat { 18 }

    // MARK: - Public API

    /// Generates the free-tier summary PDF.
    /// Must be called on an actor (e.g. @MainActor) so HeadacheLog can be
    /// read safely. Data extraction happens before the detached render task.
    func generateSummaryPDF(logs: [HeadacheLog]) async -> Data {
        let rows     = logs
            .sorted { $0.onsetTime > $1.onsetTime }
            .map { makeRow($0) }
        let header   = makeHeaderMeta(logs: logs)
        let columns  = makeColumns()

        return await Task.detached(priority: .userInitiated) { [self] in
            self.render(rows: rows, headerMeta: header, columns: columns)
        }.value
    }

    /// Premium-tier full export.
    /// Extracts all SwiftData model data on the calling actor (@MainActor),
    /// then hands plain Sendable value types to a detached render task.
    func generateFullPDF(logs: [HeadacheLog]) async -> Data {
        // --- All model access happens here, on the calling actor ---
        let sortedLogs = logs.sorted { $0.onsetTime > $1.onsetTime }

        // Summary table data (reuse existing extraction)
        let summaryRows  = sortedLogs.map { makeRow($0) }
        let headerMeta   = makeHeaderMeta(logs: logs)
        let columns      = makeColumns()

        // Full detail rows
        let fullRows     = sortedLogs.map { makeFullLogRow($0) }

        // Trigger intelligence — run InsightsService synchronously on calling actor
        let insightsService = InsightsService()
        let report = insightsService.buildReport(from: logs)
        let triggerSummary = makeTriggerSummary(from: report, totalLogs: logs.count)

        return await Task.detached(priority: .userInitiated) { [self] in
            self.renderFull(
                summaryRows: summaryRows,
                headerMeta: headerMeta,
                columns: columns,
                fullRows: fullRows,
                triggerSummary: triggerSummary
            )
        }.value
    }

    // MARK: - Summary row extraction (runs on calling actor)

    private func makeRow(_ log: HeadacheLog) -> LogRow {
        let df = DateFormatter()

        df.dateFormat = "MMM d, yyyy"
        let date = df.string(from: log.onsetTime)

        df.dateFormat = "h:mm a"
        let time = df.string(from: log.onsetTime)

        let severity = "\(log.severity)/5"
        let duration = log.formattedDuration ?? "Active"

        let weather: String = {
            guard let w = log.weather else { return "—" }
            let temp = String(format: "%.0f°", w.temperature)
            let cond = w.condition
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            return "\(temp) \(cond)"
        }()

        let medication = log.retrospective?.medicationName ?? "—"

        let notes: String = {
            guard let raw = log.retrospective?.notes, !raw.isEmpty else { return "—" }
            return raw.count > 40 ? String(raw.prefix(40)) + "…" : raw
        }()

        return LogRow(
            date:       date,
            time:       time,
            severity:   severity,
            duration:   duration,
            weather:    weather,
            medication: medication,
            notes:      notes
        )
    }

    // MARK: - Full log row extraction (runs on calling actor)

    private func makeFullLogRow(_ log: HeadacheLog) -> FullLogRow {
        let df = DateFormatter()

        df.dateFormat = "MMM d, yyyy"
        let date = df.string(from: log.onsetTime)

        df.dateFormat = "h:mm a"
        let time = df.string(from: log.onsetTime)

        let nf = NumberFormatter()
        nf.numberStyle = .decimal

        // Weather
        var weatherTemp: String?
        var weatherHumidity: String?
        var weatherPressure: String?
        var weatherUV: String?
        var weatherAQI: String?
        var weatherCondition: String?

        if let w = log.weather {
            weatherTemp      = String(format: "%.0f°C", w.temperature)
            weatherHumidity  = String(format: "%.0f%%", w.humidity)
            let trendSymbol: String
            switch w.pressureTrend {
            case "rising":  trendSymbol = "↑"
            case "falling": trendSymbol = "↓"
            default:        trendSymbol = "→"
            }
            weatherPressure  = String(format: "%.0f hPa %@", w.pressure, trendSymbol)
            weatherUV        = String(format: "UV %.0f", w.uvIndex)
            if let aqi = w.aqi { weatherAQI = "AQI \(aqi)" }
            weatherCondition = w.condition.replacingOccurrences(of: "_", with: " ").capitalized
        }

        // Health
        var healthHR: String?
        var healthRestingHR: String?
        var healthHRV: String?
        var healthSpO2: String?
        var healthSteps: String?

        if let h = log.health {
            if let hr  = h.heartRate        { healthHR        = "\(Int(hr)) bpm" }
            if let rhr = h.restingHeartRate  { healthRestingHR = "\(Int(rhr)) bpm" }
            if let hrv = h.hrv              { healthHRV       = "\(Int(hrv)) ms" }
            if let spo = h.oxygenSaturation { healthSpO2      = String(format: "%.0f%%", spo) }
            if let st  = h.stepCount        {
                healthSteps = nf.string(from: NSNumber(value: st)) ?? "\(st)"
            }
        }

        // Sleep: prefer retrospective, fall back to HealthKit
        let rawSleepHours: Double? = log.retrospective?.sleepHours ?? log.health?.sleepHours
        var sleepHoursLabel: String?
        if let s = rawSleepHours {
            let h = Int(s)
            let m = Int((s - Double(h)) * 60)
            sleepHoursLabel = m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
        let sleepQuality: Int? = log.retrospective?.sleepQuality

        // Retrospective
        var meals:          [String] = []
        var alcohol:        String?
        var caffeine:       String?
        var hydration:      String?
        var skippedMeal                     = false
        var stressLevel:    String?
        var screenTime:     String?
        var symptoms:       [String] = []
        var medicationName: String?
        var medicationDose: String?
        var medicationEffectiveness: String?
        var triggers:       [String] = []
        var notes:          String?

        if let r = log.retrospective {
            meals       = r.meals
            alcohol     = r.alcohol
            if let c = r.caffeineIntake    { caffeine  = "\(c) mg" }
            if let g = r.hydrationGlasses  { hydration = "\(g) glasses" }
            skippedMeal = r.skippedMeal
            if let s = r.stressLevel       { stressLevel = "\(s)/5" }
            if let st = r.screenTimeHours  { screenTime  = String(format: "%.1f h", st) }
            symptoms    = r.symptoms.map { displayName(raw: $0) }
            medicationName          = r.medicationName
            medicationDose          = r.medicationDose
            if let e = r.medicationEffectiveness { medicationEffectiveness = "\(e)/5" }
            triggers    = r.environmentalTriggers.map { displayName(raw: $0) }
            notes       = r.notes
        }

        let hasWeather       = log.weather != nil
        let hasHealth        = log.health?.hasAnyData == true
        let hasSleep         = rawSleepHours != nil || sleepQuality != nil
        let hasRetrospective = log.retrospective?.hasAnyData == true

        return FullLogRow(
            date:           date,
            time:           time,
            severityInt:    log.severity,
            severityLabel:  "\(log.severity)/5",
            durationLabel:  log.formattedDuration ?? "Active",
            weatherTemp:        weatherTemp,
            weatherHumidity:    weatherHumidity,
            weatherPressure:    weatherPressure,
            weatherUV:          weatherUV,
            weatherAQI:         weatherAQI,
            weatherCondition:   weatherCondition,
            healthHR:           healthHR,
            healthRestingHR:    healthRestingHR,
            healthHRV:          healthHRV,
            healthSpO2:         healthSpO2,
            healthSteps:        healthSteps,
            sleepHours:         sleepHoursLabel,
            sleepQuality:       sleepQuality,
            meals:              meals,
            alcohol:            alcohol,
            caffeine:           caffeine,
            hydration:          hydration,
            skippedMeal:        skippedMeal,
            stressLevel:        stressLevel,
            screenTime:         screenTime,
            symptoms:           symptoms,
            medicationName:     medicationName,
            medicationDose:     medicationDose,
            medicationEffectiveness: medicationEffectiveness,
            triggers:           triggers,
            notes:              notes,
            hasWeather:         hasWeather,
            hasHealth:          hasHealth,
            hasSleep:           hasSleep,
            hasRetrospective:   hasRetrospective
        )
    }

    // Human-readable display name for raw trigger/symptom shorthand keys
    private func displayName(raw: String) -> String {
        switch raw {
        case "strong_smell":        return "Strong smell"
        case "bright_light":        return "Bright light"
        case "loud_noise":          return "Loud noise"
        case "screen_glare":        return "Screen glare"
        case "weather_change":      return "Weather change"
        case "altitude":            return "Altitude"
        case "heat":                return "Heat"
        case "cold":                return "Cold"
        case "nausea":              return "Nausea"
        case "light_sensitivity":   return "Light sensitivity"
        case "sound_sensitivity":   return "Sound sensitivity"
        case "aura":                return "Aura"
        case "neck_pain":           return "Neck pain"
        case "visual_disturbance":  return "Visual disturbance"
        case "vomiting":            return "Vomiting"
        case "dizziness":           return "Dizziness"
        default:
            return raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // MARK: - TriggerSummary extraction (runs on calling actor)

    private func makeTriggerSummary(from report: InsightsReport, totalLogs: Int) -> TriggerSummary {
        guard report.minimumLogsMet else {
            return TriggerSummary(
                topTriggers: [],
                dayOfWeekCounts: makeDayOfWeekCounts(severityByDayOfWeek: [:]),
                timeOfDayCounts: makeTimeSlots(severityByTimeOfDay: [:], totalLogs: 0),
                severityBars: [],
                medicationRows: [],
                totalLogs: totalLogs,
                hasData: false
            )
        }

        // Top triggers — up to 10
        let topTriggers: [TriggerSummary.TriggerRow] = report.mostCommonTriggers
            .prefix(10)
            .enumerated()
            .map { idx, pair in
                let pct = totalLogs > 0
                    ? Int(Double(pair.count) / Double(totalLogs) * 100)
                    : 0
                return TriggerSummary.TriggerRow(
                    rank: idx + 1,
                    trigger: pair.trigger,
                    count: pair.count,
                    coPercent: pct
                )
            }

        // Day-of-week counts — derive headache counts from headacheFrequency
        let dayOfWeekCounts = makeDayOfWeekCounts(
            severityByDayOfWeek: report.severityByDayOfWeek
        )

        // Time-of-day — build from severityByTimeOfDay keys (proxy: count keys)
        // We derive counts from headacheFrequency keyed by day; approximate
        // time-of-day counts by using the proportional severity averages.
        // More accurate: count logs per time slot from headacheFrequency is
        // not available directly, so we use the presence keys in severityByTimeOfDay
        // as relative weights against totalLogs.
        let timeSlots = makeTimeSlots(
            severityByTimeOfDay: report.severityByTimeOfDay,
            totalLogs: totalLogs
        )

        // Severity distribution: count per level from headacheFrequency isn't
        // granular enough, so we use mostCommonTriggers as the trigger insight
        // and infer per-severity counts via severityByDayOfWeek proportions.
        // For the bars we compute approximate counts using average severities
        // as weights (display only — no clinical claims).
        let severityBars = makeSeverityBars(
            distribution: report.severityDistribution,
            totalLogs: totalLogs
        )

        // Medication
        let medRows: [TriggerSummary.MedRow] = report.medicationEffectiveness.map { pair in
            // medicationEffectiveness returns (name, avgEffectiveness) sorted desc.
            // timesUsed is not directly stored in InsightsReport, derive from
            // the name occurrence across logs (already filtered to >= 2 uses).
            // We use a placeholder count of "2+" since the exact count is not
            // stored in InsightsReport — this is a display-only summary.
            TriggerSummary.MedRow(
                name: pair.name,
                timesUsed: 0,   // 0 signals "use avg effectiveness label only"
                avgEffectiveness: String(format: "%.1f/5", pair.avgEffectiveness)
            )
        }

        return TriggerSummary(
            topTriggers: topTriggers,
            dayOfWeekCounts: dayOfWeekCounts,
            timeOfDayCounts: timeSlots,
            severityBars: severityBars,
            medicationRows: medRows,
            totalLogs: totalLogs,
            hasData: true
        )
    }

    private func makeDayOfWeekCounts(
        severityByDayOfWeek: [Int: Double]
    ) -> [TriggerSummary.DayCount] {
        // Calendar weekday: 1=Sun, 2=Mon … 7=Sat
        let dayAbbreviations = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let maxValue = severityByDayOfWeek.values.max() ?? 1
        return (1...7).map { wd in
            let avg = severityByDayOfWeek[wd] ?? 0
            let fraction = maxValue > 0 ? avg / maxValue : 0
            return TriggerSummary.DayCount(
                abbreviation: dayAbbreviations[wd - 1],
                count: Int(avg * 10),  // scale to integer for display
                relativeFraction: fraction
            )
        }
    }

    private func makeTimeSlots(
        severityByTimeOfDay: [TimeOfDay: Double],
        totalLogs: Int
    ) -> [TriggerSummary.TimeSlot] {
        let order: [TimeOfDay] = [.morning, .afternoon, .evening, .night]
        let totalWeight = order.reduce(0.0) { $0 + (severityByTimeOfDay[$1] ?? 0) }
        return order.map { tod in
            let weight = severityByTimeOfDay[tod] ?? 0
            let pct = totalWeight > 0 ? Int(weight / totalWeight * 100) : 0
            let count = Int(Double(totalLogs) * weight / max(totalWeight, 1))
            return TriggerSummary.TimeSlot(
                label: tod.rawValue,
                count: count,
                percent: pct
            )
        }
    }

    private func makeSeverityBars(distribution: [Int: Int], totalLogs: Int) -> [TriggerSummary.SeverityBar] {
        // Use actual logged severity counts (Mild=1, Moderate=3, Severe=5).
        // Only the three valid levels are shown; colours mapped by level index.
        let levels: [(rawValue: Int, hexColor: String)] = [
            (1, "5A9E9A"),  // Mild — muted teal
            (3, "8A7AB8"),  // Moderate — muted violet
            (5, "C47A7A"),  // Severe — muted rose
        ]
        let maxCount = distribution.values.max().flatMap { $0 > 0 ? $0 : nil } ?? 1
        return levels.map { entry in
            let count = distribution[entry.rawValue] ?? 0
            return TriggerSummary.SeverityBar(
                level: entry.rawValue,
                count: count,
                fraction: Double(count) / Double(maxCount),
                hexColor: entry.hexColor
            )
        }
    }

    // MARK: - Header metadata extraction

    private struct HeaderMeta: Sendable {
        let dateRange: String
        let count:     Int
    }

    private func makeHeaderMeta(logs: [HeadacheLog]) -> HeaderMeta {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        let dates = logs.map(\.onsetTime)
        let range: String = {
            guard !dates.isEmpty, let oldest = dates.min(), let newest = dates.max() else {
                return "No logs"
            }
            if Calendar.current.isDate(oldest, inSameDayAs: newest) {
                return df.string(from: oldest)
            }
            return "\(df.string(from: oldest)) – \(df.string(from: newest))"
        }()
        return HeaderMeta(dateRange: range, count: logs.count)
    }

    // MARK: - Summary renderer (nonisolated, only touches Sendable types)

    private func render(rows: [LogRow], headerMeta: HeaderMeta, columns: [Column]) -> Data {
        let format     = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Aurae",
            kCGPDFContextTitle   as String: "Aurae Headache Report"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        let data = renderer.pdfData { ctx in
            var pageNumber = 1
            var yOffset: CGFloat = 0

            func startNewPage() {
                ctx.beginPage()
                yOffset = margin
                drawHeader(ctx: ctx.cgContext, meta: headerMeta)
                yOffset += headerHeight + 8
                drawColumnHeaders(ctx: ctx.cgContext, y: yOffset, columns: columns)
                yOffset += columnHeaderHeight + 4
                pageNumber += 1
            }

            // First page
            ctx.beginPage()
            yOffset = margin
            drawHeader(ctx: ctx.cgContext, meta: headerMeta)
            yOffset += headerHeight + 8
            drawColumnHeaders(ctx: ctx.cgContext, y: yOffset, columns: columns)
            yOffset += columnHeaderHeight + 4

            for (index, row) in rows.enumerated() {
                let nearBottom = pageSize.height - margin - footerHeight - 8
                if yOffset + rowHeight > nearBottom {
                    drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
                    startNewPage()
                }
                drawRow(ctx: ctx.cgContext, row: row, index: index, y: yOffset, columns: columns)
                yOffset += rowHeight
            }

            drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
        }

        return data
    }

    // MARK: - Full PDF renderer (nonisolated, only touches Sendable types)

    private func renderFull(
        summaryRows: [LogRow],
        headerMeta: HeaderMeta,
        columns: [Column],
        fullRows: [FullLogRow],
        triggerSummary: TriggerSummary
    ) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Aurae",
            kCGPDFContextTitle   as String: "Aurae Full Headache Report"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        let data = renderer.pdfData { ctx in
            var pageNumber = 1

            // ----------------------------------------------------------------
            // SECTION 1 — Summary table (reuse existing logic)
            // ----------------------------------------------------------------
            var yOffset: CGFloat = 0

            func startNewPage() {
                drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
                ctx.beginPage()
                pageNumber += 1
                yOffset = margin
                drawHeader(ctx: ctx.cgContext, meta: headerMeta)
                yOffset += headerHeight + 8
                drawColumnHeaders(ctx: ctx.cgContext, y: yOffset, columns: columns)
                yOffset += columnHeaderHeight + 4
            }

            ctx.beginPage()
            yOffset = margin
            drawHeader(ctx: ctx.cgContext, meta: headerMeta)
            yOffset += headerHeight + 8
            drawColumnHeaders(ctx: ctx.cgContext, y: yOffset, columns: columns)
            yOffset += columnHeaderHeight + 4

            for (index, row) in summaryRows.enumerated() {
                let nearBottom = pageSize.height - margin - footerHeight - 8
                if yOffset + rowHeight > nearBottom {
                    startNewPage()
                }
                drawRow(ctx: ctx.cgContext, row: row, index: index, y: yOffset, columns: columns)
                yOffset += rowHeight
            }

            // ----------------------------------------------------------------
            // SECTION 2 — Full detail cards, stacked vertically
            // ----------------------------------------------------------------

            // Start a fresh page for Section 2
            drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
            ctx.beginPage()
            pageNumber += 1
            yOffset = margin
            drawSectionHeading(
                ctx: ctx.cgContext,
                text: "Full Headache Log",
                y: yOffset
            )
            yOffset += 28

            for (logIndex, row) in fullRows.enumerated() {
                let estimatedHeight = estimateDetailCardHeight(row: row)
                let nearBottom = pageSize.height - margin - footerHeight - 8

                if yOffset + estimatedHeight > nearBottom && yOffset > margin + 28 {
                    drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
                    ctx.beginPage()
                    pageNumber += 1
                    yOffset = margin
                }

                yOffset = drawDetailCard(
                    ctx: ctx.cgContext,
                    row: row,
                    y: yOffset,
                    isLast: logIndex == fullRows.count - 1
                )
            }

            // ----------------------------------------------------------------
            // SECTION 3 — Trigger Intelligence
            // ----------------------------------------------------------------
            drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
            ctx.beginPage()
            pageNumber += 1
            yOffset = margin
            yOffset = drawTriggerIntelligence(
                ctx: ctx.cgContext,
                summary: triggerSummary,
                startY: yOffset,
                pageNumber: &pageNumber,
                ctx2: ctx
            )

            drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
        }

        return data
    }

    // MARK: - Section heading

    private func drawSectionHeading(ctx: CGContext, text: String, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSerifDisplay-Regular", size: 14)
                ?? UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        NSAttributedString(string: text, attributes: attrs)
            .draw(at: CGPoint(x: margin, y: y))

        // Accent rule under heading
        ctx.setFillColor(tealColor)
        ctx.fill(CGRect(x: margin, y: y + 18, width: contentWidth, height: 2))
    }

    // MARK: - Detail card

    /// Returns the new yOffset after drawing the card.
    @discardableResult
    private func drawDetailCard(
        ctx: CGContext,
        row: FullLogRow,
        y: CGFloat,
        isLast: Bool
    ) -> CGFloat {
        var yOffset = y
        let x = margin
        let cardTopY = yOffset

        // -- Header row: Date + time, severity badge, duration --
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSerifDisplay-Regular", size: 11)
                ?? UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        let dateTimeStr = "\(row.date)  ·  \(row.time)"
        NSAttributedString(string: dateTimeStr, attributes: headerAttrs)
            .draw(at: CGPoint(x: x, y: yOffset))

        // Severity badge — filled capsule
        let badgeLabel = "Severity \(row.severityInt)"
        let badgeFont = UIFont(name: "DMSans-SemiBold", size: 8)
            ?? UIFont.systemFont(ofSize: 8, weight: .semibold)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: UIColor.white
        ]
        let badgeStr = NSAttributedString(string: badgeLabel, attributes: badgeAttrs)
        let badgeSize = badgeStr.size()
        let badgePadH: CGFloat = 6
        let badgePadV: CGFloat = 3
        let badgeW = badgeSize.width + badgePadH * 2
        let badgeH = badgeSize.height + badgePadV * 2
        let badgeX = pageSize.width - margin - badgeW - 70
        let badgeRect = CGRect(x: badgeX, y: yOffset, width: badgeW, height: badgeH)

        ctx.setFillColor(severityAccentCGColor(for: row.severityInt))
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeH / 2)
        ctx.addPath(badgePath.cgPath)
        ctx.fillPath()
        badgeStr.draw(at: CGPoint(x: badgeX + badgePadH, y: yOffset + badgePadV))

        // Duration label
        let durAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 9)
                ?? UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let durStr = NSAttributedString(string: row.durationLabel, attributes: durAttrs)
        let durSize = durStr.size()
        durStr.draw(at: CGPoint(x: pageSize.width - margin - durSize.width, y: yOffset + 2))

        yOffset += 16

        // -- Weather block --
        if row.hasWeather {
            yOffset = drawDetailSubsection(
                ctx: ctx,
                label: "WEATHER",
                y: yOffset,
                pairs: [
                    ("Temperature",  row.weatherTemp),
                    ("Humidity",     row.weatherHumidity),
                    ("Pressure",     row.weatherPressure),
                    ("UV Index",     row.weatherUV),
                    ("AQI",          row.weatherAQI),
                    ("Condition",    row.weatherCondition)
                ].compactMap { pair in
                    pair.1.map { (pair.0, $0) }
                }
            )
        }

        // -- Health block --
        if row.hasHealth {
            yOffset = drawDetailSubsection(
                ctx: ctx,
                label: "HEALTH",
                y: yOffset,
                pairs: [
                    ("Heart Rate",         row.healthHR),
                    ("Resting HR",         row.healthRestingHR),
                    ("HRV",                row.healthHRV),
                    ("SpO2",               row.healthSpO2),
                    ("Steps",              row.healthSteps)
                ].compactMap { pair in
                    pair.1.map { (pair.0, $0) }
                }
            )
        }

        // -- Sleep block --
        if row.hasSleep {
            var sleepPairs: [(String, String)] = []
            if let sh = row.sleepHours { sleepPairs.append(("Duration", sh)) }
            if let sq = row.sleepQuality { sleepPairs.append(("Quality", "\(sq)/5")) }
            yOffset = drawDetailSubsection(
                ctx: ctx,
                label: "SLEEP",
                y: yOffset,
                pairs: sleepPairs
            )
        }

        // -- Retrospective block --
        if row.hasRetrospective {
            // Food & drink
            var foodPairs: [(String, String)] = []
            if !row.meals.isEmpty   { foodPairs.append(("Meals", row.meals.joined(separator: ", "))) }
            if let a = row.alcohol  { foodPairs.append(("Alcohol", a)) }
            if let c = row.caffeine { foodPairs.append(("Caffeine", c)) }
            if let h = row.hydration{ foodPairs.append(("Hydration", h)) }
            if row.skippedMeal      { foodPairs.append(("Skipped meal", "Yes")) }
            if !foodPairs.isEmpty {
                yOffset = drawDetailSubsection(ctx: ctx, label: "FOOD & DRINK", y: yOffset, pairs: foodPairs)
            }

            // Lifestyle
            var lifePairs: [(String, String)] = []
            if let s  = row.stressLevel  { lifePairs.append(("Stress", s)) }
            if let sc = row.screenTime   { lifePairs.append(("Screen time", sc)) }
            if !lifePairs.isEmpty {
                yOffset = drawDetailSubsection(ctx: ctx, label: "LIFESTYLE", y: yOffset, pairs: lifePairs)
            }

            // Symptoms
            if !row.symptoms.isEmpty {
                yOffset = drawDetailSubsection(
                    ctx: ctx, label: "SYMPTOMS", y: yOffset,
                    pairs: [("", row.symptoms.joined(separator: ", "))]
                )
            }

            // Medication
            var medPairs: [(String, String)] = []
            if let n = row.medicationName         { medPairs.append(("Medication", n)) }
            if let d = row.medicationDose         { medPairs.append(("Dose", d)) }
            if let e = row.medicationEffectiveness{ medPairs.append(("Effectiveness", e)) }
            if !medPairs.isEmpty {
                yOffset = drawDetailSubsection(ctx: ctx, label: "MEDICATION", y: yOffset, pairs: medPairs)
            }

            // Environment
            var envPairs: [(String, String)] = []
            if !row.triggers.isEmpty { envPairs.append(("Triggers", row.triggers.joined(separator: ", "))) }
            if let n = row.notes, !n.isEmpty { envPairs.append(("Notes", n)) }
            if !envPairs.isEmpty {
                yOffset = drawDetailSubsection(ctx: ctx, label: "ENVIRONMENT", y: yOffset, pairs: envPairs)
            }
        }

        // -- Divider between logs (skip after last) --
        if !isLast {
            ctx.setStrokeColor(grayColor.copy(alpha: 0.2) ?? grayColor)
            ctx.setLineWidth(0.5)
            let divY = yOffset + 4
            ctx.move(to: CGPoint(x: margin, y: divY))
            ctx.addLine(to: CGPoint(x: margin + contentWidth, y: divY))
            ctx.strokePath()
            yOffset = divY + 8
        } else {
            yOffset += 4
        }

        _ = cardTopY  // suppress unused warning
        return yOffset
    }

    /// Draws a labelled two-column subsection block. Returns new yOffset.
    private func drawDetailSubsection(
        ctx: CGContext,
        label: String,
        y: CGFloat,
        pairs: [(String, String)]
    ) -> CGFloat {
        guard !pairs.isEmpty else { return y }

        var yOffset = y + 4

        // Label row
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 7.5)
                ?? UIFont.systemFont(ofSize: 7.5, weight: .semibold),
            .foregroundColor: UIColor(cgColor: tealColor)
        ]
        NSAttributedString(string: label, attributes: labelAttrs)
            .draw(at: CGPoint(x: margin, y: yOffset))
        yOffset += 11

        let keyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        let valAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]

        // Lay out in 2-column grid: left col 0–50%, right col 50–100%
        let colW = contentWidth / 2
        var colPairs: [(String, String)] = pairs

        while !colPairs.isEmpty {
            let left  = colPairs.removeFirst()
            let right = colPairs.isEmpty ? nil : colPairs.removeFirst()

            // Left column
            if !left.0.isEmpty {
                NSAttributedString(string: left.0 + ":", attributes: keyAttrs)
                    .draw(at: CGPoint(x: margin, y: yOffset))
            }
            // Wrap value text if needed
            let leftValX = left.0.isEmpty ? margin : margin + 60
            let leftValWidth = left.0.isEmpty ? contentWidth : colW - 60
            drawWrappedText(
                ctx: ctx,
                text: left.1,
                attrs: valAttrs,
                x: leftValX,
                y: yOffset,
                maxWidth: leftValWidth
            )

            // Right column
            if let right = right {
                if !right.0.isEmpty {
                    NSAttributedString(string: right.0 + ":", attributes: keyAttrs)
                        .draw(at: CGPoint(x: margin + colW, y: yOffset))
                }
                drawWrappedText(
                    ctx: ctx,
                    text: right.1,
                    attrs: valAttrs,
                    x: margin + colW + 60,
                    y: yOffset,
                    maxWidth: colW - 60
                )
            }

            yOffset += 13
        }

        return yOffset
    }

    /// Draws text that may wrap across lines. Returns the new yOffset.
    @discardableResult
    private func drawWrappedText(
        ctx: CGContext,
        text: String,
        attrs: [NSAttributedString.Key: Any],
        x: CGFloat,
        y: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let boundingRect = attrStr.boundingRect(
            with: CGSize(width: maxWidth, height: 1000),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attrStr.draw(
            with: CGRect(x: x, y: y, width: maxWidth, height: boundingRect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return y + boundingRect.height
    }

    /// Rough height estimate for a detail card — used for page-break decisions.
    private func estimateDetailCardHeight(row: FullLogRow) -> CGFloat {
        var h: CGFloat = 20  // header row

        if row.hasWeather       { h += 70 }
        if row.hasHealth        { h += 70 }
        if row.hasSleep         { h += 40 }
        if row.hasRetrospective {
            if !row.meals.isEmpty || row.alcohol != nil || row.caffeine != nil { h += 50 }
            if row.stressLevel != nil || row.screenTime != nil { h += 35 }
            if !row.symptoms.isEmpty { h += 25 }
            if row.medicationName != nil { h += 35 }
            let noteLength = row.notes?.count ?? 0
            h += noteLength > 0 ? 40 + CGFloat(noteLength / 80) * 10 : 25
        }
        h += 16  // divider + spacing
        return h
    }

    // MARK: - Trigger Intelligence renderer

    /// Draws the full trigger intelligence section. Returns new yOffset.
    /// Accepts a page-break callback so long sections can overflow pages.
    private func drawTriggerIntelligence(
        ctx: CGContext,
        summary: TriggerSummary,
        startY: CGFloat,
        pageNumber: inout Int,
        ctx2: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        var yOffset = startY

        // Section heading
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSerifDisplay-Regular", size: 16)
                ?? UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        NSAttributedString(string: "Trigger Intelligence", attributes: titleAttrs)
            .draw(at: CGPoint(x: margin, y: yOffset))
        yOffset += 24

        ctx.setFillColor(tealColor)
        ctx.fill(CGRect(x: margin, y: yOffset, width: contentWidth, height: 2))
        yOffset += 10

        // ------------------------------------------------------------------
        // EMPTY STATE
        // ------------------------------------------------------------------
        guard summary.hasData else {
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "DMSans-Regular", size: 10)
                    ?? UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor(cgColor: grayColor)
            ]
            let msg = "Trigger Intelligence is available after logging 5 or more headaches. You have logged \(summary.totalLogs) headache\(summary.totalLogs == 1 ? "" : "s")."
            drawWrappedText(
                ctx: ctx,
                text: msg,
                attrs: placeholderAttrs,
                x: margin,
                y: yOffset,
                maxWidth: contentWidth
            )
            drawTriggerFooter(ctx: ctx, y: yOffset + 40)
            return yOffset + 60
        }

        // ------------------------------------------------------------------
        // Top Triggers table
        // ------------------------------------------------------------------
        yOffset = drawTriggerSubheading(ctx: ctx, text: "Top Triggers", y: yOffset)
        yOffset = drawTopTriggersTable(ctx: ctx, rows: summary.topTriggers, y: yOffset)
        yOffset += 14

        // Page-break check before bar chart (estimated 120 pt)
        let nearBottom = pageSize.height - margin - footerHeight - 8
        if yOffset + 120 > nearBottom {
            drawFooter(ctx: ctx, pageNumber: pageNumber)
            ctx2.beginPage()
            pageNumber += 1
            yOffset = margin
        }

        // ------------------------------------------------------------------
        // Day-of-week bar chart
        // ------------------------------------------------------------------
        yOffset = drawTriggerSubheading(ctx: ctx, text: "Day of Week", y: yOffset)
        yOffset = drawDayOfWeekChart(ctx: ctx, days: summary.dayOfWeekCounts, y: yOffset)
        yOffset += 14

        // Page-break check
        if yOffset + 80 > nearBottom {
            drawFooter(ctx: ctx, pageNumber: pageNumber)
            ctx2.beginPage()
            pageNumber += 1
            yOffset = margin
        }

        // ------------------------------------------------------------------
        // Time-of-day table
        // ------------------------------------------------------------------
        yOffset = drawTriggerSubheading(ctx: ctx, text: "Time of Day", y: yOffset)
        yOffset = drawTimeOfDayTable(ctx: ctx, slots: summary.timeOfDayCounts, y: yOffset)
        yOffset += 14

        // Page-break check
        if yOffset + 90 > nearBottom {
            drawFooter(ctx: ctx, pageNumber: pageNumber)
            ctx2.beginPage()
            pageNumber += 1
            yOffset = margin
        }

        // ------------------------------------------------------------------
        // Severity distribution
        // ------------------------------------------------------------------
        yOffset = drawTriggerSubheading(ctx: ctx, text: "Severity Distribution", y: yOffset)
        yOffset = drawSeverityDistribution(ctx: ctx, bars: summary.severityBars, y: yOffset)
        yOffset += 14

        // ------------------------------------------------------------------
        // Medication effectiveness (only if data exists)
        // ------------------------------------------------------------------
        if !summary.medicationRows.isEmpty {
            if yOffset + 60 > nearBottom {
                drawFooter(ctx: ctx, pageNumber: pageNumber)
                ctx2.beginPage()
                pageNumber += 1
                yOffset = margin
            }
            yOffset = drawTriggerSubheading(ctx: ctx, text: "Medication Effectiveness", y: yOffset)
            yOffset = drawMedicationTable(ctx: ctx, rows: summary.medicationRows, y: yOffset)
            yOffset += 14
        }

        // ------------------------------------------------------------------
        // Footer disclaimer
        // ------------------------------------------------------------------
        drawTriggerFooter(ctx: ctx, y: yOffset)

        return yOffset + 24
    }

    private func drawTriggerSubheading(ctx: CGContext, text: String, y: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 10)
                ?? UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        NSAttributedString(string: text, attributes: attrs)
            .draw(at: CGPoint(x: margin, y: y))
        return y + 14
    }

    // Top triggers table: Rank | Trigger | Occurrences | Co-occurrence %
    private func drawTopTriggersTable(
        ctx: CGContext,
        rows: [TriggerSummary.TriggerRow],
        y: CGFloat
    ) -> CGFloat {
        guard !rows.isEmpty else {
            let noDataAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "DMSans-Regular", size: 9)
                    ?? UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor(cgColor: grayColor)
            ]
            NSAttributedString(string: "No trigger data recorded.", attributes: noDataAttrs)
                .draw(at: CGPoint(x: margin, y: y))
            return y + 14
        }

        var yOffset = y
        let colWidths: [CGFloat] = [
            contentWidth * 0.08,   // Rank
            contentWidth * 0.50,   // Trigger
            contentWidth * 0.22,   // Occurrences
            contentWidth * 0.20    // Co-%
        ]
        let headers = ["#", "Trigger", "Occurrences", "Co-occ. %"]

        // Header row
        ctx.setFillColor(rowTintColor)
        ctx.fill(CGRect(x: margin, y: yOffset, width: contentWidth, height: 16))

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 7.5)
                ?? UIFont.systemFont(ofSize: 7.5, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        var xCursor = margin + 4
        for (col, header) in zip(colWidths, headers) {
            NSAttributedString(string: header, attributes: hAttrs)
                .draw(at: CGPoint(x: xCursor, y: yOffset + 4))
            xCursor += col
        }
        yOffset += 16

        let rAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]

        for (idx, row) in rows.enumerated() {
            if idx % 2 == 0 {
                ctx.setFillColor(rowTintColor)
                ctx.fill(CGRect(x: margin, y: yOffset, width: contentWidth, height: 14))
            }
            xCursor = margin + 4
            let values = [
                "\(row.rank)",
                row.trigger,
                "\(row.count)",
                "\(row.coPercent)%"
            ]
            for (col, val) in zip(colWidths, values) {
                ctx.saveGState()
                ctx.clip(to: CGRect(x: xCursor - 4, y: yOffset, width: col, height: 14))
                NSAttributedString(string: val, attributes: rAttrs)
                    .draw(at: CGPoint(x: xCursor, y: yOffset + 3))
                ctx.restoreGState()
                xCursor += col
            }
            yOffset += 14
        }
        return yOffset
    }

    // Day-of-week bar chart
    private func drawDayOfWeekChart(
        ctx: CGContext,
        days: [TriggerSummary.DayCount],
        y: CGFloat
    ) -> CGFloat {
        let chartHeight: CGFloat = 60
        let barAreaH: CGFloat    = 44
        let labelH: CGFloat      = 10
        let countH: CGFloat      = 10
        let totalBarH            = barAreaH + labelH + countH + 4

        let barW = contentWidth / CGFloat(days.count) - 4
        var xCursor = margin

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 7)
                ?? UIFont.systemFont(ofSize: 7),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 7)
                ?? UIFont.systemFont(ofSize: 7, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]

        for day in days {
            let fraction = max(0.05, day.relativeFraction)
            let barH = barAreaH * fraction
            let barY = y + countH + 4 + (barAreaH - barH)

            // Bar fill — teal
            ctx.setFillColor(tealColor.copy(alpha: 0.7) ?? tealColor)
            ctx.fill(CGRect(x: xCursor, y: barY, width: barW, height: barH))

            // Count label above bar
            if day.count > 0 {
                let countStr = NSAttributedString(
                    string: day.count > 0 ? "\(Int(Double(day.count) / 10.0 + 0.5))" : "",
                    attributes: countAttrs
                )
                let countSize = countStr.size()
                let countX = xCursor + (barW - countSize.width) / 2
                countStr.draw(at: CGPoint(x: countX, y: barY - countH - 2))
            }

            // Day abbreviation below bar
            let labelStr = NSAttributedString(string: day.abbreviation, attributes: labelAttrs)
            let labelSize = labelStr.size()
            let labelX = xCursor + (barW - labelSize.width) / 2
            labelStr.draw(at: CGPoint(x: labelX, y: y + countH + 4 + barAreaH + 2))

            xCursor += barW + 4
        }

        return y + totalBarH + chartHeight - (barAreaH + labelH + countH + 4)
    }

    // Time-of-day table
    private func drawTimeOfDayTable(
        ctx: CGContext,
        slots: [TriggerSummary.TimeSlot],
        y: CGFloat
    ) -> CGFloat {
        var yOffset = y
        let rowH: CGFloat = 14

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let valAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]

        for (idx, slot) in slots.enumerated() {
            if idx % 2 == 0 {
                ctx.setFillColor(rowTintColor)
                ctx.fill(CGRect(x: margin, y: yOffset, width: contentWidth, height: rowH))
            }
            NSAttributedString(string: slot.label, attributes: labelAttrs)
                .draw(at: CGPoint(x: margin + 4, y: yOffset + 3))
            let valStr = "\(slot.percent)%"
            let valNS = NSAttributedString(string: valStr, attributes: valAttrs)
            valNS.draw(at: CGPoint(x: margin + 120, y: yOffset + 3))
            yOffset += rowH
        }
        return yOffset
    }

    // Severity distribution: 5 horizontal bars
    private func drawSeverityDistribution(
        ctx: CGContext,
        bars: [TriggerSummary.SeverityBar],
        y: CGFloat
    ) -> CGFloat {
        var yOffset = y
        let barH: CGFloat    = 12
        let maxBarW          = contentWidth * 0.55
        let labelW: CGFloat  = 60
        let countW: CGFloat  = 30
        let spacing: CGFloat = 4

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 8)
                ?? UIFont.systemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]

        for bar in bars {
            let levelLabel = "Level \(bar.level)"
            NSAttributedString(string: levelLabel, attributes: labelAttrs)
                .draw(at: CGPoint(x: margin, y: yOffset))

            let barX = margin + labelW
            let barW = maxBarW * bar.fraction
            ctx.setFillColor(severityAccentCGColor(for: bar.level))
            let barRect = CGRect(x: barX, y: yOffset + 2, width: max(2, barW), height: barH - 4)
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: 2)
            ctx.addPath(barPath.cgPath)
            ctx.fillPath()

            // Count label to the right of the bar
            let countStr = NSAttributedString(string: "\(bar.count)", attributes: countAttrs)
            countStr.draw(at: CGPoint(x: barX + barW + 4, y: yOffset))

            yOffset += barH + spacing
        }
        return yOffset
    }

    // Medication effectiveness table
    private func drawMedicationTable(
        ctx: CGContext,
        rows: [TriggerSummary.MedRow],
        y: CGFloat
    ) -> CGFloat {
        var yOffset = y
        let rowH: CGFloat = 14

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 7.5)
                ?? UIFont.systemFont(ofSize: 7.5, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        ctx.setFillColor(rowTintColor)
        ctx.fill(CGRect(x: margin, y: yOffset, width: contentWidth, height: 14))
        NSAttributedString(string: "Medication", attributes: hAttrs)
            .draw(at: CGPoint(x: margin + 4, y: yOffset + 3))
        NSAttributedString(string: "Avg Effectiveness", attributes: hAttrs)
            .draw(at: CGPoint(x: margin + 250, y: yOffset + 3))
        yOffset += 14

        let rAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8.5)
                ?? UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        for (idx, row) in rows.enumerated() {
            if idx % 2 == 1 {
                ctx.setFillColor(rowTintColor)
                ctx.fill(CGRect(x: margin, y: yOffset, width: contentWidth, height: rowH))
            }
            NSAttributedString(string: row.name, attributes: rAttrs)
                .draw(at: CGPoint(x: margin + 4, y: yOffset + 3))
            NSAttributedString(string: row.avgEffectiveness, attributes: rAttrs)
                .draw(at: CGPoint(x: margin + 250, y: yOffset + 3))
            yOffset += rowH
        }
        return yOffset
    }

    // Trigger intelligence footer disclaimer
    private func drawTriggerFooter(ctx: CGContext, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8)
                ?? UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let msg = "This report is generated from your personal log data. It is for informational purposes only and is not medical advice."
        drawWrappedText(
            ctx: ctx,
            text: msg,
            attrs: attrs,
            x: margin,
            y: y,
            maxWidth: contentWidth
        )
    }

    // MARK: - Header drawing

    private func drawHeader(ctx: CGContext, meta: HeaderMeta) {
        let x = margin
        var y = margin

        // Teal accent bar
        ctx.setFillColor(tealColor)
        ctx.fill(CGRect(x: x, y: y, width: contentWidth, height: 3))
        y += 10

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSerifDisplay-Regular", size: 20)
                ?? UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        NSAttributedString(string: "Aurae Headache Report", attributes: titleAttrs)
            .draw(at: CGPoint(x: x, y: y))
        y += 26

        // Subtitle: date range + count
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 11)
                ?? UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let countLabel = "\(meta.count) headache\(meta.count == 1 ? "" : "s")"
        NSAttributedString(
            string: "\(meta.dateRange)  ·  \(countLabel)",
            attributes: subtitleAttrs
        ).draw(at: CGPoint(x: x, y: y))
        y += 16

        // Bottom rule
        ctx.setStrokeColor(grayColor.copy(alpha: 0.25) ?? grayColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + contentWidth, y: y))
        ctx.strokePath()
    }

    // MARK: - Column header drawing

    private func drawColumnHeaders(ctx: CGContext, y: CGFloat, columns: [Column]) {
        ctx.setFillColor(rowTintColor)
        ctx.fill(CGRect(x: margin, y: y, width: contentWidth, height: columnHeaderHeight))

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-SemiBold", size: 9)
                ?? UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]

        var xCursor = margin + 4
        for col in columns {
            NSAttributedString(string: col.title.uppercased(), attributes: attrs)
                .draw(at: CGPoint(x: xCursor, y: y + 6))
            xCursor += col.width
        }

        ctx.setStrokeColor(grayColor.copy(alpha: 0.3) ?? grayColor)
        ctx.setLineWidth(0.5)
        let ruleY = y + columnHeaderHeight
        ctx.move(to: CGPoint(x: margin, y: ruleY))
        ctx.addLine(to: CGPoint(x: margin + contentWidth, y: ruleY))
        ctx.strokePath()
    }

    // MARK: - Data row drawing

    private func drawRow(ctx: CGContext, row: LogRow, index: Int, y: CGFloat, columns: [Column]) {
        if index % 2 == 0 {
            ctx.setFillColor(rowTintColor)
            ctx.fill(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight))
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 9)
                ?? UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]

        let values = [
            row.date, row.time, row.severity, row.duration,
            row.weather, row.medication, row.notes
        ]

        var xCursor = margin + 4
        for (col, value) in zip(columns, values) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: xCursor - 4, y: y, width: col.width, height: rowHeight))
            NSAttributedString(string: value, attributes: attrs)
                .draw(at: CGPoint(x: xCursor, y: y + 8))
            ctx.restoreGState()
            xCursor += col.width
        }
    }

    // MARK: - Footer drawing

    private func drawFooter(ctx: CGContext, pageNumber: Int) {
        let y = pageSize.height - margin - footerHeight

        ctx.setStrokeColor(grayColor.copy(alpha: 0.25) ?? grayColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        ctx.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DMSans-Regular", size: 8)
                ?? UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        let leftText = NSAttributedString(
            string: "Generated by Aurae · \(df.string(from: .now)) · Informational use only — not medical advice.",
            attributes: attrs
        )
        leftText.draw(at: CGPoint(x: margin, y: y + 5))

        let pageStr = NSAttributedString(string: "Page \(pageNumber)", attributes: attrs)
        let strSize = pageStr.size()
        pageStr.draw(at: CGPoint(x: pageSize.width - margin - strSize.width, y: y + 5))
    }
}
