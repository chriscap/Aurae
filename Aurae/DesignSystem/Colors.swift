//
//  Colors.swift
//  Aurae
//
//  Design system color palette. Never hardcode hex values elsewhere in the app.
//  Dark mode variants are handled via SwiftUI's adaptive Color initialiser where
//  needed; the semantic tokens below are the single source of truth.
//
//  Palette updated 2026-02-25 to the "Calm Blue" direction:
//  Primary shifted from teal (#8AC4C1) to muted blue (#5B8EBF / #6FA8DC dark).
//  Backgrounds updated to navy-dark (#121B28) and near-white (#FAFBFC light).
//  Severity colors shifted to desaturated warm palette (5 levels).
//  Forced dark mode removed — app is now fully adaptive.
//

import SwiftUI
import UIKit

// MARK: - Hex initialiser (internal utility)

extension Color {
    /// Initialise a `Color` from a six-character hex string (with or without leading `#`).
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - UIColor hex initialiser (required by adaptive token definitions)

extension UIColor {
    convenience init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255.0
        let b = CGFloat(rgb & 0x0000FF)           / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Core palette

extension Color {

    // -------------------------------------------------------------------------
    // Brand primary — muted blue
    // Light: #5B8EBF  Dark: #6FA8DC
    // -------------------------------------------------------------------------

