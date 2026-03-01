//
//  LogConfirmationView.swift
//  Aurae
//
//  Full-screen overlay shown immediately after a headache is logged.
//  Auto-dismisses after 3.5 seconds via a fade transition, or on tap.
//  Never shown as a modal sheet — it layers over the home screen so the
//  user can see the app is still alive and ready beneath.
//
//  Respects Reduce Motion: the pulsing ring animation is replaced with a
//  static ring when the accessibility setting is active.
//

import SwiftData
import SwiftUI

struct LogConfirmationView: View {

    /// The log that was just created. Used to display the severity and onset time.
    let log: HeadacheLog

    /// Called once the 3.5-second auto-dismiss timer fires, the user taps
    /// to dismiss early, or after they acknowledge the red-flag banner.
    let onDismiss: () -> Void

    // -------------------------------------------------------------------------
    // MARK: Animation state
    // -------------------------------------------------------------------------

    @State private var isVisible: Bool = false
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0

    // -------------------------------------------------------------------------
    // MARK: Safety state (D-28, D-33)
    // -------------------------------------------------------------------------

    /// Controls the "When to Seek Medical Care" sheet.
    @State private var showMedicalEscalation = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        ZStack {
            // Frosted background — semi-transparent so the home screen is
            // visible beneath, reinforcing that logging happened in-place.
            Color.auraeNavy
                .opacity(0.82)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Layout.sectionSpacing) {
                    Spacer(minLength: Layout.sectionSpacing)

                    // Animated ring + checkmark
                    ringStack

                    // Confirmation text
                    confirmationText

                    // Subtle hint
                    hintText

                    // D-28, D-33: Red-flag safety banner — primary exposure point.
                    // Shown immediately when a triggering condition is detected.
                    // When the banner is visible, the auto-dismiss is suppressed
                    // until the user acknowledges or dismisses it.
                    if shouldShowRedFlagBanner(for: log), !log.hasAcknowledgedRedFlag {
                        RedFlagBannerCard(
                            urgency: redFlagUrgency(for: log),
                            onLearnMore: {
                                showMedicalEscalation = true
                            },
                            onDismiss: {
                                log.hasAcknowledgedRedFlag = true
                                // Allow a short pause then dismiss the overlay.
                                Task {
                                    try? await Task.sleep(for: .milliseconds(400))
                                    await MainActor.run { onDismiss() }
                                }
                            }
                        )
                        .padding(.horizontal, Layout.screenPadding)
                    }

                    Spacer(minLength: Layout.sectionSpacing)
                }
            }
            .opacity(contentOpacity)
        }
        // Tap anywhere to dismiss early — especially helpful when the user
        // is feeling well and wants to skip the confirmation.
        .onTapGesture { onDismiss() }
        .sheet(isPresented: $showMedicalEscalation) {
            MedicalEscalationView()
        }
        .onAppear { runAppearSequence() }
    }

    // -------------------------------------------------------------------------
    // MARK: Sub-views
    // -------------------------------------------------------------------------

    private var ringStack: some View {
        ZStack {
            // Outer pulse ring (hidden when Reduce Motion is on)
            if !reduceMotion {
                Circle()
                    .strokeBorder(Color.auraeTeal.opacity(0.25), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                    .opacity(ringOpacity * (2.0 - pulseScale))
            }

            // Main ring
            Circle()
                .strokeBorder(Color.auraeTeal, lineWidth: 2.5)
                .frame(width: 88, height: 88)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.auraeTeal)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
        }
    }

    private var confirmationText: some View {
        VStack(spacing: Layout.itemSpacing) {
            Text("Logged")
                .font(.auraeH1)
                .foregroundStyle(Color.auraeStarlight)

            Text(onsetTimeText)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextCaption)

            severityBadge
        }
    }

    private var severityBadge: some View {
        Text(log.severityLevel.label)
            .font(.auraeLabel)
            .foregroundStyle(Color.severityAccent(for: log.severity))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Color.severitySurface(for: log.severity).opacity(0.15)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        Color.severityAccent(for: log.severity).opacity(0.4),
                        lineWidth: 1
                    )
            )
    }

    // Severity-aware contextual hint so the message feels relevant to the
    // user's current experience rather than a generic placeholder. (REC-05)
    private var hintText: some View {
        Text(hintCopy)
            .font(.auraeCaption)
            .foregroundStyle(Color.auraeTextCaption)
            .multilineTextAlignment(.center)
            .padding(.top, Layout.itemSpacing)
    }

    private var hintCopy: String {
        switch log.severity {
        case 1, 2:
            return "Rest in a calm, quiet space if you can."
        case 3:
            return "Stay hydrated and reduce screen brightness."
        case 4:
            return "Consider taking any prescribed medication now."
        default:   // 5
            return "Find a dark, quiet room and rest. You've got this."
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------------------

    private var onsetTimeText: String {
        log.onsetTime.formatted(date: .omitted, time: .shortened)
    }

    // -------------------------------------------------------------------------
    // MARK: Animation sequence
    // -------------------------------------------------------------------------

    private func runAppearSequence() {
        if reduceMotion {
            // Instant appearance — no motion.
            ringScale    = 1.0
            ringOpacity  = 1.0
            contentOpacity = 1.0
            scheduleDismiss()
            return
        }

        // Phase 1: Fade in the whole overlay.
        withAnimation(.easeOut(duration: 0.25)) {
            contentOpacity = 1.0
        }

        // Phase 2: Spring the ring and checkmark into place.
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65).delay(0.1)) {
            ringScale   = 1.0
            ringOpacity = 1.0
        }

        // Phase 3: Pulse the outer ring once.
        withAnimation(
            .easeOut(duration: 0.9)
            .delay(0.4)
            .repeatCount(1, autoreverses: false)
        ) {
            pulseScale = 1.6
        }

        scheduleDismiss()
    }

    private func scheduleDismiss() {
        Task {
            // Hold for 3.5 seconds — migraine sufferers need extra time to
            // read the severity-contextual hint with reduced cognitive bandwidth.
            try? await Task.sleep(for: .seconds(3.5))

            // D-28, D-33: If a red-flag banner is active and the user has not
            // yet acknowledged it, suppress the auto-dismiss. The banner's own
            // onDismiss callback will call onDismiss() when the user acts.
            let bannerActive = shouldShowRedFlagBanner(for: log) && !log.hasAcknowledgedRedFlag
            guard !bannerActive else { return }

            // Fade out.
            await MainActor.run {
                withAnimation(
                    reduceMotion
                        ? .linear(duration: 0)
                        : .easeIn(duration: 0.3)
                ) {
                    contentOpacity = 0.0
                }
            }

            // Wait for fade to finish before removing the overlay.
            try? await Task.sleep(for: .milliseconds(310))
            await MainActor.run { onDismiss() }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Red-flag helpers (D-28, D-33)
    // -------------------------------------------------------------------------

    /// Returns true when the log contains a trigger condition requiring the
    /// safety banner. Mirrors the logic in HomeView.
    private func shouldShowRedFlagBanner(for log: HeadacheLog) -> Bool {
        if log.onsetSpeed == .instantaneous { return true }
        let symptoms = log.retrospective?.symptoms ?? []
        return symptoms.contains("aura") && symptoms.contains("visual_disturbance")
    }

    /// Returns the urgency tier for the banner (D-33).
    private func redFlagUrgency(for log: HeadacheLog) -> RedFlagUrgency {
        if log.onsetSpeed == .instantaneous && log.severity >= 4 { return .urgent }
        return .advisory
    }
}

// MARK: - Preview

#Preview("LogConfirmationView") {
    LogConfirmationPreviewWrapper()
}

private struct LogConfirmationPreviewWrapper: View {
    private let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(
            for: HeadacheLog.self, WeatherSnapshot.self,
                HealthSnapshot.self, RetrospectiveEntry.self,
            configurations: config
        )
    }()

    var body: some View {
        let log = HeadacheLog(onsetTime: .now, severity: 4)
        container.mainContext.insert(log)
        return ZStack {
            Color.auraeAdaptiveBackground.ignoresSafeArea()
            Text("Home screen behind overlay")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextCaption)
            LogConfirmationView(log: log) { }
        }
        .modelContainer(container)
    }
}
