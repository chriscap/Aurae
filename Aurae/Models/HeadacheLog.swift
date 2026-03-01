//
//  HeadacheLog.swift
//  Aurae
//
//  Primary SwiftData model. One instance represents a single headache episode
//  from onset through resolution and retrospective enrichment.
//
//  Relationships:
//   - weather:       @Relationship(.cascade) — deletes the snapshot with the log
//   - health:        @Relationship(.cascade)
//   - retrospective: @Relationship(.cascade)
//
//  The model is intentionally flat: related objects are separate @Model classes
//  (not embedded structs) so SwiftData can query and persist them independently.
//

import Foundation
import SwiftData

// MARK: - OnsetSpeed (D-33)

/// Describes how quickly a headache reached peak intensity at the time of logging.
/// Added at v1.6 (23 Feb 2026) per clinical requirement D-33.
///
/// The `.instantaneous` case maps to the ICHD-3 definition of thunderclap headache
/// (maximum intensity within 1 minute). The word "thunderclap" must NOT appear in any
/// user-facing copy — it implies diagnostic classification.
enum OnsetSpeed: String, Codable {
    case gradual        // "Gradually, over 30 minutes or more"
    case moderate       // "Quickly, within about 1 to 30 minutes"
    case instantaneous  // "Almost instantly, within seconds to about a minute"
}

@Model
final class HeadacheLog {

    // MARK: - Identity

    /// Stable identifier. Generated at the moment of onset and never changed.
    @Attribute(.unique) var id: UUID

    // MARK: - Core event

    /// When the headache started — set at the moment the user taps "Log Headache".
    var onsetTime: Date

    /// When the headache ended. Nil while the headache is still active.
    var resolvedTime: Date?

    /// Severity using the 1/3/5 three-level scale:
    ///   1 = Mild, 3 = Moderate, 5 = Severe (D-53, 2026-02-28).
    /// Values 2 and 4 are legacy; one-time migration converts them to 3 and 5
    /// respectively on first launch after this version.
    /// Default is 3 (Moderate).
    var severity: Int

    /// True while the headache episode is ongoing (resolvedTime == nil).
    /// This flag is denormalised to simplify predicate queries for active logs.
    var isActive: Bool

    // MARK: - Auto-captured context

    /// Weather data captured at onset. Nil if the weather fetch failed or
    /// location permission was denied.
    @Relationship(deleteRule: .cascade)
    var weather: WeatherSnapshot?

    /// Apple Health snapshot captured at onset. Nil if HealthKit access was
    /// denied or no recent readings were available.
    @Relationship(deleteRule: .cascade)
    var health: HealthSnapshot?

    // MARK: - Post-headache detail

    /// Retrospective data filled in after resolution. Nil until the user
    /// opens the retrospective flow.
    @Relationship(deleteRule: .cascade)
    var retrospective: RetrospectiveEntry?

    // MARK: - Clinical fields (v1.6)

    /// Onset speed selected by the user at log time (D-33).
    /// Nil when the user selects "Not sure" or does not answer.
    /// A nil value triggers no safety banner — it is always treated as no signal.
    var onsetSpeed: OnsetSpeed? = nil

    /// Per-log flag tracking whether the user has dismissed the red-flag safety
    /// banner for this specific log (D-31). Replaces the former global
    /// `hasSeenRedFlagBanner` @AppStorage boolean.
    /// Reset per-log so future triggering logs always show the banner fresh.
    var hasAcknowledgedRedFlag: Bool = false

    // MARK: - Metadata

    /// Timestamp when this record was created in SwiftData (equals onsetTime
    /// for fresh logs; may differ for retrospectively added entries).
    var createdAt: Date

    /// Timestamp of the most recent write to this record.
    var updatedAt: Date

    // MARK: - Init

    init(
        id: UUID = UUID(),
        onsetTime: Date = .now,
        severity: Int = 3,
        weather: WeatherSnapshot? = nil,
        health: HealthSnapshot? = nil,
        retrospective: RetrospectiveEntry? = nil
    ) {
        precondition((1...5).contains(severity), "Severity must be 1–5, got \(severity)")
        self.id            = id
        self.onsetTime     = onsetTime
        self.resolvedTime  = nil
        self.severity      = severity
        self.isActive      = true
        self.weather       = weather
        self.health        = health
        self.retrospective = retrospective
        self.createdAt     = .now
        self.updatedAt     = .now
    }
}

// MARK: - Lifecycle helpers

extension HeadacheLog {

    /// Marks the headache as resolved at the given time.
    /// Call this when the user taps "Mark as Resolved".
    func resolve(at time: Date = .now) {
        resolvedTime = time
        isActive     = false
        updatedAt    = .now
    }

    /// Duration of the episode. Returns nil while the headache is active.
    var duration: TimeInterval? {
        guard let resolved = resolvedTime else { return nil }
        return resolved.timeIntervalSince(onsetTime)
    }

    /// Formatted duration string (e.g. "2h 15m"). Nil while active.
    var formattedDuration: String? {
        guard let d = duration else { return nil }
        let totalMinutes = Int(d / 60)
        let hours   = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, let m): return "\(m)m"
        case (let h, 0): return "\(h)h"
        default:         return "\(hours)h \(minutes)m"
        }
    }

    /// Returns the `SeverityLevel` enum equivalent.
    /// Clamps to valid range defensively.
    var severityLevel: SeverityLevel {
        SeverityLevel(rawValue: max(1, min(5, severity))) ?? .moderate
    }
}

// MARK: - Predicate helpers

extension HeadacheLog {

    /// A predicate that matches only currently active (unresolved) logs.
    static var activeLogsPredicate: Predicate<HeadacheLog> {
        #Predicate<HeadacheLog> { $0.isActive == true }
    }

    /// A predicate that matches resolved logs within a given date range.
    static func logsPredicate(from start: Date, to end: Date) -> Predicate<HeadacheLog> {
        #Predicate<HeadacheLog> {
            $0.onsetTime >= start && $0.onsetTime <= end
        }
    }

    /// A predicate that matches logs at or above a given minimum severity.
    static func logsPredicate(minimumSeverity: Int) -> Predicate<HeadacheLog> {
        #Predicate<HeadacheLog> { $0.severity >= minimumSeverity }
    }
}
