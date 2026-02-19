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

    /// Fixed Sun–Sat abbreviations (locale-independent for predictability).
    private let weekdayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

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
                .overlay(Color.auraeLavender)
                .padding(.bottom, 4)

            dayGrid
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, Layout.itemSpacing)
        }
        .background(Color.auraeBackground)
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
                    .foregroundStyle(Color.auraeNavy)
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(viewModel.selectedMonthTitle)
                .font(.auraeH2)
                .foregroundStyle(Color.auraeNavy)

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
                            : Color.auraeNavy
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
                    .foregroundStyle(Color.auraeMidGray)
                    .frame(maxWidth: .infinity)
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
        let leading     = weekdayRaw - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        return (leading, daysInMonth)
    }
}

// MARK: - DayCell

private struct DayCell: View {

    let day:        Int
    let logs:       [HeadacheLog]
    let isToday:    Bool
    let isSelected: Bool
    let onTap:      () -> Void

    private var hasLogs:     Bool { !logs.isEmpty }
    private var maxSeverity: Int  { logs.map(\.severity).max() ?? 3 }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .center) {
                // Selected highlight fill (behind the content)
                if isSelected && hasLogs {
                    Circle()
                        .fill(Color.auraeTeal.opacity(0.10))
                        .frame(width: 36, height: 36)
                }

                // Today ring
                if isToday {
                    Circle()
                        .stroke(Color.auraeTeal, lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                }

                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.jakarta(12, weight: isToday ? .semibold : .regular))
                        .foregroundStyle(
                            isToday  ? Color.auraeTeal :
                            hasLogs  ? Color.auraeNavy :
                                       Color.auraeMidGray
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
        .accessibilityHint(hasLogs ? "Tap to view headaches on this day" : "")
    }

    private var severityDot: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.severityAccent(for: maxSeverity))
                .frame(width: 8, height: 8)

            if logs.count > 1 {
                Text("\(logs.count)")
                    .font(.jakarta(6, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 11, height: 11)
                    .background(Color.auraeNavy)
                    .clipShape(Circle())
                    .offset(x: 7, y: -7)
            }
        }
    }

    private var cellAccessibilityLabel: String {
        switch logs.count {
        case 0: return "Day \(day), no headaches"
        case 1:
            let label = SeverityLevel(rawValue: max(1, min(5, maxSeverity)))?.label ?? ""
            return "Day \(day), 1 headache, \(label) severity. Tap to view."
        default:
            return "Day \(day), \(logs.count) headaches. Tap to view."
        }
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Layout.itemSpacing) {
                        ForEach(logs) { log in
                            // NavigationLink to LogDetailView added in Step 11.
                            LogCard(viewModel: cardViewModel(log))
                                .padding(.horizontal, Layout.screenPadding)
                        }
                        Spacer(minLength: Layout.sectionSpacing)
                    }
                    .padding(.top, Layout.itemSpacing)
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
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
