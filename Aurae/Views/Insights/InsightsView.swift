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

    // MARK: Safety & disclaimer state (CHANGE 6, 7, 9 — D-18, D-22, D-27)

    /// Set to true after the user dismisses the first-time insights disclaimer banner.
    @AppStorage("hasSeenInsightsDisclaimer") private var hasSeenInsightsDisclaimer: Bool = false

    /// Set to true after the user dismisses the educational first-insights interstitial.
    @AppStorage("hasSeenFirstInsights") private var hasSeenFirstInsights: Bool = false

    // NOTE: D-31 — removed global `@AppStorage("hasSeenRedFlagBanner")`.
    // Dismiss state is now tracked per-log via HeadacheLog.hasAcknowledgedRedFlag.
    // This ensures a future triggering log always shows the banner fresh.

    /// Controls presentation of the "When to Seek Medical Care" sheet.
    @State private var showMedicalEscalation: Bool = false

    @Environment(\.entitlementService) private var entitlementService

    /// In DEBUG builds, treat all users as Pro so insights content is
    /// visible without a real subscription. No effect in production.
    private var effectiveIsPro: Bool {
        #if DEBUG
        return true
        #else
        return entitlementService.isPro
        #endif
    }

    // MARK: - Red-flag detection (D-18, D-31, D-33)
    //
    // Show the safety banner when the most recent ACTIVE log has a red-flag
    // trigger condition AND the user has not yet acknowledged it for this log.
    // D-31: per-log dismiss via HeadacheLog.hasAcknowledgedRedFlag.

    private var mostRecentLog: HeadacheLog? { allLogs.first }

    /// Trigger condition: onsetSpeed == .instantaneous OR (aura + visual_disturbance).
    private func hasRedFlagCondition(log: HeadacheLog) -> Bool {
        if log.onsetSpeed == .instantaneous { return true }
        let symptoms = Set(log.retrospective?.symptoms ?? [])
        return symptoms.contains("aura") && symptoms.contains("visual_disturbance")
    }

    /// True when the red-flag banner should currently be visible.
    private var shouldShowRedFlagBanner: Bool {
        guard let log = mostRecentLog, log.isActive else { return false }
        return hasRedFlagCondition(log: log) && !log.hasAcknowledgedRedFlag
    }

    private var redFlagUrgencyForMostRecent: RedFlagUrgency {
        guard let log = mostRecentLog else { return .advisory }
        if log.onsetSpeed == .instantaneous && log.severity >= 4 { return .urgent }
        return .advisory
    }

    /// True when the first-insights interstitial should be presented.
    private var shouldShowFirstInsights: Bool {
        entitlementService.isPro
            && allLogs.count >= InsightsService.minimumLogs
            && !hasSeenFirstInsights
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                // D-32: Medication overuse awareness card is ungated — visible to
                // all users regardless of isPro or log count. Wrap in a VStack so
                // it stacks above the gated content without disrupting layout.
                VStack(spacing: 0) {
                    // Show the card outside the gated content switch so free users
                    // receive the awareness prompt even when the insights tab is locked.
                    let acuteDays = InsightsService.acuteMedicationDaysThisMonth(from: allLogs)
                    if acuteDays >= InsightsService.medicationOveruseThreshold {
                        MedicationOveruseWarningCard(days: acuteDays) {
                            showMedicalEscalation = true
                        }
                        .padding(.horizontal, Layout.screenPadding)
                        .padding(.top, Layout.itemSpacing)
                    }
                    content
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.updateLogs(allLogs) }
            .onChange(of: allLogs) { _, new in viewModel.updateLogs(new) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            // D-18, D-28, D-33: "When to Seek Medical Care" sheet
            .sheet(isPresented: $showMedicalEscalation) { MedicalEscalationView() }
            // CHANGE 9: First-insights educational interstitial (D-27)
            .fullScreenCover(isPresented: Binding(
                get: { shouldShowFirstInsights },
                set: { if !$0 { hasSeenFirstInsights = true } }
            )) {
                FirstInsightsView()
            }
        }
    }

    // MARK: - Top-level state switch

    @ViewBuilder
    private var content: some View {
        if !effectiveIsPro {
            lockedView
        } else if viewModel.isLoading {
            // Contextual loading state — tells the user what is happening
            // rather than showing a bare spinner. (REC-21)
            VStack(spacing: Layout.itemSpacing) {
                ProgressView()
                    .tint(Color.auraePrimary)
                Text("Analysing your patterns…")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeMidGray)
            }
        } else if !viewModel.minimumLogsMet {
            keepLoggingView
        } else if let report = viewModel.report {
            // D-28, D-31: The full insights view is wrapped in a VStack so the
            // red-flag banner and medication overuse card appear above the scroll
            // content without disrupting the existing scroll layout.
            VStack(spacing: 0) {
                if shouldShowRedFlagBanner, let log = mostRecentLog {
                    // D-31: per-log dismiss via hasAcknowledgedRedFlag
                    RedFlagBannerCard(
                        urgency: redFlagUrgencyForMostRecent,
                        onLearnMore: { showMedicalEscalation = true },
                        onDismiss: { log.hasAcknowledgedRedFlag = true }
                    )
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.top, Layout.itemSpacing)
                }
                fullInsightsScrollView(report: report)
            }
        }
    }

    // MARK: - Locked state

    private var lockedView: some View {
        ZStack {
            // Blurred mock content behind the overlay — entirely decorative,
            // VoiceOver users navigate directly to the unlock CTA. (A18-04)
            mockInsightCards
                .blur(radius: 12)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // Overlay
            VStack(spacing: Layout.itemSpacing) {
                // Decorative lock badge — meaning conveyed by heading text below.
                ZStack {
                    Circle()
                        .fill(Color.auraePrimary)
                        .frame(width: 64, height: 64)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.auraeDeepSlate)
                }
                .accessibilityHidden(true)

                Text("Unlock Insights")
                    .font(.auraeH2)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Text("Aurae Pro analyses your pattern history and surfaces your personal triggers.")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeMidGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.screenPadding)

                Text("Try free for 14 days — no credit card needed.")
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraePrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.screenPadding)

                AuraeButton("Unlock Insights") { showPaywall = true }
                    .accessibilityHint("Opens the upgrade screen for Aurae Pro")
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
                                    .fill(Color.auraeAdaptiveSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                            }
                        }
                        mockLabelRow(width: 60)
                        ForEach(0..<3, id: \.self) { _ in
                            Capsule()
                                .fill(Color.auraeAdaptiveSecondary)
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
                                    .fill(Color.auraeAdaptiveSecondary)
                                    .frame(width: 36, height: 36)
                                Capsule()
                                    .fill(Color.auraeAdaptiveSecondary)
                                    .frame(width: 40, height: 10)
                                Capsule()
                                    .fill(Color.auraeAdaptiveSecondary.opacity(0.6))
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
                                    .fill(Color.auraeAdaptiveSecondary)
                                    .frame(width: 44, height: 14)
                                Capsule()
                                    .fill(Color.auraeAdaptiveSecondary.opacity(0.6))
                                    .frame(height: 8)
                            }
                            .padding(Layout.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.auraeAdaptiveSecondary.opacity(0.4))
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
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius, x: 0, y: Layout.cardShadowY
        )
    }

    private func mockLabelRow(width: CGFloat) -> some View {
        Capsule()
            .fill(Color.auraeAdaptiveSecondary)
            .frame(width: width, height: 10)
    }

    private func mockBar(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.auraeAdaptiveSecondary)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.auraePrimary.opacity(0.35))
                    .frame(width: geo.size.width * fraction, height: 10)
            }
        }
        .frame(height: 10)
    }

    // MARK: - Keep logging empty state

    private var keepLoggingView: some View {
        keepLoggingContent(
            remaining: InsightsService.minimumLogs - viewModel.totalLogs
        )
    }

    private func keepLoggingContent(remaining: Int) -> some View {
        let remainingText = "Log \(remaining) more headache\(remaining == 1 ? "" : "s") to unlock pattern analysis."
        return VStack(spacing: Layout.itemSpacing) {
            // Decorative icon — meaning conveyed by heading and body text below.
            ZStack {
                Circle()
                    .fill(Color.auraeAdaptiveSecondary)
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.auraePrimary)
            }
            .accessibilityHidden(true)

            Text("Keep logging")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            Text(remainingText)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeMidGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.screenPadding * 2)

            // Mini progress bar with axis labels (REC-22).
            // The bar itself is decorative; the axis labels convey the numbers.
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.auraeAdaptiveSecondary)
                            .frame(height: 8)
                            .accessibilityHidden(true)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.auraePrimary)
                            .frame(
                                width: geo.size.width * min(Double(viewModel.totalLogs) / Double(InsightsService.minimumLogs), 1.0),
                                height: 8
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.totalLogs)
                            .accessibilityHidden(true)
                    }
                }
                .frame(height: 8)

                // Axis labels: current count on the left, target on the right
                HStack {
                    Text("\(viewModel.totalLogs) logged")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraePrimary)
                    Spacer()
                    Text("Goal: \(InsightsService.minimumLogs)")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                }
            }
            .padding(.horizontal, Layout.screenPadding * 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Keep logging. \(remainingText) \(viewModel.totalLogs) of \(InsightsService.minimumLogs) logged.")
    }

    // MARK: - Medication overuse awareness card (D-32)
    //
    // MARK: - Full insights

    private func fullInsightsScrollView(report: InsightsReport) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {

                // CHANGE 7: First-time dismissible disclaimer banner (D-22)
                if !hasSeenInsightsDisclaimer {
                    insightsDisclaimerBanner
                }

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

                // CHANGE 7: Permanent compact footer (D-22)
                insightsFooter
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Layout.itemSpacing)
            .padding(.bottom, Layout.sectionSpacing)
        }
    }

    // MARK: - Insights disclaimer banner (CHANGE 7 — D-22)
    //
    // First-time-only, dismissible banner. Stored via @AppStorage so it is shown
    // exactly once and never again after dismissal.

    private var insightsDisclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Patterns are based on your logged data only. They are for informational purposes and do not constitute medical advice.")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraePrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    hasSeenInsightsDisclaimer = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.auraePrimary.opacity(0.7))
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            }
            .accessibilityLabel("Dismiss disclaimer")
        }
        .padding(.horizontal, Layout.cardPadding)
        .padding(.vertical, 10)
        .background(Color.auraeAccent)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Disclaimer. Patterns are based on your logged data only. For informational purposes. Not medical advice.")
    }

    // MARK: - Insights footer (CHANGE 7 — D-22)
    //
    // Permanent compact footer at the bottom of every Insights scroll view.
    // Always visible regardless of disclaimer dismissal state.

    private var insightsFooter: some View {
        VStack(spacing: Layout.itemSpacing) {
            Divider()
                .background(Color.auraeMidGray.opacity(0.2))

            Text("For informational purposes only · Not medical advice")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Disclaimer: for informational purposes only, not medical advice.")
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
                    iconColor: .auraePrimary
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
        InsightCard(title: "Your Top Triggers") {
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
        InsightCard(title: "When Do They Hit?") {
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
        let symbols = Calendar.current.veryShortWeekdaySymbols
        guard wd >= 1, wd <= symbols.count else { return "" }
        return symbols[wd - 1]
    }
}

// MARK: - Weather card

extension InsightsView {

    private func weatherCard(report: InsightsReport) -> some View {
        InsightCard(title: "Weather Patterns") {
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
        InsightCard(title: "Sleep & Headaches") {
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
        InsightCard(title: "What's Working") {
            VStack(spacing: Layout.itemSpacing) {
                ForEach(report.medicationEffectiveness, id: \.name) { item in
                    MedicationRow(name: item.name, avgEffectiveness: item.avgEffectiveness)
                }
            }
        }
    }
}

// MARK: - MedicationOveruseWarningCard (D-32)
//
// Ungated inline card shown in the Insights tab when the user has logged
// acute medication on 10 or more distinct calendar days in the current month.
//
// Copy is verbatim per PRD Section 7.2 (D-32). Do not alter without clinical
// advisor and legal review (OQ-01).

private struct MedicationOveruseWarningCard: View {
    let days: Int
    let onLearnMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "pills.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.auraeAmber)
                    .accessibilityHidden(true)
                Text("Medication pattern noticed")
                    .font(.auraeLabel)
                    .foregroundStyle(Color.auraeTextPrimary)
            }
            // Verbatim copy per PRD Section 7.2 — do not alter without sign-off.
            Text("You've logged acute medication for headache relief more than 10 times this month. Frequent use of certain pain relievers may be associated with rebound headaches in some people. This is for your awareness only — not a diagnosis. It may be worth mentioning this pattern to your healthcare provider.")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button("Learn more about when to seek care") {
                onLearnMore()
            }
            .font(.auraeLabel)
            .foregroundStyle(Color.auraePrimary)
            .buttonStyle(.plain)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAmber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Medication pattern noticed. You've logged acute medication for headache relief more than 10 times this month.")
    }
}

// MARK: - InsightCard wrapper

private struct InsightCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.auraeSectionLabel)          // 17pt DM Sans Medium — clear hierarchy without serif legibility penalty
                .foregroundStyle(Color.auraeTextSecondary)

            content()
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
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
            // Decorative icon badge — value and label below carry the content.
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            Text(value)
                .font(.dmSerifDisplay(26, relativeTo: .title))
                .monospacedDigit()
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            Text(label)
                .font(.auraeMetricUnit)
                .foregroundStyle(Color.auraeMidGray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(minWidth: 120, alignment: .leading)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0, y: Layout.cardShadowY
        )
        // Combine icon + value + label into a single VoiceOver element so
        // users hear "12, Total logs" rather than three separate elements. (A18-04)
        .accessibilityElement(children: .combine)
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
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)

            // Proportional bar — decorative visual encoding of count. The
            // count text to the right and the combined label carry the data. (A18-04)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.auraeAdaptiveSecondary)
                        .frame(height: 12)
                        .accessibilityHidden(true)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.auraePrimary)
                        .frame(
                            width: geo.size.width * CGFloat(count) / CGFloat(max(maxCount, 1)),
                            height: 12
                        )
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 12)
            .accessibilityHidden(true)

            Text("\(count)")
                .font(.auraeCaption)
                .monospacedDigit()
                .foregroundStyle(Color.auraeMidGray)
                .frame(width: 24, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count) occurrence\(count == 1 ? "" : "s")")
    }
}

