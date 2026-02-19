//
//  AuraeApp.swift
//  Aurae
//
//  Application entry point. Responsibilities:
//
//  1. Configures the SwiftData ModelContainer with all four persistent models
//     and injects it into the SwiftUI environment.
//
//  2. Acts as UNUserNotificationCenterDelegate to handle interactive notification
//     actions (MARK_RESOLVED, SNOOZE) and foreground notification presentation.
//
//  Notification delegate notes:
//  - `UNUserNotificationCenterDelegate` methods are called on an arbitrary
//    background thread by the system. We create a detached SwiftData
//    ModelContext from the container's mainContext configuration to perform
//    the database fetch safely.
//  - The log UUID is read from the notification's userInfo dictionary.
//    This avoids passing @Model objects across actor/thread boundaries.
//  - Both delegate methods call their completionHandler on the same thread
//    they were invoked on, satisfying the UNUserNotificationCenter contract.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct AuraeApp: App {

    // -------------------------------------------------------------------------
    // MARK: SwiftData container
    // -------------------------------------------------------------------------

    let modelContainer: ModelContainer

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    init() {
        // Build the persistent store. A failure here means the on-disk store
        // is irrecoverably corrupted; crash loudly so it surfaces immediately.
        do {
            modelContainer = try ModelContainer(
                for:
                    HeadacheLog.self,
                    HealthSnapshot.self,
                    RetrospectiveEntry.self,
                    WeatherSnapshot.self
            )
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }

        // Register interactive notification categories before any notification
        // is scheduled. This is idempotent — safe to call every launch.
        NotificationService.shared.registerCategories()

        // Set the dedicated notification delegate so we receive action callbacks
        // and can control foreground notification presentation.
        UNUserNotificationCenter.current().delegate = AppNotificationDelegate.shared

        // Inject the container into the delegate so it can create ModelContexts
        // inside notification callbacks without accessing the SwiftUI environment.
        AppNotificationDelegate.shared.modelContainer = modelContainer
    }

    // -------------------------------------------------------------------------
    // MARK: Scene
    // -------------------------------------------------------------------------

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - RootView

/// Wraps ContentView and gates it behind a full-screen onboarding cover.
///
/// `@AppStorage("hasCompletedOnboarding")` persists to UserDefaults under the
/// key "hasCompletedOnboarding". The cover is shown on first launch (value is
/// false) and never again after the user completes or skips onboarding.
///
/// Placed here rather than inside ContentView to keep ContentView focused on
/// tab navigation. RootView is the single place that owns the launch gate.
private struct RootView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// Two-way binding that maps `hasCompletedOnboarding` onto
    /// `isPresented` for the full-screen cover.
    ///
    /// isPresented = true  when hasCompletedOnboarding = false  (show cover)
    /// isPresented = false when hasCompletedOnboarding = true   (dismiss cover)
    ///
    /// Setting isPresented = false from inside the cover (i.e., when onComplete
    /// fires and sets hasCompletedOnboarding = true) updates the AppStorage value
    /// and causes SwiftUI to dismiss the cover on the next render pass.
    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { isShowing in
                if !isShowing {
                    hasCompletedOnboarding = true
                }
            }
        )
    }

    var body: some View {
        ContentView()
            .fullScreenCover(isPresented: showOnboarding) {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
    }
}

// MARK: - AppNotificationDelegate

/// Handles UNUserNotificationCenterDelegate callbacks.
///
/// Separated from `AuraeApp` into a dedicated `NSObject` subclass because:
/// - `App` structs cannot subclass `NSObject` directly.
/// - `UNUserNotificationCenterDelegate` requires an `NSObject`-based type.
/// - This keeps `AuraeApp` a pure value type (struct).
///
/// The shared instance is set as the delegate in `AuraeApp.init()` and lives
/// for the duration of the process.
@MainActor
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = AppNotificationDelegate()

    /// Reference to the model container, injected by `AuraeApp` after init.
    /// Used to create a `ModelContext` for database operations inside callbacks.
    var modelContainer: ModelContainer?

    // -------------------------------------------------------------------------
    // MARK: Foreground presentation
    // -------------------------------------------------------------------------

    /// Called when a notification arrives while the app is in the foreground.
    /// Returns `.banner` + `.sound` so the follow-up prompt is still visible
    /// even when the user is actively using the app.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // -------------------------------------------------------------------------
    // MARK: Action response
    // -------------------------------------------------------------------------

    /// Called when the user taps an interactive action or the notification itself.
    ///
    /// Handled actions:
    /// - `MARK_RESOLVED`: Fetches the log by UUID and calls `resolve(at:)`.
    /// - `SNOOZE`:        Reschedules the follow-up for 30 minutes from now.
    /// - Default tap:     No-op for MVP (History deep-link deferred to a later phase).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo   = response.notification.request.content.userInfo
        let actionID   = response.actionIdentifier

        // Extract log UUID — required for both actions.
        guard
            let logIDString = userInfo[NotificationService.UserInfoKey.logID] as? String,
            let logID       = UUID(uuidString: logIDString)
        else {
            completionHandler()
            return
        }

        switch actionID {

        case NotificationService.Action.markResolved:
            Task {
                await resolveLog(id: logID)
                completionHandler()
            }

        case NotificationService.Action.snooze:
            // Reconstruct enough context from userInfo to build the snooze
            // notification body without a database read.
            let severity  = (userInfo[NotificationService.UserInfoKey.severity] as? Int) ?? 3
            let onsetEpoch = userInfo[NotificationService.UserInfoKey.onset] as? TimeInterval ?? Date.now.timeIntervalSince1970
            let onsetTime = Date(timeIntervalSince1970: onsetEpoch)

            Task {
                await NotificationService.shared.scheduleSnooze(
                    logID:     logID,
                    severity:  severity,
                    onsetTime: onsetTime
                )
                completionHandler()
            }

        default:
            // Default tap — no action for MVP. Future: deep-link to log detail.
            completionHandler()
        }
    }

    // =========================================================================
    // MARK: - Private helpers
    // =========================================================================

    /// Fetches the `HeadacheLog` with the given UUID from a background
    /// `ModelContext` and calls `resolve(at:)` if it is still active.
    ///
    /// SwiftData `ModelContext` operations must be performed on the actor that
    /// owns the context. We create a new context from `modelContainer` here;
    /// the main context is untouched from this background path.
    private func resolveLog(id: UUID) async {
        // modelContainer is set by AuraeApp after init. If it is nil
        // (e.g. very early launch edge case) we cannot proceed.
        // resolveLog is already @MainActor-isolated (instance method on a
        // @MainActor class), so modelContainer is accessible directly.
        guard let container = modelContainer else {
            return
        }

        let context = ModelContext(container)

        // Fetch the log matching the UUID.
        let predicate = #Predicate<HeadacheLog> { $0.id == id }
        let descriptor = FetchDescriptor<HeadacheLog>(predicate: predicate)

        do {
            let results = try context.fetch(descriptor)
            guard let log = results.first, log.isActive else { return }
            log.resolve(at: .now)
            try context.save()
        } catch {
            // Resolution failure is non-fatal — the user can still resolve
            // the log manually from the History tab.
        }
    }
}
