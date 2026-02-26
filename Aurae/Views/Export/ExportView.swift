//
//  ExportView.swift
//  Aurae
//
//  The Export tab (Step 12 + Step 16). Lets the user choose a date range,
//  see how many headache logs fall in that range, and export a PDF.
//
//  Free tier  — summary table PDF (Date, Time, Severity, Duration,
//               Weather, Medication, Notes truncated to 40 chars)
//  Premium    — full contextual PDF with detail cards and trigger intelligence
//
//  The @Query lives here, not in ExportViewModel. Results are piped to the VM
//  via .onAppear and .onChange, following the same pattern used in HistoryView.
//

import SwiftUI
import SwiftData

// MARK: - ExportView

struct ExportView: View {

    @Query(sort: \HeadacheLog.onsetTime, order: .reverse)
    private var allLogs: [HeadacheLog]

    @State private var viewModel = ExportViewModel()
    @State private var showPaywall: Bool = false

    @Environment(\.entitlementService) private var entitlementService

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                        dateRangeSection
                        logCountBadge
                        freeExportSection
                        if entitlementService.isPro {
                            premiumProSection
                        } else {
                            premiumLockedSection
                        }
                    }
                    .padding(Layout.screenPadding)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.large)
            // Keep the VM in sync with the query result
            .onAppear {
                viewModel.updateLogs(allLogs)
            }
            .onChange(of: allLogs) { _, newLogs in
                viewModel.updateLogs(newLogs)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Date range section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            Text("Date Range")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            // Quick-select preset chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    datePresetChip("Last 7 days", days: 7)
                    datePresetChip("Last 30 days", days: 30)
                    datePresetChip("Last 3 months", days: 90)
                    datePresetChip("All time", days: nil)
                }
            }

            VStack(spacing: 0) {
                DatePickerRow(
                    label: "From",
                    selection: $viewModel.dateRangeStart,
                    in: ...viewModel.dateRangeEnd
                )

                Divider()
                    .padding(.leading, Layout.screenPadding)

                DatePickerRow(
                    label: "To",
                    selection: $viewModel.dateRangeEnd,
                    in: viewModel.dateRangeStart...
                )
            }
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(Layout.cardShadowOpacity),
                radius: Layout.cardShadowRadius,
                x: 0, y: Layout.cardShadowY
            )
        }
    }

    private func datePresetChip(_ label: String, days: Int?) -> some View {
        let isActive: Bool = {
            if let days {
                let target = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                return Calendar.current.isDate(viewModel.dateRangeStart, inSameDayAs: target)
                    && Calendar.current.isDateInToday(viewModel.dateRangeEnd)
            } else {
                // "All time" — check if start is very old (more than 5 years back)
                return viewModel.dateRangeStart < Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
            }
        }()

        return Button {
            if let days {
                viewModel.dateRangeStart = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            } else {
                viewModel.dateRangeStart = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
            }
            viewModel.dateRangeEnd = Date()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.auraeLabel)
                .foregroundStyle(isActive ? Color.auraeTealAccessible : Color.auraeAdaptivePrimaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? Color.auraeAdaptiveSoftTeal : Color.auraeAdaptiveSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Log count badge

    private var logCountBadge: some View {
        HStack(spacing: 8) {
            // Decorative icon — the text label carries the log count. (A18-08)
            Image(systemName: "doc.text")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.auraeTeal)
                .accessibilityHidden(true)

            Text(viewModel.logCountDescription)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeMidGray)
        }
    }

    // MARK: - Free export section

    private var freeExportSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            Text("Summary Export")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            // What's included card
            VStack(alignment: .leading, spacing: 10) {
                Text("What's included")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                ForEach(includedColumns, id: \.self) { column in
                    IncludedRow(label: column)
                }
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.auraeAdaptiveSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))

            // Export button
            AuraeButton(
                "Export PDF",
                isLoading: viewModel.isGenerating,
                isDisabled: viewModel.selectedLogs.isEmpty
            ) {
                viewModel.generate()
            }

            if viewModel.selectedLogs.isEmpty && !viewModel.isGenerating {
                Text("No headache logs in the selected date range.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }

            // Share link — appears once data is ready
            if let url = viewModel.shareURL {
                ShareLink(item: url, subject: Text("Aurae Headache Report")) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .accessibilityHidden(true)
                        Text("Share PDF")
                            .font(.auraeLabel)
                        Spacer()
                    }
                    .frame(height: Layout.buttonHeight)
                    .foregroundStyle(Color.auraeTealAccessible)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.buttonRadius, style: .continuous)
                            .strokeBorder(Color.auraeTealAccessible, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share PDF report")
                .accessibilityHint("Opens the system share sheet for the generated summary PDF")
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeDestructive)
                    .padding(.top, 4)
            }

            // Medical disclaimer
            Text("This report is for informational purposes only and is not medical advice.")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Premium locked section

    private var premiumLockedSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            Text("Full Contextual Export")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Decorative lock badge — heading "Aurae Pro" below conveys gate. (A18-08)
                    ZStack {
                        Circle()
                            .fill(Color.auraeTeal.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.auraeTeal)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aurae Pro")
                            .font(.auraeLabel)
                            .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        Text("Unlock a detailed clinical-style PDF with full trigger context, symptom history, and trend analysis.")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeMidGray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(premiumFeatures, id: \.self) { feature in
                        HStack(spacing: 8) {
                            // Decorative bullet checkmark — absorbed by row combine. (A18-08)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.auraeTeal)
                                .accessibilityHidden(true)
                            Text(feature)
                                .font(.auraeCaption)
                                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AuraeButton("Upgrade to Aurae Pro", style: .secondary) {
                    showPaywall = true
                }
                .accessibilityHint("Opens the upgrade screen for Aurae Pro")
            }
            .padding(Layout.cardPadding)
            .background(Color.auraeAdaptiveSoftTeal)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        }
    }

    // MARK: - Premium Pro section (shown when user is Pro)

    private var premiumProSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            Text("Full Contextual Export")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            VStack(alignment: .leading, spacing: Layout.itemSpacing) {

                // What's included card
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's included")
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    ForEach(fullExportFeatures, id: \.self) { feature in
                        IncludedRow(label: feature)
                    }
                }
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.auraeAdaptiveSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))

                // Export CTA — loading hint provided by AuraeButton itself.
                AuraeButton(
                    "Export Full PDF",
                    isLoading: viewModel.isGeneratingFull,
                    isDisabled: viewModel.selectedLogs.isEmpty
                ) {
                    viewModel.generateFull()
                }

                if viewModel.selectedLogs.isEmpty && !viewModel.isGeneratingFull {
                    Text("No headache logs in the selected date range.")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                // Share link — appears once full PDF is ready
                if let url = viewModel.shareURLFull {
                    ShareLink(item: url, subject: Text("Aurae Full Headache Report")) {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .accessibilityHidden(true)
                            Text("Share Full PDF")
                                .font(.auraeLabel)
                            Spacer()
                        }
                        .frame(height: Layout.buttonHeight)
                        .foregroundStyle(Color.auraeTealAccessible)
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.buttonRadius, style: .continuous)
                                .strokeBorder(Color.auraeTealAccessible, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Share full PDF report")
                    .accessibilityHint("Opens the system share sheet for the generated full contextual PDF")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Error message
                if let error = viewModel.errorMessageFull {
                    Text(error)
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeDestructive)
                        .padding(.top, 4)
                }

                // Medical disclaimer
                Text("This report is for informational purposes only and is not medical advice.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
                    .multilineTextAlignment(.leading)
            }
            .padding(Layout.cardPadding)
            .background(Color.auraeAdaptiveSoftTeal)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        }
    }

    // MARK: - Static content

    private let includedColumns: [String] = [
        "Date and time of onset",
        "Severity (1–5 scale)",
        "Headache duration",
        "Weather at onset (temperature and condition)",
        "Medication taken",
        "Notes (first 40 characters)"
    ]

    private let premiumFeatures: [String] = [
        "Full notes and all retrospective fields",
        "Symptom and trigger history per entry",
        "HealthKit metrics at time of onset",
        "Trend charts embedded in the document",
        "CSV and JSON data export"
    ]

    private let fullExportFeatures: [String] = [
        "All summary data (date, time, severity, duration, weather, medication)",
        "Full retrospective: food, lifestyle, symptoms, environment",
        "Complete notes (no character limit)",
        "Trigger intelligence summary with top patterns",
        "Day-of-week and time-of-day distribution charts",
        "Severity distribution and medication effectiveness"
    ]
}

