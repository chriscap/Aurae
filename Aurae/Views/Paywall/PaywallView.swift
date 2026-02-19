//
//  PaywallView.swift
//  Aurae
//
//  Presents the RevenueCat-managed paywall for Aurae Pro.
//
//  Architecture:
//  -------------
//  RevenueCatUI's PaywallView renders the offering configured in the
//  RevenueCat dashboard — no hardcoded pricing, copy, or trial lengths in code.
//  This means the paywall can be A/B tested and updated from the dashboard
//  without a new App Store submission.
//
//  The wrapper NavigationStack adds a dismiss button so the sheet can always
//  be closed, even if RevenueCat fails to load an offering (the SDK shows a
//  built-in error state in that case).
//
//  On purchase and on restore, EntitlementService.shared.checkEntitlement()
//  is called to refresh isPro immediately without waiting for the next
//  PurchasesDelegate callback.
//
//  Fallback:
//  ---------
//  If no offering is configured in the RevenueCat dashboard, RevenueCatUI
//  renders its own "No products available" empty state. The dismiss button
//  remains visible so the user is never trapped.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - PaywallView

struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.entitlementService) private var entitlementService

    var body: some View {
        NavigationStack {
            // RevenueCatUI.PaywallView renders the active offering from the
            // RevenueCat dashboard. purchaseCompleted and restoreCompleted
            // receive the updated CustomerInfo; we refresh entitlement from
            // there rather than relying solely on the delegate.
            RevenueCatUI.PaywallView()
                .onPurchaseCompleted { customerInfo in
                    Task {
                        await entitlementService.checkEntitlement()
                        dismiss()
                    }
                }
                .onRestoreCompleted { customerInfo in
                    Task {
                        await entitlementService.checkEntitlement()
                        dismiss()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Color.auraeMidGray)
                        }
                        .accessibilityLabel("Close")
                    }
                }
        }
        .task {
            // Ensure entitlement state is fresh when the paywall opens.
            // Handles the case where the user already purchased on another
            // device and just needs to restore.
            await entitlementService.checkEntitlement()
        }
    }
}

// MARK: - Preview

#Preview("PaywallView") {
    PaywallView()
        .environment(\.entitlementService, EntitlementService.shared)
}
