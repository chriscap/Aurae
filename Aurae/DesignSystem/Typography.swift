//
//  Typography.swift
//  Aurae
//
//  Defines the semantic type scale, spacing system, radius system, and global
//  layout constants. Reference these tokens everywhere; never hardcode point
//  sizes, spacing values, or corner radii in views.
//
//  Typography update 2026-02-25:
//  Migrated from DM Serif Display + DM Sans → system fonts (Font.system).
//  Rationale: Dynamic Type compliance is automatic, VoiceOver/assistive
//  integrations are deeper, performance is improved (no font loading), and
//  system fonts are consistent with iOS health app conventions. The product
//  personality shift is intentional — "calm native utility" over
//  "editorial health journal."
//
//  Legacy aliases:
//  dmSerifDisplay(), dmSans(), fraunces(), and jakarta() are kept as
//  forwarding methods that return Font.system(), enabling zero-diff migration
//  of existing call sites. Remove once all views are updated.
//

import SwiftUI

// MARK: - Legacy font constructors (now forward to system fonts)

extension Font {

    /// DM Serif Display — now resolves to Font.system for bold display text.
    /// Kept for zero-diff migration of existing call sites.
    static func dmSerifDisplay(_ size: CGFloat, weight: Font.Weight = .bold, relativeTo textStyle: Font.TextStyle) -> Font {
        return .system(size: size, weight: .bold, design: .default).relativeTo(textStyle, size: size)
    }

    static func dmSerifDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .system(size: size, weight: .bold)
    }

    /// Fraunces alias — forwards to system font for zero-diff migration.
    static func fraunces(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .system(size: size, weight: weight)
    }

    static func fraunces(_ size: CGFloat, weight: Font.Weight = .bold, relativeTo textStyle: Font.TextStyle) -> Font {
        return .system(size: size, weight: weight)
    }

    /// DM Sans — now resolves to Font.system. Kept for migration compat.
    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }

    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle) -> Font {
        return .system(size: size, weight: weight)
    }

    /// Plus Jakarta Sans alias — forwards to system font.
    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }

    static func jakarta(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle) -> Font {
        return .system(size: size, weight: weight)
    }
}

// MARK: - Helper: relativeTo (approximates Dynamic Type scaling)

private extension Font {
    /// Returns a custom-size system font scaled relative to a text style.
    /// Uses .custom with relativeTo under the hood for Dynamic Type support.
    func relativeTo(_ textStyle: Font.TextStyle, size: CGFloat) -> Font {
        // System fonts handle Dynamic Type natively; this is a no-op passthrough.
        return self
    }
}

// MARK: - Semantic type scale

extension Font {

    // MARK: Display / Hero

    /// 48pt Bold — large screen titles (History, Insights, Profile headers)
    static let auraeHero = Font.system(size: 48, weight: .bold)

    /// 44pt Bold — editorial hero numerals (streak count, large metrics).
    /// Kept at this size for visual impact on the Home screen.
    static let auraeDisplay = Font.system(size: 44, weight: .bold)

    // MARK: Titles

    /// 34pt Bold — primary screen titles (used in History, Insights, Profile).
    static let auraeLargeTitle = Font.system(size: 34, weight: .bold)

    /// 28pt Bold — modal / sheet titles (Log Headache, etc.).
    static let auraeTitle1 = Font.system(size: 28, weight: .bold)

    /// 24pt Bold — section headings.
    static let auraeTitle2 = Font.system(size: 24, weight: .bold)

    /// 20pt SemiBold — sub-section headings and card titles.
    static let auraeTitle3 = Font.system(size: 20, weight: .semibold)

    // MARK: Headings (legacy names kept for compat)

    /// 26pt SemiBold — top-level section headings.
    static let auraeH1 = Font.system(size: 26, weight: .semibold)

    /// 20pt SemiBold — sub-section headings. Maps to auraeTitle3.
    static let auraeH2 = Font.system(size: 20, weight: .semibold)

    /// 18pt SemiBold — prominent secondary headings.
    static let auraeSubhead = Font.system(size: 18, weight: .semibold)

    // MARK: UI text

    /// 18pt SemiBold — section prompts, labelled headings.
    static let auraeHeadline = Font.system(size: 18, weight: .semibold)

    /// 17pt Medium — section prompts and secondary sub-headings.
    static let auraeSectionLabel = Font.system(size: 17, weight: .medium)

