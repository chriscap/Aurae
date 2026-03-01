//
//  InsightsViewModel.swift
//  Aurae
//
//  Drives InsightsView. Receives the log array from @Query in the view
//  (same pattern as HomeViewModel, HistoryViewModel, ExportViewModel) and
//  computes an InsightsReport asynchronously to keep the UI thread free.
//
//  Architecture note:
//  @Query lives in InsightsView. Results are passed to updateLogs(_:) via
//  .onAppear and .onChange so the VM remains a plain @Observable class with
//  no SwiftData dependency.
//

import Foundation
import Observation

// MARK: - InsightsViewModel

@Observable
@MainActor
final class InsightsViewModel {

    // MARK: - Output state

    /// The most recently computed report. nil during first computation.
    private(set) var report: InsightsReport? = nil

    /// True while the report is being computed in the background.
    private(set) var isLoading: Bool = false

    // MARK: - Derived

    var minimumLogsMet: Bool {
        report?.minimumLogsMet ?? false
    }

    var totalLogs: Int {
        report?.totalLogs ?? 0
    }

    // MARK: - Private

    private let service = InsightsService()
    private var computeTask: Task<Void, Never>? = nil

    // Snapshot type used to cross the actor boundary — all fields are
    // extracted from @Model objects on @MainActor before the Task.detached.
    struct LogSnapshot: Sendable {
        let severity:     Int
        let onsetTime:    Date
        let resolvedTime: Date?
        let isActive:     Bool
        // Weather
        let pressure:     Double?
        let pressureTrend: String?
        let humidity:     Double?
        let temperature:  Double?
        // Health
        let healthSleepHours: Double?
        // Retrospective
        let retro: RetroSnapshot?

        struct RetroSnapshot: Sendable {
            let environmentalTriggers: [String]
            let meals:                 [String]
            let skippedMeal:           Bool
            let stressLevel:           Int?
            let symptoms:              [String]
            let sleepHours:            Double?
            let medicationName:        String?
            let medicationEffectiveness: Int?
        }
    }

    // MARK: - Public API

    /// Called by InsightsView via .onAppear and .onChange(of: logs).
    func updateLogs(_ logs: [HeadacheLog]) {
        // Cancel any in-flight computation so we don't race.
        computeTask?.cancel()

        isLoading = true

        // Extract Sendable snapshots on @MainActor before handing off.
        let snapshots = logs.map { log -> LogSnapshot in
            let retro: LogSnapshot.RetroSnapshot? = log.retrospective.map { r in
                LogSnapshot.RetroSnapshot(
                    environmentalTriggers:     r.environmentalTriggers,
                    meals:                     r.meals,
                    skippedMeal:               r.skippedMeal,
                    stressLevel:               r.stressLevel,
                    symptoms:                  r.symptoms,
                    sleepHours:                r.sleepHours,
                    medicationName:            r.medicationName,
                    medicationEffectiveness:   r.medicationEffectiveness
                )
            }
            return LogSnapshot(
                severity:      log.severity,
                onsetTime:     log.onsetTime,
                resolvedTime:  log.resolvedTime,
                isActive:      log.isActive,
                pressure:      log.weather?.pressure,
                pressureTrend: log.weather?.pressureTrend,
                humidity:      log.weather?.humidity,
                temperature:   log.weather?.temperature,
                healthSleepHours: log.health?.sleepHours,
                retro:         retro
            )
        }

        computeTask = Task {
            let computed = await Task.detached(priority: .userInitiated) { [service] in
                service.buildReport(from: snapshots)
            }.value

            guard !Task.isCancelled else { return }
            self.report    = computed
            self.isLoading = false
        }
    }
}

// MARK: - InsightsService overload for Sendable snapshots

// InsightsService.buildReport works on [HeadacheLog] which is @MainActor-bound.
// This extension provides an identical overload that works on [LogSnapshot]
// so the heavy computation can run off the main thread.
//
// All logic is duplicated intentionally — the type system enforces that
// raw @Model objects never cross the actor boundary.

extension InsightsService {

    // swiftlint:disable function_body_length
    func buildReport(from snapshots: [InsightsViewModel.LogSnapshot]) -> InsightsReport {
        typealias S = InsightsViewModel.LogSnapshot
        typealias R = InsightsViewModel.LogSnapshot.RetroSnapshot

        guard snapshots.count >= Self.minimumLogs else {
            return .empty(totalLogs: snapshots.count, minimum: Self.minimumLogs)
        }

        let resolved = snapshots.filter { !$0.isActive }

        // Average severity
        let avgSeverity = snapshots.isEmpty ? 0.0
            : Double(snapshots.map(\.severity).reduce(0, +)) / Double(snapshots.count)

        // Average duration
        let durations: [TimeInterval] = resolved.compactMap { s in
            guard let r = s.resolvedTime else { return nil }
            return r.timeIntervalSince(s.onsetTime)
        }
        let avgDuration: TimeInterval? = durations.isEmpty ? nil
            : durations.reduce(0, +) / Double(durations.count)

        // Streak
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let headacheDays = Set(snapshots.map { cal.startOfDay(for: $0.onsetTime) })
        var streak = 0
        var day = today
        while !headacheDays.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
            if streak > 365 { break }
        }
        let streakDays = max(0, streak - 1)

