//
//  InsightsView.swift
//  Aurae
//
//  Premium pattern-analysis screen. Gated behind EntitlementService.isPro.
//
//  States:
//  1. !isPro            → blurred locked preview + "Unlock Insights" CTA
//  2. isPro + < 5 logs  → "Keep logging" empty state
//  3. isPro + ≥ 5 logs  → full insights layout
//
//  Layout (full state):
//  - Summary strip: stat cards in a horizontal ScrollView
//  - Triggers card: native bar chart (GeometryReader + Rectangle, no Charts)
//  - Patterns card: weekday heatmap + time-of-day breakdown
//  - Weather card:  WeatherCorrelation rows
//  - Sleep card:    two stat tiles + insight string
//  - Medication card: ranked list with star ratings
//
//  All analysis is on-device. No raw health values are displayed — only
//  aggregated statistics and plain-language descriptions.
//

import SwiftUI
import SwiftData

// MARK: - InsightsView

struct InsightsView: View {

    @Query(sort: \HeadacheLog.onsetTime, order: .reverse)
    private var allLogs: [HeadacheLog]

    @State private var viewModel = InsightsViewModel()
    @State private var showPaywall = false

    @Environment(\.entitlementService) private var entitlementService

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeBackground.ignoresSafeArea()
                content
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.updateLogs(allLogs) }
            .onChange(of: allLogs) { _, new in viewModel.updateLogs(new) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Top-level state switch

    @ViewBuilder
    private var content: some View {
        if !entitlementService.isPro {
            lockedView
        } else if viewModel.isLoading {
            // Contextual loading state — tells the user what is happening
            // rather than showing a bare spinner. (REC-21)
            VStack(spacing: Layout.itemSpacing) {
                ProgressView()
                    .tint(Color.auraeTeal)
                Text("Analysing your patterns…")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeMidGray)
            }
        } else if !viewModel.minimumLogsMet {
            keepLoggingView
        } else if let report = viewModel.report {
            fullInsightsScrollView(report: report)
        }
    }

    // MARK: - Locked state

    private var lockedView: some View {
        ZStack {
            // Blurred mock content behind the overlay
            mockInsightCards
                .blur(radius: 12)
                .allowsHitTesting(false)

            // Overlay
            VStack(spacing: Layout.itemSpacing) {
                ZStack {
                    Circle()
                        .fill(Color.auraeTeal)
                        .frame(width: 64, height: 64)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text("Unlock Insights")
                    .font(.auraeH2)
                    .foregroundStyle(Color.auraeNavy)

                Text("Aurae Pro analyses your pattern history and surfaces your personal triggers.")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeMidGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.screenPadding)

                AuraeButton("Unlock Insights") { showPaywall = true }
                    .padding(.horizontal, Layout.screenPadding)
            }
            .padding(Layout.screenPadding)
        }
    }

    // Decorative mock cards shown behind the lock overlay.
    // Each card mimics the visual structure of a real Insights card so the
    // blurred preview gives users a genuine sense of the premium content. (REC-24)
    private var mockInsightCards: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Layout.itemSpacing) {
                // Card 1: mock trigger bar chart
                mockCard(height: 130) {
                    VStack(alignment: .leading, spacing: 8) {
                        mockLabelRow(width: 90)
                        ForEach([0.75, 0.5, 0.35, 0.2] as [CGFloat], id: \.self) { fraction in
                            mockBar(fraction: fraction)
                        }
                    }
                }

                // Card 2: mock weekday heatmap + time-of-day rows
                mockCard(height: 170) {
                    VStack(alignment: .leading, spacing: 12) {
                        mockLabelRow(width: 80)
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.auraeLavender)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                            }
                        }
                        mockLabelRow(width: 60)
                        ForEach(0..<3, id: \.self) { _ in
                            Capsule()
                                .fill(Color.auraeLavender)
                                .frame(height: 12)
                        }
                    }
                }

                // Card 3: mock stat cards in a horizontal strip
                mockCard(height: 110) {
                    HStack(spacing: Layout.itemSpacing) {
                        ForEach(0..<3, id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.auraeLavender)
                                    .frame(width: 36, height: 36)
                                Capsule()
                                    .fill(Color.auraeLavender)
                                    .frame(width: 40, height: 10)
                                Capsule()
                                    .fill(Color.auraeLavender.opacity(0.6))
                                    .frame(width: 60, height: 8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // Card 4: mock sleep stat tiles
                mockCard(height: 100) {
                    HStack(spacing: Layout.itemSpacing) {
                        ForEach(0..<2, id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 6) {
                                Capsule()
                                    .fill(Color.auraeLavender)
                                    .frame(width: 44, height: 14)
                                Capsule()
                                    .fill(Color.auraeLavender.opacity(0.6))
                                    .frame(height: 8)
                            }
                            .padding(Layout.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.auraeLavender.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Layout.screenPadding)
        }
    }

    // MARK: Mock card helpers

    private func mockCard<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            mockLabelRow(width: 110)
            content()
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius, x: 0, y: Layout.cardShadowY
        )
    }

    private func mockLabelRow(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.auraeLavender)
            .frame(width: width, height: 10)
    }

    private func mockBar(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.auraeLavender)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.auraeTeal.opacity(0.35))
                    .frame(width: geo.size.width * fraction, height: 10)
            }
        }
        .frame(height: 10)
    }

    // MARK: - Keep logging empty state

    private var keepLoggingView: some View {
        VStack(spacing: Layout.itemSpacing) {
            ZStack {
                Circle()
                    .fill(Color.auraeLavender)
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.auraeTeal)
            }

            Text("Keep logging")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeNavy)

            Text("Log \(InsightsService.minimumLogs - viewModel.totalLogs) more headache\(InsightsService.minimumLogs - viewModel.totalLogs == 1 ? "" : "s") to unlock pattern analysis.")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeMidGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.screenPadding * 2)

            // Mini progress bar with axis labels (REC-22)
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.auraeLavender)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.auraeTeal)
                            .frame(
                                width: geo.size.width * min(Double(viewModel.totalLogs) / Double(InsightsService.minimumLogs), 1.0),
                                height: 8
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.totalLogs)
                    }
                }
                .frame(height: 8)

                // Axis labels: current count on the left, target on the right
                HStack {
                    Text("\(viewModel.totalLogs) logged")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeTeal)
                    Spacer()
                    Text("Goal: \(InsightsService.minimumLogs)")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                }
            }
            .padding(.horizontal, Layout.screenPadding * 2)
        }
    }

    // MARK: - Full insights

    private func fullInsightsScrollView(report: InsightsReport) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                summaryStrip(report: report)
                triggersCard(report: report)
                patternsCard(report: report)
                if !report.weatherCorrelations.isEmpty {
                    weatherCard(report: report)
                }
                sleepCard(report: report)
                if !report.medicationEffectiveness.isEmpty {
                    medicationCard(report: report)
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Layout.itemSpacing)
            .padding(.bottom, Layout.sectionSpacing)
        }
    }
}

