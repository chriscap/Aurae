//
//  HealthSnapshot.swift
//  Aurae
//
//  SwiftData model representing a point-in-time capture of the user's Apple
//  Health data at the moment of headache onset. All fields are optional because:
//    1. HealthKit permissions may be partially granted or fully denied.
//    2. Not all users own an Apple Watch; HR / HRV data may be unavailable.
//    3. Apple Health may have no recent reading for a given type.
//
//  All raw health values are stored locally and never transmitted externally.
//

import Foundation
import SwiftData

@Model
final class HealthSnapshot {

    // MARK: - Cardiovascular

    /// Most recent heart rate reading in beats per minute.
    /// Sourced from HKQuantityTypeIdentifier.heartRate.
    var heartRate: Double?

    /// Heart Rate Variability (SDNN) in milliseconds.
    /// Sourced from HKQuantityTypeIdentifier.heartRateVariabilitySDNN.
    var hrv: Double?

    /// Blood oxygen saturation as a percentage (0–100).
    /// Sourced from HKQuantityTypeIdentifier.oxygenSaturation.
    var oxygenSaturation: Double?

    /// Resting heart rate in beats per minute (Apple's daily computed value).
    /// Sourced from HKQuantityTypeIdentifier.restingHeartRate.
    var restingHeartRate: Double?

    // MARK: - Activity

    /// Step count for the current day up to the moment of onset.
    /// Sourced from HKQuantityTypeIdentifier.stepCount.
    var stepCount: Int?

    // MARK: - Sleep

    /// Total sleep duration from the previous night, in hours.
    /// Derived from HKCategoryTypeIdentifier.sleepAnalysis samples.
    /// "Previous night" is defined as 6 PM the prior day to 10 AM on onset day.
    var sleepHours: Double?

    // MARK: - Provenance

    /// Timestamp when HealthKit was queried (differs from onset time by < 2 s).
    var capturedAt: Date

    // MARK: - Init

    init(
        heartRate: Double? = nil,
        hrv: Double? = nil,
        oxygenSaturation: Double? = nil,
        restingHeartRate: Double? = nil,
        stepCount: Int? = nil,
        sleepHours: Double? = nil,
        capturedAt: Date = .now
    ) {
        self.heartRate        = heartRate
        self.hrv              = hrv
        self.oxygenSaturation = oxygenSaturation
        self.restingHeartRate = restingHeartRate
        self.stepCount        = stepCount
        self.sleepHours       = sleepHours
        self.capturedAt       = capturedAt
    }
}

// MARK: - Display helpers

extension HealthSnapshot {

    /// Whether any cardiovascular metric was successfully captured.
    var hasCardiovascularData: Bool {
        heartRate != nil || hrv != nil || restingHeartRate != nil || oxygenSaturation != nil
    }

    /// Whether any data was captured at all.
    var hasAnyData: Bool {
        hasCardiovascularData || stepCount != nil || sleepHours != nil
    }

    /// Short human-readable summary for display in log cards.
    var displaySummary: String {
        var parts: [String] = []
        if let hr = heartRate          { parts.append("\(Int(hr)) bpm") }
        if let hrv = hrv               { parts.append("HRV \(Int(hrv)) ms") }
        if let spo2 = oxygenSaturation { parts.append("SpO2 \(Int(spo2))%") }
        if let sleep = sleepHours      { parts.append(String(format: "%.1f h sleep", sleep)) }
        return parts.isEmpty ? "No health data captured" : parts.joined(separator: "  ·  ")
    }

    /// Formatted sleep duration string, e.g. "7h 30m".
    var formattedSleepDuration: String? {
        guard let hours = sleepHours else { return nil }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