    /// Brand primary — muted steel blue. Use for CTAs, active states, links, icons.
    static let auraePrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "6FA8DC") : UIColor(hex: "5B8EBF")
    })

    /// Light accent surface. Light: #E8F2F9  Dark: #253545
    static let auraeAccent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "253545") : UIColor(hex: "E8F2F9")
    })

    /// Accent foreground (text on accent surface). Light: #7BA8D1  Dark: #A4BED6
    static let auraeAccentForeground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "A4BED6") : UIColor(hex: "7BA8D1")
    })

    // -------------------------------------------------------------------------
    // Legacy teal tokens — kept for backward compatibility during migration.
    // New call sites should use auraePrimary instead.
    // -------------------------------------------------------------------------

    /// Brand teal — legacy token, kept for components not yet migrated.
    static let auraeTeal = Color(hex: "5B8EBF")

    /// CTA teal — legacy alias for the primary action button fill.
    static let auraeCtaTeal = Color(hex: "5B8EBF")

    /// Soft teal surface — legacy alias.
    static let auraeSoftTeal = Color(hex: "E8F2F9")

    /// Text-safe teal — use for text on light backgrounds.
    static let auraeTealAccessible = Color(hex: "3D6A96")

    // -------------------------------------------------------------------------
    // Text
    // -------------------------------------------------------------------------

    /// Primary foreground. Light: #1F2937  Dark: #E1E9F2
    static let auraeNavy = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "E1E9F2") : UIColor(hex: "1F2937")
    })

    /// Secondary / slate heading. Light: #374151  Dark: #C8D6E5
    static let auraeSlate = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "C8D6E5") : UIColor(hex: "374151")
    })

    /// Muted metadata. Light: #6B7280  Dark: #8A9BAD
    static let auraeMidGray = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "8A9BAD") : UIColor(hex: "6B7280")
    })

    /// Border / stroke color. Light: #5B8EBF @20%  Dark: #6FA8DC @15%
    static let auraeBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "6FA8DC").withAlphaComponent(0.15)
            : UIColor(hex: "5B8EBF").withAlphaComponent(0.20)
    })

    /// Muted red for destructive actions and error states.
    static let auraeDestructive = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "D87A7A") : UIColor(hex: "EF4444")
    })

    // -------------------------------------------------------------------------
    // Severity fill colors — desaturated warm palette (5 levels).
    // These are the dot/indicator colors shown in list views.
    // -------------------------------------------------------------------------

    static let auraeMild     = Color(hex: "6EBF9E")   // Desaturated emerald
    static let auraeLight    = Color(hex: "5CAAA4")   // Muted teal
    static let auraeModerate = Color(hex: "C4935A")   // Muted amber
    static let auraeSevere   = Color(hex: "C07048")   // Muted terracotta
    static let auraeExtreme  = Color(hex: "B85C5C")   // Muted rose-red

    // -------------------------------------------------------------------------
    // Legacy severity surfaces (kept for badge/chip backgrounds)
    // -------------------------------------------------------------------------

    static let auraeBlush = Color(hex: "F5E8E8")
    static let auraeSage  = Color(hex: "D4EDE9")

    // -------------------------------------------------------------------------
    // Categorical accents (charts, onboarding)
    // -------------------------------------------------------------------------

    static let auraeIndigo    = Color(hex: "5B8EBF")
    static let auraeAmber     = Color(hex: "C4935A")
    static let auraeDarkSage  = Color(hex: "5CAAA4")
    static let auraePeriwinkle = Color(hex: "7BA8D1")
    static let auraeSoftViolet = Color(hex: "9B8EC4")

    // -------------------------------------------------------------------------
    // Label colors for selected/accessible states
    // -------------------------------------------------------------------------

    /// Dark ink label for use on filled buttons / colored pill backgrounds.
    static let auraeSeverityLabelSelected = Color(hex: "1C2826")

    /// Text-safe lavender for light backgrounds.
    static let auraeLavenderAccessible = Color(hex: "8064A2")

    static let auraeVioletPrimary = Color(hex: "B3A8D9")
    static let auraeSoftLavender  = Color(hex: "B6A6CA")
    static let auraeLavender      = Color(hex: "EDE8F4")

    // -------------------------------------------------------------------------
    // Glow tokens (kept for backward compat — used in active banners etc.)
    // -------------------------------------------------------------------------

    static let auraeGlowTeal = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "5B8EBF").withAlphaComponent(0.30)
            : UIColor(hex: "5B8EBF").withAlphaComponent(0.15)
    })

    static let auraeGlowViolet = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "9B8EC4").withAlphaComponent(0.25)
            : UIColor(hex: "9B8EC4").withAlphaComponent(0.15)
    })

    // -------------------------------------------------------------------------
    // Gradients
    // -------------------------------------------------------------------------

    /// Primary brand gradient — muted blue, topLeading → bottomTrailing.
    /// CRITICAL: Always apply a 20% black overlay when placing text on this gradient.
    static let auraePrimaryGradient = LinearGradient(
        colors: [Color(hex: "5B8EBF"), Color(hex: "7BA8D1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle teal gradient — legacy alias, kept for compat.
    static let auraeSubtleGradient = LinearGradient(
        colors: [Color(hex: "5B8EBF"), Color(hex: "A4BED6")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Signature brand gradient — three-stop blue. Used for hero cards.
    static let auraeSignatureGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "5B8EBF"), location: 0.0),
            .init(color: Color(hex: "7BA8D1"), location: 0.5),
            .init(color: Color(hex: "9B8EC4"), location: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Brand mark gradient — original teal to violet.
    /// Used exclusively for AuraeLogoMark and deliberate brand gradient moments.
    /// Do NOT substitute with auraePrimaryGradient — these are different colors.
    static let auraeMarkGradient = LinearGradient(
        colors: [Color(hex: "2D7D7D"), Color(hex: "B3A8D9")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Adaptive semantic tokens

extension Color {

    /// Primary app background. Light: #FAFBFC  Dark: #121B28
    static let auraeAdaptiveBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "121B28") : UIColor(hex: "FAFBFC")
    })

    /// Card / sheet surface. Light: #FFFFFF  Dark: #1A2332
    static let auraeAdaptiveCard = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1A2332") : UIColor(hex: "FFFFFF")
    })

    /// Secondary surface — pill fills, chip backgrounds.
    /// Light: #EFF6FC  Dark: #1E2A38
    static let auraeAdaptiveSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1E2A38") : UIColor(hex: "EFF6FC")
    })

    /// Subtle tint — activity strips, annotation backgrounds.
    /// Light: #F3F4F6  Dark: #1A2332
    static let auraeAdaptiveSubtle = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1A2332") : UIColor(hex: "F3F4F6")
    })

    /// Elevated surface — modals, sheets above card level.
    /// Light: #EFF6FC  Dark: #253545
    static let auraeAdaptiveElevated = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "253545") : UIColor(hex: "EFF6FC")
    })

    /// Input field background.
    /// Light: #FFFFFF  Dark: #1E2A38
    static let auraeAdaptiveInput = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1E2A38") : UIColor(hex: "FFFFFF")
    })

    /// Primary text. Light: #1F2937  Dark: #E1E9F2
    static let auraeAdaptivePrimaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "E1E9F2") : UIColor(hex: "1F2937")
    })

    /// Primary text — semantic alias for new call sites.
    static let auraeTextPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "E1E9F2") : UIColor(hex: "1F2937")
    })

    /// Secondary text — metadata, labels, captions.
    /// Light: #6B7280  Dark: #8A9BAD
    static let auraeTextSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "8A9BAD") : UIColor(hex: "6B7280")
    })

    /// Soft blue tint surface.
    /// Light: #E8F2F9  Dark: #1E2A38
    static let auraeAdaptiveSoftTeal = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1E2A38") : UIColor(hex: "E8F2F9")
    })

    /// Severity mild/low surface.
    static let auraeAdaptiveSage = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "1A2E22") : UIColor(hex: "D8F0E8")
    })

    /// Severity high surface.
    static let auraeAdaptiveBlush = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "2E1A1A") : UIColor(hex: "F5E8E8")
    })

    /// Hero button fill — brand blue.
    static let auraeAdaptiveHeroFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "6FA8DC") : UIColor(hex: "5B8EBF")
    })

    /// Hero button glow — blue bloom.
    static let auraeAdaptiveHeroGlow = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "6FA8DC").withAlphaComponent(0.30)
            : UIColor(hex: "5B8EBF").withAlphaComponent(0.20)
    })

    // -------------------------------------------------------------------------
    // Legacy aliases for views awaiting migration
    // -------------------------------------------------------------------------

    static let auraeDeepSlate = Color(hex: "121B28")
    static let auraeStarlight = Color(hex: "E1E9F2")
    static let auraeSoftInk   = Color(hex: "1F2937")
    static let auraeCardDark  = Color(hex: "1A2332")
    static let auraeSecondaryBackgroundDark = Color(hex: "1E2A38")
    static let auraeBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "121B28") : UIColor(hex: "FAFBFC")
    })
}

