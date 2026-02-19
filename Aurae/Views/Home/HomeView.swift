//
//  HomeView.swift
//  Aurae
//
//  The main screen. Owns the @Query result (latest logs, descending) and passes
//  derived data to HomeViewModel for logic. The split keeps SwiftData's property
//  wrapper in a View (the only place @Query is valid) while keeping all mutable
//  state and business logic in the testable view model.
//
//  Layout (top to bottom):
//    1. Greeting + date strip
//    2. Recent activity pill
//    3. Active-headache banner (conditional)
//    4. Severity selector
//    5. Log Headache CTA button (hero)
//    6. Confirmation overlay (full-screen, auto-dismissing)
//

import SwiftUI
import SwiftData

struct HomeView: View {

    // -------------------------------------------------------------------------
    // MARK: SwiftData + environment
    // -------------------------------------------------------------------------

    @Environment(\.modelContext) private var modelContext

    /// All logs sorted newest-first. HomeView passes this to the view model
    /// whenever it changes so recency text and active-log state stay current.
    @Query(sort: \HeadacheLog.onsetTime, order: .reverse)
    private var logs: [HeadacheLog]

    // -------------------------------------------------------------------------
    // MARK: View model
    // -------------------------------------------------------------------------

    @State private var viewModel = HomeViewModel()

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        ZStack {
            // Base background
            Color.auraeBackground
                .ignoresSafeArea()

            // Scrollable content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.top, Layout.sectionSpacing)

                    recentActivityPill
                        .padding(.top, Layout.itemSpacing)

                    if let active = activeLog {
                        activeHeadacheBanner(log: active)
                            .padding(.top, Layout.sectionSpacing)
                    }

                    severitySection
                        .padding(.top, Layout.sectionSpacing)

                    logButton
                        .padding(.top, Layout.itemSpacing)

                    // Error message — only shown on rare insert failures.
                    if let error = viewModel.loggingError {
                        errorBanner(message: error)
                            .padding(.top, Layout.itemSpacing)
                    }

                    // Bottom breathing room above tab bar.
                    Spacer(minLength: Layout.sectionSpacing * 2)
                }
                .padding(.horizontal, Layout.screenPadding)
            }

            // Full-screen confirmation overlay — rendered above everything.
            if let log = viewModel.confirmedLog {
                LogConfirmationView(log: log) {
                    viewModel.clearConfirmation()
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // Sync the view model's recency text whenever SwiftData delivers new results.
        .onChange(of: logs) { _, newLogs in
            viewModel.updateRecentActivity(from: newLogs)
        }
        .onAppear {
            viewModel.updateRecentActivity(from: logs)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Header
    // -------------------------------------------------------------------------

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.greeting)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeMidGray)

            Text(viewModel.formattedDate)
                .font(.auraeH2)
                .foregroundStyle(Color.auraeNavy)
        }
        .accessibilityElement(children: .combine)
    }

    // -------------------------------------------------------------------------
    // MARK: Recent activity pill
    // -------------------------------------------------------------------------

    private var recentActivityPill: some View {
        Text(viewModel.recentActivityText)
            .font(.auraeCaption)
            .foregroundStyle(Color.auraeMidGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.auraeLavender)
            .clipShape(Capsule())
            .accessibilityLabel(viewModel.recentActivityText)
    }

    // -------------------------------------------------------------------------
    // MARK: Active headache banner
    // -------------------------------------------------------------------------

    private var activeLog: HeadacheLog? {
        logs.first.flatMap { $0.isActive ? $0 : nil }
    }

    private func activeHeadacheBanner(log: HeadacheLog) -> some View {
        HStack(spacing: 12) {
            // Pulsing dot
            Circle()
                .fill(Color.severityAccent(for: log.severity))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text("Headache in progress")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeNavy)

                Text("Started \(log.onsetTime.formatted(date: .omitted, time: .shortened))")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
            }

            Spacer()

            // Severity chip
            Text(log.severityLevel.label)
                .font(.auraeCaption)
                .foregroundStyle(Color.severityAccent(for: log.severity))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.severitySurface(for: log.severity))
                .clipShape(Capsule())
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeLavender)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0,
            y: Layout.cardShadowY
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Headache in progress. \(log.severityLevel.label) severity. Started at \(log.onsetTime.formatted(date: .omitted, time: .shortened))."
        )
    }

    // -------------------------------------------------------------------------
    // MARK: Severity selector
    // -------------------------------------------------------------------------

    private var severitySection: some View {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            Text("How severe?")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeMidGray)

            SeveritySelector(selected: $viewModel.selectedSeverity)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Log button
    // -------------------------------------------------------------------------

    private var logButton: some View {
        AuraeButton(
            "Log Headache",
            isLoading: viewModel.isLogging
        ) {
            viewModel.logHeadache(context: modelContext)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Error banner
    // -------------------------------------------------------------------------

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "B06020"))

            Text(message)
                .font(.auraeCaption)
                .foregroundStyle(Color(hex: "B06020"))
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FEF8F0"))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }
}

// MARK: - Preview

#Preview("HomeView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )

    // Seed a resolved log 2 days ago.
    let past = HeadacheLog(
        onsetTime: Date.now.addingTimeInterval(-86400 * 2),
        severity: 3
    )
    past.resolve(at: Date.now.addingTimeInterval(-86400 * 2 + 7200))
    container.mainContext.insert(past)

    return HomeView()
        .modelContainer(container)
}

#Preview("HomeView — active headache") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )

    let active = HeadacheLog(
        onsetTime: Date.now.addingTimeInterval(-3600),
        severity: 4
    )
    container.mainContext.insert(active)

    return HomeView()
        .modelContainer(container)
}

#Preview("HomeView — empty state") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return HomeView()
        .modelContainer(container)
}
