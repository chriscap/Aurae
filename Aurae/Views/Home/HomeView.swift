//
//  HomeView.swift
//  Aurae
//
//  The primary screen. Owns the @Query result and passes derived state to
//  HomeViewModel for business logic.
//
//  State machine (driven by hasActiveHeadache):
//
//  No active headache:
//    header → activity pill → severity selector → "Log Headache" button
//
//  Active headache exists:
//    header → activity pill → active-headache banner (with resolve button)
//             → "Mark as Resolved" primary button
//             (severity selector hidden — a new log cannot be started yet)
//
//  The full-screen confirmation overlay renders above both states.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    // -------------------------------------------------------------------------
    // MARK: Environment + data
    // -------------------------------------------------------------------------

    @Environment(\.modelContext) private var modelContext

    /// All logs newest-first. Passed to the view model whenever SwiftData
    /// delivers an updated result so recency text stays current.
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
            Color.auraeBackground.ignoresSafeArea()

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

                    // Severity selector only shown when no headache is active.
                    // When a headache is ongoing the user resolves it — they
                    // cannot start a new log until the active one is closed.
                    if !viewModel.hasActiveHeadache {
                        severitySection
                            .padding(.top, Layout.sectionSpacing)
                    }

                    // Larger gap above the primary action button so it reads
                    // as a distinct action zone, not a continuation of the
                    // severity selector above it. (REC-01)
                    primaryActionButton
                        .padding(.top, Layout.sectionSpacing)

                    if let error = viewModel.loggingError {
                        errorBanner(message: error)
                            .padding(.top, Layout.itemSpacing)
                    }

                    Spacer(minLength: Layout.sectionSpacing * 2)
                }
                .padding(.horizontal, Layout.screenPadding)
            }

            // Full-screen confirmation overlay — above all content.
            if let log = viewModel.confirmedLog {
                LogConfirmationView(log: log) {
                    viewModel.clearConfirmation()
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onChange(of: logs) { _, updated in
            viewModel.updateRecentActivity(from: updated)
        }
        .onAppear {
            viewModel.updateRecentActivity(from: logs)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.hasActiveHeadache)
    }

    // -------------------------------------------------------------------------
    // MARK: Header
    // -------------------------------------------------------------------------

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.greeting)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeMidGray)

            // Fraunces 18pt with a .title3 Dynamic Type anchor so the date
            // heading scales properly without competing with H2 section titles
            // elsewhere on the screen. (REC-02)
            Text(viewModel.formattedDate)
                .font(.fraunces(18, weight: .regular, relativeTo: .title3))
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
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
            HStack(spacing: 12) {
                // Severity indicator dot
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

                Text(log.severityLevel.label)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.severityAccent(for: log.severity))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.severitySurface(for: log.severity))
                    .clipShape(Capsule())
            }

            // Duration — updated every 60 seconds via TimelineView so the
            // elapsed time stays accurate without a manual timer. (REC-03)
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                durationLine(for: log)
            }
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
            "Headache in progress. \(log.severityLevel.label) severity. Started \(log.onsetTime.formatted(date: .omitted, time: .shortened))."
        )
    }

    private func durationLine(for log: HeadacheLog) -> some View {
        let elapsed = Date.now.timeIntervalSince(log.onsetTime)
        let minutes = Int(elapsed / 60)
        let durationText: String = {
            if minutes < 60 { return "\(minutes)m so far" }
            let h = minutes / 60
            let m = minutes % 60
            return m == 0 ? "\(h)h so far" : "\(h)h \(m)m so far"
        }()

        return Text(durationText)
            .font(.auraeCaption)
            .foregroundStyle(Color.auraeMidGray)
            .accessibilityHidden(true)
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
    // MARK: Primary action button
    // -------------------------------------------------------------------------

    /// Switches between "Log Headache" and "Mark as Resolved" depending on
    /// whether a headache is currently active. The view model guards against
    /// incorrect calls, but the button label reinforces the current state.
    private var primaryActionButton: some View {
        Group {
            if viewModel.hasActiveHeadache, let active = activeLog {
                AuraeButton(
                    "Mark as Resolved",
                    style: .secondary
                ) {
                    viewModel.resolveHeadache(active, context: modelContext)
                }
            } else {
                AuraeButton(
                    "Log Headache",
                    isLoading: viewModel.isLogging
                ) {
                    viewModel.logHeadache(context: modelContext)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Error banner
    // -------------------------------------------------------------------------

    // Error banner uses neutral tones (auraeMidGray / auraeLavender) so it
    // does not alarm the user unnecessarily — the message text is sufficient.
    // Severity-coloured banners are reserved for severity indicators. (REC-04)
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14))
                .foregroundStyle(Color.auraeMidGray)

            Text(message)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeLavender)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }
}

// MARK: - Previews

#Preview("No logs — empty state") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return HomeView()
        .modelContainer(container)
}

#Preview("Resolved log 2 days ago") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let past = HeadacheLog(
        onsetTime: Date.now.addingTimeInterval(-86400 * 2),
        severity: 3
    )
    past.resolve(at: Date.now.addingTimeInterval(-86400 * 2 + 7200))
    container.mainContext.insert(past)
    return HomeView()
        .modelContainer(container)
}

#Preview("Active headache — resolve state") {
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
