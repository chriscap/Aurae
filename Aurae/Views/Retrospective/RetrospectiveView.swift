//
//  RetrospectiveView.swift
//  Aurae
//
//  Full-screen retrospective entry form. Presented modally from the History tab
//  (or the Log Detail screen) after a headache has been resolved.
//
//  Layout:
//  - NavigationStack with "Log Details" title (inline)
//  - Completion ring in the leading nav bar position
//  - Scrollable VStack of four collapsible sections
//  - Sticky "Save" AuraeButton pinned below the scroll area
//  - Discard alert when user dismisses with unsaved changes
//
//  Shared primitive components used by the section sub-views live at the bottom
//  of this file as internal (module-visible) structs:
//    RetroSectionContainer  — disclosure group wrapper with completion dot
//    ChipGrid               — wrapping grid of multi-select chips
//    RetroChipSection       — labelled wrapper around ChipGrid
//    WrappingHStack         — flow-layout HStack (no ViewThatFits dependency)
//    RetroStarRating        — 1–5 tappable star row
//    RetroStepper<V>        — labelled integer stepper with formatted value label
//    RetroStepperDouble     — labelled Double stepper (0.5 step)
//    RetroTextField         — single-line branded text field
//

import SwiftUI
import SwiftData

// MARK: - RetrospectiveView

struct RetrospectiveView: View {

    // -------------------------------------------------------------------------
    // MARK: Dependencies
    // -------------------------------------------------------------------------

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RetrospectiveViewModel

    // -------------------------------------------------------------------------
    // MARK: UI state
    // -------------------------------------------------------------------------

    @State private var showDiscardAlert: Bool = false

    // -------------------------------------------------------------------------
    // MARK: Init
    // -------------------------------------------------------------------------

