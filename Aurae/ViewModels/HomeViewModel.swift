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

    /// Blocks the Log button while an insert is in flight.
    var isLogging: Bool = false

    /// Non-nil while the confirmation overlay is visible.
    var confirmedLog: HeadacheLog? = nil

    /// Non-fatal insert error shown inline beneath the Log button.
    var loggingError: String? = nil

    /// Set after resolveHeadache() completes so HomeView can present
    /// the post-resolve retrospective sheet. Cleared when the sheet dismisses.
    var logPendingRetrospective: HeadacheLog? = nil

    // -------------------------------------------------------------------------
    // MARK: Derived display state (fed by HomeView's @Query result)
    // -------------------------------------------------------------------------

    /// Recency text shown in the activity pill, e.g. "Last headache: 3 days ago."
    var recentActivityText: String = "No headaches logged yet."

    /// The most recent log. Populated by updateRecentActivity(from:).
    /// Used to drive the active-headache banner and the resolve action.
    var mostRecentLog: HeadacheLog? = nil

    /// Days since the last resolved headache. nil when no resolved logs exist
    /// or a headache is currently active.
    var daysSinceLastHeadache: Int? = nil

    /// Weather snapshot from the most recent log, used by the ambient context card.
    var lastLogWeather: WeatherSnapshot? = nil

    /// Sleep hours from the most recent log's health snapshot, used by the ambient triptych.
    var lastSleepHours: Double? = nil

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
        lastLogWeather  = logs.first?.weather
        lastSleepHours  = logs.first?.health?.sleepHours

        let mostRecent = logs.first
        mostRecentLog  = mostRecent

        // D-29: daysSinceLastHeadache must be nil whenever an active headache
        // exists. Displaying a stale streak count during an active episode is
        // factually misleading. The right side of the header is empty while active.
        if mostRecent?.isActive == true {
            daysSinceLastHeadache = nil
        } else {
            let lastResolved = logs.first(where: { !$0.isActive })
            if let last = lastResolved {
                daysSinceLastHeadache = Calendar.current
                    .dateComponents([.day], from: last.onsetTime, to: .now).day
            } else {
                daysSinceLastHeadache = nil
            }
        }

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
    /// Called by LogHeadacheModal on submission. Severity and onset speed are
    /// captured interactively in the modal; location and symptoms are written
    /// into a partial RetrospectiveEntry so the retrospective form pre-populates
    /// them as already-selected on next open.
    ///
    /// Guards:
    /// - Ignores the call if isLogging (double-tap prevention).
    /// - Ignores the call if a headache is already active.
    func logHeadache(
        severity:   SeverityLevel,
        onsetSpeed: OnsetSpeed?,
        location:   String,
        symptoms:   [String],
        context:    ModelContext
    ) {
        guard !isLogging, !hasActiveHeadache else { return }

        isLogging    = true
        loggingError = nil

        let log = HeadacheLog(
            onsetTime: Date.now,
            severity:  severity.rawValue
        )
        // D-33: capture onset speed at log time.
        log.onsetSpeed = onsetSpeed

        // Create a partial RetrospectiveEntry with any location/symptoms captured
        // in the modal. The full retrospective form reads this on next open,
        // showing those selections as already toggled on.
        if !location.isEmpty || !symptoms.isEmpty {
            let retro = RetrospectiveEntry(
                symptoms:         symptoms,
                headacheLocation: location.isEmpty ? nil : location
            )
            log.retrospective = retro
            context.insert(retro)
        }

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
        let logID       = log.id
        let logSeverity = log.severity
        let onsetTime   = log.onsetTime
        Task {
            await NotificationService.shared.scheduleFollowUp(
                logID:     logID,
                severity:  logSeverity,
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

        // Signal HomeView to present the post-resolve retrospective sheet.
        // LogDetailView has its own retrospective path and does not go through
        // this method, so this assignment only fires on the HomeView resolve path.
        logPendingRetrospective = log
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
        if snapshot.hasAnyData { return snapshot }
        #if DEBUG
        // Simulator has no real HealthKit data. Return a mock snapshot so
        // the health card is visible during development. No effect in production.
        return HealthSnapshot(
            heartRate:        72,
            hrv:              44,
            oxygenSaturation: 98,
            restingHeartRate: 64,
            stepCount:        4_200,
            sleepHours:       7.5
        )
        #else
        return nil
        #endif
    }

    // =========================================================================
    // MARK: - Confirmation dismissal
    // =========================================================================

    /// Called by LogConfirmationView once its auto-dismiss timer fires.
    func clearConfirmation() {
        confirmedLog = nil
    }
}
