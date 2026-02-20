//
//  SeveritySelector.swift
//  Aurae
//
//  A reusable 1–5 severity picker. Each level renders as a labelled pill that
//  fills with the appropriate severity surface colour when selected. The control
//  provides haptic feedback on each selection change and meets the 44 pt minimum
//  tap target. All colour and font references come from the design system.
//

import SwiftUI

// MARK: - Severity level model

/// Represents one of the five named severity levels Aurae uses throughout the app.
enum SeverityLevel: Int, CaseIterable, Identifiable {
    case mild       = 1
    case moderate   = 2
    case severe     = 3
    case verySevere = 4
    case worst      = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .mild:       return "Mild"
        case .moderate:   return "Moderate"
        case .severe:     return "Severe"
        case .verySevere: return "Very Severe"
        case .worst:      return "Worst"
        }
    }

    /// Single-character shorthand shown when horizontal space is tight.
    var shortLabel: String {
        switch self {
        case .mild:       return "1"
        case .moderate:   return "2"
        case .severe:     return "3"
        case .verySevere: return "4"
        case .worst:      return "5"
        }
    }

    var accessibilityLabel: String {
        "Severity \(rawValue) of 5 — \(label)"
    }
}

// MARK: - SeveritySelector

/// Horizontal severity picker rendering five labelled pill buttons.
///
/// Usage:
/// ```swift
/// @State private var severity = SeverityLevel.moderate
/// SeveritySelector(selected: $severity)
/// ```
///
/// Use `compact: true` to show numeric short-labels instead of full text,
/// for use in constrained containers such as log cards.
struct SeveritySelector: View {

    @Binding var selected: SeverityLevel
    var compact: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SeverityLevel.allCases) { level in
                SeverityPill(
                    level: level,
                    isSelected: selected == level,
                    compact: compact
                ) {
                    guard selected != level else { return }
                    feedbackGenerator.impactOccurred()
                    withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7)) {
                        selected = level
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Severity selector")
    }
}

// MARK: - SeverityPill

private struct SeverityPill: View {

    let level: SeverityLevel
    let isSelected: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(compact ? level.shortLabel : level.label)
                .font(.auraeLabel)
                .foregroundStyle(isSelected ? .white : Color.auraeMidGray)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, compact ? 8 : 10)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.severityPillHeight)
                .background(pillBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.severityPillRadius, style: .continuous))
                .overlay(pillBorder)
                // Lift the selected pill with a subtle shadow so it reads as
                // the active state without relying on colour contrast alone.
                .shadow(
                    color: isSelected
                        ? Color.severityAccent(for: level.rawValue).opacity(0.25)
                        : .clear,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(level.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            Color.severityAccent(for: level.rawValue)
        } else {
            Color.severitySurface(for: level.rawValue)
        }
    }

    private var pillBorder: some View {
        RoundedRectangle(cornerRadius: Layout.severityPillRadius, style: .continuous)
            .strokeBorder(
                isSelected
                    ? Color.severityAccent(for: level.rawValue)
                    : Color.severityAccent(for: level.rawValue).opacity(0.2),
                lineWidth: 1.5
            )
    }
}

// MARK: - Preview

#Preview("Severity Selector") {
    @Previewable @State var severity: SeverityLevel = .moderate

    VStack(spacing: 24) {
        SeveritySelector(selected: $severity)

        Text("Selected: \(severity.label)")
            .font(.auraeBody)
            .foregroundStyle(Color.auraeMidGray)

        SeveritySelector(selected: $severity, compact: true)
    }
    .padding(Layout.screenPadding)
    .background(Color.auraeBackground)
}
