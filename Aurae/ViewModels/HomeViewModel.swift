//
//  HomeViewModel.swift
//  Aurae
//
//  Owns all mutable state and business logic for HomeView.
//
//  Architecture:
//  - @Observable @MainActor — all stored properties drive SwiftUI re-renders
//    automatically; all SwiftData mutations stay on the main actor.
//  - Background capture (weather + health) runs concurrently via async let
//    and writes results back via MainActor.run. The UI never waits for it.
//  - Active-headache guard prevents duplicate logs while a headache is ongoing.
//  - resolveHeadache cancels the pending notification and persists the
//    resolved state in one atomic save.
//
//  Service wiring (all steps complete):
//    Step 4 — HealthKitService.shared.snapshot()
//    Steps 5 & 6 — LocationService → WeatherService
//    Step 7 — NotificationService.shared.scheduleFollowUp / cancelFollowUp
//

import SwiftUI
import SwiftData

// MARK: - Capture result

/// Plain value struct produced by the background capture task.
/// All stored properties are value types — safe across actor boundaries.
private struct CaptureResult: Sendable {
    var weather: WeatherSnapshot?
    var health: HealthSnapshot?
}

// MARK: - HomeViewModel

@Observable
@MainActor
final class HomeViewModel {

    // -------------------------------------------------------------------------
    // MARK: UI state
    // -------------------------------------------------------------------------

    /// Selected severity before tapping Log. Defaults to Moderate per PRD.
    var selectedSeverity: SeverityLevel = .moderate

    /// Blocks the Log button while an insert is in flight.
    var isLogging: Bool = false

    /// Non-nil while the confirmation overlay is visible.
    var confirmedLog: HeadacheLog? = nil

    /// Non-fatal insert error shown inline beneath the Log button.
    var loggingError: String? = nil

    // -------------------------------------------------------------------------
    // MARK: Derived display state (fed by HomeView's @Query result)
    // -------------------------------------------------------------------------

    /// Recency text shown in the activity pill, e.g. "Last headache: 3 days ago."
    var recentActivityText: String = "No headaches logged yet."

    /// The most recent log. Populated by updateRecentActivity(from:).
    /// Used to drive the active-headache banner and the resolve action.
    var mostRecentLog: HeadacheLog? = nil

    // -------------------------------------------------------------------------
    // MARK: Computed — greeting + date
    // -------------------------------------------------------------------------

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
        switch hour {
        case 5..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<21: return "Good evening."
        default:      return "Good night."
        }
    }

    var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMM."
        return fmt.string(from: Date.now)
    }

    // -------------------------------------------------------------------------
    // MARK: Computed — active headache guard
    // -------------------------------------------------------------------------

    /// True when the most recent log has not yet been resolved.
    /// HomeView uses this to suppress the severity selector and change the
    /// Log button to a "Mark as Resolved" button.
    var hasActiveHeadache: Bool {
        mostRecentLog?.isActive == true
    }

    // =========================================================================
    // MARK: - Recent activity
    // =========================================================================

    /// Called by HomeView's .onChange(of: logs) each time SwiftData delivers
    /// a new result set. Derives display strings without caching the array.
    func updateRecentActivity(from logs: [HeadacheLog]) {
        mostRecentLog = logs.first

        guard let latest = logs.first else {
            recentActivityText = "No headaches logged yet."
            return
        }

        if latest.isActive {
            recentActivityText = "Headache in progress."
            return
        }

        let days = Calendar.current.dateComponents(
            [.day], from: latest.onsetTime, to: Date.now
        ).day ?? 0

        switch days {
        case 0:  recentActivityText = "Last headache: today."
        case 1:  recentActivityText = "Last headache: yesterday."
        default: recentActivityText = "Last headache: \(days) days ago."
        }
    }

    // =========================================================================
    // MARK: - Log action
    // =========================================================================

    /// Creates a HeadacheLog, persists it, shows the confirmation overlay,
    /// schedules the follow-up notification, and fires background capture.
    ///
    /// Guards:
    /// - Ignores the tap if isLogging (double-tap prevention).
    /// - Ignores the tap if a headache is already active — HomeView wires
    ///   the button to resolveHeadache instead when hasActiveHeadache is true.
    func logHeadache(context: ModelContext) {
        guard !isLogging, !hasActiveHeadache else { return }

        isLogging    = true
        loggingError = nil

        let log = HeadacheLog(
            onsetTime: Date.now,
            severity:  selectedSeverity.rawValue
        )

        context.insert(log)
        do {
            try context.save()
        } catch {
            loggingError = "Could not save your log. Please try again."
            isLogging = false
            return
        }

        // Confirmation overlay appears immediately — the user is done.
        confirmedLog = log
        isLogging    = false

        // Schedule follow-up notification asynchronously — does not block UI.
        // preferredDelay is fetched inside the Task so it reflects any
        // UserDefaults value the user may have changed in Settings.
        let logID     = log.id
        let severity  = log.severity
        let onsetTime = log.onsetTime
        Task {
            await NotificationService.shared.scheduleFollowUp(
                logID:     logID,
                severity:  severity,
                onsetTime: onsetTime
            )
        }

        // Enrich the log with weather + health data in the background.
        fireBackgroundCapture(for: log, context: context)
    }

    // =========================================================================
    // MARK: - Resolve action
    // =========================================================================

    /// Marks the given log as resolved, persists the change, and cancels the
    /// pending follow-up notification. Called when the user taps
    /// "Mark as Resolved" on the active-headache banner.
    func resolveHeadache(_ log: HeadacheLog, context: ModelContext) {
        log.resolve(at: Date.now)
        try? context.save()

        // Cancel the follow-up notification — the headache is already resolved.
        let logID = log.id
        Task {
            await NotificationService.shared.cancelFollowUp(for: logID)
        }
    }

    // =========================================================================
    // MARK: - Background capture
    // =========================================================================

    /// Fires weather + health captures concurrently and writes results back to
    /// the persisted log on the main actor. Entirely non-blocking from the UI's
    /// perspective — confirmation has already been shown by this point.
    private func fireBackgroundCapture(for log: HeadacheLog, context: ModelContext) {
        Task {
            let result = await performCaptures()

            await MainActor.run {
                if let weather = result.weather {
                    log.weather = weather
                    context.insert(weather)
                }
                if let health = result.health {
                    log.health = health
                    context.insert(health)
                }
                log.updatedAt = Date.now
                try? context.save()
            }
        }
    }

    private nonisolated func performCaptures() async -> CaptureResult {
        async let weatherResult = captureWeather()
        async let healthResult  = captureHealth()
        let (weather, health) = await (weatherResult, healthResult)
        return CaptureResult(weather: weather, health: health)
    }

    private nonisolated func captureWeather() async -> WeatherSnapshot? {
        guard let coordinate = await LocationService.shared.requestLocation() else {
            return nil
        }
        return await WeatherService.shared.capture(
            latitude:  coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private nonisolated func captureHealth() async -> HealthSnapshot? {
        let snapshot = await HealthKitService.shared.snapshot()
        return snapshot.hasAnyData ? snapshot : nil
    }

    // =========================================================================
    // MARK: - Confirmation dismissal
    // =========================================================================

    /// Called by LogConfirmationView once its auto-dismiss timer fires.
    func clearConfirmation() {
        confirmedLog = nil
    }
}
