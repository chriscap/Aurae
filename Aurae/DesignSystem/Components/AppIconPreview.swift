//
//  AppIconPreview.swift
//  Aurae
//
//  SwiftUI visual representation of the Aurae app icon.
//
//  Use the #Preview macros below to review the icon design in Xcode Canvas
//  at different rendered sizes.
//
//  IMPORTANT: This file is for design review only. Actual icon assets must
//  be exported as PNG and placed in Assets.xcassets/AppIcon.appiconset.
//  The iOS system applies the squircle mask automatically — do not apply
//  corner radius to the exported PNG, and do not add a border or padding ring.
//
//  Background: #0D0E11 with a centered teal bloom (12–15% opacity).
//  Mark: three-ring halo at 57% of tile width. No wordmark at icon sizes.
//  Gradient: teal #2D7D7D → violet #B3A8D9 (auraeMarkGradient).
//

import SwiftUI

// MARK: - AppIconPreview

/// Renders the Aurae app icon at a given point size with iOS squircle masking.
/// Use size: 1024 to produce an export-quality preview in Canvas.
struct AppIconPreview: View {

    /// Point size of the icon tile. 60pt matches the standard iOS home screen
    /// icon size; 1024pt matches the App Store submission resolution.
    let size: CGFloat

    init(size: CGFloat = 320) {
        self.size = size
    }

    var body: some View {
        ZStack {
            // ── Background: deep navy ────────────────────────────────────────
            Color(hex: "0D0E11")

            // ── Centered teal bloom ──────────────────────────────────────────
            // Visible at larger sizes; at 60pt renders as a subtle darkening
            // that prevents the background reading as flat black.
            RadialGradient(
                colors: [
                    Color(hex: "2D7D7D").opacity(0.14),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.50
            )

            // ── Logo mark ────────────────────────────────────────────────────
            // 57% of tile width = outer ellipse fills a confident but
            // non-dominant proportion of the icon canvas.
            AuraeLogoMark(
                markSize: size * 0.57,
                ringCount: size < 80 ? 2 : 3   // drop outer ring at small renders
            )
        }
        .frame(width: size, height: size)
        // iOS squircle corner radius ≈ 22.37% of tile width (system value).
        // This approximation is for design preview only.
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
    }
}

// MARK: - Previews

#Preview("App Icon — Home screen (60pt)") {
    HStack(spacing: 20) {
        AppIconPreview(size: 60)
        AppIconPreview(size: 60)
        AppIconPreview(size: 60)
    }
    .padding(32)
    .background(Color(hex: "1C1C1E")) // simulates dark home screen wallpaper
}

#Preview("App Icon — Standard preview (320pt)") {
    AppIconPreview(size: 320)
        .padding(40)
        .background(Color(hex: "1C1C1E"))
}

#Preview("App Icon — Sizes") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                AppIconPreview(size: 29)
                Text("29pt").font(.auraeCaption2).foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                AppIconPreview(size: 40)
                Text("40pt").font(.auraeCaption2).foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                AppIconPreview(size: 60)
                Text("60pt").font(.auraeCaption2).foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                AppIconPreview(size: 76)
                Text("76pt").font(.auraeCaption2).foregroundStyle(.secondary)
            }
        }
        AppIconPreview(size: 200)
        Text("200pt").font(.auraeCaption).foregroundStyle(.secondary)
    }
    .padding(32)
    .background(Color(hex: "1C1C1E"))
}

#Preview("App Icon — Light home screen") {
    HStack(spacing: 20) {
        AppIconPreview(size: 60)
        AppIconPreview(size: 60)
        AppIconPreview(size: 60)
    }
    .padding(32)
    .background(Color(hex: "F2F2F7")) // simulates light home screen wallpaper
}