// MARK: - Summary strip

extension InsightsView {

    private func summaryStrip(report: InsightsReport) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.itemSpacing) {
                StatCard(
                    value: "\(report.totalLogs)",
                    label: "Total logs",
                    icon: "list.bullet.clipboard",
                    iconColor: .auraeTeal
                )
                StatCard(
                    value: String(format: "%.1f", report.averageSeverity),
                    label: "Avg severity",
                    icon: "gauge.medium",
                    iconColor: Color.severityAccent(for: Int(report.averageSeverity.rounded()))
                )
                if let dur = report.averageDuration {
                    StatCard(
                        value: formattedDuration(dur),
                        label: "Avg duration",
                        icon: "clock",
                        iconColor: Color.auraeIndigo
                    )
                }
                StatCard(
                    value: "\(report.streakDays)d",
                    label: "Headache-free streak",
                    icon: "flame.fill",
                    iconColor: Color.auraeAmber
                )
            }
            .padding(.vertical, 4)
        }
    }

    private func formattedDuration(_ ti: TimeInterval) -> String {
        let total = Int(ti / 60)
        let h = total / 60
        let m = total % 60
        return h == 0 ? "\(m)m" : m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

// MARK: - Triggers card (native bar chart)

extension InsightsView {

    private func triggersCard(report: InsightsReport) -> some View {
        InsightCard(title: "YOUR TOP TRIGGERS") {
            if report.mostCommonTriggers.isEmpty {
                Text("Log retrospective data to see your trigger patterns.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
            } else {
                VStack(spacing: 10) {
                    let maxCount = report.mostCommonTriggers.first?.count ?? 1
                    ForEach(report.mostCommonTriggers, id: \.trigger) { item in
                        TriggerBarRow(
                            label: item.trigger,
                            count: item.count,
                            maxCount: maxCount
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Patterns card

extension InsightsView {

    private func patternsCard(report: InsightsReport) -> some View {
        InsightCard(title: "WHEN DO THEY HIT?") {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                // Day of week heatmap
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day of week")
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeMidGray)

                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { wd in
                            WeekdayCell(
                                label: weekdayAbbrev(wd),
                                severity: report.severityByDayOfWeek[wd]
                            )
                        }
                    }
                }

                // Time of day
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time of day")
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeMidGray)

                    VStack(spacing: 8) {
                        ForEach(TimeOfDay.allCases, id: \.self) { tod in
                            TimeOfDayRow(
                                tod: tod,
                                severity: report.severityByTimeOfDay[tod]
                            )
                        }
                    }
                }
            }
        }
    }

    private func weekdayAbbrev(_ wd: Int) -> String {
        ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][wd - 1]
    }
}

// MARK: - Weather card

extension InsightsView {

    private func weatherCard(report: InsightsReport) -> some View {
        InsightCard(title: "WEATHER PATTERNS") {
            VStack(spacing: Layout.itemSpacing) {
                ForEach(report.weatherCorrelations) { corr in
                    WeatherCorrelationRow(correlation: corr)
                }
            }
        }
    }
}

// MARK: - Sleep card

extension InsightsView {

    private func sleepCard(report: InsightsReport) -> some View {
        InsightCard(title: "SLEEP & HEADACHES") {
            if let sc = report.sleepCorrelation {
                VStack(alignment: .leading, spacing: Layout.itemSpacing) {
                    HStack(spacing: Layout.itemSpacing) {
                        SleepStatTile(
                            value: String(format: "%.1fh", sc.avgSleepOnBadDays),
                            label: "On high-severity days",
                            color: Color.severityAccent(for: 4)
                        )
                        SleepStatTile(
                            value: String(format: "%.1fh", sc.avgSleepOnGoodDays),
                            label: "On low-severity days",
                            color: Color.severityAccent(for: 1)
                        )
                    }

                    Text(sc.insight)
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                        .lineSpacing(3)
                }
            } else {
                Text("Not enough sleep data yet. Log retrospective sleep hours to see this insight.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
            }
        }
    }
}

// MARK: - Medication card

extension InsightsView {

    private func medicationCard(report: InsightsReport) -> some View {
        InsightCard(title: "WHAT'S WORKING") {
            VStack(spacing: Layout.itemSpacing) {
                ForEach(report.medicationEffectiveness, id: \.name) { item in
                    MedicationRow(name: item.name, avgEffectiveness: item.avgEffectiveness)
                }
            }
        }
    }
}

// MARK: - InsightCard wrapper

private struct InsightCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeMidGray)

            content()
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(.fraunces(22, weight: .bold))
                .foregroundStyle(Color.auraeNavy)

            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(width: 120, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
    }
}

// MARK: - TriggerBarRow (native bar chart row)

private struct TriggerBarRow: View {
    let label: String
    let count: Int
    let maxCount: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeNavy)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.auraeLavender)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.auraeTeal)
                        .frame(
                            width: geo.size.width * CGFloat(count) / CGFloat(max(maxCount, 1)),
                            height: 12
                        )
                }
            }
            .frame(height: 12)

            Text("\(count)")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - WeekdayCell