    init(log: HeadacheLog, context: ModelContext) {
        _viewModel = State(initialValue: RetrospectiveViewModel(log: log, context: context))
    }

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Layout.sectionSpacing) {
                        // Progress hint — complements the small CompletionRing in the toolbar
                        progressHint

                        FoodDrinkSection(
                            selectedMeals:    $viewModel.selectedMeals,
                            alcoholDetail:    $viewModel.alcoholDetail,
                            caffeineIntakeMg: $viewModel.caffeineIntakeMg,
                            hydrationGlasses: $viewModel.hydrationGlasses,
                            skippedMeal:      $viewModel.skippedMeal,
                            hasData:          viewModel.foodSectionHasData
                        )

                        LifestyleSection(
                            sleepHours:               $viewModel.sleepHours,
                            sleepHoursSet:            $viewModel.sleepHoursSet,
                            sleepPrefilledFromHealth:  viewModel.sleepPrefilledFromHealth,
                            sleepQuality:             $viewModel.sleepQuality,
                            stressLevel:              $viewModel.stressLevel,
                            screenTimeHours:          $viewModel.screenTimeHours,
                            hasData:                  viewModel.lifestyleSectionHasData
                        )

                        MedicationSection(
                            medicationName:          $viewModel.medicationName,
                            medicationDose:          $viewModel.medicationDose,
                            medicationEffectiveness: $viewModel.medicationEffectiveness,
                            medicationIsAcute:       $viewModel.medicationIsAcute,
                            hasData:                 viewModel.medicationSectionHasData
                        )

                        EnvironmentSection(
                            selectedTriggers: $viewModel.selectedTriggers,
                            selectedSymptoms: $viewModel.selectedSymptoms,
                            headacheLocation: $viewModel.headacheLocation,
                            headacheType:     $viewModel.headacheType,
                            cyclePhase:       $viewModel.cyclePhase,
                            notes:            $viewModel.notes,
                            hasData:          viewModel.environmentSectionHasData
                        )

                        // Bottom padding so the sticky Save button does not
                        // obscure the last section's content.
                        Spacer(minLength: Layout.buttonHeight + Layout.sectionSpacing)
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.top, Layout.itemSpacing)
                }

                // Sticky save button — sits above the scroll content
                saveButtonBar
            }
            .navigationTitle("Log Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Discard changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. They will be lost if you go back now.")
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Toolbar
    // -------------------------------------------------------------------------

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Completion ring — leading position
        ToolbarItem(placement: .navigationBarLeading) {
            CompletionRing(fraction: viewModel.completionFraction)
        }

        // Dismiss button — trailing
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                if viewModel.hasUnsavedChanges {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.auraeMidGray)
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            }
            .accessibilityLabel("Close")
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Progress hint
    // -------------------------------------------------------------------------

    private var progressHint: some View {
        let completedCount = [
            viewModel.foodSectionHasData,
            viewModel.lifestyleSectionHasData,
            viewModel.medicationSectionHasData,
            viewModel.environmentSectionHasData
        ].filter { $0 }.count

        return Text("\(completedCount) of 4 sections complete")
            .font(.auraeCaption)
            .foregroundStyle(Color.auraeMidGray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // -------------------------------------------------------------------------
    // MARK: Save button bar
    // -------------------------------------------------------------------------

    private var saveButtonBar: some View {
        VStack(spacing: 0) {
            // Gradient fade so content appears to scroll beneath the button
            LinearGradient(
                colors: [Color.auraeAdaptiveBackground.opacity(0), Color.auraeAdaptiveBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            VStack {
                AuraeButton(
                    "Save",
                    isLoading: viewModel.isSaving,
                    isDisabled: !viewModel.hasUnsavedChanges
                ) {
                    if viewModel.save() {
                        dismiss()
                    }
                }
                .accessibilityHint("Saves your retrospective notes for this headache")

                // Only show the "no changes" hint when editing a retrospective
                // that already existed — on first open the disabled button
                // state is sufficient feedback without extra copy beneath it.
                if !viewModel.hasUnsavedChanges && !viewModel.isSaving
                    && viewModel.hadExistingRetrospectiveOnEntry {
                    Text("No changes to save yet.")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }

                if let error = viewModel.saveError {
                    Text(error)
                        .font(.auraeCaption)
                        .foregroundStyle(Color.severityAccent(for: 4))
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, Layout.itemSpacing)
            .background(Color.auraeAdaptiveBackground)
        }
    }
}

// MARK: - CompletionRing

/// A circular progress ring shown in the nav bar leading slot.
/// Animates as the user fills in more fields.
struct CompletionRing: View {
    let fraction: Double

    private let diameter: CGFloat = 28
    private let lineWidth: CGFloat = 3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.auraeAdaptiveSecondary, lineWidth: lineWidth)
                .accessibilityHidden(true)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.auraePrimary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8),
                    value: fraction
                )
                .accessibilityHidden(true)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel("Completion: \(Int(fraction * 100)) percent")
    }
}

// =============================================================================
// MARK: - Shared primitive components
// (Internal — used by FoodDrinkSection, LifestyleSection, MedicationSection,
//  EnvironmentSection without any additional import.)
// =============================================================================

// MARK: RetroSectionContainer

/// Branded disclosure group with a title and an optional filled dot indicating
/// that the section contains at least one piece of data.
struct RetroSectionContainer<Content: View>: View {
    let title: String
    let hasData: Bool
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header — tappable to collapse/expand
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.auraeH2)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    // Completion dot — decorative; expanded/collapsed state is in
                    // the button's accessibilityHint below. (A18-06)
                    if hasData {
                        Circle()
                            .fill(Color.auraePrimary)
                            .frame(width: 7, height: 7)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityHidden(true)
                    }

                    Spacer()

                    // Decorative chevron — direction is already conveyed by hint.
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.auraeMidGray)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .accessibilityHidden(true)
                }
                .padding(Layout.cardPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
            .accessibilityAddTraits(isExpanded ? [] : [.isButton])

            if isExpanded {
                VStack(spacing: Layout.itemSpacing) {
                    content()
                }
                .padding(.horizontal, Layout.cardPadding)
                .padding(.bottom, Layout.cardPadding)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0,
            y: Layout.cardShadowY
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
        .animation(
            reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8),
            value: hasData
        )
    }
}

// MARK: ChipGrid

/// A wrapping multi-select chip grid. Tapping a chip toggles its membership
/// in the `selected` set. Selected chips use auraeTeal, unselected use
/// auraeLavender.
struct ChipGrid: View {
    let items: [ChipItem]
    @Binding var selected: Set<String>

