//
//  NotificationService.swift
//  Aurae
//
//  Full implementation of local notification scheduling for headache follow-up.
//
//  Notification strategy (per PRD):
//  - On log: schedule a "How's your headache?" notification after a
//    user-configurable delay (default 1 hour). The delay is read from
//    UserDefaults key "followUpDelay" so it persists across launches.
//  - On resolve: cancel the pending notification for that log so the
//    user is not interrupted after they have already updated their status.
//  - Authorization is requested lazily on first schedule attempt, not on launch.
//  - The app is fully functional if notification permission is denied —
//    follow-ups simply will not appear.
//
//  Notification identifiers are derived deterministically from the log's UUID
//  so cancellation is reliable without maintaining a separate lookup table.
//
//  Category / actions registered here; the delegate response lives in AuraeApp.
//

import Foundation
import UserNotifications

// MARK: - Follow-up delay options

/// The configurable delay between onset logging and the follow-up notification.
/// Raw value is `TimeInterval` so it can be persisted in UserDefaults directly.
enum FollowUpDelay: TimeInterval, CaseIterable, Identifiable {
    case thirtyMinutes = 1800
    case oneHour       = 3600
    case twoHours      = 7200

    var id: TimeInterval { rawValue }

    var label: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .oneHour:       return "1 hour"
        case .twoHours:      return "2 hours"
        }
    }
}

// MARK: - UserDefaults key

private extension String {
    static let followUpDelayKey = "followUpDelay"
}

// MARK: - Notification identifiers / categories

extension NotificationService {
    enum Category {
        static let headacheFollowUp = "HEADACHE_FOLLOWUP"
    }

    enum Action {
        static let markResolved = "MARK_RESOLVED"
        static let snooze       = "SNOOZE"
    }

    enum UserInfoKey {
        static let logID    = "logID"
        static let severity = "severity"
        static let onset    = "onset"
    }
}

// MARK: - NotificationService