private struct WeekdayCell: View {
    let label: String
    let severity: Double?

    private var backgroundColor: Color {
        guard let s = severity else { return Color.auraeLavender }
        return Color.severitySurface(for: Int(s.rounded()))
    }

    private var foregroundColor: Color {
        guard let s = severity else { return Color.auraeMidGray }
        return Color.severityAccent(for: Int(s.rounded()))
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.jakarta(10, weight: .semibold))
                .foregroundStyle(Color.auraeMidGray)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                if let s = severity {
                    Text(String(format: "%.1f", s))
                        .font(.jakarta(11, weight: .semibold))
                        .foregroundStyle(foregroundColor)
                } else {
                    Text("—")
                        .font(.jakarta(11))
                        .foregroundStyle(Color.auraeMidGray)
                }
            }
        }
    }
}

// MARK: - TimeOfDayRow

private struct TimeOfDayRow: View {
    let tod: TimeOfDay
    let severity: Double?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tod.icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.auraeTeal)
                .frame(width: 24)

            Text(tod.rawValue)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeNavy)
                .frame(width: 76, alignment: .leading)

            if let s = severity {
                // Severity dot coloured by level
                Circle()
                    .fill(Color.severityAccent(for: Int(s.rounded())))
                    .frame(width: 10, height: 10)

                Text(String(format: "%.1f avg", s))
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
            } else {
                Text("No data")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - WeatherCorrelationRow

private struct WeatherCorrelationRow: View {
    let correlation: WeatherCorrelation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.auraeTeal.opacity(0.10 + correlation.strength * 0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: correlation.sfSymbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.auraeTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(correlation.factor)
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeNavy)

                    Text(correlation.correlation)
                        .font(.jakarta(11))
                        .foregroundStyle(Color.auraeTeal)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.auraeSoftTeal)
                        .clipShape(Capsule())
                }

                Text(correlation.description)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - SleepStatTile

