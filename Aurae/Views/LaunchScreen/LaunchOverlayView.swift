//
//  LaunchOverlayView.swift
//  Aurae
//
//  Animated brand overlay shown at every cold launch.
//
//  Sequence:
//    0.0s  → mark + wordmark fade in        (0.6s easeInOut)
//    0.6s  → hold                           (0.25s)
//    0.85s → backdrop + wordmark fade out   (0.35s easeIn)
//    0.85s → mark journeys to upper-right   (0.55s easeInOut, concurrent)
//             scaling 68pt → 200pt, opacity 1.0 → 0.24
//    1.41s → onDismiss() — caller cross-fades overlay out + home screen in
//             (no per-mark dissolve; the whole overlay exits via .transition)
//
//  NOTE: This is the SwiftUI animated overlay layer. The static
//  LaunchScreen.storyboard must use hardcoded #0D0E11 — adaptive tokens
//  are not available at that rendering stage.
//

import SwiftUI

// MARK: - LaunchOverlayView

struct LaunchOverlayView: View {

    let onDismiss: () -> Void

    // Backdrop (background fill + blooms)
    @State private var backdropOpacity: Double = 1

    // Mark — has its own opacity so it can stay alive after backdrop fades
    @State private var markOpacity: Double = 0
    @State private var markOffset: CGSize = CGSize(width: 0, height: -20) // optical center in lockup
    @State private var markScale: CGFloat = 1.0

    // Wordmark — fades with backdrop
    @State private var wordmarkOpacity: Double = 0

    private let launchMarkSize: CGFloat = 68
    private let watermarkSize: CGFloat = 200

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Backdrop ──────────────────────────────────────────────
                backdropLayer
                    .opacity(backdropOpacity)

                // ── Mark ──────────────────────────────────────────────────
                // Positioned independently so it can detach from the lockup
                // and journey to the watermark position after the backdrop fades.
                AuraeLogoMark(markSize: launchMarkSize, ringCount: 3)
                    .scaleEffect(markScale)
                    .offset(markOffset)
                    .opacity(markOpacity)

                // ── Wordmark ──────────────────────────────────────────────
                Text("aurae")
                    .font(.custom("DMSerifDisplay-Regular", size: 28))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .tracking(4.2)
                    .offset(y: 50) // sits below mark in optical lockup
                    .opacity(wordmarkOpacity)
            }
            .task {
                // Target position for the mark in the ZStack's coordinate
                // space (origin = screen center).
                // Mirrors the watermark position in HomeView:
                //   HStack > Spacer + 200pt ZStack .offset(x: 40, y: -16)
                // → mark center lands on watermark: x = screenWidth−65, y = 84pt from screen top
                // Watermark in HomeView uses .ignoresSafeArea(), so its center sits
                // at ~84pt from screen top. The GeoReader measures the safe-area-bounded
                // space, whose centre is at (safeAreaTop + geo.height/2) from screen top.
                // To land the mark on the watermark we compute the exact offset:
                //   targetY = watermarkCenterY − geoCenter.y
                //           = 84 − (safeAreaTop + geo.height/2)
                //           = −(geo.height/2 − (84 − safeAreaTop))
                let watermarkCenterYFromScreenTop: CGFloat = 84
                let safeTop = geo.safeAreaInsets.top
                let targetOffset = CGSize(
                    width:  geo.size.width  / 2 - 60,
                    height: -(geo.size.height / 2 - (watermarkCenterYFromScreenTop - safeTop))
                )
                let targetScale = watermarkSize / launchMarkSize  // ≈ 2.94×

                // 1. Fade in lockup
                withAnimation(.easeInOut(duration: 0.6)) {
                    markOpacity    = 1.0
                    wordmarkOpacity = 1.0
                }

                // 2. Hold
                try? await Task.sleep(for: .milliseconds(850))

                // 3. Backdrop + wordmark fade out
                withAnimation(.easeIn(duration: 0.35)) {
                    backdropOpacity  = 0
                    wordmarkOpacity  = 0
                }

                // 4. Mark journeys to watermark position (concurrent with step 3)
                withAnimation(.easeInOut(duration: 0.55)) {
                    markOffset  = targetOffset
                    markScale   = targetScale
                    markOpacity = 0.24  // lands at watermark inner-core opacity
                }

                // 5. Dismiss — caller animates the whole overlay out via .transition(.opacity)
                //    and cross-fades ContentView in simultaneously. No per-mark dissolve
                //    needed; the overlay exit IS the fade-out.
                try? await Task.sleep(for: .milliseconds(580))
                onDismiss()
            }
        }
    }

    // MARK: - Backdrop

    private var backdropLayer: some View {
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
        }
    }
}

// MARK: - Previews

#Preview("Launch Overlay — animated") {
    ZStack {
        Color(hex: "121B28").ignoresSafeArea()
        LaunchOverlayView(onDismiss: {})
    }
}

#Preview("Lockup — static") {
    ZStack {
        Color(hex: "0D0E11").ignoresSafeArea()

        RadialGradient(
            colors: [Color(hex: "2D7D7D").opacity(0.07), Color.clear],
            center: UnitPoint(x: 0.45, y: 0.48),
            startRadius: 0, endRadius: 280
        )
        .ignoresSafeArea()

        ZStack {
            AuraeLogoMark(markSize: 68)
                .offset(y: -20)
            Text("aurae")
                .font(.custom("DMSerifDisplay-Regular", size: 28))
                .foregroundStyle(Color.white.opacity(0.88))
                .tracking(4.2)
                .offset(y: 50)
        }
    }
}
