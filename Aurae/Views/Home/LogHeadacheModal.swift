//
//  LogHeadacheModal.swift
//  Aurae
//
//  Modal sheet for logging a new headache onset.
//  Presented when the user taps the "Log Headache" card on HomeView.
//
//  Layout (design director order):
//  1. How intense is it?   — SeveritySelector  (required to submit)
//  2. How did it start?    — OnsetSpeedSelector
//  3. Capturing context    — informational card (auto-capture status)
//  4. Where does it hurt?  — single-select location chips
//  5. Any other symptoms?  — multi-select symptom chips
//  6. Sticky "Log Headache" CTA — always visible at modal bottom
//
//  Data flow:
//  - Local @State holds all form inputs until submission.
//  - On submit, HomeViewModel.logHeadache(severity:onsetSpeed:location:symptoms:context:)
//    creates the log and a partial RetrospectiveEntry, then fires background capture.
//  - The RetrospectiveViewModel reads the partial entry on next open, pre-populating
//    location and symptoms as already-toggled-on selections.
//

import SwiftUI
import SwiftData

struct LogHeadacheModal: View {

    @Environment(\.dismiss)                  private var dismiss
    @Environment(\.modelContext)             private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var viewModel: HomeViewModel

    // MARK: Local form state

    @State private var selectedSeverity:   SeverityLevel?  = nil
    @State private var selectedOnsetSpeed: OnsetSpeed?     = nil
    @State private var selectedLocation:   String          = ""
    @State private var selectedSymptoms:   Set<String>     = []

    // MARK: Location options (must match RetrospectiveViewModel.locationOptions)

    private let locationOptions = [
        "Forehead", "Temples", "Back of head", "One side", "Entire head"
    ]

    // Subset shown at log time — most clinically relevant at onset.
    // Full list is available in the retrospective flow.
    private let modalSymptomChips: [ChipItem] = [
        ChipItem(id: "nausea",            label: "Nausea"),
        ChipItem(id: "light_sensitivity", label: "Light sensitivity"),
        ChipItem(id: "sound_sensitivity", label: "Sound sensitivity"),
        ChipItem(id: "aura",              label: "Visual aura"),
        ChipItem(id: "dizziness",         label: "Dizziness"),
    ]

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AuraeSpacing.xxl) {
                        severitySection
                        onsetSpeedSection
                        contextCard
                        locationSection
                        symptomsSection
                        Spacer(minLength: Layout.buttonHeight + 48)
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.top, AuraeSpacing.lg)
                }

                stickyLogButton
            }
            .navigationTitle("Log Headache")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(Color.auraeAdaptiveSecondary)
                                .frame(width: 30, height: 30)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        }
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    // MARK: - Severity

    private var severitySection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            HStack(spacing: AuraeSpacing.xs) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.auraeMidGray)
                    .accessibilityHidden(true)
                Text("How are you feeling?")
                    .font(.auraeHeadline)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
            }
            SeveritySelector(selected: $selectedSeverity)
        }
    }

    // MARK: - Onset speed

    private var onsetSpeedSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            Text("How did it start?")
                .font(.auraeHeadline)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
            OnsetSpeedSelector(selected: $selectedOnsetSpeed)
        }
    }

    // MARK: - Context card

    private var contextCard: some View {
        HStack(spacing: AuraeSpacing.md) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.auraePrimary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Capturing context")
                    .font(.auraeCalloutBold)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                Text("Location and weather are captured automatically on log.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextSecondary)
            }

            Spacer()
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Location and weather are captured automatically when you log.")
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            Text("Where does it hurt?")
                .font(.auraeHeadline)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            WrappingHStack(spacing: 8) {
                ForEach(locationOptions, id: \.self) { option in
                    locationChip(option)
                }
            }
        }
    }

    private func locationChip(_ option: String) -> some View {
        let isSelected = selectedLocation == option
        return Button {
            selectedLocation = isSelected ? "" : option
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(option)
                .font(.auraeLabel)
                .foregroundStyle(isSelected ? Color.auraePrimary : Color.auraeAdaptivePrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.auraeAccent : Color.auraeAdaptiveCard)
                .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.auraePrimary.opacity(0.50) : Color.auraeBorder,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Symptoms

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            Text("Any other symptoms?")
                .font(.auraeHeadline)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            WrappingHStack(spacing: 8) {
                ForEach(modalSymptomChips) { chip in
                    symptomChip(chip)
                }
            }
        }
    }

    private func symptomChip(_ chip: ChipItem) -> some View {
        let isSelected = selectedSymptoms.contains(chip.id)
        return Button {
            if isSelected {
                selectedSymptoms.remove(chip.id)
            } else {
                selectedSymptoms.insert(chip.id)
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(chip.label)
                .font(.auraeLabel)
                .foregroundStyle(isSelected ? Color.auraePrimary : Color.auraeAdaptivePrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.auraeAccent : Color.auraeAdaptiveCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? Color.auraePrimary.opacity(0.50) : Color.auraeBorder,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(chip.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Sticky CTA

    private var stickyLogButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.auraeAdaptiveBackground.opacity(0),
                    Color.auraeAdaptiveBackground.opacity(0.9),
                    Color.auraeAdaptiveBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)

            AuraeButton(
                "Log Headache",
                style: .hero,
                isLoading: viewModel.isLogging,
                isDisabled: selectedSeverity == nil
            ) {
                guard let severity = selectedSeverity else { return }
                viewModel.logHeadache(
                    severity:   severity,
                    onsetSpeed: selectedOnsetSpeed,
                    location:   selectedLocation,
                    symptoms:   Array(selectedSymptoms),
                    context:    modelContext
                )
                dismiss()
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 8)
            .background(Color.auraeAdaptiveBackground)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Preview

#Preview("Log Modal") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return LogHeadacheModal(viewModel: HomeViewModel())
        .modelContainer(container)
}
