//
//  ExportView.swift
//  Aurae
//
//  The Export tab (Step 12). Lets the user choose a date range, see how many
//  headache logs fall in that range, and export a PDF summary.
//
//  Free tier — summary table PDF (Date, Time, Severity, Duration,
//              Weather, Medication, Notes truncated to 40 chars)
//  Premium   — full contextual PDF (locked card, upgrade CTA)
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                        dateRangeSection
                        logCountBadge
                        freeExportSection
                        premiumLockedSection
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
        }
    }

    // MARK: - Date range section

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            Text("Date Range")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeNavy)

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
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
            .shadow(
                color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
                radius: Layout.cardShadowRadius,
                x: 0, y: Layout.cardShadowY
            )
        }
    }

    // MARK: - Log count badge

    private var logCountBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.auraeTeal)

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
                .foregroundStyle(Color.auraeNavy)

            // What's included card
            VStack(alignment: .leading, spacing: 10) {
                Text("What's included")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeNavy)

                ForEach(includedColumns, id: \.self) { column in
                    IncludedRow(label: column)
                }
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.auraeLavender)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))

            // Export button
            AuraeButton(
                "Export PDF",
                isLoading: viewModel.isGenerating,
                isDisabled: viewModel.selectedLogs.isEmpty
            ) {
                viewModel.generate()
            }

            // Share link — appears once data is ready
            if let url = viewModel.shareURL {
                ShareLink(item: url, subject: Text("Aurae Headache Report")) {
                    HStack {
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        Text("Share PDF")
                            .font(.auraeLabel)
                        Spacer()
                    }
                    .frame(height: Layout.buttonHeight)
                    .foregroundStyle(Color.auraeTeal)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.buttonRadius, style: .continuous)
                            .strokeBorder(Color.auraeTeal, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.auraeCaption)
                    .foregroundStyle(Color(hex: "B03A2E"))
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
                .foregroundStyle(Color.auraeNavy)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.auraeTeal.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.auraeTeal)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aurae Pro")
                            .font(.auraeLabel)
                            .foregroundStyle(Color.auraeNavy)
                        Text("Unlock a detailed clinical-style PDF with full trigger context, symptom history, and trend analysis.")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeMidGray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(premiumFeatures, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.auraeTeal)
                            Text(feature)
                                .font(.auraeCaption)
                                .foregroundStyle(Color.auraeNavy)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AuraeButton("Upgrade to Aurae Pro", style: .secondary) {
                    // Step 14: trigger RevenueCat paywall
                }
            }
            .padding(Layout.cardPadding)
            .background(Color.auraeSoftTeal)
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
                .foregroundStyle(Color.auraeNavy)
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
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.auraeTeal)
                .padding(.top, 1)

            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeNavy)
                .fixedSize(horizontal: false, vertical: true)
        }
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
    }
}

#Preview("ExportView") {
    ExportPreviewWrapper()
}