private struct SleepStatTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.fraunces(22, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - MedicationRow

private struct MedicationRow: View {
    let name: String
    let avgEffectiveness: Double   // 1–5

    private var starCount: Int { Int(avgEffectiveness.rounded()) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "pill.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.auraeTeal)
                .frame(width: 20)

            Text(name)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeNavy)

            Spacer(minLength: 4)

            // Star rating
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= starCount ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(i <= starCount ? Color.auraeAmber : Color.auraeLavender)
                }
            }

            Text(String(format: "%.1f", avgEffectiveness))
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
                .frame(width: 26, alignment: .trailing)
        }
    }
}

// MARK: - Preview

private struct InsightsPreviewWrapper: View {
    let container: ModelContainer

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: HeadacheLog.self, WeatherSnapshot.self,
                HealthSnapshot.self, RetrospectiveEntry.self,
            configurations: config
        )
        let ctx = container.mainContext
        let triggers = [["weather_change", "screen_glare"], ["bright_light"], ["strong_smell", "weather_change"]]
        let meds = [("Ibuprofen", 4), ("Sumatriptan", 5), ("Ibuprofen", 3)]

        for i in 0..<8 {
            let log = HeadacheLog(
                onsetTime: Date.now.addingTimeInterval(Double(-i) * 86400 * 4),
                severity: (i % 5) + 1
            )
            let weather = WeatherSnapshot(
                temperature: 18 + Double(i % 5),
                humidity: 60 + Double(i * 4 % 30),
                pressure: 1005 + Double(i % 12),
                pressureTrend: i % 3 == 0 ? "falling" : "stable",
                uvIndex: 3,
                condition: "partly_cloudy"
            )
            let health = HealthSnapshot(sleepHours: 6.0 + Double(i % 3))
            let retro = RetrospectiveEntry(
                meals: i % 2 == 0 ? ["aged cheese"] : [],
                skippedMeal: i % 3 == 0,
                sleepHours: 6.5 + Double(i % 3) * 0.5,
                stressLevel: i % 5 + 1,
                medicationName: meds[i % 3].0,
                medicationEffectiveness: meds[i % 3].1,
                symptoms: ["nausea", "light_sensitivity"],
                environmentalTriggers: triggers[i % 3]
            )
            log.weather = weather
            log.health  = health
            log.retrospective = retro
            if i % 2 == 0 { log.resolve(at: log.onsetTime.addingTimeInterval(7200)) }
            ctx.insert(weather)
            ctx.insert(health)
            ctx.insert(retro)
            ctx.insert(log)
        }
        self.container = container
    }

    var body: some View {
        InsightsView()
            .modelContainer(container)
            .environment(\.entitlementService, EntitlementService.shared)
    }
}

#Preview("InsightsView — full (Pro)") {
    InsightsPreviewWrapper()
}

#Preview("InsightsView — locked (free)") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return InsightsView()
        .modelContainer(container)
        .environment(\.entitlementService, EntitlementService.shared)
}