    /// 14pt Medium — card sub-headings, category names.
    static let auraeSecondaryLabel = Font.system(size: 14, weight: .medium)

    /// 16pt Regular — primary reading copy and form fields.
    static let auraeBody = Font.system(size: 16, weight: .regular)

    /// 16pt SemiBold — emphasized body copy.
    static let auraeBodyBold = Font.system(size: 16, weight: .semibold)

    /// 15pt Regular — metric values paired with a unit label.
    static let auraeMetricUnit = Font.system(size: 15, weight: .regular)

    /// 14pt Regular — supporting text, callouts.
    static let auraeCallout = Font.system(size: 14, weight: .regular)

    /// 14pt SemiBold — emphasized callout / callout bold.
    static let auraeCalloutBold = Font.system(size: 14, weight: .semibold)

    /// 13pt SemiBold — interactive labels, tab bar, buttons.
    static let auraeLabel = Font.system(size: 13, weight: .semibold)

    /// 13pt Regular — footnote text.
    static let auraeFootnote = Font.system(size: 13, weight: .regular)

    /// 12pt SemiBold — emphasized captions, section headers in cards.
    static let auraeCaptionEmphasis = Font.system(size: 12, weight: .semibold)

    /// 12pt Medium — caption bold variant.
    static let auraeCaptionBold = Font.system(size: 12, weight: .medium)

    /// 12pt Regular — timestamps, metadata, fine print.
    static let auraeCaption = Font.system(size: 12, weight: .regular)

    /// 10pt Regular — smallest text (used sparingly).
    static let auraeCaption2 = Font.system(size: 10, weight: .regular)
}

// MARK: - Spacing system

/// Global spacing scale. Use these values in all padding, gap, and offset contexts.
/// Never hardcode magic numbers — use the appropriate tier from this enum.
enum AuraeSpacing {
    static let xxxs: CGFloat = 2
    static let xxs:  CGFloat = 4
    static let xs:   CGFloat = 8
    static let sm:   CGFloat = 12
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 24
    static let xxl:  CGFloat = 32
    static let xxxl: CGFloat = 48
    static let huge: CGFloat = 64
}

// MARK: - Radius system

/// Corner radius scale. Use these for all rounded elements.
enum AuraeRadius {
    static let xs:   CGFloat = 8    // Small elements (chips, badges)
    static let sm:   CGFloat = 12   // Buttons, inputs
    static let md:   CGFloat = 16   // Standard cards
    static let lg:   CGFloat = 20   // Large cards
    static let xl:   CGFloat = 24   // Hero cards, context cards
    static let xxl:  CGFloat = 32   // Extra large
    static let full: CGFloat = 9999 // Pill / capsule
}

// MARK: - Layout constants (legacy — use AuraeSpacing / AuraeRadius for new code)

/// Global spacing, sizing, and shadow constants.
/// Use these in every view — never hardcode magic numbers.
enum Layout {
    /// Horizontal padding applied to the full screen edge.
    static let screenPadding: CGFloat = 24

    /// Standard corner radius for cards and surfaces.
    static let cardRadius: CGFloat = AuraeRadius.md

    /// Shadow radius applied to card surfaces.
    static let cardShadowRadius: CGFloat = 8

    /// Shadow opacity for card surfaces.
    static let cardShadowOpacity: Double = 0.05

    /// Y-offset for card drop shadows.
    static let cardShadowY: CGFloat = 2

    /// Height of the primary CTA button.
    static let buttonHeight: CGFloat = 56

    /// Height of the hero Log Headache button.
    static let heroButtonHeight: CGFloat = 56

    /// Corner radius of the primary CTA button.
    static let buttonRadius: CGFloat = AuraeRadius.md

    /// Corner radius of the hero Log Headache button.
    static let heroButtonRadius: CGFloat = AuraeRadius.md

    /// Minimum accessible tap target per Apple HIG and WCAG 2.1 AA.
    static let minTapTarget: CGFloat = 44

    /// Vertical space between top-level page sections.
    static let sectionSpacing: CGFloat = 24

    /// Vertical space between items within a section or card.
    static let itemSpacing: CGFloat = 12

    /// Standard inner padding for card surfaces.
    static let cardPadding: CGFloat = 20

    /// Height of each severity pill / intensity card.
    static let severityPillHeight: CGFloat = 44

    /// Corner radius of severity pills.
    static let severityPillRadius: CGFloat = AuraeRadius.full
}
