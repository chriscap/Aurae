//
//  MedicationSection.swift
//  Aurae
//
//  Collapsible Medication section for the retrospective entry screen.
//
//  Controls:
//  - Medication name text field with inline suggestions chip row
//    (Ibuprofen, Paracetamol, Sumatriptan, Aspirin, Naproxen)
//  - Dose text field (free text, e.g. "400 mg")
//  - Effectiveness: 1–5 star rating
//

import SwiftUI

struct MedicationSection: View {

    @Binding var medicationName: String
    @Binding var medicationDose: String
    @Binding var medicationEffectiveness: Int
    /// D-32: acute vs preventive classification. Nil = not yet classified.
    @Binding var medicationIsAcute: Bool?
    let hasData: Bool

    @State private var isExpanded: Bool = true
    @FocusState private var nameFocused: Bool
    @FocusState private var doseFocused: Bool

    var body: some View {
        RetroSectionContainer(
            title: "Medication",
            hasData: hasData,
            isExpanded: $isExpanded
        ) {
            // Medication name field + quick-select suggestions
            medicationNameField

            // Fields shown only once a name is entered
            if !medicationName.isEmpty {
                // D-32: Medication type classification toggle
                medicationTypeToggle
                    .transition(.move(edge: .top).combined(with: .opacity))

                RetroTextField(
                    placeholder: "Dose (e.g. 400 mg)",
                    text: $medicationDose
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Effectiveness stars — only show once a name is entered
            if !medicationName.isEmpty {
                RetroStarRating(label: "How much did it help?", rating: $medicationEffectiveness)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: medicationName.isEmpty)
    }

    // -------------------------------------------------------------------------
    // MARK: Medication type toggle (D-32)
    // -------------------------------------------------------------------------

    /// Two-pill acute/preventive toggle. Shown only when a medication name is entered.
    /// Binding is Bool?: true = acute, false = preventive, nil = not yet classified.
    private var medicationTypeToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How do you take this medication?")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)

            HStack(spacing: 8) {
                medicationTypePill(
                    label: "For headache relief",
                    isSelected: medicationIsAcute == true
                ) {
                    medicationIsAcute = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                medicationTypePill(
                    label: "Daily as prescribed",
                    isSelected: medicationIsAcute == false
                ) {
                    medicationIsAcute = false
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("How do you take this medication?")
        .accessibilityValue(medicationIsAcute == true
            ? "For headache relief"
            : medicationIsAcute == false
                ? "Daily as prescribed"
                : "Not answered")
    }

    private func medicationTypePill(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(isSelected ? Color.auraeTealAccessible : Color.auraeAdaptivePrimaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.auraeAccent : Color.auraeAdaptiveSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? Color.auraeBorder : Color.auraeBorder,
                        lineWidth: 0.5
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // -------------------------------------------------------------------------
    // MARK: Medication name field
    // -------------------------------------------------------------------------

    private var medicationNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            RetroTextField(
                placeholder: "Medication name",
                text: $medicationName
            )

            // Quick-select suggestion chips — shown always for discoverability.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RetrospectiveViewModel.medicationSuggestions, id: \.self) { suggestion in
                        Button {
                            medicationName = suggestion
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(suggestion)
                                .font(.auraeCaption)
                                .foregroundStyle(
                                    medicationName == suggestion
                                        ? Color.auraeTealAccessible
                                        : Color.auraeAdaptivePrimaryText
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    medicationName == suggestion
                                        ? Color.auraeAdaptiveSoftTeal
                                        : Color.auraeAdaptiveSecondary
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(suggestion)
                        .accessibilityAddTraits(
                            medicationName == suggestion ? [.isSelected] : []
                        )
                    }
                }
                .padding(.horizontal, 1) // prevent clip
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var name:         String = "Ibuprofen"
    @Previewable @State var dose:         String = "400 mg"
    @Previewable @State var effectiveness: Int   = 4
    @Previewable @State var isAcute: Bool?       = nil

    ScrollView {
        MedicationSection(
            medicationName:          $name,
            medicationDose:          $dose,
            medicationEffectiveness: $effectiveness,
            medicationIsAcute:       $isAcute,
            hasData:                 true
        )
        .padding(Layout.screenPadding)
    }
    .background(Color.auraeAdaptiveBackground)
}