actor NotificationService {

    // -------------------------------------------------------------------------
    // MARK: Shared instance
    // -------------------------------------------------------------------------

    static let shared = NotificationService()

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    private let center = UNUserNotificationCenter.current()

    /// Tracks whether we have already requested authorization this session.
    /// The system permission dialog shows at most once per app install.
    private var authorizationRequested = false

    // =========================================================================
    // MARK: - Category registration
    // =========================================================================

    /// Registers the HEADACHE_FOLLOWUP category with its two interactive actions.
    ///
    /// Call this once from `AuraeApp.init()` — before any notifications are
    /// scheduled — so the category is always available when a notification fires.
    ///
    /// This method is idempotent: calling it multiple times has no side-effect.
    nonisolated func registerCategories() {
        let markResolvedAction = UNNotificationAction(
            identifier: Action.markResolved,
            title: "Mark Resolved",
            options: [.authenticationRequired]
        )

        let snoozeAction = UNNotificationAction(
            identifier: Action.snooze,
            title: "Snooze 30 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: Category.headacheFollowUp,
            actions: [markResolvedAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // =========================================================================
    // MARK: - Preferred delay (UserDefaults-backed)
    // =========================================================================

    /// The delay the user has chosen in Settings (or the default of one hour).
    ///
    /// Reading and writing `UserDefaults` is safe inside an actor because
    /// `UserDefaults` is internally thread-safe. No stored mutable actor
    /// property is needed — the backing store is UserDefaults itself.
    var preferredDelay: FollowUpDelay {
        get {
            let stored = UserDefaults.standard.double(forKey: .followUpDelayKey)
            return FollowUpDelay(rawValue: stored) ?? .oneHour
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: .followUpDelayKey)
        }
    }

    // =========================================================================
    // MARK: - Public API
    // =========================================================================

    // -------------------------------------------------------------------------
    // MARK: requestAuthorization()
    // -------------------------------------------------------------------------

    /// Requests authorization to display alerts, play sounds, and badge the icon.
    /// Called lazily from `scheduleFollowUp` on first use.
    /// Returns `true` if the user has granted (or previously granted) permission.
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard !authorizationRequested else {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
        authorizationRequested = true

        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // -------------------------------------------------------------------------
    // MARK: scheduleFollowUp(logID:severity:onsetTime:)
    // -------------------------------------------------------------------------

    /// Schedules a follow-up notification asking the user to update their
    /// headache status. The delay is read from `preferredDelay` at call time.
    ///
    /// - Parameters:
    ///   - logID:     The `UUID` of the `HeadacheLog` this notification relates to.
    ///   - severity:  The severity level (1–5) recorded at onset. Embedded in
    ///                the notification body so no database read is needed on action.
    ///   - onsetTime: The onset timestamp. Used to compute elapsed time for the
    ///                notification body and stored in userInfo for snooze reschedule.
    ///
    /// Silently no-ops if notification permission is denied.
    func scheduleFollowUp(
        logID:     UUID,
        severity:  Int,
        onsetTime: Date
    ) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let delay      = preferredDelay
        let identifier = notificationIdentifier(for: logID)

        // Remove any existing notification for this log before rescheduling.
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content        = UNMutableNotificationContent()
        content.title      = "How's your headache?"
        content.body       = buildBody(severity: severity, onsetTime: onsetTime, delay: delay)
        content.sound      = .default
        content.categoryIdentifier = Category.headacheFollowUp

        // Store log metadata in userInfo so the delegate can act without a
        // database fetch for most operations.
        content.userInfo = [
            UserInfoKey.logID:    logID.uuidString,
            UserInfoKey.severity: severity,
            UserInfoKey.onset:    onsetTime.timeIntervalSince1970
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay.rawValue,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Scheduling failure is non-fatal. The user can still manually
            // update their log via the History tab.
        }
    }

    // -------------------------------------------------------------------------
    // MARK: scheduleSnooze(logID:severity:onsetTime:)
    // -------------------------------------------------------------------------

    /// Re-schedules a follow-up notification for 30 minutes from now.
    /// Called by `AuraeApp` when the user taps the "Snooze 30 min" action.
    ///
    /// The snooze delay is always 30 minutes regardless of `preferredDelay`
    /// — the user has explicitly asked for a short deferral.
    func scheduleSnooze(logID: UUID, severity: Int, onsetTime: Date) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let identifier = notificationIdentifier(for: logID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content        = UNMutableNotificationContent()
        content.title      = "How's your headache?"
        content.body       = buildBody(severity: severity, onsetTime: onsetTime, delay: .thirtyMinutes)
        content.sound      = .default
        content.categoryIdentifier = Category.headacheFollowUp
        content.userInfo = [
            UserInfoKey.logID:    logID.uuidString,
            UserInfoKey.severity: severity,
            UserInfoKey.onset:    onsetTime.timeIntervalSince1970
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: FollowUpDelay.thirtyMinutes.rawValue,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch { }
    }

    // -------------------------------------------------------------------------
    // MARK: cancelFollowUp(for:)
    // -------------------------------------------------------------------------

    /// Cancels any pending follow-up notification for the given log UUID.
    /// Called when the user marks a headache as resolved before the notification fires.
    func cancelFollowUp(for logID: UUID) {
        let identifier = notificationIdentifier(for: logID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // =========================================================================
    // MARK: - Helpers
    // =========================================================================

    /// Produces a stable notification identifier for a given log UUID.
    private func notificationIdentifier(for logID: UUID) -> String {
        "aurae.followup.\(logID.uuidString)"
    }

    /// Builds the notification body string using severity and onset time.
    ///
    /// Example: "Your severity 4 headache started 1h ago. Tap to log how it's going."
    /// The elapsed time is computed from onset to now + the scheduled delay
    /// so the body is accurate at delivery time.
    private func buildBody(severity: Int, onsetTime: Date, delay: FollowUpDelay) -> String {
        let deliveryTime = onsetTime.addingTimeInterval(delay.rawValue)
        let elapsed      = deliveryTime.timeIntervalSince(onsetTime)
        let elapsedStr   = formatElapsed(elapsed)
        return "Your severity \(severity) headache started \(elapsedStr) ago. Tap to log how it's going."
    }

    /// Formats a `TimeInterval` as a human-readable elapsed string.
    /// Examples: "30m", "1h", "2h 30m"
    private func formatElapsed(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let hours   = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, let m): return "\(m)m"
        case (let h, 0): return "\(h)h"
        default:         return "\(hours)h \(minutes)m"
        }
    }
}
