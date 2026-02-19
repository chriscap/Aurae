//
//  NotificationService.swift
//  Aurae
//
//  Manages local notifications for the headache follow-up prompt.
//
//  Step 7: Shell with correct public API surface fully wired into HomeViewModel.
//  Step 8: Fill in the UNUserNotificationCenter implementations.
//
//  Notification strategy (per PRD):
//  - On log: schedule a "How's your headache?" notification at a
//    user-configurable delay (default 1 hour).
//  - On resolve: cancel the pending notification for that log so the
//    user is not interrupted after they have already updated their status.
//  - Authorization is requested lazily on first schedule attempt, not on launch.
//  - The app is fully functional if notification permission is denied —
//    follow-ups simply will not appear.
//
//  Notification identifiers are derived deterministically from the log's UUID
//  so cancellation is reliable without maintaining a separate lookup table.
//

import Foundation
import UserNotifications

// MARK: - Follow-up delay options

/// The configurable delay between onset logging and the follow-up notification.
/// Stored as a raw `TimeInterval` so it can be persisted in UserDefaults.
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
    /// The system permission dialog shows at most once; subsequent calls to
    /// requestAuthorization resolve immediately.
    private var authorizationRequested = false

    // =========================================================================
    // MARK: - Public API
    // =========================================================================

    // -------------------------------------------------------------------------
    // MARK: requestAuthorization()
    // -------------------------------------------------------------------------

    /// Requests authorization to display alerts and play sounds.
    /// Called lazily from `scheduleFollowUp` on first use.
    /// Returns true if the user has granted (or previously granted) permission.
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard !authorizationRequested else {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
        authorizationRequested = true

        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    // -------------------------------------------------------------------------
    // MARK: scheduleFollowUp(for:delay:)
    // -------------------------------------------------------------------------

    /// Schedules a follow-up notification asking the user to update their
    /// headache status after the given delay.
    ///
    /// - Parameters:
    ///   - logID: The `UUID` of the `HeadacheLog` this notification relates to.
    ///   - delay: How long after onset to deliver the notification.
    ///            Defaults to one hour.
    ///
    /// Silently no-ops if notification permission is denied.
    func scheduleFollowUp(for logID: UUID, delay: FollowUpDelay = .oneHour) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        // Step 8 will add the full UNMutableNotificationContent and
        // UNTimeIntervalNotificationTrigger here. The identifier scheme below
        // is already final so cancellation works correctly today.
        let identifier = notificationIdentifier(for: logID)

        // Remove any existing notification for this log before scheduling a
        // new one — handles the case where severity is updated before the
        // follow-up fires.
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "How's your headache?"
        content.body  = "Tap to update your log and track how it resolved."
        content.sound = .default

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
    // MARK: cancelFollowUp(for:)
    // -------------------------------------------------------------------------

    /// Cancels any pending follow-up notification for the given log.
    /// Called when the user marks a headache as resolved before the
    /// notification fires.
    func cancelFollowUp(for logID: UUID) {
        let identifier = notificationIdentifier(for: logID)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // =========================================================================
    // MARK: - Helpers
    // =========================================================================

    /// Produces a stable notification identifier for a given log UUID.
    /// Using a consistent scheme means we never need a separate lookup table.
    private func notificationIdentifier(for logID: UUID) -> String {
        "aurae.followup.\(logID.uuidString)"
    }
}
