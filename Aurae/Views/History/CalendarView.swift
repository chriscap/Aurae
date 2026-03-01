//
//  CalendarView.swift
//  Aurae
//
//  Month-grid calendar that visualises headache days with severity-colored dots.
//
//  Layout:
//  - Month navigation header (prev/next arrows + month title)
//  - 7-column weekday header (Sun–Sat, locale-aware)
//  - Day cell grid — each cell shows day number + optional severity dot
//  - Tapping a day that has logs presents a modal sheet with LogCards
//
//  Data flow:
//  - viewModel.selectedMonth controls which month is rendered
//  - viewModel.logsByDay is a [Int: [HeadacheLog]] keyed by day-of-month
//  - viewModel.navigateMonth(by:) mutates selectedMonth in the VM
//

import SwiftUI
import SwiftData

// MARK: - IdentifiableDay

/// Thin Identifiable wrapper around a calendar day number (1–31).
/// Required so .sheet(item:) can bind to a selected day.
struct IdentifiableDay: Identifiable {
    let id: Int   // calendar day number within the current month
}

// MARK: - CalendarView

struct CalendarView: View {

    @Bindable var viewModel: HistoryViewModel

    /// The currently selected day (drives the bottom sheet).
    @State private var selectedDay: IdentifiableDay? = nil

    // MARK: Grid layout

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    /// Locale-aware weekday abbreviations ordered from the locale's first weekday.
    private var weekdayLabels: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            monthNavigationHeader
                .padding(.horizontal, Layout.screenPadding)
                .padding(.top, Layout.itemSpacing)
                .padding(.bottom, 8)

            weekdayHeader
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 4)

            Divider()
                .overlay(Color.auraeAdaptiveSecondary)
                .padding(.bottom, 4)

            dayGrid
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, Layout.itemSpacing)
        }
        .background(Color.auraeAdaptiveBackground)
        .sheet(item: $selectedDay) { day in
            DayDetailSheet(
                day:           day.id,
                month:         viewModel.selectedMonth,
                logs:          viewModel.logsByDay[day.id] ?? [],
                cardViewModel: { viewModel.cardViewModel(for: $0) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Month navigation header

    private var monthNavigationHeader: some View {
        HStack(spacing: 0) {
            Button {
                viewModel.navigateMonth(by: -1)
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(viewModel.selectedMonthTitle)
                .font(.auraeH2)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)

            Spacer()

            Button {
                viewModel.navigateMonth(by: 1)
                selectedDay = nil
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        viewModel.isCurrentMonth
                            ? Color.auraeMidGray.opacity(0.30)
                            : Color.auraeAdaptivePrimaryText
                    )
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .disabled(viewModel.isCurrentMonth)
            .accessibilityLabel("Next month")
        }
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeTextCaption)
                    .frame(maxWidth: .infinity)
                    // Column headers are decorative — the date cells carry the
                    // full accessibility information including the weekday. (A18-01)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Day grid

    private var dayGrid: some View {
        let (leadingBlanks, daysInMonth) = monthLayout(for: viewModel.selectedMonth)
        let calendar     = Calendar.current
        let todayDay     = calendar.component(.day, from: .now)
        let isThisMonth  = viewModel.isCurrentMonth

        return LazyVGrid(columns: columns, spacing: 4) {
            // Empty leading cells to push day 1 into the correct column.
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: Layout.minTapTarget)
            }

            ForEach(1...daysInMonth, id: \.self) { day in
                DayCell(
                    day:        day,
                    month:      viewModel.selectedMonth,
                    logs:       viewModel.logsByDay[day] ?? [],
                    isToday:    isThisMonth && day == todayDay,
                    isSelected: selectedDay?.id == day
                ) {
                    guard viewModel.logsByDay[day] != nil else { return }
                    selectedDay = IdentifiableDay(id: day)
                }
            }
        }
    }

    // MARK: - Month layout helper

    /// Returns (leadingBlanks, daysInMonth) for the given month.
    /// leadingBlanks = weekday index of the 1st (0 = Sunday in Gregorian).
    private func monthLayout(for month: Date) -> (Int, Int) {
        let calendar    = Calendar.current
        let firstDay    = calendar.startOfMonth(for: month)
        // weekday is 1-based: 1 = Sunday, 7 = Saturday
        let weekdayRaw  = calendar.component(.weekday, from: firstDay)
        let leading     = (weekdayRaw - calendar.firstWeekday + 7) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        return (leading, daysInMonth)
    }
}

// MARK: - DayCell

private struct DayCell: View {

    let day:        Int
    let month:      Date
    let logs:       [HeadacheLog]
    let isToday:    Bool
    let isSelected: Bool
    let onTap:      () -> Void