// MARK: - Severity colour mapping

extension Color {

    /// Background surface for a 1–5 severity value. Adapts to light/dark.
    static func severitySurface(for level: Int) -> Color {
        switch level {
        case 1: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "152A22") : UIColor(hex: "D8F0E8")
        })
        case 2: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "152826") : UIColor(hex: "D0EBEA")
        })
        case 3: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "2A2012") : UIColor(hex: "F2E4D0")
        })
        case 4: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "281A10") : UIColor(hex: "EFDCC8")
        })
        case 5: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "2E1A1A") : UIColor(hex: "F0D8D8")
        })
        default: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "1E2A38") : UIColor(hex: "EFF6FC")
        })
        }
    }

    /// Foreground accent color for a 1–5 severity value.
    /// Desaturated warm palette — muted but perceptually distinct.
    static func severityAccent(for level: Int) -> Color {
        switch level {
        case 1:  return Color(hex: "6EBF9E")  // Desaturated emerald — Mild
        case 2:  return Color(hex: "5CAAA4")  // Muted teal — Light
        case 3:  return Color(hex: "C4935A")  // Muted amber — Moderate
        case 4:  return Color(hex: "C07048")  // Muted terracotta — Severe
        case 5:  return Color(hex: "B85C5C")  // Muted rose-red — Extreme
        default: return Color(hex: "5B8EBF")
        }
    }

    /// Pill fill color for the SeveritySelector for a given 1–5 severity value.
    /// Desaturated warm semantic ramp — calmer for photosensitive users.
    /// Original saturated values preserved as comments for easy revert.
    static func severityPillFill(for level: Int) -> Color {
        switch level {
        case 1: return Color(UIColor { t in
            // Original: #10B981 (Emerald)
            t.userInterfaceStyle == .dark ? UIColor(hex: "7DCB9E") : UIColor(hex: "6EBF9E")
        })
        case 2: return Color(UIColor { t in
            // Original: #14B8A6 (Teal)
            t.userInterfaceStyle == .dark ? UIColor(hex: "6CBBB5") : UIColor(hex: "5CAAA4")
        })
        case 3: return Color(UIColor { t in
            // Original: #F59E0B (Amber)
            t.userInterfaceStyle == .dark ? UIColor(hex: "D4A870") : UIColor(hex: "C4935A")
        })
        case 4: return Color(UIColor { t in
            // Original: #F97316 (Orange)
            t.userInterfaceStyle == .dark ? UIColor(hex: "D08060") : UIColor(hex: "C07048")
        })
        case 5: return Color(UIColor { t in
            // Original: #EF4444 (Rose)
            t.userInterfaceStyle == .dark ? UIColor(hex: "CC7070") : UIColor(hex: "B85C5C")
        })
        default: return Color(UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor(hex: "7DCB9E") : UIColor(hex: "6EBF9E")
        })
        }
    }
}