        // Top triggers
        var triggerCounts: [String: Int] = [:]
        for s in snapshots {
            guard let r = s.retro else { continue }
            for t in r.environmentalTriggers where !t.isEmpty {
                triggerCounts[displayName(trigger: t), default: 0] += 1
            }
            for m in r.meals where !m.isEmpty {
                triggerCounts[m.capitalized, default: 0] += 1
            }
            if r.skippedMeal { triggerCounts["Skipped meal", default: 0] += 1 }
            if let stress = r.stressLevel, stress >= 4 {
                triggerCounts["High stress", default: 0] += 1
            }
        }
        let topTriggers = triggerCounts.sorted { $0.value > $1.value }
            .prefix(5).map { (trigger: $0.key, count: $0.value) }

        // Top symptoms
        var symptomCounts: [String: Int] = [:]
        for s in snapshots {
            guard let r = s.retro else { continue }
            for sym in r.symptoms where !sym.isEmpty {
                symptomCounts[displayName(symptom: sym), default: 0] += 1
            }
        }
        let topSymptoms = symptomCounts.sorted { $0.value > $1.value }
            .prefix(5).map { (symptom: $0.key, count: $0.value) }

        // Severity by weekday
        var wdSums:   [Int: Int] = [:]
        var wdCounts: [Int: Int] = [:]
        for s in snapshots {
            let wd = cal.component(.weekday, from: s.onsetTime)
            wdSums[wd, default: 0]   += s.severity
            wdCounts[wd, default: 0] += 1
        }
        let severityByWeekday: [Int: Double] = wdSums.reduce(into: [:]) { res, pair in
            if let n = wdCounts[pair.key], n > 0 {
                res[pair.key] = Double(pair.value) / Double(n)
            }
        }

        // Severity by time of day
        var todSums:   [TimeOfDay: Int] = [:]
        var todCounts: [TimeOfDay: Int] = [:]
        for s in snapshots {
            let tod = TimeOfDay.from(date: s.onsetTime)
            todSums[tod, default: 0]   += s.severity
            todCounts[tod, default: 0] += 1
        }
        let severityByTOD: [TimeOfDay: Double] = todSums.reduce(into: [:]) { res, pair in
            if let n = todCounts[pair.key], n > 0 {
                res[pair.key] = Double(pair.value) / Double(n)
            }
        }

        // Weather correlations (requires pressure/humidity fields)
        var weatherCorrelations: [WeatherCorrelation] = []
        let withWeather = snapshots.filter { $0.pressure != nil }
        if withWeather.count >= 3 {
            // Falling pressure
            let fallingCount = withWeather.filter { $0.pressureTrend == "falling" }.count
            let fallingRate  = Double(fallingCount) / Double(withWeather.count)
            if fallingRate > 0.2 {
                let str = min(fallingRate * 2, 1.0)
                weatherCorrelations.append(WeatherCorrelation(
                    factor:      "Falling pressure",
                    correlation: correlationLabel(strength: str),
                    description: "\(Int(fallingRate * 100))% of your headaches occurred when barometric pressure was falling.",
                    sfSymbol:    "arrow.down.circle.fill",
                    strength:    str
                ))
            }
            // Low pressure
            let lowP = withWeather.filter { ($0.pressure ?? 1013) < 1013 }
            if !lowP.isEmpty {
                let avgLow  = low_avg(lowP)
                let avgHigh = low_avg(withWeather.filter { ($0.pressure ?? 0) >= 1013 })
                let diff = avgLow - avgHigh
                if diff > 0.3 {
                    let str = min(diff / 2.0, 1.0)
                    weatherCorrelations.append(WeatherCorrelation(
                        factor:      "Low pressure",
                        correlation: correlationLabel(strength: str),
                        description: String(format: "Headaches are %.1f points more severe when pressure is below 1013 hPa.", diff),
                        sfSymbol:    "gauge.low",
                        strength:    str
                    ))
                }
            }
            // High humidity
            let hiHum = withWeather.filter { ($0.humidity ?? 0) > 70 }
            if hiHum.count >= 2 {
                let rate = Double(hiHum.count) / Double(withWeather.count)
                if rate > 0.3 {
                    let str = min(rate * 1.5, 1.0)
                    weatherCorrelations.append(WeatherCorrelation(
                        factor:      "High humidity",
                        correlation: correlationLabel(strength: str),
                        description: "\(Int(rate * 100))% of your headaches occurred when humidity exceeded 70%.",
                        sfSymbol:    "humidity.fill",
                        strength:    str
                    ))
                }
            }
        }

