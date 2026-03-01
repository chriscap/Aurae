//
//  SeveritySelector.swift
//  Aurae
//
//  Three-level severity scale: Mild / Moderate / Severe.
//
//  Integer values are 1 / 3 / 5 (skipping 2 and 4) to preserve the
//  InsightsService thresholds:  severity >= 4 = "bad days",
//                               severity <= 2 = "good days".
//
//  Reduced from 5 to 3 levels 2026-02-28 per PM decision (D-53) and
//  Clinical Advisor conditional approval. The prior "Light" (2) and
//  "Extreme" (5) labels had no validated clinical basis. "Mild / Moderate
//  / Severe" aligns with ICHD-3 vocabulary.
//
//  Each card shows a functional behavioral anchor below the label (clinical
//  requirement: reduces subjective variability across logging events).
//
//  Usage:
//  ```swift
//  @State private var severity: SeverityLevel? = nil
//  SeveritySelector(selected: $severity)
//  ```
//

import SwiftUI

// MARK: - Severity level model

/// Three-level severity scale. Raw values 1/3/5 preserve InsightsService thresholds.
enum SeverityLevel: Int, CaseIterable, Identifiable {
    case mild     = 1
    case moderate = 3
    case severe   = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .severe:   return "Severe"
        }
    }

    /// Functional behavioral anchor shown below the label at logging time.
    /// Derived from MIDAS/ICHD-3 functional disability framing (D-53).
    var behavioralAnchor: String {
        switch self {
        case .mild:     return "Noticeable but does not limit my activity"
        case .moderate: return "Limits some of my usual activities"
        case .severe:   return "Prevents me from doing my usual activities"
        }
    }

    /// Desaturated warm color dot for this severity level.
    var color: Color { Color.severityAccent(for: rawValue) }

    /// Pill fill color for compact pill-style selectors.
    var pillFill: Color { Color.severityPillFill(for: rawValue) }

    var accessibilityLabel: String { "\(label). \(behavioralAnchor)" }
}

// MARK: - SeveritySelector (card style — for log modal)

/// Vertical stack of selection cards for the Log Headache modal.
/// Each card is 64pt tall with a color dot and severity label.
struct SeveritySelector: View {

    @Binding var selected: SeverityLevel?
    /// When true, renders as compact horizontal pills (e.g. History filter).
    var compact: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        if compact {
            HStack(spacing: 8) {
                ForEach(SeverityLevel.allCases) { level in
                    compactPill(level: level)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Severity selector")
            .accessibilityValue(selected?.label ?? "None selected")
        } else {
            VStack(spacing: AuraeSpacing.xs) {
                ForEach(SeverityLevel.allCases) { level in
                    severityCard(level: level)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Intensity selector")
            .accessibilityValue(selected?.label ?? "None selected")
        }
    }

    // MARK: Card (full-size, for log modal)

    private func severityCard(level: SeverityLevel) -> some View {
        let isSelected = selected == level
        return Button {
            guard selected != level else { return }
            feedbackGenerator.impactOccurred()
            withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7)) {
                selected = level
            }
        } label: {
            HStack(spacing: AuraeSpacing.md) {
                Circle()
                    .fill(level.color)
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.label)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected
                            ? Color.auraePrimary
                            : Color.auraeAdaptivePrimaryText)
                    Text(level.behavioralAnchor)
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected
                            ? Color.auraePrimary.opacity(0.75)
                            : Color.auraeTextCaption)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.auraePrimary)
                }
            }
            .padding(.horizontal, AuraeSpacing.md)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .background(isSelected ? Color.auraeAccent : Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.auraePrimary : Color.auraeBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(level.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Compact pill (for LogCard, History list, etc.)

    private func compactPill(level: SeverityLevel) -> some View {
        let isSelected = selected == level
        return Button {
            guard selected != level else { return }
            feedbackGenerator.impactOccurred()
            selected = level
        } label: {
            Text(level.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected
                    ? Color.auraeSeverityLabelSelected
                    : Color.auraeTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Layout.severityPillHeight)
                .background(isSelected
                    ? level.pillFill
                    : Color.auraeAdaptiveSecondary)
                .clipShape(Capsule())
                .scaleEffect(isSelected && !reduceMotion ? 1.03 : 1.0)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                    value: isSelected
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(level.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("SeveritySelector — cards") {
    @Previewable @State var severity: SeverityLevel? = nil

    VStack(spacing: 24) {
        SeveritySelector(selected: $severity)

        Text(severity.map { "Selected: \($0.label)" } ?? "None selected")
            .font(.auraeBody)
            .foregroundStyle(Color.auraeMidGray)
    }
    .padding(Layout.screenPadding)
    .background(Color.auraeAdaptiveBackground)
}

#Preview("SeveritySelector — compact pills") {
    @Previewable @State var severity: SeverityLevel? = nil

    SeveritySelector(selected: $severity, compact: true)
        .padding(Layout.screenPadding)
        .background(Color.auraeAdaptiveBackground)
}
