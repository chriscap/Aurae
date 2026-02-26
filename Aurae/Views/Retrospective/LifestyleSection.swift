//
//  LifestyleSection.swift
//  Aurae
//
//  Collapsible Lifestyle section for the retrospective entry screen.
//
//  Controls:
//  - Sleep hours slider (0–12h, step 0.5h) — optionally pre-populated from
//    the HealthKit snapshot, indicated by a subtle "From Apple Health" badge.
//  - Sleep quality: 1–5 star rating
//  - Stress level: 1–5 picker (pill style, same as severity selector)
//  - Screen time stepper (0–16h, step 0.5h)
//

import SwiftUI

struct LifestyleSection: View {

    @Binding var sleepHours: Double
    @Binding var sleepHoursSet: Bool
    let sleepPrefilledFromHealth: Bool
    @Binding var sleepQuality: Int
    @Binding var stressLevel: Int
    @Binding var screenTimeHours: Double
    let hasData: Bool

    @State private var isExpanded: Bool = true

    var body: some View {
        RetroSectionContainer(
            title: "Lifestyle",
            hasData: hasData,
            isExpanded: $isExpanded
        ) {
            // Sleep hours slider
            sleepSlider

            // Sleep quality stars
            RetroStarRating(label: "Sleep quality", rating: $sleepQuality)

            // Stress level pills
            stressLevelPicker

            // Screen time stepper
            RetroStepperDouble(
                label: "Screen time",
                value: $screenTimeHours,
                range: 0...16,
                step: 0.5,
                formatValue: {
                    $0 == 0 ? "None" : ($0 == 1 ? "1h" : String(format: "%.1gh", $0))
                }
            )
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Sleep slider
    // -------------------------------------------------------------------------

    private var sleepSlider: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            HStack {
                Text("Sleep")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Spacer()

                // Pre-filled badge
                if sleepPrefilledFromHealth {
                    Label("Apple Health", systemImage: "heart.fill")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraePrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.auraeAccent)
                        .clipShape(Capsule())
                }

                // Current value label
                Text(sleepHoursSet ? formatSleep(sleepHours) : "Not set")
                    .font(.auraeLabel)
                    .foregroundStyle(sleepHoursSet ? Color.auraeAdaptivePrimaryText : Color.auraeMidGray)
                    .frame(minWidth: 52, alignment: .trailing)
            }

            Slider(value: $sleepHours, in: 0...12, step: 0.5)
                .tint(Color.auraePrimary)
                .onChange(of: sleepHours) { _, _ in
                    sleepHoursSet = true
                }
                .accessibilityLabel("Sleep hours")
                .accessibilityValue(sleepHoursSet ? formatSleep(sleepHours) : "Not set")

            // Axis labels
            HStack {
                Text("0h")
                Spacer()
                Text("6h")
                Spacer()
                Text("12h")
            }
            .font(.auraeCaption)
            .foregroundStyle(Color.auraeMidGray)
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }

    // -------------------------------------------------------------------------
    // MARK: Stress level picker
    // -------------------------------------------------------------------------

    private var stressLevelPicker: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            HStack {
                Text("Stress level")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                Spacer()
                if stressLevel > 0 {
                    Text(stressLabel(stressLevel))
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                }
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        if stressLevel == level {
                            stressLevel = 0 // deselect
                        } else {
                            stressLevel = level
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("\(level)")
                            .font(.auraeLabel)
                            .foregroundStyle(stressLevel == level ? Color.auraeTealAccessible : Color.auraeAdaptivePrimaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.severityPillHeight)
                            .background(
                                stressLevel == level
                                    ? Color.auraeAdaptiveSoftTeal
                                    : Color.auraeAdaptiveSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Layout.severityPillRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stress level \(level)")
                    .accessibilityAddTraits(stressLevel == level ? [.isSelected] : [])
                }
            }
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }

    // -------------------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------------------

    private func formatSleep(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func stressLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Very low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Extreme"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var sleepHours: Double     = 6.5
    @Previewable @State var sleepHoursSet: Bool    = true
    @Previewable @State var sleepQuality: Int      = 3
    @Previewable @State var stressLevel: Int       = 4
    @Previewable @State var screenTimeHours: Double = 3.0

    ScrollView {
        LifestyleSection(
            sleepHours:              $sleepHours,
            sleepHoursSet:           $sleepHoursSet,
            sleepPrefilledFromHealth: true,
            sleepQuality:            $sleepQuality,
            stressLevel:             $stressLevel,
            screenTimeHours:         $screenTimeHours,
            hasData:                 true
        )
        .padding(Layout.screenPadding)
    }
    .background(Color.auraeAdaptiveBackground)
}
