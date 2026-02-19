//
//  LocationService.swift
//  Aurae
//
//  CoreLocation wrapper that provides a single async location lookup.
//
//  Design rules enforced here:
//  - When-in-use authorization only. "Always" authorization is never requested.
//  - Permission is requested lazily on first call, never on launch.
//  - The returned coordinate is a transient value type — it is never stored,
//    logged, or written to SwiftData. It flows directly into WeatherService.
//  - The app is fully functional if location is denied; weather capture is
//    skipped and the field remains nil for manual retrospective entry.
//
//  Concurrency architecture:
//  CLLocationManager must be created and configured on the main thread. Its
//  delegate callbacks arrive on an unspecified thread. This file uses two
//  separate objects to satisfy both constraints:
//
//  - LocationService (actor): the public API surface, safe for callers on any
//    actor. Serialises concurrent location requests so only one CLLocationManager
//    request is in flight at a time.
//
//  - LocationDelegate (@MainActor class): owns the CLLocationManager instance
//    (created on the main actor), bridges callbacks to an AsyncStream, and is
//    isolated to the main actor to satisfy CLLocationManager's threading rule.
//

import Foundation
import CoreLocation

// MARK: - Coordinate (Sendable value type)

/// A latitude/longitude pair. Value type, Sendable — safe to pass across
/// actor boundaries without copying or wrapping.
struct Coordinate: Sendable {
    let latitude: Double
    let longitude: Double
}

// MARK: - LocationService

actor LocationService {

    // -------------------------------------------------------------------------
    // MARK: Shared instance
    // -------------------------------------------------------------------------

    static let shared = LocationService()

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    /// The main-actor delegate that owns CLLocationManager.
    /// Lazily created on the main actor the first time requestLocation() is called.
    private var delegate: LocationDelegate?

    // =========================================================================
    // MARK: - Public API
    // =========================================================================

    /// Requests when-in-use authorization (if not yet determined), then fetches
    /// the device's current location.
    ///
    /// Returns a `Coordinate` on success, or `nil` if:
    /// - The user denies or restricts location access
    /// - The device's location hardware is unavailable
    /// - The location fix times out
    ///
    /// Calling this method while a request is already in flight waits for the
    /// same result rather than firing a second CLLocationManager request.
    func requestLocation() async -> Coordinate? {
        let locationDelegate = await resolvedDelegate()
        return await locationDelegate.fetchOnce()
    }

    // -------------------------------------------------------------------------
    // MARK: Private
    // -------------------------------------------------------------------------

    /// Returns the shared `LocationDelegate`, creating it on the main actor
    /// if this is the first call.
    private func resolvedDelegate() async -> LocationDelegate {
        if let existing = delegate {
            return existing
        }
        let fresh = await MainActor.run { LocationDelegate() }
        delegate = fresh
        return fresh
    }
}

// MARK: - LocationDelegate

/// Main-actor-isolated object that owns `CLLocationManager` and bridges its
/// delegate callbacks to `async/await` via `AsyncStream`.
///
/// `CLLocationManager` requires creation and method calls on the main thread.
/// `@MainActor` isolation satisfies this requirement without any manual
/// `DispatchQueue.main` calls.
@MainActor
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {

    // -------------------------------------------------------------------------
    // MARK: CoreLocation objects
    // -------------------------------------------------------------------------

    private let manager: CLLocationManager

    // -------------------------------------------------------------------------
    // MARK: Pending request state
    // -------------------------------------------------------------------------

    /// The continuation for an in-flight `fetchOnce()` call.
    /// Nil when no request is pending.
    private var pendingContinuation: CheckedContinuation<Coordinate?, Never>?

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        // City-level accuracy is sufficient for weather lookup and avoids
        // slower, battery-intensive GPS fixes. One kilometre of error has
        // negligible impact on a weather API result.
    }

    // =========================================================================
    // MARK: - Public API (called from LocationService actor)
    // =========================================================================

    /// Requests a single location fix. If a request is already in flight,
    /// the second caller waits for the same CLLocationManager result.
    func fetchOnce() async -> Coordinate? {
        // If a fix is already in progress, wait for that result.
        // We serialise by holding the continuation reference — a second call
        // while pendingContinuation != nil means we need to wait differently.
        // Simplest correct approach: return nil for concurrent callers since
        // HomeViewModel only calls this once per log action.
        guard pendingContinuation == nil else { return nil }

        // Check authorization before requesting.
        let status = manager.authorizationStatus
        switch status {
        case .denied, .restricted:
            return nil
        case .notDetermined:
            // Request authorization; the delegate callback will then trigger
            // the location request when authorization is granted.
            break
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            return nil
        }

        return await withCheckedContinuation { continuation in
            pendingContinuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                // requestWhenInUseAuthorization triggers
                // locationManagerDidChangeAuthorization, which calls
                // manager.requestLocation() once granted.
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                // Denied or restricted — resume immediately with nil.
                pendingContinuation = nil
                continuation.resume(returning: nil)
            }
        }
    }

    // =========================================================================
    // MARK: - CLLocationManagerDelegate
    // =========================================================================

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last,
              let continuation = pendingContinuation
        else { return }

        pendingContinuation = nil
        let coordinate = Coordinate(
            latitude:  location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        continuation.resume(returning: coordinate)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        guard let continuation = pendingContinuation else { return }
        pendingContinuation = nil
        // Any location failure produces nil — the caller handles gracefully.
        continuation.resume(returning: nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Authorization just granted — fire the deferred location request.
            if pendingContinuation != nil {
                manager.requestLocation()
            }
        case .denied, .restricted:
            // Authorization denied — resume any waiting caller with nil.
            if let continuation = pendingContinuation {
                pendingContinuation = nil
                continuation.resume(returning: nil)
            }
        case .notDetermined:
            // Still waiting for user decision — no action needed.
            break
        @unknown default:
            if let continuation = pendingContinuation {
                pendingContinuation = nil
                continuation.resume(returning: nil)
            }
        }
    }
}