    private var hasLogs:     Bool { !logs.isEmpty }
    private var maxSeverity: Int  { logs.map(\.severity).max() ?? 3 }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .center) {
                // Selected highlight fill — decorative, absorbed by the button label.
                if isSelected && hasLogs {
                    Circle()
                        .fill(Color.auraePrimary.opacity(0.10))
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                }

                // Today ring — decorative, "today" is communicated via the label.
                if isToday {
                    Circle()
                        .stroke(Color.auraePrimary, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.jakarta(12, weight: isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isToday  ? Color.auraePrimary :
                            hasLogs  ? Color.auraeAdaptivePrimaryText :
                                       Color.auraeTextCaption
                        )

                    if hasLogs {
                        severityDot
                    } else {
                        // Placeholder to keep cell heights equal
                        Color.clear.frame(width: 8, height: 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellAccessibilityLabel)
        .accessibilityAddTraits(isToday ? .isSelected : [])
        .accessibilityHint(hasLogs ? "Tap to view headaches on this day" : "")
    }

    private var severityDot: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative dot — colour conveys severity but label carries the text.
            Circle()
                .fill(Color.severityAccent(for: maxSeverity))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            if logs.count > 1 {
                Text("\(logs.count)")
                    .font(.jakarta(6, weight: .semibold))
                    .foregroundStyle(Color.auraeStarlight)
                    .frame(width: 11, height: 11)
                    .background(Color.auraeAdaptivePrimaryText)
                    .clipShape(Circle())
                    .offset(x: 7, y: -7)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }

    /// Produces a full human-readable label such as "March 15, today, 2 headaches".
    /// Uses the month date to construct the correct calendar date for formatting.
    private var cellAccessibilityLabel: String {
        // Reconstruct the full date so the formatter produces a month name.
        let date = Calendar.current.date(bySetting: .day, value: day, of: month)

        let dateString: String
        if let date {
            dateString = date.formatted(.dateTime.month(.wide).day())
        } else {
            dateString = "Day \(day)"
        }

        var parts: [String] = [dateString]
        if isToday { parts.append("today") }

        switch logs.count {
        case 0:
            parts.append("no headaches")
        case 1:
            let severityLabel = SeverityLevel(rawValue: max(1, min(5, maxSeverity)))?.label ?? ""
            parts.append("1 headache, \(severityLabel) severity")
        default:
            parts.append("\(logs.count) headaches")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - DayDetailSheet

/// Bottom sheet listing all logs for a tapped calendar day.
struct DayDetailSheet: View {

    let day:           Int
    let month:         Date
    let logs:          [HeadacheLog]
    let cardViewModel: (HeadacheLog) -> LogCardViewModel

    private var dateTitle: String {
        // Reconstruct the specific date to format it.
        guard let date = Calendar.current.date(
            bySetting: .day, value: day, of: month
        ) else { return "Day \(day)" }
        return date.formatted(date: .long, time: .omitted)
    }

    // Subtitle beneath the large title gives the log count at a glance (REC-18).
    private var countSubtitle: String {
        logs.count == 1 ? "1 headache" : "\(logs.count) headaches"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeAdaptiveBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
                        // Count subtitle rendered below the large navigation title.
                        Text(countSubtitle)
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTextCaption)
                            .padding(.horizontal, Layout.screenPadding)
                            .padding(.top, 4)

                        ForEach(logs) { log in
                            NavigationLink(destination: LogDetailView(log: log)) {
                                LogCard(viewModel: cardViewModel(log))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Layout.screenPadding)
                        }
                        Spacer(minLength: Layout.sectionSpacing)
                    }
                    .padding(.top, Layout.itemSpacing)
                }
            }
            // Use .large so the date title reads at full scale in the sheet,
            // consistent with other NavigationStack screens. (REC-18)
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Previews

private struct CalendarPreviewWrapper: View {
    private let container: ModelContainer
    private let vm = HistoryViewModel()

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container  = try! ModelContainer(
            for: HeadacheLog.self, WeatherSnapshot.self,
                HealthSnapshot.self, RetrospectiveEntry.self,
            configurations: config
        )
        let calendar = Calendar.current
        let today    = Date.now

        for (dayOffset, severity) in [(0, 4), (-3, 2), (-7, 5), (-12, 1), (-15, 3), (-20, 4)] {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let log = HeadacheLog(onsetTime: date, severity: severity)
                if dayOffset != 0 { log.resolve(at: date.addingTimeInterval(3600)) }
                container.mainContext.insert(log)
            }
        }
        // Second log on day −3 to test the count badge
        if let date = calendar.date(byAdding: .day, value: -3, to: today) {
            let log2 = HeadacheLog(onsetTime: date.addingTimeInterval(7200), severity: 2)
            log2.resolve(at: date.addingTimeInterval(10800))
            container.mainContext.insert(log2)
        }
    }

    var body: some View {
        CalendarView(viewModel: vm)
            .modelContainer(container)
    }
}

#Preview("Calendar — populated") {
    CalendarPreviewWrapper()
}
