//
//  MedicalEscalationView.swift
//  Aurae
//
//  Static informational screen: "When to Seek Medical Care."
//
//  Entry points:
//    - Conditional safety banner in InsightsView (primary)
//    - Settings screen (secondary persistent entry point)
//
//  Clinical safety requirement (D-18, 22 Feb 2026):
//    This screen is available to ALL users (free and premium) and must
//    never be gated behind an entitlement check.
//
//  Copy source: clinical advisor recommendations (OQ-01).
//  Final copy requires legal review before V1 release.
//
//  Design: calm, minimal Aurae aesthetic. Not alarming, not clinical-cold.
//  All colours and fonts use design system tokens — no hardcoded values.
//

import SwiftUI

// MARK: - MedicalEscalationView

struct MedicalEscalationView: View {

    @Environment(\.dismiss) private var dismiss

    // Each warning item displayed in the list.
    fileprivate struct WarningItem {
        let icon: String
        let body: String
        let urgentNote: String?   // Optional red-flag sub-note (e.g. "Seek emergency care immediately.")
    }

    // Content sourced from clinical advisor (OQ-01). Do not modify without
    // clinical + legal sign-off.
    private let items: [WarningItem] = [
        WarningItem(
            icon: "bolt.fill",
            body: "A sudden, severe headache unlike any you've had before — sometimes described as the worst headache of your life.",
            urgentNote: "Seek emergency care immediately."
        ),
        WarningItem(
            icon: "thermometer.medium",
            body: "Headache with fever, stiff neck, confusion, or unusual sensitivity to light.",
            urgentNote: nil
        ),
        WarningItem(
            icon: "figure.fall",
            body: "A headache following a head injury or fall.",
            urgentNote: nil
        ),
        WarningItem(
            icon: "eye.trianglebadge.exclamationmark",
            body: "Weakness, numbness, difficulty speaking, or vision changes accompanying your headache.",
            urgentNote: nil
        ),
        WarningItem(
            icon: "waveform.path.ecg",
            body: "A new headache pattern that is rapidly getting worse, or headaches waking you from sleep.",
            urgentNote: nil
        ),
        WarningItem(
            icon: "person.fill.questionmark",
            body: "Your first significant headache after age 50.",
            urgentNote: nil
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.sectionSpacing) {

                        // Intro copy — empathetic, not clinical-cold
                        Text("Aurae helps you track headache patterns, but some symptoms benefit from prompt medical attention. Use this list as a reference.")
                            .font(.auraeBody)
                            .foregroundStyle(Color.auraeTextCaption)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        // Warning items list
                        VStack(spacing: Layout.itemSpacing) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                WarningRow(item: item)
                            }
                        }

                        // D-32: "About Frequent Medication Use" informational section.
                        // This is distinct from the emergency red-flag items above —
                        // it is informational in tone, not an escalation prompt.
                        Divider()
                            .padding(.vertical, Layout.itemSpacing)

                        Text("About Frequent Medication Use")
                            .font(.auraeSecondaryLabel)
                            .foregroundStyle(Color.auraeTextSecondary)

                        VStack(spacing: Layout.itemSpacing) {
                            WarningRow(item: WarningItem(
                                icon: "pills.fill",
                                body: "If you find yourself taking medication for headache relief on many days each month, this is worth discussing with a doctor or neurologist. In some cases, taking certain pain relievers very frequently may itself contribute to more frequent headaches over time. Your clinician can help you understand whether this applies to your situation.",
                                urgentNote: nil
                            ))
                        }

                        Text("This information is for general awareness only. Aurae does not diagnose medication overuse headache or any other condition.")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTextCaption.opacity(0.8))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        // Footer disclaimer
                        Text("This list is not exhaustive. Aurae is a tracking tool, not a medical advisor. If you are concerned about your symptoms, please consult a qualified healthcare professional.")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTextCaption.opacity(0.8))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, Layout.itemSpacing)
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.top, Layout.itemSpacing)
                    .padding(.bottom, Layout.sectionSpacing + Layout.buttonHeight)
                }

                // Sticky Done button
                VStack {
                    Spacer()
                    doneButtonBar
                }
            }
            .navigationTitle("When to Seek Medical Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.auraeMidGray)
                            .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    // MARK: - Done button bar

    private var doneButtonBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.auraeAdaptiveBackground.opacity(0), Color.auraeAdaptiveBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            AuraeButton("Done") { dismiss() }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, Layout.itemSpacing)
                .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - WarningRow

private struct WarningRow: View {

    let item: MedicalEscalationView.WarningItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // Icon badge — amber colour signals attention without aggressive red.
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.auraeAmber.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.auraeAmber)
            }
            // Decorative badge — body text carries the full meaning for VoiceOver.
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.body)
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeTextPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let note = item.urgentNote {
                    Text(note)
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeAmber)
                }
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0,
            y: Layout.cardShadowY
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.urgentNote.map { "\(item.body) \($0)" } ?? item.body)
    }
}

// MARK: - Preview

#Preview("MedicalEscalationView") {
    MedicalEscalationView()
}