        // Sleep correlation
        let badSleep  = snapshots.filter { $0.severity >= 4 }.compactMap { $0.retro?.sleepHours ?? $0.healthSleepHours }
        let goodSleep = snapshots.filter { $0.severity <= 2 }.compactMap { $0.retro?.sleepHours ?? $0.healthSleepHours }
        var sleepCorr: SleepCorrelation? = nil
        if badSleep.count >= 2, goodSleep.count >= 2 {
            let avgBad  = badSleep.reduce(0, +)  / Double(badSleep.count)
            let avgGood = goodSleep.reduce(0, +) / Double(goodSleep.count)
            let diff = avgGood - avgBad
            let insight: String
            if diff > 0.5 {
                insight = String(format: "You sleep %.1f hour(s) more on headache-free days. Less sleep appears linked to more severe headaches.", diff)
            } else {
                insight = "Sleep duration shows little variation between headache-free and high-severity days."
            }
            sleepCorr = SleepCorrelation(avgSleepOnBadDays: avgBad, avgSleepOnGoodDays: avgGood, insight: insight)
        }

        // Medication effectiveness
        var medScores: [String: [Int]] = [:]
        for s in snapshots {
            guard let r = s.retro,
                  let name = r.medicationName, !name.isEmpty,
                  let eff = r.medicationEffectiveness else { continue }
            medScores[name, default: []].append(eff)
        }
        let medEffectiveness = medScores
            .filter { $0.value.count >= 2 }
            .map { name, vals -> (name: String, avgEffectiveness: Double) in
                let avg = Double(vals.reduce(0, +)) / Double(vals.count)
                return (name: name, avgEffectiveness: avg)
            }
            .sorted { $0.avgEffectiveness > $1.avgEffectiveness }

        // Headache frequency
        let cutoff = cal.date(byAdding: .day, value: -90, to: .now) ?? .now
        var freq: [Date: Int] = [:]
        for s in snapshots where s.onsetTime >= cutoff {
            let d = cal.startOfDay(for: s.onsetTime)
            freq[d, default: 0] += 1
        }

        // Severity distribution (categorical counts per level)
        var sevDist: [Int: Int] = [1: 0, 3: 0, 5: 0]
        for s in snapshots {
            let level = SeverityLevel(rawValue: max(1, min(5, s.severity))) ?? .moderate
            sevDist[level.rawValue, default: 0] += 1
        }

        return InsightsReport(
            minimumLogsRequired: Self.minimumLogs,
            totalLogs:           snapshots.count,
            averageSeverity:     avgSeverity,
            averageDuration:     avgDuration,
            streakDays:          streakDays,
            mostCommonTriggers:  topTriggers,
            mostCommonSymptoms:  topSymptoms,
            severityByDayOfWeek: severityByWeekday,
            severityByTimeOfDay: severityByTOD,
            weatherCorrelations: weatherCorrelations,
            sleepCorrelation:    sleepCorr,
            medicationEffectiveness: medEffectiveness,
            headacheFrequency:   freq,
            severityDistribution: sevDist
        )
    }
    // swiftlint:enable function_body_length

    private func low_avg(_ sn: [InsightsViewModel.LogSnapshot]) -> Double {
        guard !sn.isEmpty else { return 0 }
        return Double(sn.map(\.severity).reduce(0, +)) / Double(sn.count)
    }

    private func displayName(trigger: String) -> String {
        switch trigger {
        case "strong_smell":   return "Strong smell"
        case "bright_light":   return "Bright light"
        case "loud_noise":     return "Loud noise"
        case "screen_glare":   return "Screen glare"
        case "weather_change": return "Weather change"
        case "altitude":       return "Altitude"
        case "heat":           return "Heat"
        case "cold":           return "Cold"
        default:               return trigger.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func displayName(symptom: String) -> String {
        switch symptom {
        case "nausea":             return "Nausea"
        case "light_sensitivity":  return "Light sensitivity"
        case "sound_sensitivity":  return "Sound sensitivity"
        case "aura":               return "Aura"
        case "neck_pain":          return "Neck pain"
        case "visual_disturbance": return "Visual disturbance"
        case "vomiting":           return "Vomiting"
        case "dizziness":          return "Dizziness"
        default:                   return symptom.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // D-21 (22 Feb 2026): Statistical correlation language is prohibited.
    // Use frequency-based language to match InsightsService.correlationLabel().
    private func correlationLabel(strength: Double) -> String {
        switch strength {
        case 0.7...:     return "Frequently present"
        case 0.4..<0.7:  return "Sometimes present"
        default:         return "Occasionally present"
        }
    }
}