    var body: some View {
        WrappingHStack(spacing: 8) {
            ForEach(items) { item in
                let isSelected = selected.contains(item.id)
                Button {
                    if isSelected {
                        selected.remove(item.id)
                    } else {
                        selected.insert(item.id)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(item.label)
                        .font(.auraeLabel)
                        .foregroundStyle(isSelected ? Color.auraePrimary : Color.auraeAdaptivePrimaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
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
                .accessibilityLabel(item.label)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
    }
}

// MARK: RetroChipSection

/// Labelled wrapper around ChipGrid for use inside section containers.
struct RetroChipSection: View {
    let label: String
    let items: [ChipItem]
    @Binding var selected: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            ChipGrid(items: items, selected: $selected)
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }
}

// MARK: SingleSelectPillGroup

/// A wrapping grid of single-select pill buttons. Tapping the selected option
/// deselects it (sets `selected` to ""). Used for location, headache type, and
/// cycle phase pickers in EnvironmentSection.
///
/// `options` is the ordered list of display labels.
/// `keyMap` maps label → model key stored in the binding; pass nil when they are equal.
struct SingleSelectPillGroup: View {
    let options: [String]
    var keyMap:  [String: String]? = nil
    @Binding var selected: String

    var body: some View {
        WrappingHStack(spacing: 8) {
            ForEach(options, id: \.self) { label in
                let key        = keyMap?[label] ?? label
                let isSelected = selected == key
                Button {
                    selected = isSelected ? "" : key
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(label)
                        .font(.auraeLabel)
                        .foregroundStyle(isSelected ? Color.auraePrimary : Color.auraeAdaptivePrimaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
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
        }
    }
}

// MARK: WrappingHStack

/// A flow-layout view that wraps its children onto the next line when the
/// horizontal space is exhausted. Used for chip grids where we do not know
/// how many items will fit per row at design time.
///
/// Implementation: measures each child via a GeometryReader in the background
/// (zero-size reads) then uses a custom Layout to position them.
struct WrappingHStack: SwiftUI.Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    // `SwiftUI.Layout.Subviews` is the correct fully-qualified typealias.
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: SwiftUI.Layout.Subviews,
        cache: inout ()
    ) -> CGSize {
        // Use the proposed width from the parent. Fall back to a safe 320 pt
        // minimum — we never receive a nil proposal in practice inside a ScrollView.
        let width = proposal.width ?? 320
        var currentX: CGFloat   = 0
        var currentY: CGFloat   = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentY  += lineHeight + lineSpacing
                currentX   = 0
                lineHeight = 0
            }
            currentX   += size.width + spacing
            lineHeight  = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: currentY + lineHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: SwiftUI.Layout.Subviews,
        cache: inout ()
    ) {
        var currentX: CGFloat   = bounds.minX
        var currentY: CGFloat   = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentY  += lineHeight + lineSpacing
                currentX   = bounds.minX
                lineHeight = 0
            }
            subview.place(
                at:       CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            currentX   += size.width + spacing
            lineHeight  = max(lineHeight, size.height)
        }
    }
}

// MARK: RetroStarRating

/// A 1–5 tappable star row. Tapping the currently selected star deselects it
/// (resets to 0).
struct RetroStarRating: View {
    let label: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = (rating == star) ? 0 : star
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 26))
                            .foregroundStyle(star <= rating ? Color.auraePrimary : Color.auraeMidGray)
                            .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(star <= rating ? "\(star) out of 5, selected" : "\(star) out of 5")
                    .accessibilityHint(rating == star ? "Double-tap to deselect" : "Double-tap to select")
                    .accessibilityAddTraits(star <= rating ? .isSelected : [])
                }
                Spacer()
            }
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue(rating == 0 ? "Not set" : "\(rating) out of 5")
    }
}

// MARK: RetroIntensityScale

