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

            // Dose text field — only show once a name is entered
            if !medicationName.isEmpty {
                RetroTextField(
                    placeholder: "Dose (e.g. 400 mg)",
                    text: $medicationDose
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Effectiveness stars — only show once a name is entered
            if !medicationName.isEmpty {
                RetroStarRating(label: "Effectiveness", rating: $medicationEffectiveness)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: medicationName.isEmpty)
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
                                        ? .white
                                        : Color.auraeNavy
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    medicationName == suggestion
                                        ? Color.auraeTeal
                                        : Color.auraeLavender
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
    @Previewable @State var name: String         = "Ibuprofen"
    @Previewable @State var dose: String         = "400 mg"
    @Previewable @State var effectiveness: Int   = 4

    ScrollView {
        MedicationSection(
            medicationName:          $name,
            medicationDose:          $dose,
            medicationEffectiveness: $effectiveness,
            hasData:                 true
        )
        .padding(Layout.screenPadding)
    }
    .background(Color.auraeBackground)
}
