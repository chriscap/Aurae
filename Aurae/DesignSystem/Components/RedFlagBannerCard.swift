//
//  RedFlagBannerCard.swift
//  Aurae
//
//  Reusable red-flag safety banner. Two urgency tiers:
//  - .urgent:   amber background, strong copy, emergency services framing
//  - .advisory: softer amber tint, advisory copy
//
//  All copy is clinically reviewed (D-28, D-33). Do not modify without
//  clinical + legal sign-off (OQ-01).
//
//  D-31: dismiss state is tracked per-log via HeadacheLog.hasAcknowledgedRedFlag,
//  not via a global @AppStorage boolean.
//

import SwiftUI

// MARK: - RedFlagUrgency

/// Urgency tier for the red-flag safety banner.
/// Defined here and shared across LogConfirmationView, HomeView, and InsightsView.
enum RedFlagUrgency {
    /// Primary urgent tier: `onsetSpeed == .instantaneous && severity >= 4`.
    /// Uses stronger copy with emergency services framing.
    case urgent
    /// Secondary advisory tier: `onsetSpeed == .instantaneous && severity < 4`.
    /// Uses softer advisory copy. Shown in LogConfirmationView only.
    case advisory
}

// MARK: - RedFlagBannerCard

struct RedFlagBannerCard: View {
    let urgency: RedFlagUrgency
    let onLearnMore: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.auraeAmber)
                    .accessibilityHidden(true)
                Text(headlineText)
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeTextPrimary)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.auraeMidGray)
                        .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            Text(bodyText)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button("When to seek medical care") {
                onLearnMore()
            }
            .font(.auraeLabel)
            .foregroundStyle(Color.auraeTealAccessible)
            .buttonStyle(.plain)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAmber.opacity(urgency == .urgent ? 0.12 : 0.07))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(headlineText). \(bodyText)")
    }

    // MARK: - Copy (clinically reviewed — do not alter without clinical + legal sign-off)

    private var headlineText: String {
        switch urgency {
        case .urgent:   return "Please read this"
        case .advisory: return "A note about your headache"
        }
    }

    /// Verbatim clinically approved copy per PRD Section 7.1 (D-33).
    /// Do not alter without clinical advisor and legal review (OQ-01).
    private var bodyText: String {
        switch urgency {
        case .urgent:
            return "This headache came on very suddenly and severely. Headaches that reach full intensity very quickly can sometimes be a sign of a serious condition that needs immediate medical attention. If this is the worst headache you have ever had, or if you have any other unusual symptoms, please seek emergency medical care now or call emergency services. This app cannot diagnose the cause of your headache."
        case .advisory:
            return "You noted this headache came on very quickly. Sudden-onset headaches can occasionally signal a condition that needs medical attention. If anything feels unusual or severe, please contact a healthcare provider. This app cannot diagnose the cause of your headache."
        }
    }
}

// MARK: - Preview

#Preview("RedFlagBannerCard — urgent") {
    VStack(spacing: 16) {
        RedFlagBannerCard(urgency: .urgent, onLearnMore: { }, onDismiss: { })
        RedFlagBannerCard(urgency: .advisory, onLearnMore: { }, onDismiss: { })
    }
    .padding(Layout.screenPadding)
    .background(Color.auraeAdaptiveBackground)
}
