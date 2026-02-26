//
//  EnvironmentSection.swift
//  Aurae
//
//  Collapsible Environment section for the retrospective entry screen.
//
//  Controls:
//  - Environmental trigger chips (Bright light, Loud noise, Strong smell, etc.)
//  - Symptom chips (Nausea, Light sensitivity, Sound sensitivity, etc.)
//  - Headache location: segmented picker (Front, Sides, Back, Top, Whole head)
//  - Headache type: segmented picker (Tension, Migraine, Cluster, Unknown)
//  - Cycle phase: optional picker ("" = not set)
//  - Notes: multi-line text editor
//

import SwiftUI

struct EnvironmentSection: View {

    @Binding var selectedTriggers: Set<String>
    @Binding var selectedSymptoms: Set<String>
    @Binding var headacheLocation: String
    @Binding var headacheType: String
    @Binding var cyclePhase: String
    @Binding var notes: String
    let hasData: Bool

    @State private var isExpanded: Bool = true

    var body: some View {
        RetroSectionContainer(
            title: "Environment & Symptoms",
            hasData: hasData,
            isExpanded: $isExpanded
        ) {
            // Environmental triggers
            RetroChipSection(
                label: "Triggers",
                items: RetrospectiveViewModel.triggerChips,
                selected: $selectedTriggers
            )

            // Symptoms
            RetroChipSection(
                label: "Symptoms",
                items: RetrospectiveViewModel.symptomChips,
                selected: $selectedSymptoms
            )

            // Headache location
            locationPicker

            // Headache type
            headacheTypePicker

            // Cycle phase
            cyclePhasePicker

            // Notes
            notesEditor
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Location picker
    // -------------------------------------------------------------------------

    private var locationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            SingleSelectPillGroup(
                options:  RetrospectiveViewModel.locationOptions,
                selected: $headacheLocation
            )
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }

    // -------------------------------------------------------------------------
    // MARK: Headache type picker
    // -------------------------------------------------------------------------

    private var headacheTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            SingleSelectPillGroup(
                options:  RetrospectiveViewModel.headacheTypeOptions.map(\.label),
                keyMap:   Dictionary(
                    uniqueKeysWithValues: RetrospectiveViewModel.headacheTypeOptions.map { ($0.label, $0.key) }
                ),
                selected: $headacheType
            )

            // D-24 (22 Feb 2026): Non-dismissible inline disclaimer required by
            // clinical review. The headache type taxonomy is user-selected, not
            // clinically validated — the UI must reflect that ambiguity.
            Text("Self-reported. Select the type that best matches your experience.")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }

    // -------------------------------------------------------------------------
    // MARK: Cycle phase picker
    // -------------------------------------------------------------------------

    private var cyclePhasePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cycle Phase")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            SingleSelectPillGroup(
                options:  RetrospectiveViewModel.cyclePhaseOptions.map(\.label),
                keyMap:   Dictionary(
                    uniqueKeysWithValues: RetrospectiveViewModel.cyclePhaseOptions.map { ($0.label, $0.key) }
                ),
                selected: $cyclePhase
            )
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }

    // -------------------------------------------------------------------------
    // MARK: Notes editor
    // -------------------------------------------------------------------------

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Any additional observations...")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeMidGray.opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $notes)
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
            }
            .padding(Layout.cardPadding)
            .background(Color.auraeAdaptiveSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
        }
    }

}

// MARK: - Preview

#Preview {
    @Previewable @State var triggers: Set<String>  = ["bright_light", "loud_noise"]
    @Previewable @State var symptoms: Set<String>  = ["nausea"]
    @Previewable @State var location: String       = "Front"
    @Previewable @State var type: String           = "tension"
    @Previewable @State var phase: String          = ""
    @Previewable @State var notes: String          = ""

    ScrollView {
        EnvironmentSection(
            selectedTriggers: $triggers,
            selectedSymptoms: $symptoms,
            headacheLocation: $location,
            headacheType:     $type,
            cyclePhase:       $phase,
            notes:            $notes,
            hasData:          true
        )
        .padding(Layout.screenPadding)
    }
    .background(Color.auraeAdaptiveBackground)
}
