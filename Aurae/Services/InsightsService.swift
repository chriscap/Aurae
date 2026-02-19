//
//  InsightsService.swift
//  Aurae
//
//  Pure on-device pattern analysis. All computation is synchronous and
//  stateless — no network, no persistence, no side effects.
//
//  Input:  [HeadacheLog] (read on the calling actor — safe because HeadacheLog
//          is a SwiftData @Model read on @MainActor in InsightsViewModel)
//  Output: InsightsReport (a tree of value types — fully Sendable)
//
//  Privacy guarantee: no raw health values leave this function. The report
//  contains only aggregate statistics (averages, counts, correlations).
//
//  Minimum log threshold: 5 logs required. Below this, all correlation
//  fields default to empty/nil and the view shows a "keep logging" state.
//

import Foundation

// MARK: - Supporting types

// ---------------------------------------------------------------------------
// TimeOfDay
// ---------------------------------------------------------------------------

enum TimeOfDay: String, CaseIterable, Sendable {
    case morning   = "Morning"    // 06:00–11:59
    case afternoon = "Afternoon"  // 12:00–16:59
    case evening   = "Evening"    // 17:00–21:59
    case night     = "Night"      // 22:00–05:59

    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default:      return .night
        }
    }

    var icon: String {
        switch self {
        case .morning:   return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening:   return "sunset.fill"
        case .night:     return "moon.stars.fill"
        }
    }
}

// ---------------------------------------------------------------------------
// WeatherCorrelation
// ---------------------------------------------------------------------------

struct WeatherCorrelation: Identifiable, Sendable {
    let id: UUID
    let factor: String        // e.g. "Pressure drop"
    let correlation: String   // e.g. "Strong correlation"
    let description: String   // Full plain-language insight
    let sfSymbol: String      // Icon name for display
    let strength: Double      // 0–1, drives visual emphasis

    init(factor: String, correlation: String, description: String,
         sfSymbol: String, strength: Double) {
        self.id          = UUID()
        self.factor      = factor
        self.correlation = correlation
        self.description = description
        self.sfSymbol    = sfSymbol
        self.strength    = strength
    }
}

// ---------------------------------------------------------------------------
// SleepCorrelation
// ---------------------------------------------------------------------------

struct SleepCorrelation: Sendable {
    /// Average sleep hours on days rated severity ≥ 4 (bad days)
    let avgSleepOnBadDays: Double
    /// Average sleep hours on days rated severity ≤ 2 (good days)
    let avgSleepOnGoodDays: Double
    /// Plain-language insight derived from the comparison
    let insight: String
}

// ---------------------------------------------------------------------------
// InsightsReport
// ---------------------------------------------------------------------------

struct InsightsReport: Sendable {

    // Guard: returns true when the report is backed by enough data to be
    // meaningful. The view checks this before rendering correlation sections.
    let minimumLogsRequired: Int
    let totalLogs: Int

    var minimumLogsMet: Bool { totalLogs >= minimumLogsRequired }

    // Summary
    let averageSeverity: Double
    let averageDuration: TimeInterval?   // nil if no resolved logs

    /// Current consecutive headache-free streak ending today, in whole days.
    let streakDays: Int

    // Triggers & symptoms (top 5 by frequency)
    let mostCommonTriggers: [(trigger: String, count: Int)]
    let mostCommonSymptoms: [(symptom: String, count: Int)]

    // Temporal patterns
    /// Calendar.weekday index (1 = Sunday … 7 = Saturday) → avg severity
    let severityByDayOfWeek: [Int: Double]
    let severityByTimeOfDay: [TimeOfDay: Double]

    // Correlations
    let weatherCorrelations: [WeatherCorrelation]
    let sleepCorrelation: SleepCorrelation?

    // Medication
    /// Ranked by avg effectiveness descending; only entries with ≥2 data points
    let medicationEffectiveness: [(name: String, avgEffectiveness: Double)]

    /// Day-level headache frequency for the trailing 90 days.
    /// Key = start of day (midnight), value = number of logs that day.
    let headacheFrequency: [Date: Int]

    // Empty report — shown when totalLogs < minimumLogsRequired
    static func empty(totalLogs: Int, minimum: Int) -> InsightsReport {
        InsightsReport(
            minimumLogsRequired: minimum,
            totalLogs: totalLogs,
            averageSeverity: 0,
            averageDuration: nil,
            streakDays: 0,
            mostCommonTriggers: [],
            mostCommonSymptoms: [],
            severityByDayOfWeek: [:],
            severityByTimeOfDay: [:],
            weatherCorrelations: [],
            sleepCorrelation: nil,
            medicationEffectiveness: [],
            headacheFrequency: [:]
        )
    }
}

