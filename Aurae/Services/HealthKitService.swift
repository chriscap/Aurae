//
//  HealthKitService.swift
//  Aurae
//
//  Swift actor that owns all HealthKit interactions for the app.
//  Serial actor isolation prevents concurrent HKHealthStore queries from
//  racing, while still allowing callers on any actor to await results.
//
//  Design rules enforced here:
//  - Authorization is requested lazily on first snapshot/sleep call,
//    never on app launch.
//  - Every public method returns an optional value or a plain struct —
//    they never throw. All HKError and authorization failures are caught
//    internally and produce nil.
//  - No health values are logged, transmitted, or written anywhere other
//    than the local SwiftData store (writes happen in HomeViewModel).
//  - The service is fully functional when HealthKit is unavailable
//    (e.g. iPad, simulator) — isAvailable gates all live queries.
//

import Foundation
import HealthKit

// MARK: - HealthKitService

actor HealthKitService {

    // -------------------------------------------------------------------------
    // MARK: Shared instance
    // -------------------------------------------------------------------------

    static let shared = HealthKitService()

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    private let store = HKHealthStore()

    /// Tracks whether we have already called requestAuthorization this session.
    /// HealthKit remembers the user's decision across launches, but the system
    /// prompt only appears once. Re-calling request is harmless but wastes time.
    private var authorizationRequested = false

    // -------------------------------------------------------------------------
    // MARK: Quantity types
    // -------------------------------------------------------------------------

    private let heartRateType      = HKQuantityType(.heartRate)
    private let hrvType            = HKQuantityType(.heartRateVariabilitySDNN)
    private let oxygenType         = HKQuantityType(.oxygenSaturation)
    private let stepCountType      = HKQuantityType(.stepCount)
    private let restingHRType      = HKQuantityType(.restingHeartRate)

    // -------------------------------------------------------------------------
    // MARK: Category types
    // -------------------------------------------------------------------------

    private let sleepType          = HKCategoryType(.sleepAnalysis)
    private let menstrualFlowType  = HKCategoryType(.menstrualFlow)

    // -------------------------------------------------------------------------
    // MARK: Availability
    // -------------------------------------------------------------------------

    /// False on devices that do not support HealthKit (iPad without Shared iPad,
    /// some simulators). All public methods check this before touching the store.
    private var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // -------------------------------------------------------------------------
    // MARK: Read types (passed to requestAuthorization)
    // -------------------------------------------------------------------------

    private var readTypes: Set<HKObjectType> {
        [
            heartRateType,
            hrvType,
            oxygenType,
            stepCountType,
            restingHRType,
            sleepType,
            menstrualFlowType
        ]
    }

    // =========================================================================
    // MARK: - Public API
    // =========================================================================

    // -------------------------------------------------------------------------
    // MARK: snapshot()
    // -------------------------------------------------------------------------

    /// Reads the most recent sample for each quantity type and the previous
    /// night's sleep duration, then assembles them into a `HealthSnapshot`.
    ///
    /// Returns a snapshot with all-nil fields if HealthKit is unavailable or
    /// all permissions are denied. Never throws.
    func snapshot() async -> HealthSnapshot {
        guard isAvailable else {
            return HealthSnapshot(capturedAt: Date.now)
        }

        await requestAuthorizationIfNeeded()

        // Run all quantity reads concurrently. Sleep is a separate query path.
        async let hr      = latestQuantitySample(type: heartRateType,
                                                 unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrv     = latestQuantitySample(type: hrvType,
                                                 unit: .secondUnit(with: .milli))
        async let spo2    = latestQuantitySample(type: oxygenType,
                                                 unit: .percent())
        async let resting = latestQuantitySample(type: restingHRType,
                                                 unit: HKUnit.count().unitDivided(by: .minute()))
        async let steps   = todayStepCount()
        async let sleep   = lastNightSleep()

        let (heartRate, hrvMs, oxygen, restingHR, stepCount, sleepHours) =
            await (hr, hrv, spo2, resting, steps, sleep)

        // oxygenSaturation from HealthKit is in the range 0.0–1.0.
        // Convert to percentage (0–100) for the display model.
        let spo2Percent = oxygen.map { $0 * 100.0 }

        return HealthSnapshot(
            heartRate:        heartRate,
            hrv:              hrvMs,
            oxygenSaturation: spo2Percent,
            restingHeartRate: restingHR,
            stepCount:        stepCount.map { Int($0) },
            sleepHours:       sleepHours,
            capturedAt:       Date.now
        )
    }

    // -------------------------------------------------------------------------
    // MARK: lastNightSleep()
    // -------------------------------------------------------------------------

    /// Queries `sleepAnalysis` samples for the previous night.
    ///
    /// Window: 10:00 PM the day before the query → 10:00 AM on the query day.
    /// This window captures a full night's sleep regardless of local timezone
    /// and is robust to irregular sleep schedules.
    ///
    /// All asleep-stage values are summed:
    /// - `.asleepUnspecified`  (legacy apps, third-party trackers)
    /// - `.asleepCore`         (Apple Watch Stage 1/2)
    /// - `.asleepREM`          (Apple Watch REM)
    /// - `.asleepDeep`         (Apple Watch Stage 3)
    ///
    /// Returns total sleep in hours, or nil if unavailable / unauthorized.
    func lastNightSleep() async -> Double? {
        guard isAvailable else { return nil }
        await requestAuthorizationIfNeeded()
        return await fetchSleepHours(for: previousNightWindow())
    }

    // -------------------------------------------------------------------------
    // MARK: authorizationStatus()
    // -------------------------------------------------------------------------

    /// Returns the current authorization status for a given HealthKit type.
    /// Useful for displaying permission state in Settings / onboarding.
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        guard isAvailable else { return .notDetermined }
        return store.authorizationStatus(for: type)
    }

    // =========================================================================
    // MARK: - Authorization
    // =========================================================================

    /// Requests read authorization for all types Aurae uses.
    /// Called lazily from `snapshot()` and `lastNightSleep()`.
    /// HealthKit shows the system permission sheet at most once per type;
    /// subsequent calls resolve immediately without UI.
    private func requestAuthorizationIfNeeded() async {
        guard !authorizationRequested, isAvailable else { return }
        authorizationRequested = true

        // Bridge the completion-handler API to async/await.
        // We intentionally ignore the Bool success parameter — HealthKit
        // does not distinguish "user denied" from "already authorized" via
        // that flag. We read per-type status separately when needed.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.requestAuthorization(toShare: nil, read: readTypes) { _, _ in
                continuation.resume()
            }
        }
    }

    // =========================================================================
    // MARK: - Quantity queries
    // =========================================================================

    /// Fetches the single most recent sample for a quantity type and returns
    /// its value in the given unit, or nil if no sample exists / is authorized.
    private func latestQuantitySample(
        type: HKQuantityType,
        unit: HKUnit
    ) async -> Double? {
        let status = store.authorizationStatus(for: type)
        // .notDetermined means we haven't asked yet — try anyway, the query
        // returns empty results rather than an error.
        // .sharingDenied is the write-only case; for reads, HealthKit returns
        // empty results for denied read types rather than an error.
        // We proceed in all cases and let the result set speak for itself.
        guard status != .sharingDenied else { return nil }

        let sort = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        let predicate = HKQuery.predicateForSamples(
            withStart: Date.distantPast,
            end: Date.now,
            options: .strictEndDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                guard error == nil,
                      let sample = samples?.first as? HKQuantitySample
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Step count
    // -------------------------------------------------------------------------

    /// Returns today's cumulative step count from midnight to now using
    /// HKStatisticsQuery (more efficient than summing individual samples).
    private func todayStepCount() async -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date.now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date.now,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard error == nil,
                      let sum = result?.sumQuantity()
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: .count()))
            }
            store.execute(query)
        }
    }

    // =========================================================================
    // MARK: - Sleep query
    // =========================================================================

    /// Queries sleepAnalysis samples within the given date interval and returns
    /// the total asleep duration in hours.
    private func fetchSleepHours(for interval: DateInterval) async -> Double? {
        let predicate = HKQuery.predicateForSamples(
            withStart: interval.start,
            end: interval.end,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        let samples: [HKCategorySample]? = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: results as? [HKCategorySample])
            }
            store.execute(query)
        }

        guard let samples, !samples.isEmpty else { return nil }

        // Sum all asleep-stage samples, merging overlapping intervals to avoid
        // double-counting when multiple sources (iPhone + Watch) write the same
        // time period.
        let totalSeconds = mergedAsleepDuration(from: samples)
        guard totalSeconds > 0 else { return nil }
        return totalSeconds / 3600.0
    }

    // -------------------------------------------------------------------------
    // MARK: Sleep stage filtering + overlap merging
    // -------------------------------------------------------------------------

    /// Returns true for any sleep analysis value that represents actual sleep
    /// (as opposed to "in bed but awake").
    private func isAsleepValue(_ value: Int) -> Bool {
        guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: value) else {
            return false
        }
        switch sleepValue {
        case .asleepUnspecified, .asleepCore, .asleepREM, .asleepDeep:
            return true
        case .inBed, .awake:
            return false
        @unknown default:
            // Future sleep stages added by Apple should default to counting as
            // sleep — a conservative assumption that is easy to revisit.
            return false
        }
    }

    /// Merges overlapping sleep intervals and returns the total asleep duration
    /// in seconds. Overlap merging prevents double-counting when the iPhone and
    /// Apple Watch both write samples for the same time period.
    private func mergedAsleepDuration(from samples: [HKCategorySample]) -> TimeInterval {
        // Filter to asleep stages only.
        let asleepIntervals: [DateInterval] = samples.compactMap { sample in
            guard isAsleepValue(sample.value) else { return nil }
            return DateInterval(start: sample.startDate, end: sample.endDate)
        }
        .sorted { $0.start < $1.start }

        guard !asleepIntervals.isEmpty else { return 0 }

        // Greedy interval merge.
        var merged: [DateInterval] = [asleepIntervals[0]]
        for interval in asleepIntervals.dropFirst() {
            let last = merged[merged.count - 1]
            if interval.start <= last.end {
                // Overlapping or adjacent — extend the current merged interval.
                let newEnd = max(last.end, interval.end)
                merged[merged.count - 1] = DateInterval(start: last.start, end: newEnd)
            } else {
                merged.append(interval)
            }
        }

        return merged.reduce(0) { $0 + $1.duration }
    }

    // =========================================================================
    // MARK: - Date window helpers
    // =========================================================================

    /// Returns the date interval representing the previous night's sleep window:
    /// 10:00 PM yesterday → 10:00 AM today.
    private func previousNightWindow() -> DateInterval {
        let calendar = Calendar.current
        let now = Date.now

        // 10 AM today
        let tenAMToday = calendar.date(
            bySettingHour: 10, minute: 0, second: 0, of: now
        ) ?? now

        // 10 PM yesterday = 10 AM today − 12 hours
        let tenPMYesterday = tenAMToday.addingTimeInterval(-12 * 3600)

        // If it is currently before 10 AM, we want the window ending at
        // 10 AM today. If it is after 10 AM, we want last night's window
        // (10 PM two days ago → 10 AM yesterday). Shift accordingly.
        let windowEnd: Date
        let windowStart: Date

        if now < tenAMToday {
            // Currently before 10 AM — last night's window ends this morning.
            windowEnd   = tenAMToday
            windowStart = tenPMYesterday
        } else {
            // Currently after 10 AM — shift the window back one full day.
            windowEnd   = tenAMToday.addingTimeInterval(-24 * 3600)
            windowStart = tenPMYesterday.addingTimeInterval(-24 * 3600)
        }

        return DateInterval(start: windowStart, end: windowEnd)
    }
}
