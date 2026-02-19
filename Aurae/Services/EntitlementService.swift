//
//  EntitlementService.swift
//  Aurae
//
//  Single source of truth for the user's subscription entitlement status.
//
//  Design decisions:
//  -----------------
//  - @Observable final class, NOT an actor. RevenueCat's PurchasesDelegate
//    delivers CustomerInfo on the main thread, and the @Observable machinery
//    must publish property changes on the main thread. Using an actor would
//    require explicit MainActor hops on every delegate callback, adding
//    unnecessary complexity. All mutations are explicitly annotated @MainActor
//    instead.
//
//  - Singleton (static let shared). EntitlementService is injected into the
//    SwiftUI environment at the root of the view hierarchy (RootView in
//    AuraeApp.swift) and read via @Environment throughout the app. The
//    singleton guarantees a single shared isPro state regardless of how many
//    views observe it.
//
//  - Purchases.configure() is NOT called here. It is called once in
//    AuraeApp.init() before any view is created, which guarantees the SDK is
//    ready before EntitlementService first reads CustomerInfo.
//
//  - Entitlement identifier "pro" matches the identifier created in the
//    RevenueCat dashboard.
//

import Foundation
import Observation
import RevenueCat

// MARK: - EntitlementService

@Observable
final class EntitlementService: NSObject {

    // MARK: - Singleton

    static let shared = EntitlementService()

    // MARK: - Public state

    /// true when the user holds an active "pro" entitlement.
    /// Updated on every CustomerInfo refresh and on purchase/restore.
    /// Always starts false and corrects itself on first checkEntitlement() call.
    @MainActor
    private(set) var isPro: Bool = false

    /// Set while restorePurchases() is running so callers can show a spinner.
    @MainActor
    private(set) var isRestoring: Bool = false

    /// Non-nil when restorePurchases() throws or CustomerInfo fetch fails.
    @MainActor
    private(set) var errorMessage: String? = nil

    // MARK: - Init

    private override init() {
        super.init()
        // Register as delegate immediately so CustomerInfo updates received
        // at any point in the app lifecycle are captured.
        Purchases.shared.delegate = self
    }

    // MARK: - Public API

    /// Fetches the latest CustomerInfo from RevenueCat and updates isPro.
    /// Safe to call multiple times — RevenueCat caches aggressively.
    func checkEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            await applyCustomerInfo(info)
        } catch {
            // Non-fatal. isPro retains its last known value.
            // Do not surface this error in UI — silent degradation is correct.
        }
    }

    /// Restores prior purchases and updates isPro.
    /// Throws if the restore call itself fails (e.g. no App Store account).
    func restorePurchases() async throws {
        await MainActor.run { isRestoring = true; errorMessage = nil }
        defer { Task { @MainActor in self.isRestoring = false } }
        let info = try await Purchases.shared.restorePurchases()
        await applyCustomerInfo(info)
    }

    // MARK: - Private helpers

    @MainActor
    private func applyCustomerInfo(_ info: CustomerInfo) {
        isPro = info.entitlements["pro"]?.isActive == true
    }
}

// MARK: - PurchasesDelegate

extension EntitlementService: PurchasesDelegate {

    /// Called by RevenueCat whenever CustomerInfo changes — on purchase,
    /// restore, subscription expiry, or billing recovery.
    nonisolated func purchases(
        _ purchases: Purchases,
        receivedUpdated customerInfo: CustomerInfo
    ) {
        Task { @MainActor in
            self.applyCustomerInfo(customerInfo)
        }
    }
}

// MARK: - EnvironmentKey

import SwiftUI

private struct EntitlementServiceKey: EnvironmentKey {
    static let defaultValue: EntitlementService = .shared
}

extension EnvironmentValues {
    var entitlementService: EntitlementService {
        get { self[EntitlementServiceKey.self] }
        set { self[EntitlementServiceKey.self] = newValue }
    }
}
