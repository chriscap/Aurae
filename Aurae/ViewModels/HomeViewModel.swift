//
//  HomeViewModel.swift
//  Aurae
//
//  Owns all mutable state and business logic for HomeView.
//
//  Architecture notes:
//  - @Observable (Swift 5.9 / iOS 17) replaces ObservableObject + @Published.
//    Views that read any stored property automatically re-render when it changes.
//  - All SwiftData mutations run on @MainActor (ModelContext is main-actor bound).
//  - Background capture tasks (weather, health) are fired concurrently with
//    async let and update the persisted log once results arrive. The UI never
//    waits for them — confirmation is shown the moment the log is inserted.
//  - Step 4 complete: captureHealth() calls HealthKitService.shared.snapshot().
//  - Step 5 (WeatherService) and Step 6 (LocationService) remain stubbed.
//

import SwiftUI
import SwiftData

// MARK: - Capture result (passed back to main actor after background work)

/// Plain value struct produced by the background capture task.
/// All types are value types so they cross actor boundaries safely.
private struct CaptureResult {
    var weather: WeatherSnapshot?
    var health: HealthSnapshot?
}

// MARK: - HomeViewModel

@Observable
@MainActor
final class HomeViewModel {

    // -------------------------------------------------------------------------
    // MARK: State read by HomeView
    // -------------------------------------------------------------------------

    /// Currently selected severity. Defaults to Moderate per PRD.
    var selectedSeverity: SeverityLevel = .moderate

    /// True while the log-insert is in flight (prevents double-tap).
    var isLogging: Bool = false

    /// Set to non-nil to trigger the confirmation overlay.
    /// Cleared after the overlay auto-dismisses.
    var confirmedLog: HeadacheLog? = nil

    /// Non-fatal error surfaced to the user if something unexpected goes wrong
    /// during logging. The app remains functional regardless.
    var loggingError: String? = nil

    // -------------------------------------------------------------------------
    // MARK: Derived display state (populated from the @Query result in HomeView)
    // -------------------------------------------------------------------------

    /// Human-readable recency string shown below the app name.
    /// HomeView calls `updateRecentActivity(from:)` whenever the query result changes.
    var recentActivityText: String = "No headaches logged yet."

    /// The most recent log, used to decide whether to show "Ongoing" banner.
    var mostRecentLog: HeadacheLog? = nil

    // -------------------------------------------------------------------------
    // MARK: Greeting
    // -------------------------------------------------------------------------

    /// Contextual greeting driven by the current hour.
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date.now)
        switch hour {
        case 5..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<21: return "Good evening."
        default:      return "Good night."
        }
    }

    /// Formatted date string for the home screen header, e.g. "Tuesday, 18 Feb."
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM."
        return formatter.string(from: Date.now)
    }

    // -------------------------------------------------------------------------
    // MARK: Recent activity
    // -------------------------------------------------------------------------

    /// Called by HomeView's `.onChange(of: logs)` whenever SwiftData delivers
    /// an updated result set. Derives the display string without storing the
    /// full array in the view model.
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

    // -------------------------------------------------------------------------
    // MARK: Log action
    // -------------------------------------------------------------------------

    /// Creates a HeadacheLog, persists it immediately, shows the confirmation
    /// overlay, then fires background capture without blocking the UI.
    ///
    /// - Parameter context: The SwiftData ModelContext injected from the view.
    func logHeadache(context: ModelContext) {
        guard !isLogging else { return }
        isLogging = true
        loggingError = nil

        let log = HeadacheLog(
            onsetTime: Date.now,
            severity: selectedSeverity.rawValue
        )

        // Insert synchronously — this is the only thing the user waits for.
        context.insert(log)
        do {
            try context.save()
        } catch {
            // Insertion failure is extremely rare (disk full, corrupted store).
            // Surface the message but do not crash — the in-memory object still
            // exists and the UI will recover on next launch.
            loggingError = "Could not save your log. Please try again."
            isLogging = false
            return
        }

        // Show confirmation immediately — capture runs in the background.
        confirmedLog = log
        isLogging = false

        // Fire background enrichment concurrently, non-blocking.
        fireBackgroundCapture(for: log, context: context)
    }

    // -------------------------------------------------------------------------
    // MARK: Background capture
    // -------------------------------------------------------------------------

    /// Fires weather and health captures concurrently. Attaches results to the
    /// persisted log once both complete. Never throws to the caller — partial
    /// or total capture failure leaves those fields nil for manual entry later.
    ///
    /// When real services are wired in (Steps 4–6 of the build order), replace
    /// each stub block with the actual service call. The surrounding concurrency
    /// structure does not change.
    private func fireBackgroundCapture(for log: HeadacheLog, context: ModelContext) {
        Task {
            let result = await performCaptures()

            // Re-enter the main actor to mutate the SwiftData object.
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

    /// Runs all captures concurrently. Returns a `CaptureResult` regardless of
    /// individual failures — a failed capture produces nil.
    private nonisolated func performCaptures() async -> CaptureResult {
        async let weatherResult: WeatherSnapshot? = captureWeather()
        async let healthResult: HealthSnapshot? = captureHealth()
        let (weather, health) = await (weatherResult, healthResult)
        return CaptureResult(weather: weather, health: health)
    }

    // Step 6 replacement point: WeatherService.capture(location:)
    private nonisolated func captureWeather() async -> WeatherSnapshot? {
        try? await Task.sleep(for: .milliseconds(200))
        return nil
    }

    // Step 4 — live HealthKit snapshot. Returns nil gracefully if the user
    // has denied all permissions or HealthKit is unavailable on this device.
    private nonisolated func captureHealth() async -> HealthSnapshot? {
        let snapshot = await HealthKitService.shared.snapshot()
        // Return nil rather than an empty snapshot so the caller can
        // distinguish "no data captured" from "service not called".
        return snapshot.hasAnyData ? snapshot : nil
    }

    // -------------------------------------------------------------------------
    // MARK: Confirmation dismissal
    // -------------------------------------------------------------------------

    /// Called by LogConfirmationView once its auto-dismiss timer fires.
    func clearConfirmation() {
        confirmedLog = nil
    }
}