// MARK: - WeekdayCell

private struct WeekdayCell: View {
    let label: String
    let severity: Double?

    private var backgroundColor: Color {
        guard let s = severity else { return Color.auraeAdaptiveSecondary }
        return Color.severitySurface(for: Int(s.rounded()))
    }

    private var foregroundColor: Color {
        guard let s = severity else { return Color.auraeMidGray }
        return Color.severityAccent(for: Int(s.rounded()))
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.jakarta(11, weight: .semibold, relativeTo: .caption2))
                .foregroundStyle(Color.auraeMidGray)

            ZStack {
                // Decorative background — colour encodes severity level, text carries value.
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(severity.map { "\(label): \(String(format: "%.1f", $0)) average severity" } ?? "\(label): no data")
    }
}

// MARK: - TimeOfDayRow

private struct TimeOfDayRow: View {
    let tod: TimeOfDay
    let severity: Double?

    var body: some View {
        HStack(spacing: 12) {
            // Decorative time-of-day icon — label carries the period name. (A18-04)
            Image(systemName: tod.icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.auraePrimary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(tod.rawValue)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
                .frame(width: 76, alignment: .leading)

            if let s = severity {
                // Decorative severity dot — colour encodes level, text carries value.
                Circle()
                    .fill(Color.severityAccent(for: Int(s.rounded())))
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(severity.map { "\(tod.rawValue): \(String(format: "%.1f", $0)) average severity" } ?? "\(tod.rawValue): no data")
    }
}

// MARK: - WeatherCorrelationRow

private struct WeatherCorrelationRow: View {
    let correlation: WeatherCorrelation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Decorative icon badge — factor name in the text column carries
            // the semantic meaning for VoiceOver users. (A18-04)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.auraePrimary.opacity(0.10 + correlation.strength * 0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: correlation.sfSymbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.auraePrimary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(correlation.factor)
                        .font(.auraeLabel)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Text(correlation.correlation)
                        .font(.jakarta(11))
                        .foregroundStyle(Color.auraePrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.auraeAccent)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(correlation.factor): \(correlation.correlation). \(correlation.description)")
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
                .font(.dmSerifDisplay(26, relativeTo: .title))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.auraeMetricUnit)
                .foregroundStyle(Color.auraeMidGray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - MedicationRow

private struct MedicationRow: View {
    let name: String
    let avgEffectiveness: Double   // 1–5

    private var starCount: Int { Int(avgEffectiveness.rounded()) }

    var body: some View {
        HStack(spacing: 10) {
            // Decorative pill icon.
            Image(systemName: "pill.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.auraePrimary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(name)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            Spacer(minLength: 4)

            // Star rating — decorative visual; numeric value label carries the data.
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= starCount ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(i <= starCount ? Color.auraeAmber : Color.auraeAdaptiveSecondary)
                        .accessibilityHidden(true)
                }
            }

            Text(String(format: "%.1f", avgEffectiveness))
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
                .frame(width: 26, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(String(format: "%.1f", avgEffectiveness)) out of 5 effectiveness")
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
