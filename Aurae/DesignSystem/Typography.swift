//
//  Typography.swift
//  Aurae
//
//  Defines the two custom typefaces (Fraunces, Plus Jakarta Sans), the semantic
//  type scale, and global layout constants. Reference these tokens everywhere;
//  never hardcode point sizes, font names, or spacing values in views.
//
//  Font files must be added to the Xcode target and declared in Info.plist under
//  "Fonts provided by application":
//    - Fraunces_72pt-Regular.ttf
//    - Fraunces_72pt-Bold.ttf
//    - PlusJakartaSans-Regular.ttf
//    - PlusJakartaSans-SemiBold.ttf
//

import SwiftUI

// MARK: - Custom font constructors

extension Font {

    // -------------------------------------------------------------------------
    // Fraunces — display and heading typeface
    // -------------------------------------------------------------------------

    /// Returns a Fraunces font at the given point size.
    /// Falls back to the system serif if the font file is not registered.
    static func fraunces(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let postScriptName = weight == .bold
            ? "Fraunces72pt-Bold"
            : "Fraunces72pt-Regular"
        return .custom(postScriptName, size: size)
    }

    /// Fraunces with Dynamic Type support. The `textStyle` controls how the
    /// size scales when the user changes their preferred content size category.
    static func fraunces(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        let postScriptName = weight == .bold
            ? "Fraunces72pt-Bold"
            : "Fraunces72pt-Regular"
        return .custom(postScriptName, size: size, relativeTo: textStyle)
    }

    // -------------------------------------------------------------------------
    // Plus Jakarta Sans — body and UI typeface
    // -------------------------------------------------------------------------

    /// Returns a Plus Jakarta Sans font at the given point size.
    /// Falls back to the system sans-serif if the font file is not registered.
    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let postScriptName = weight == .semibold
            ? "PlusJakartaSans-SemiBold"
            : "PlusJakartaSans-Regular"
        return .custom(postScriptName, size: size)
    }

    /// Plus Jakarta Sans with Dynamic Type support.
    static func jakarta(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        let postScriptName = weight == .semibold
            ? "PlusJakartaSans-SemiBold"
            : "PlusJakartaSans-Regular"
        return .custom(postScriptName, size: size, relativeTo: textStyle)
    }
}

// MARK: - Semantic type scale

extension Font {
    /// 48 pt Fraunces Bold — home screen hero numbers and app name.
    static let auraeDisplay = Font.fraunces(48, weight: .bold, relativeTo: .largeTitle)

    /// 32 pt Fraunces Bold — top-level section headings.
    static let auraeH1 = Font.fraunces(32, weight: .bold, relativeTo: .title)

    /// 22 pt Fraunces Regular — sub-section headings and card titles.
    static let auraeH2 = Font.fraunces(22, relativeTo: .title2)

    /// 16 pt Plus Jakarta Sans Regular — primary reading copy and form fields.
    static let auraeBody = Font.jakarta(16, relativeTo: .body)

    /// 13 pt Plus Jakarta Sans SemiBold — interactive labels, tab bar, buttons.
    static let auraeLabel = Font.jakarta(13, weight: .semibold, relativeTo: .caption)

    /// 12 pt Plus Jakarta Sans Regular — timestamps, metadata, fine print.
    static let auraeCaption = Font.jakarta(12, relativeTo: .caption2)
}

// MARK: - Layout constants

/// Global spacing, sizing, and shadow constants.
/// Use these in every view — never hardcode magic numbers.
enum Layout {
    // Horizontal padding applied to the full screen edge.
    static let screenPadding: CGFloat = 20

    // Standard corner radius for cards and surfaces.
    static let cardRadius: CGFloat = 18

    // Shadow radius applied to card surfaces.
    static let cardShadowRadius: CGFloat = 8

    // Shadow opacity for card surfaces (use with `.shadow(color:radius:x:y:)`).
    static let cardShadowOpacity: Double = 0.07

    // Y-offset for card drop shadows.
    static let cardShadowY: CGFloat = 4

    // Height of the primary CTA button (Log Headache, etc.).
    static let buttonHeight: CGFloat = 56

    // Corner radius of the primary CTA button.
    static let buttonRadius: CGFloat = 16

    // Minimum accessible tap target per Apple HIG and WCAG 2.1 AA.
    static let minTapTarget: CGFloat = 44

    // Vertical space between top-level page sections.
    static let sectionSpacing: CGFloat = 32

    // Vertical space between items within a section or card.
    static let itemSpacing: CGFloat = 12

    // Standard inner padding for card surfaces.
    static let cardPadding: CGFloat = 16

    // Height of each severity pill button in the severity selector.
    static let severityPillHeight: CGFloat = 44

    // Corner radius of severity pills.
    static let severityPillRadius: CGFloat = 12
}
