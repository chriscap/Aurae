//
//  OnsetSpeedSelector.swift
//  Aurae
//
//  Four-option onset speed picker. Fill-based pill design (updated 2026-02-23)
//  to match the revised SeveritySelector:
//    Selected:   auraeAdaptiveSoftTeal fill, auraeTealAccessible label (WCAG AA).
//    Unselected: auraeAdaptiveSecondary fill, auraeTextSecondary label (WCAG AA).
//  All four options — three speeds + "Not sure" — sit in a single HStack row
//  for compact vertical footprint. "Not sure" is visually identical but deselects
//  any prior selection (sets binding to nil).
//
//  Clinical note (D-33): The "Not sure" option is required to accommodate users
//  who were asleep at onset or cannot recall. A nil value triggers no safety
//  banner — it is always treated as no signal. Do not remove this option.
//

import SwiftUI

// MARK: - OnsetSpeedSelector

struct OnsetSpeedSelector: View {

    @Binding var selected: OnsetSpeed?

    /// Tracks whether the user has interacted with the selector.
    /// Distinguishes "nothing selected yet" from "actively chose Not sure".
    @State private var hasInteracted: Bool = false

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        // Single row: three speed options + "Not sure" escape hatch.
        // Compact layout keeps the Log Headache CTA visible on screen.
        HStack(spacing: 6) {
            ForEach([OnsetSpeed.gradual, .moderate, .instantaneous], id: \.self) { speed in
                OnsetSpeedPill(
                    speed: speed,
                    isSelected: selected == speed
                ) {
                    guard selected != speed else { return }
                    feedbackGenerator.impactOccurred()
                    hasInteracted = true
                    selected = speed
                }
            }

            // "Not sure" — inline with the three speed pills.
            // Only shows as selected after user explicitly taps it.
            OnsetSpeedPill(
                speed: nil,
                isSelected: hasInteracted && selected == nil
            ) {
                guard selected != nil || !hasInteracted else { return }
                feedbackGenerator.impactOccurred()
                hasInteracted = true
                selected = nil
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Onset speed selector")
        .accessibilityValue(selected.map { speedAccessibilityLabel($0) } ?? "Not sure")
    }

    private func speedAccessibilityLabel(_ speed: OnsetSpeed) -> String {
        switch speed {
        case .gradual:       return "Gradually, over 30 minutes or more"
        case .moderate:      return "Quickly, within about 1 to 30 minutes"
        case .instantaneous: return "Almost instantly, within seconds to about a minute"
        }
    }
}

// MARK: - OnsetSpeedPill

private struct OnsetSpeedPill: View {

    /// nil = "Not sure" option
    let speed: OnsetSpeed?
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 3) {
                Text(pillLabel)
                    .font(.jakarta(12, weight: .semibold))
                    .foregroundStyle(primaryLabelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let sub = sublabel {
                    // Fixed: 11pt with Dynamic Type binding (was 10pt, no scaling). (QA-C)
                    Text(sub)
                        .font(.jakarta(11, relativeTo: .caption2))
                        .foregroundStyle(sublabelColor)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Layout.severityPillHeight)
            .background(pillFill)
            .clipShape(Capsule())
            .scaleEffect(isSelected && !reduceMotion ? 1.03 : 1.0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pillLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Computed

    private var pillLabel: String {
        guard let speed else { return "Not sure" }
        switch speed {
        case .gradual:       return "Gradually"
        case .moderate:      return "Within minutes"
        case .instantaneous: return "Almost instantly"
        }
    }

    private var sublabel: String? {
        guard let speed else { return nil }
        switch speed {
        case .gradual:       return "30+ min"
        case .moderate:      return "1–30 min"
        case .instantaneous: return "Under 1 min"
        }
    }

    /// Selected: auraeTealAccessible (WCAG AA 4.55:1 on teal surface). (QA-B fix)
    /// Unselected: auraeTextSecondary (WCAG AA 5.3:1 on secondary surface). (QA-A fix)
    /// "Not sure": always uses auraeTextSecondary.
    private var primaryLabelColor: Color {
        isSelected && speed != nil
            ? Color.auraeTealAccessible
            : Color.auraeTextSecondary
    }

    /// Sublabel colour — full opacity for WCAG AA compliance.
    private var sublabelColor: Color {
        isSelected && speed != nil
            ? Color.auraeTealAccessible
            : Color.auraeTextSecondary
    }

    /// Selected speed pill: soft teal surface. Unselected / "Not sure": secondary surface.
    @ViewBuilder
    private var pillFill: some View {
        if isSelected && speed != nil {
            Color.auraeAdaptiveSoftTeal
        } else {
            Color.auraeAdaptiveSecondary
        }
    }
}

// MARK: - Preview

#Preview("Onset Speed Selector") {
    @Previewable @State var speed: OnsetSpeed? = nil

    VStack(spacing: 24) {
        OnsetSpeedSelector(selected: $speed)
        Text(speed.map { "\($0.rawValue)" } ?? "Not sure")
            .font(.auraeBody)
            .foregroundStyle(Color.auraeMidGray)
    }
    .padding(Layout.screenPadding)
    .background(Color.auraeAdaptiveBackground)
}