/// A 1–5 numbered pill row for intensity ratings where star iconography
/// carries the wrong semantic connotation (e.g. stress level).
/// Tapping the selected value deselects it (resets to 0).
struct RetroIntensityScale: View {
    let label: String
    @Binding var rating: Int
    /// Optional closure mapping a level (1–5) to a descriptive string shown in the header.
    var levelLabel: ((Int) -> String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                Spacer()
                if rating > 0, let levelLabel {
                    Text(levelLabel(rating))
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                }
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        rating = (rating == level) ? 0 : level
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("\(level)")
                            .font(.auraeLabel)
                            .foregroundStyle(rating == level ? Color.auraeTealAccessible : Color.auraeAdaptivePrimaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: Layout.severityPillHeight)
                            .background(
                                rating == level
                                    ? Color.auraeAdaptiveSoftTeal
                                    : Color.auraeAdaptiveSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Layout.severityPillRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(rating == level ? "\(level) out of 5, selected" : "\(level) out of 5")
                    .accessibilityHint(rating == level ? "Double-tap to deselect" : "Double-tap to select")
                    .accessibilityAddTraits(rating == level ? .isSelected : [])
                }
            }
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
        .accessibilityValue(rating == 0 ? "Not set" : (levelLabel?(rating) ?? "\(rating) out of 5"))
    }
}

// MARK: RetroStepper

/// A labelled stepper for integer values with a formatted value label
/// on the trailing side.
struct RetroStepper: View {
    let label: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let formatValue: (Int) -> String

    var body: some View {
        HStack {
            Text(label)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            Spacer()

            Text(formatValue(value))
                .font(.auraeBody)
                .foregroundStyle(value == range.lowerBound ? Color.auraeMidGray : Color.auraeAdaptivePrimaryText)
                .frame(minWidth: 72, alignment: .trailing)
                .monospacedDigit()

            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(formatValue(value))")
    }
}

// MARK: RetroStepperDouble

/// Variant of RetroStepper for Double values (e.g. screen time in 0.5h steps).
struct RetroStepperDouble: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatValue: (Double) -> String

    var body: some View {
        HStack {
            Text(label)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            Spacer()

            Text(formatValue(value))
                .font(.auraeBody)
                .foregroundStyle(value == range.lowerBound ? Color.auraeMidGray : Color.auraeAdaptivePrimaryText)
                .frame(minWidth: 72, alignment: .trailing)
                .monospacedDigit()

            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(formatValue(value))")
    }
}

// MARK: RetroTextField

/// A single-line branded text field with a subtle background surface.
struct RetroTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.auraeBody)
            .foregroundStyle(Color.auraeAdaptivePrimaryText)
            .tint(Color.auraePrimary)
            .padding(Layout.cardPadding)
            .background(Color.auraeAdaptiveSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }
}

// MARK: RetroToggleRow

/// A labelled toggle row.
struct RetroToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
        }
        .tint(Color.auraePrimary)
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius - 4, style: .continuous))
    }
}

// MARK: - Previews

#Preview("Empty state") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let log = HeadacheLog(onsetTime: Date.now.addingTimeInterval(-7200), severity: 3)
    log.resolve(at: Date.now.addingTimeInterval(-3600))
    container.mainContext.insert(log)
    return RetrospectiveView(log: log, context: container.mainContext)
}

#Preview("Pre-populated from HealthKit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let health = HealthSnapshot(sleepHours: 6.5)
    let log    = HeadacheLog(onsetTime: Date.now.addingTimeInterval(-7200), severity: 4, health: health)
    log.resolve(at: Date.now.addingTimeInterval(-3600))
    container.mainContext.insert(log)
    return RetrospectiveView(log: log, context: container.mainContext)
}

#Preview("Existing retrospective") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let retro = RetrospectiveEntry(
        meals:                  ["Coffee", "Chocolate"],
        caffeineIntake:         250,
        sleepHours:             6.0,
        sleepQuality:           2,
        stressLevel:            4,
        medicationName:         "Ibuprofen",
        medicationDose:         "400 mg",
        medicationEffectiveness: 3,
        symptoms:               ["nausea", "light_sensitivity"],
        headacheLocation:       "Front",
        headacheType:           "tension",
        environmentalTriggers: ["bright_light", "loud_noise"]
    )
    let log = HeadacheLog(
        onsetTime:     Date.now.addingTimeInterval(-7200),
        severity:      4,
        retrospective: retro
    )
    log.resolve(at: Date.now.addingTimeInterval(-3600))
    container.mainContext.insert(log)
    return RetrospectiveView(log: log, context: container.mainContext)
}
