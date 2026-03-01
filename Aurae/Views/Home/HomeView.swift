//
//  HomeView.swift
//  Aurae
//
//  Restyled 2026-02-25 to "Calm Blue" direction.
//  Log flow unchanged: severity selector inline, Log Headache button at bottom.
//  New sections added when logs exist: streak card, This Month stats,
//  Quick Insights, Recent Activity.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Query(sort: [SortDescriptor(\HeadacheLog.onsetTime, order: .reverse)])
    private var logs: [HeadacheLog]

    @AppStorage("hasLoggedFirstHeadache") private var hasLoggedFirstHeadache: Bool = false
    @AppStorage("userDisplayName") private var userDisplayName: String = ""

    @State private var viewModel = HomeViewModel()
    @State private var showLogModal = false
    @State private var showMedicalEscalation = false

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                brandWatermark

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                            .padding(.top, AuraeSpacing.xl)

                        // Log action card / active headache card — always first
                        logOrActiveCard
                            .padding(.top, AuraeSpacing.lg)

                        // Red flag banner — only shown during active headache
                        if let active = activeLog,
                           shouldShowRedFlagBanner(for: active),
                           !active.hasAcknowledgedRedFlag {
                            RedFlagBannerCard(
                                urgency: redFlagUrgency(for: active),
                                onLearnMore: { showMedicalEscalation = true },
                                onDismiss: { active.hasAcknowledgedRedFlag = true }
                            )
                            .padding(.top, AuraeSpacing.sm)
                        }

                        // Ambient context card — shows weather conditions at last log
                        ambientContextCard
                            .padding(.top, AuraeSpacing.lg)

                        // Informational sections — always visible, empty states when no data
                        thisMonthSection
                            .padding(.top, AuraeSpacing.xxl)

                        quickInsightsSection
                            .padding(.top, AuraeSpacing.xxl)

                        recentActivitySection
                            .padding(.top, AuraeSpacing.xxl)

                        if let error = viewModel.loggingError {
                            errorBanner(message: error)
                                .padding(.top, AuraeSpacing.sm)
                        }

                        Spacer(minLength: AuraeSpacing.xxxl)
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.bottom, AuraeSpacing.xxxl)
                }

                // Confirmation overlay
                if let log = viewModel.confirmedLog {
                    LogConfirmationView(log: log) { viewModel.clearConfirmation() }
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .sheet(isPresented: $showLogModal) {
                LogHeadacheModal(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $viewModel.logPendingRetrospective) { log in
                RetrospectiveView(log: log, context: modelContext)
            }
            .sheet(isPresented: $showMedicalEscalation) { MedicalEscalationView() }
        }
        .onChange(of: logs) { _, updated in
            viewModel.updateRecentActivity(from: updated)
            if !updated.isEmpty && !hasLoggedFirstHeadache { hasLoggedFirstHeadache = true }
        }
        .onAppear { viewModel.updateRecentActivity(from: logs) }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
                   value: viewModel.hasActiveHeadache)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AuraeSpacing.xxs) {
                Text(viewModel.formattedDate)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextSecondary)
                Text(viewModel.greeting)
                    .font(.auraeLargeTitle)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            avatarBadge
        }
    }

    private var avatarBadge: some View {
        let initials: String = {
            let parts = userDisplayName.trimmingCharacters(in: .whitespaces).split(separator: " ")
            if parts.isEmpty { return "?" }
            if parts.count == 1 { return String(parts[0].prefix(1)).uppercased() }
            return (String(parts[0].prefix(1)) + String(parts[parts.count - 1].prefix(1))).uppercased()
        }()
        return ZStack {
            Circle()
                .fill(Color.auraePrimary.opacity(0.20))
            Text(initials)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraePrimary)
        }
        .frame(width: 36, height: 36)
        .accessibilityLabel("Profile: \(userDisplayName.isEmpty ? "Set your name in Profile" : userDisplayName)")
    }

    // MARK: - Brand watermark

    /// Ghosted "A" mark in the top-right background layer.
    /// Purely decorative — sits beneath all content and absorbs no input.
    private var brandWatermark: some View {
        VStack {
            HStack {
                Spacer()
                Text("A")
                    .font(.fraunces(200, weight: .bold))
                    .foregroundStyle(Color.auraeAdaptivePrimaryText.opacity(0.04))
                    .offset(x: 44, y: -24)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Ambient context card

    /// Shows weather conditions captured at the most recent log.
    /// Hidden when no weather data is available.
    @ViewBuilder
    private var ambientContextCard: some View {
        if let w = viewModel.lastLogWeather {
            HStack(spacing: 14) {
                Image(systemName: weatherIconName(for: w.condition))
                    .font(.system(size: 24))
                    .foregroundStyle(Color.auraeTeal)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(w.temperature))° · \(w.condition.replacingOccurrences(of: "_", with: " ").capitalized)")
                        .font(.auraeCalloutBold)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    Text("Conditions at last log")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeTextCaption)
                }

                Spacer()

                if w.pressureTrend != "stable" {
                    VStack(alignment: .center, spacing: 2) {
                        Image(systemName: w.pressureTrend == "rising" ? "arrow.up" : "arrow.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.auraeTextCaption)
                        Text("Pressure")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTextCaption)
                    }
                    .accessibilityLabel("Pressure \(w.pressureTrend)")
                }
            }
            .padding(Layout.cardPadding)
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraeBorder, lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Last log conditions: \(Int(w.temperature)) degrees, \(w.condition.replacingOccurrences(of: "_", with: " "))")
        }
    }

    private func weatherIconName(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear", "sunny":       return "sun.max.fill"
        case "partly_cloudy":        return "cloud.sun.fill"
        case "cloudy", "overcast":   return "cloud.fill"
        case "rain", "drizzle":      return "cloud.rain.fill"
        case "snow":                 return "cloud.snow.fill"
        case "storm":                return "cloud.bolt.fill"
        case "fog", "mist":          return "cloud.fog.fill"
        default:                     return "cloud.fill"
        }
    }

    // MARK: - Log or active headache card

    /// Single card that occupies the same position regardless of state.
    /// Default:         "Log Headache" → opens LogHeadacheModal
    /// Active headache: shows in-progress status + Mark as Resolved CTA
    @ViewBuilder
    private var logOrActiveCard: some View {
        if let active = activeLog {
            activeHeadacheCard(log: active)
        } else {
            VStack(spacing: AuraeSpacing.sm) {
                // Streak card — only when there's a streak to show
                if let days = viewModel.daysSinceLastHeadache {
                    streakCard(days: days)
                }
                logActionCard
            }
        }
    }

    /// Card-style "Log Headache" trigger. Tapping opens the modal.
    private var logActionCard: some View {
        Button { showLogModal = true } label: {
            HStack(spacing: AuraeSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AuraeRadius.sm, style: .continuous)
                        .fill(Color.auraePrimary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.auraePrimary)
                }
                .accessibilityHidden(true)

                Text("Log Headache")
                    .font(.auraeH2)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Spacer()
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity)
            .background(Color.auraePrimary.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraePrimary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log Headache")
        .accessibilityHint("Opens the headache logging form")
    }

    private func streakCard(days: Int) -> some View {
        HStack(spacing: AuraeSpacing.md) {
            // Icon — concentric circle echoes brand mark halo
            ZStack {
                RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                    .fill(Color.auraePrimary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "circle.dotted.and.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.auraePrimary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Days headache-free")
                    .font(.auraeCallout)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText.opacity(0.70))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(days)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    Text(days == 1 ? "day" : "days")
                        .font(.auraeCallout)
                        .foregroundStyle(Color.auraeTextSecondary)
                }
            }

            Spacer()
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity)
        .background(Color.auraePrimary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                .strokeBorder(Color.auraePrimary.opacity(0.20), lineWidth: 1)
        )
        .accessibilityLabel("\(days) \(days == 1 ? "day" : "days") headache-free")
    }

    // MARK: - This Month stats

    private var thisMonthSection: some View {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let monthLogs = logs.filter { $0.onsetTime >= thirtyDaysAgo }
        let episodeCount = monthLogs.count
        let avgDuration: String = {
            let resolved = monthLogs.compactMap(\.duration)
            guard !resolved.isEmpty else { return "—" }
            let avgHours = resolved.reduce(0, +) / Double(resolved.count) / 3600
            return String(format: "%.1f hrs", avgHours)
        }()

        return VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            Text("Last 30 Days")
                .font(.auraeHeadline)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            HStack(spacing: AuraeSpacing.sm) {
                statCard(icon: "calendar", value: "\(episodeCount)", label: "Episodes")
                statCard(icon: "clock", value: avgDuration, label: "Avg. duration")
            }
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                    .fill(Color.auraePrimary.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.auraePrimary)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextSecondary)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
    }

    // MARK: - Quick Insights

    private var quickInsightsSection: some View {
        let insights = quickInsights
        return VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            HStack {
                Text("Quick Insights")
                    .font(.auraeHeadline)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                Spacer()
                if !insights.isEmpty {
                    Text("View All")
                        .font(.auraeCalloutBold)
                        .foregroundStyle(Color.auraePrimary)
                }
            }

            if insights.isEmpty {
                Text("Log 5 or more episodes to start seeing your patterns.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextSecondary)
                    .padding(Layout.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.auraeAdaptiveCard)
                    .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                            .strokeBorder(Color.auraeBorder, lineWidth: 1)
                    )
            } else {
                ForEach(insights, id: \.title) { insight in
                    insightCard(icon: insight.icon, title: insight.title, description: insight.description)
                }
                // Correlational disclaimer — required by clinical advisor.
                // Free users on this surface have no Insights tab disclaimer infrastructure.
                Text("These patterns reflect associations in your logged data, not confirmed causes.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextSecondary)
                    .padding(.top, AuraeSpacing.xxs)
                    .accessibilityHidden(true)
            }
        }
    }

    private func insightCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AuraeSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                    .fill(Color.auraePrimary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.auraePrimary)
            }

            VStack(alignment: .leading, spacing: AuraeSpacing.xxs) {
                Text(title)
                    .font(.auraeCalloutBold)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                Text(description)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(AuraeSpacing.md)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
    }

    // Derive top 2 insight strings from log data
    private struct QuickInsight { let icon: String; let title: String; let description: String }

    private var quickInsights: [QuickInsight] {
        guard logs.count >= 5 else { return [] }
        var result: [QuickInsight] = []

        // Sleep pattern: what fraction of logs followed < 6h sleep
        let logsWithSleep = logs.compactMap { log -> (HeadacheLog, Double)? in
            guard let h = log.health?.sleepHours else { return nil }
            return (log, h)
        }
        if logsWithSleep.count >= 3 {
            let lowSleepCount = logsWithSleep.filter { $0.1 < 6 }.count
            let pct = Int(Double(lowSleepCount) / Double(logsWithSleep.count) * 100)
            if pct >= 50 {
                result.append(QuickInsight(
                    icon: "moon.fill",
                    title: "Sleep Pattern",
                    description: "\(pct)% of your logged episodes were preceded by less than 6 hours of sleep. Sleep patterns may be worth discussing with your care team."
                ))
            }
        }

        // Weather: any logs with falling pressure
        let weatherLogs = logs.compactMap(\.weather)
        let fallingCount = weatherLogs.filter { $0.pressureTrend == "falling" }.count
        if fallingCount >= 2 {
            result.append(QuickInsight(
                icon: "cloud.fill",
                title: "Weather Association",
                description: "Barometric pressure changes were frequently logged around your headache episodes. This may be worth discussing with your care team."
            ))
        }

        return Array(result.prefix(2))
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        let recent = Array(logs.prefix(3))
        return VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            Text("Recent Activity")
                .font(.auraeHeadline)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            if recent.isEmpty {
                VStack(spacing: AuraeSpacing.sm) {
                    AuraeLogoMark(markSize: 32, ringCount: 2, opacity: 0.18)
                    Text("Your history will appear here as you log.")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Layout.cardPadding)
                .frame(maxWidth: .infinity)
                .background(Color.auraeAdaptiveCard)
                .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                        .strokeBorder(Color.auraeBorder, lineWidth: 1)
                )
            } else {
                VStack(spacing: AuraeSpacing.sm) {
                    ForEach(recent) { log in
                        recentActivityRow(log: log)
                    }
                }
            }
        }
    }

    private func recentActivityRow(log: HeadacheLog) -> some View {
        HStack(spacing: AuraeSpacing.md) {
            // Left severity bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.severityAccent(for: log.severity))
                .frame(width: 4, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.onsetTime.formatted(date: .abbreviated, time: .omitted))
                    .font(.auraeCalloutBold)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                let durStr = log.formattedDuration.map { " · \($0)" } ?? ""
                Text("\(log.severityLevel.label)\(durStr)")
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
    }

    // MARK: - Active headache card

    private var activeLog: HeadacheLog? {
        logs.first.flatMap { $0.isActive ? $0 : nil }
    }

    /// Replaces the log action card when a headache is in progress.
    /// Shows live elapsed time + inline "Mark as Resolved" CTA.
    private func activeHeadacheCard(log: HeadacheLog) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left severity bar
                Rectangle()
                    .fill(Color.severityAccent(for: log.severity))
                    .frame(width: 4)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AuraeSpacing.xs) {
                    HStack(spacing: AuraeSpacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Headache in progress")
                                .font(.auraeH2)
                                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                            Text("Started \(log.onsetTime.formatted(date: .omitted, time: .shortened))")
                                .font(.auraeCaption)
                                .foregroundStyle(Color.auraeTextCaption)
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

                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        let elapsed = Date.now.timeIntervalSince(log.onsetTime)
                        let minutes = Int(elapsed / 60)
                        let text: String = {
                            if minutes < 60 { return "\(minutes)m" }
                            let h = minutes / 60; let m = minutes % 60
                            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
                        }()
                        Text(text)
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTextCaption)
                    }
                }
                .padding(Layout.cardPadding)
            }

            Divider()
                .overlay(Color.auraeBorder)

            // Mark as Resolved — inline CTA at card bottom
            Button {
                viewModel.resolveHeadache(log, context: modelContext)
            } label: {
                Text("Mark as Resolved")
                    .font(.auraeCalloutBold)
                    .foregroundStyle(Color.auraePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AuraeSpacing.sm)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark headache as resolved")
            .accessibilityHint("Stops the timer and opens the retrospective form")
        }
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Headache in progress. \(log.severityLevel.label) severity. Started \(log.onsetTime.formatted(date: .omitted, time: .shortened)).")
    }

    // MARK: - Error banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 14))
                .foregroundStyle(Color.auraeMidGray)
                .accessibilityHidden(true)
            Text(message)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextCaption)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.sm, style: .continuous))
    }

    // MARK: - Red flag helpers

    private func shouldShowRedFlagBanner(for log: HeadacheLog) -> Bool {
        if log.onsetSpeed == .instantaneous { return true }
        let symptoms = log.retrospective?.symptoms ?? []
        return symptoms.contains("aura") && symptoms.contains("visual_disturbance")
    }

    private func redFlagUrgency(for log: HeadacheLog) -> RedFlagUrgency {
        if log.onsetSpeed == .instantaneous && log.severity >= 4 { return .urgent }
        return .advisory
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
    return HomeView().modelContainer(container)
}

#Preview("With logs — 7 day streak") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let context = container.mainContext
    for i in 1...5 {
        let log = HeadacheLog(onsetTime: Date.now.addingTimeInterval(-86400 * Double(i + 7)), severity: (i % 5) + 1)
        log.resolve(at: log.onsetTime.addingTimeInterval(3600 * Double(i)))
        context.insert(log)
    }
    return HomeView().modelContainer(container)
}

#Preview("Active headache") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let active = HeadacheLog(onsetTime: Date.now.addingTimeInterval(-3600), severity: 4)
    container.mainContext.insert(active)
    return HomeView().modelContainer(container)
}
