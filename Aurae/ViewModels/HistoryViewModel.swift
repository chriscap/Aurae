//
//  HistoryViewModel.swift
//  Aurae
//
//  Owns display logic for the History tab. The raw @Query result is owned
//  by HistoryView and passed in via updateLogs(_:) each time SwiftData
//  delivers a new snapshot — the same pattern used by HomeViewModel.
//
//  Responsibilities:
//  - Month navigation (selectedMonth drives CalendarView display)
//  - Search filtering (by onset date formatted string and retrospective notes)
//  - Month-grouped sections for the list view
//  - Swipe-to-delete (deletes from the injected ModelContext)
//  - Building LogCardViewModels from HeadacheLogs (keeps LogCard pure)
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {

    // =========================================================================
    // MARK: - Public state (drives SwiftUI)
    // =========================================================================

    /// The calendar month currently displayed in CalendarView.
    /// Defaults to today's month. Mutations trigger a calendar re-render.
    var selectedMonth: Date = Calendar.current.startOfMonth(for: .now)

    /// Live search text bound to the .searchable modifier in HistoryView.
    var searchText: String = ""

    /// Whether the list or calendar view is shown.
    enum DisplayMode: String, CaseIterable, Identifiable {
        case list     = "List"
        case calendar = "Calendar"
        var id: String { rawValue }
    }
    var displayMode: DisplayMode = .list

    // =========================================================================
    // MARK: - Private — raw data from SwiftData
    // =========================================================================

    /// The full, unfiltered, query-ordered log array. Updated every time
    /// HistoryView's @Query fires via updateLogs(_:).
    private var allLogs: [HeadacheLog] = []

    // =========================================================================
    // MARK: - Computed — filtered and grouped
    // =========================================================================

    /// Logs after applying the current searchText filter.
    /// Filters are applied client-side because the search scope is small
    /// (hundreds of logs at most) and predicate building for partial text
    /// is cumbersome with SwiftData's macro-based #Predicate.
    var filteredLogs: [HeadacheLog] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return allLogs
        }
        let query = searchText.lowercased()
        return allLogs.filter { log in
            // Match against formatted onset date
            let dateStr = log.onsetTime.formatted(date: .abbreviated, time: .shortened).lowercased()
            if dateStr.contains(query) { return true }
            // Match against retrospective notes
            if let notes = log.retrospective?.notes?.lowercased(), notes.contains(query) {
                return true
            }
            // Match against headache type
            if let type = log.retrospective?.headacheType?.lowercased(), type.contains(query) {
                return true
            }
            return false
        }
    }

    /// Logs grouped by calendar month, newest month first.
    /// Each inner array is sorted newest-first within the month.
    /// Used to build List sections in the list view.
    var groupedByMonth: [[HeadacheLog]] {
        let calendar = Calendar.current
        var buckets: [Date: [HeadacheLog]] = [:]
        for log in filteredLogs {
            let key = calendar.startOfMonth(for: log.onsetTime)
            buckets[key, default: []].append(log)
        }
        return buckets
            .sorted { $0.key > $1.key }
            .map { $0.value } // already sorted newest-first from @Query
    }

    /// Logs that fall within the currently selected calendar month.
    /// Used by CalendarView to draw dots and populate the day sheet.
    var logsInSelectedMonth: [HeadacheLog] {
        let calendar = Calendar.current
        guard
            let range = calendar.range(of: .day, in: .month, for: selectedMonth),
            let firstDay = calendar.date(
                from: calendar.dateComponents([.year, .month], from: selectedMonth)
            ),
            let lastDay = calendar.date(
                byAdding: DateComponents(day: range.count - 1),
                to: firstDay
            )
        else { return [] }

        let startOfFirst = calendar.startOfDay(for: firstDay)
        let endOfLast    = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay

        return allLogs.filter {
            $0.onsetTime >= startOfFirst && $0.onsetTime < endOfLast
        }
    }

    /// A dictionary mapping calendar day number → logs on that day,
    /// for the currently selected month. Used by CalendarView.
    var logsByDay: [Int: [HeadacheLog]] {
        let calendar = Calendar.current
        var result: [Int: [HeadacheLog]] = [:]
        for log in logsInSelectedMonth {
            let day = calendar.component(.day, from: log.onsetTime)
            result[day, default: []].append(log)
        }
        return result
    }

    // =========================================================================
    // MARK: - Month header formatting
    // =========================================================================

    /// Returns a formatted section header string for a group of logs.
    /// Example: "February 2026"
    func monthHeader(for logs: [HeadacheLog]) -> String {
        guard let first = logs.first else { return "" }
        return Self.monthYearFormatter.string(from: first.onsetTime)
    }

    /// Formatted month + year string for the currently selected calendar month.
    var selectedMonthTitle: String {
        Self.monthYearFormatter.string(from: selectedMonth)
    }

    // =========================================================================
    // MARK: - Month navigation
    // =========================================================================

    /// Moves selectedMonth forward (+1) or backward (-1) by one calendar month.
    func navigateMonth(by delta: Int) {
        guard let newMonth = Calendar.current.date(
            byAdding: .month, value: delta, to: selectedMonth
        ) else { return }
        selectedMonth = Calendar.current.startOfMonth(for: newMonth)
    }

    /// Returns true when selectedMonth is the current calendar month,
    /// disabling the forward navigation arrow.
    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    // =========================================================================
    // MARK: - Data ingestion
    // =========================================================================

    /// Called by HistoryView's .onChange(of: logs) each time @Query fires.
    func updateLogs(_ logs: [HeadacheLog]) {
        allLogs = logs
    }

    // =========================================================================
    // MARK: - Delete
    // =========================================================================

    /// Deletes a set of logs identified by UUID from the given context.
    /// Called after the user confirms a swipe-to-delete action.
    func deleteLogs(withIDs ids: Set<UUID>, context: ModelContext) {
        for log in allLogs where ids.contains(log.id) {
            context.delete(log)
        }
        try? context.save()
    }

    // =========================================================================
    // MARK: - LogCardViewModel factory
    // =========================================================================

    /// Converts a HeadacheLog into a LogCardViewModel.
    /// This keeps LogCard decoupled from SwiftData entirely.
    func cardViewModel(for log: HeadacheLog) -> LogCardViewModel {
        LogCardViewModel(
            id:               log.id,
            onsetTime:        log.onsetTime,
            resolvedTime:     log.resolvedTime,
            severity:         log.severity,
            isActive:         log.isActive,
            weatherCondition: log.weather?.condition,
            weatherTemp:      log.weather?.temperature,
            heartRate:        log.health?.heartRate,
            hasRetrospective: log.retrospective?.hasAnyData == true
        )
    }

    // =========================================================================
    // MARK: - Private formatters (cached)
    // =========================================================================

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}

// MARK: - Calendar extension (shared utility)

extension Calendar {
    /// Returns the first instant of the month containing `date`.
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
