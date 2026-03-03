//
//  LaunchOverlayView.swift
//  Aurae
//
//  Animated brand overlay that appears at every cold launch and fades away
//  once the app is ready. Sits on top of ContentView in RootView.
//
//  Sequence:
//    0.0s → lockup fades in  (0.6s easeInOut)
//    0.6s → hold             (0.25s pause)
//    0.85s → overlay fades out (0.35s easeIn) → onDismiss()
//    Total visible: ~1.2s minimum
//
//  NOTE: This is the SwiftUI animated overlay layer, not the static system
//  launch screen. The static LaunchScreen.storyboard (or UILaunchScreen
//  Info.plist key) must use hardcoded hex #0D0E11 — adaptive color tokens
//  are not available at that rendering stage.
//

import SwiftUI

// MARK: - LaunchOverlayView

struct LaunchOverlayView: View {

    /// Called after the exit animation completes. RootView sets its
    /// `showLaunchOverlay` flag to false in response.
    let onDismiss: () -> Void

    @State private var lockupOpacity: Double = 0
    @State private var overlayOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────────
            // Hardcoded to #0D0E11 (auraeAdaptiveBackground dark).
            // The launch overlay always renders in dark mode.
            Color(hex: "0D0E11")
                .ignoresSafeArea()

            // Inner teal bloom — faint warm presence, slightly left of center.
            RadialGradient(
                colors: [
                    Color(hex: "2D7D7D").opacity(0.07),
                    Color.clear
                ],
                center: UnitPoint(x: 0.45, y: 0.48),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            // Outer violet bloom — offset 40pt lower and 20pt right.
            RadialGradient(
                colors: [
                    Color(hex: "B3A8D9").opacity(0.05),
                    Color.clear
                ],
                center: UnitPoint(x: 0.52, y: 0.54),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // ── Lockup ───────────────────────────────────────────────────────
            // Mark + wordmark fade in as a single unit. No stagger.
            VStack(spacing: 20) {
                AuraeLogoMark(markSize: 68)

                // DM Serif Display at 28pt — above the 26pt display serif
                // threshold, appropriate for a pure brand moment on dark.
                Text("aurae")
                    .font(.dmSerifDisplay(28))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .tracking(1.5)
            }
            .opacity(lockupOpacity)
        }
        .opacity(overlayOpacity)
        .task {
            // Fade in
            withAnimation(.easeInOut(duration: 0.6)) {
                lockupOpacity = 1.0
            }

            // Hold — 0.25s after fade-in completes = 0.85s total
            try? await Task.sleep(for: .milliseconds(850))

            // Fade out entire overlay
            withAnimation(.easeIn(duration: 0.35)) {
                overlayOpacity = 0.0
            }

            // Wait for animation to finish before removing the view
            try? await Task.sleep(for: .milliseconds(360))
            onDismiss()
        }
    }
}

// MARK: - Previews

#Preview("Launch Overlay — Dark") {
    ZStack {
        // Simulate the app behind the overlay
        Color(hex: "121B28").ignoresSafeArea()
        LaunchOverlayView(onDismiss: {})
    }
}

#Preview("Lockup Only — Static") {
    ZStack {
        Color(hex: "0D0E11").ignoresSafeArea()

        RadialGradient(
            colors: [Color(hex: "2D7D7D").opacity(0.07), Color.clear],
            center: UnitPoint(x: 0.45, y: 0.48),
            startRadius: 0,
            endRadius: 280
        )
        .ignoresSafeArea()

        RadialGradient(
            colors: [Color(hex: "B3A8D9").opacity(0.05), Color.clear],
            center: UnitPoint(x: 0.52, y: 0.54),
            startRadius: 0,
            endRadius: 400
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            AuraeLogoMark(markSize: 68)
            Text("aurae")
                .font(.dmSerifDisplay(28))
                .foregroundStyle(Color.white.opacity(0.88))
                .tracking(1.5)
        }
    }
}