// MARK: - InsightsService

struct InsightsService {

    static let minimumLogs = 5

    // MARK: - Entry point

    /// Analyse the given logs and return a fully populated InsightsReport.
    /// Must be called on the same actor that owns the HeadacheLog models
    /// (always @MainActor via InsightsViewModel).
    func buildReport(from logs: [HeadacheLog]) -> InsightsReport {
        guard logs.count >= Self.minimumLogs else {
            return .empty(totalLogs: logs.count, minimum: Self.minimumLogs)
        }

        let resolved = logs.filter { !$0.isActive }

        return InsightsReport(
            minimumLogsRequired: Self.minimumLogs,
            totalLogs: logs.count,
            averageSeverity:          averageSeverity(logs: logs),
            averageDuration:          averageDuration(resolved: resolved),
            streakDays:               currentStreak(logs: logs),
            mostCommonTriggers:       topTriggers(logs: logs),
            mostCommonSymptoms:       topSymptoms(logs: logs),
            severityByDayOfWeek:      severityByWeekday(logs: logs),
            severityByTimeOfDay:      severityByTimeOfDay(logs: logs),
            weatherCorrelations:      weatherCorrelations(logs: logs),
            sleepCorrelation:         sleepCorrelation(logs: logs),
            medicationEffectiveness:  medicationEffectiveness(logs: logs),
            headacheFrequency:        headacheFrequency(logs: logs)
        )
    }

    // MARK: - Severity

