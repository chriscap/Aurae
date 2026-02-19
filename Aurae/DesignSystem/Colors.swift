//
//  Colors.swift
//  Aurae
//
//  Design system color palette. Never hardcode hex values elsewhere in the app.
//  Dark mode variants are handled via SwiftUI's adaptive Color initialiser where
//  needed; the semantic tokens below are the single source of truth.
//

import SwiftUI

// MARK: - Hex initialiser (internal utility)

extension Color {
    /// Initialise a `Color` from a six-character hex string (no leading `#`).
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") // tolerate an optional leading hash
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Aurae Palette

extension Color {

    // -------------------------------------------------------------------------
    // Primary
    // -------------------------------------------------------------------------

    /// Deep Navy — primary text, headings, key actions.
    static let auraeNavy = Color(hex: "0D1B2A")

    /// Slate — secondary headings and dark surfaces.
    static let auraeSlate = Color(hex: "1C2B3A")

    /// Soft Teal — brand accent, CTA buttons, highlights.
    static let auraeTeal = Color(hex: "2D7D7D")

    /// Soft Teal surface — premium highlights and tinted backgrounds.
    static let auraeSoftTeal = Color(hex: "E8F4F4")

    // -------------------------------------------------------------------------
    // Surfaces
    // -------------------------------------------------------------------------

    /// Fog White — primary app background and card surfaces.
    static let auraeBackground = Color(hex: "F5F6F8")

    /// Mist Lavender — secondary surfaces, selected states.
    static let auraeLavender = Color(hex: "EEF0F8")

    // -------------------------------------------------------------------------
    // Text
    // -------------------------------------------------------------------------

    /// Storm Gray — secondary text, labels, metadata.
    static let auraeMidGray = Color(hex: "6B7280")

    // -------------------------------------------------------------------------
    // Severity
    // -------------------------------------------------------------------------

    /// Pale Blush — severity high; warm, non-aggressive alert surface.
    static let auraeBlush = Color(hex: "FDF0EE")

    /// Sage Green — severity low; calm, positive state surface.
    static let auraeSage = Color(hex: "D1EAD4")
}

// MARK: - Severity colour mapping

extension Color {
    /// Returns the appropriate background surface colour for a given 1–5 severity value.
    static func severitySurface(for level: Int) -> Color {
        switch level {
        case 1:      return auraeSage
        case 2:      return Color(hex: "E8F5E9")  // interpolated — soft green-white
        case 3:      return auraeLavender
        case 4:      return Color(hex: "FEF8F0")  // interpolated — warm peach-white
        case 5:      return auraeBlush
        default:     return auraeLavender
        }
    }

    /// Returns the foreground accent colour for a given 1–5 severity value.
    static func severityAccent(for level: Int) -> Color {
        switch level {
        case 1, 2:   return Color(hex: "3A7D5A")  // dark sage
        case 3:      return auraeTeal
        case 4:      return Color(hex: "B06020")  // warm amber
        case 5:      return Color(hex: "B03A2E")  // muted red
        default:     return auraeTeal
        }
    }
}
