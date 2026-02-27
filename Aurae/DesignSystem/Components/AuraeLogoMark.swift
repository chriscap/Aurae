//
//  AuraeLogoMark.swift
//  Aurae
//
//  Brand mark and lockup components.
//
//  AuraeLogoMark — concentric aura halo, teal-to-violet gradient.
//  AuraeLogoLockup — horizontal mark + "aurae" wordmark.
//
//  Usage:
//    AuraeLogoMark(markSize: 68)                          // 3-ring, full opacity
//    AuraeLogoMark(markSize: 24, ringCount: 2)            // 2-ring for small contexts
//    AuraeLogoMark(markSize: 52, opacity: 0.70)           // locked / dim state
//    AuraeLogoMark(markSize: 32, opacity: 0.18)           // ghost watermark
//    AuraeLogoLockup(markSize: 40, wordmarkSize: 17)      // export PDF header
//

import SwiftUI

// MARK: - AuraeLogoMark

/// Concentric aura halo mark. Three concentric ellipses in brand teal-to-violet gradient.
/// At sizes below 40pt, use `ringCount: 2` to drop the faint outer ring.
struct AuraeLogoMark: View {

    /// Bounding box of the outer ring (and the component's frame).
    let markSize: CGFloat

    /// 2 = inner + middle only. 3 = all three rings (default).
    var ringCount: Int = 3

    /// Overall opacity of the entire mark. Use 0.70 for locked states, 0.18 for ghost watermarks.
    var opacity: Double = 1.0

    var body: some View {
        ZStack {
            // Outer ring — only at ringCount == 3
            if ringCount >= 3 {
                Ellipse()
                    .fill(Color.auraeMarkGradient)
                    .frame(width: markSize, height: markSize)
                    .opacity(0.14)
            }
            // Middle ring
            Ellipse()
                .fill(Color.auraeMarkGradient)
                .frame(width: markSize * 0.71, height: markSize * 0.71)
                .opacity(0.35)
            // Inner ellipse
            Ellipse()
                .fill(Color.auraeMarkGradient)
                .frame(width: markSize * 0.41, height: markSize * 0.41)
                .opacity(1.0)
        }
        .frame(width: markSize, height: markSize)
        .opacity(opacity)
        .accessibilityHidden(true) // decorative — lockup provides the label
    }
}

// MARK: - AuraeLogoLockup

/// Horizontal lockup: AuraeLogoMark on the left, "aurae" wordmark on the right.
/// The entire element reads as "Aurae" in VoiceOver.
struct AuraeLogoLockup: View {

    let markSize: CGFloat
    let wordmarkSize: CGFloat

    var wordmarkColor: Color = .auraeAdaptivePrimaryText
    var spacing: CGFloat = 8
    var ringCount: Int = 3
    var opacity: Double = 1.0

    var body: some View {
        HStack(spacing: spacing) {
            AuraeLogoMark(markSize: markSize, ringCount: ringCount, opacity: opacity)
            Text("aurae")
                .font(.system(size: wordmarkSize, weight: .semibold, design: .default))
                .foregroundStyle(wordmarkColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aurae")
    }
}

// MARK: - Previews

#Preview("Mark sizes") {
    VStack(spacing: 24) {
        AuraeLogoMark(markSize: 68)
        AuraeLogoMark(markSize: 52, opacity: 0.70)
        AuraeLogoMark(markSize: 32, ringCount: 2)
        AuraeLogoMark(markSize: 32, opacity: 0.18)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "0D0E11"))
}

#Preview("Lockup sizes") {
    VStack(alignment: .leading, spacing: 20) {
        AuraeLogoLockup(markSize: 68, wordmarkSize: 26)
        AuraeLogoLockup(markSize: 40, wordmarkSize: 17, wordmarkColor: .auraeAdaptivePrimaryText, ringCount: 2)
        AuraeLogoLockup(markSize: 24, wordmarkSize: 13,
                        wordmarkColor: .auraeTextSecondary, ringCount: 2)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "0D0E11"))
}