    private func averageSeverity(logs: [HeadacheLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        return Double(logs.map(\.severity).reduce(0, +)) / Double(logs.count)
    }

    // MARK: - Duration

    private func averageDuration(resolved: [HeadacheLog]) -> TimeInterval? {
        let durations = resolved.compactMap(\.duration)
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    // MARK: - Streak

    private func currentStreak(logs: [HeadacheLog]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        // Build a set of days that had at least one headache
        let headacheDays = Set(logs.map { cal.startOfDay(for: $0.onsetTime) })
        var streak = 0
        var day = today
        // Walk backwards; stop as soon as we hit a headache day
        while !headacheDays.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
            // Safety cap — avoid infinite loop on very sparse data
            if streak > 365 { break }
        }
        // Subtract 1: today itself counts as headache-free only if no log exists today
        return max(0, streak - 1)
    }

    // MARK: - Triggers

    private func topTriggers(logs: [HeadacheLog]) -> [(trigger: String, count: Int)] {
        var counts: [String: Int] = [:]
        for log in logs {
            guard let retro = log.retrospective else { continue }
            // Environmental triggers
            for t in retro.environmentalTriggers where !t.isEmpty {
                counts[displayName(trigger: t), default: 0] += 1
            }
            // Meals / food triggers
            for m in retro.meals where !m.isEmpty {
                counts[m.capitalized, default: 0] += 1
            }
            // Skipped meal
            if retro.skippedMeal {
                counts["Skipped meal", default: 0] += 1
            }
            // Stress
            if let stress = retro.stressLevel, stress >= 4 {
                counts["High stress", default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (trigger: $0.key, count: $0.value) }
    }

    private func topSymptoms(logs: [HeadacheLog]) -> [(symptom: String, count: Int)] {
        var counts: [String: Int] = [:]
        for log in logs {
            guard let retro = log.retrospective else { continue }
            for s in retro.symptoms where !s.isEmpty {
                counts[displayName(symptom: s), default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (symptom: $0.key, count: $0.value) }
    }

    // MARK: - Temporal patterns

    private func severityByWeekday(logs: [HeadacheLog]) -> [Int: Double] {
        let cal = Calendar.current
        var sums:   [Int: Int] = [:]
        var counts: [Int: Int] = [:]
        for log in logs {
            let wd = cal.component(.weekday, from: log.onsetTime)
            sums[wd, default: 0]   += log.severity
            counts[wd, default: 0] += 1
        }
        return sums.reduce(into: [:]) { result, pair in
            let (wd, sum) = pair
            if let n = counts[wd], n > 0 {
                result[wd] = Double(sum) / Double(n)
            }
        }
    }

    private func severityByTimeOfDay(logs: [HeadacheLog]) -> [TimeOfDay: Double] {
        var sums:   [TimeOfDay: Int] = [:]
        var counts: [TimeOfDay: Int] = [:]
        for log in logs {
            let tod = TimeOfDay.from(date: log.onsetTime)
            sums[tod, default: 0]   += log.severity
            counts[tod, default: 0] += 1
        }
        return sums.reduce(into: [:]) { result, pair in
            let (tod, sum) = pair
            if let n = counts[tod], n > 0 {
                result[tod] = Double(sum) / Double(n)
            }
        }
    }

    // MARK: - Weather correlations

    private func weatherCorrelations(logs: [HeadacheLog]) -> [WeatherCorrelation] {
        let withWeather = logs.compactMap { log -> (log: HeadacheLog, weather: WeatherSnapshot)? in
            guard let w = log.weather else { return nil }
            return (log, w)
        }
        guard withWeather.count >= 3 else { return [] }

        var correlations: [WeatherCorrelation] = []

        // Pressure drop correlation
        if let c = pressureDropCorrelation(pairs: withWeather) { correlations.append(c) }
        // Low pressure correlation
        if let c = lowPressureCorrelation(pairs: withWeather)  { correlations.append(c) }
        // High humidity correlation
        if let c = humidityCorrelation(pairs: withWeather)     { correlations.append(c) }
        // Temperature correlation
        if let c = temperatureCorrelation(pairs: withWeather)  { correlations.append(c) }

        return correlations
    }

    private func pressureDropCorrelation(
        pairs: [(log: HeadacheLog, weather: WeatherSnapshot)]
    ) -> WeatherCorrelation? {
        let fallingCount = pairs.filter { $0.weather.pressureTrend == "falling" }.count
        let total = pairs.count
        guard total > 0 else { return nil }
        let rate = Double(fallingCount) / Double(total)
        guard rate > 0.2 else { return nil }   // only report if meaningful

        let pct = Int(rate * 100)
        let strength = min(rate * 2, 1.0)
        let label = correlationLabel(strength: strength)
        return WeatherCorrelation(
            factor:      "Falling pressure",
            correlation: label,
            description: "\(pct)% of your headaches occurred when barometric pressure was falling.",
            sfSymbol:    "arrow.down.circle.fill",
            strength:    strength
        )
    }

    private func lowPressureCorrelation(
        pairs: [(log: HeadacheLog, weather: WeatherSnapshot)]
    ) -> WeatherCorrelation? {
        let lowPressure = pairs.filter { $0.weather.pressure < 1013 }
        guard !lowPressure.isEmpty else { return nil }
        let avgSevLow  = averageSev(pairs: lowPressure)
        let avgSevHigh = averageSev(pairs: pairs.filter { $0.weather.pressure >= 1013 })
        let diff = avgSevLow - avgSevHigh
        guard diff > 0.3 else { return nil }

        let strength = min(diff / 2.0, 1.0)
        return WeatherCorrelation(
            factor:      "Low pressure",
            correlation: correlationLabel(strength: strength),
            description: String(format: "Headaches are %.1f points more severe on average when pressure is below 1013 hPa.", diff),
            sfSymbol:    "gauge.low",
            strength:    strength
        )
    }

    private func humidityCorrelation(
        pairs: [(log: HeadacheLog, weather: WeatherSnapshot)]
    ) -> WeatherCorrelation? {
        let highHumidity = pairs.filter { $0.weather.humidity > 70 }
        guard highHumidity.count >= 2 else { return nil }
        let rate = Double(highHumidity.count) / Double(pairs.count)
        guard rate > 0.3 else { return nil }

        let strength = min(rate * 1.5, 1.0)
        return WeatherCorrelation(
            factor:      "High humidity",
            correlation: correlationLabel(strength: strength),
            description: String(format: "%d%% of your headaches occurred when humidity was above 70%%.", Int(rate * 100)),
            sfSymbol:    "humidity.fill",
            strength:    strength
        )
    }

    private func temperatureCorrelation(
        pairs: [(log: HeadacheLog, weather: WeatherSnapshot)]
    ) -> WeatherCorrelation? {
        let temps = pairs.map { $0.weather.temperature }
        guard let minT = temps.min(), let maxT = temps.max() else { return nil }
        let range = maxT - minT
        guard range > 10 else { return nil }   // needs enough spread to say anything

        let median = temps.sorted()[temps.count / 2]
        let hot = pairs.filter { $0.weather.temperature > median }
        let cold = pairs.filter { $0.weather.temperature <= median }
        let avgSevHot  = averageSev(pairs: hot)
        let avgSevCold = averageSev(pairs: cold)
        let diff = abs(avgSevHot - avgSevCold)
        guard diff > 0.3 else { return nil }

        let hotter = avgSevHot > avgSevCold
        let strength = min(diff / 2.0, 1.0)
        return WeatherCorrelation(
            factor:      hotter ? "High temperature" : "Low temperature",
            correlation: correlationLabel(strength: strength),
            description: String(format: "Headaches average %.1f points %@ severe in %@ weather.",
                diff,
                diff > 0 ? "more" : "less",
                hotter ? "warmer" : "colder"),
            sfSymbol:    "thermometer.medium",
            strength:    strength
        )
    }

    private func averageSev(pairs: [(log: HeadacheLog, weather: WeatherSnapshot)]) -> Double {
        guard !pairs.isEmpty else { return 0 }
        return Double(pairs.map(\.log.severity).reduce(0, +)) / Double(pairs.count)
    }

    // MARK: - Sleep correlation

    private func sleepCorrelation(logs: [HeadacheLog]) -> SleepCorrelation? {
        // Use retrospective sleepHours first; fall back to HealthKit snapshot.
        let badDaysSleep = logs
            .filter { $0.severity >= 4 }
            .compactMap { sleepHours(for: $0) }

        let goodDaysSleep = logs
            .filter { $0.severity <= 2 }
            .compactMap { sleepHours(for: $0) }

        guard badDaysSleep.count >= 2, goodDaysSleep.count >= 2 else { return nil }

        let avgBad  = badDaysSleep.reduce(0, +)  / Double(badDaysSleep.count)
        let avgGood = goodDaysSleep.reduce(0, +) / Double(goodDaysSleep.count)
        let diff = avgGood - avgBad

        let insight: String
        if diff > 0.5 {
            insight = String(format: "You sleep %.1f hour(s) more on headache-free days. Less sleep appears linked to more severe headaches.", diff)
        } else if diff < -0.5 {
            insight = String(format: "Sleep patterns appear similar across headache-free and high-severity days (%.1f h difference).", abs(diff))
        } else {
            insight = "Sleep duration shows little variation between headache-free and high-severity days."
        }

        return SleepCorrelation(
            avgSleepOnBadDays:  avgBad,
            avgSleepOnGoodDays: avgGood,
            insight:            insight
        )
    }

    private func sleepHours(for log: HeadacheLog) -> Double? {
        log.retrospective?.sleepHours ?? log.health?.sleepHours
    }

    // MARK: - Medication effectiveness

    private func medicationEffectiveness(logs: [HeadacheLog]) -> [(name: String, avgEffectiveness: Double)] {
        var scores: [String: [Int]] = [:]
        for log in logs {
            guard
                let retro = log.retrospective,
                let name  = retro.medicationName, !name.isEmpty,
                let score = retro.medicationEffectiveness
            else { continue }
            scores[name, default: []].append(score)
        }
        return scores
            .filter { $0.value.count >= 2 }   // minimum 2 data points for validity
            .map { name, vals in
                let avg = Double(vals.reduce(0, +)) / Double(vals.count)
                return (name: name, avgEffectiveness: avg)
            }
            .sorted { $0.avgEffectiveness > $1.avgEffectiveness }
    }

    // MARK: - Headache frequency (trailing 90 days)

    private func headacheFrequency(logs: [HeadacheLog]) -> [Date: Int] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -90, to: .now) ?? .now
        var freq: [Date: Int] = [:]
        for log in logs where log.onsetTime >= cutoff {
            let day = cal.startOfDay(for: log.onsetTime)
            freq[day, default: 0] += 1
        }
        return freq
    }

    // MARK: - Display name helpers

    private func displayName(trigger: String) -> String {
        switch trigger {
        case "strong_smell":    return "Strong smell"
        case "bright_light":    return "Bright light"
        case "loud_noise":      return "Loud noise"
        case "screen_glare":    return "Screen glare"
        case "weather_change":  return "Weather change"
        case "altitude":        return "Altitude"
        case "heat":            return "Heat"
        case "cold":            return "Cold"
        default:                return trigger.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func displayName(symptom: String) -> String {
        switch symptom {
        case "nausea":               return "Nausea"
        case "light_sensitivity":    return "Light sensitivity"
        case "sound_sensitivity":    return "Sound sensitivity"
        case "aura":                 return "Aura"
        case "neck_pain":            return "Neck pain"
        case "visual_disturbance":   return "Visual disturbance"
        case "vomiting":             return "Vomiting"
        case "dizziness":            return "Dizziness"
        default:                     return symptom.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // MARK: - Correlation label

    private func correlationLabel(strength: Double) -> String {
        switch strength {
        case 0.7...:  return "Strong correlation"
        case 0.4..<0.7: return "Moderate correlation"
        default:      return "Weak correlation"
        }
    }
}