// MARK: - DatePickerRow

private struct DatePickerRow: View {
    let label: String
    let selection: Binding<Date>
    let range: PartialRangeThrough<Date>?
    let rangeFrom: PartialRangeFrom<Date>?

    // Convenience inits to support both range types from the call sites

    init(label: String, selection: Binding<Date>, in range: PartialRangeThrough<Date>) {
        self.label     = label
        self.selection = selection
        self.range     = range
        self.rangeFrom = nil
    }

    init(label: String, selection: Binding<Date>, in range: PartialRangeFrom<Date>) {
        self.label     = label
        self.selection = selection
        self.range     = nil
        self.rangeFrom = range
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                .frame(width: 40, alignment: .leading)

            Spacer()

            if let r = range {
                DatePicker("", selection: selection, in: r, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Color.auraeTeal)
            } else if let r = rangeFrom {
                DatePicker("", selection: selection, in: r, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Color.auraeTeal)
            }
        }
        .padding(.horizontal, Layout.cardPadding)
        .frame(height: 52)
    }
}

// MARK: - IncludedRow

private struct IncludedRow: View {
    let label: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Decorative bullet checkmark — row is combined so label text is read. (A18-08)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.auraeTeal)
                .padding(.top, 1)
                .accessibilityHidden(true)

            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

private struct ExportPreviewWrapper: View {
    let container: ModelContainer

    init() {
        let config    = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: HeadacheLog.self, WeatherSnapshot.self,
                HealthSnapshot.self, RetrospectiveEntry.self,
            configurations: config
        )

        // Seed a few sample logs
        let ctx = container.mainContext
        for i in 0..<6 {
            let log = HeadacheLog(
                onsetTime: Date.now.addingTimeInterval(Double(-i) * 86400 * 3),
                severity: (i % 5) + 1
            )
            if i % 2 == 0 {
                let retro = RetrospectiveEntry(
                    medicationName: "Ibuprofen",
                    notes: "Triggered after long screen session"
                )
                log.retrospective = retro
                ctx.insert(retro)
            }
            ctx.insert(log)
        }
        self.container = container
    }

    var body: some View {
        ExportView()
            .modelContainer(container)
            .environment(\.entitlementService, EntitlementService.shared)
    }
}

#Preview("ExportView") {
    ExportPreviewWrapper()
}
