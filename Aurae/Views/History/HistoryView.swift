//
//  HistoryView.swift
//  Aurae
//
//  The History tab. Toggles between a grouped list of LogCards and a month
//  calendar via a segmented control in the toolbar.
//
//  Architecture:
//  - @Query is owned here (not in the VM) — same pattern as HomeView.
//  - HistoryViewModel holds sorting, filtering, grouping, and delete logic.
//  - NavigationLink rows use a placeholder destination (LogDetailView stub)
//    until Step 11 is implemented.
//
//  Swipe-to-delete fires a confirmation alert before deleting. The model
//  context is pulled from the environment, not stored on the VM.
//

import SwiftUI
import SwiftData

struct HistoryView: View {

    // -------------------------------------------------------------------------
    // MARK: Environment + query
    // -------------------------------------------------------------------------

    @Environment(\.modelContext) private var modelContext

    /// All logs newest-first — passed to VM via .onChange.
    @Query(sort: \HeadacheLog.onsetTime, order: .reverse)
    private var logs: [HeadacheLog]

    // -------------------------------------------------------------------------
    // MARK: View model
    // -------------------------------------------------------------------------

    @State private var viewModel = HistoryViewModel()

    // -------------------------------------------------------------------------
    // MARK: Delete confirmation state
    // -------------------------------------------------------------------------

    /// IDs staged for deletion — set by the swipe action, cleared after alert.
    @State private var pendingDeleteIDs: Set<UUID> = []
    @State private var showDeleteAlert: Bool = false

    // -------------------------------------------------------------------------
    // MARK: Retrospective sheet state
    // -------------------------------------------------------------------------

    @State private var logForRetrospective: HeadacheLog? = nil

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        NavigationStack {
            ZStack {
                Color.auraeBackground.ignoresSafeArea()

                Group {
                    switch viewModel.displayMode {
                    case .list:
                        listContent
                    case .calendar:
                        calendarContent
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by date or notes"
            )
            .alert("Delete headache log?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteLogs(withIDs: pendingDeleteIDs, context: modelContext)
                    pendingDeleteIDs.removeAll()
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteIDs.removeAll()
                }
            } message: {
                Text("This will permanently delete the log and all associated data.")
            }
            .sheet(item: $logForRetrospective) { log in
                RetrospectiveView(log: log, context: modelContext)
            }
        }
        .onChange(of: logs) { _, updated in
            viewModel.updateLogs(updated)
        }
        .onAppear {
            viewModel.updateLogs(logs)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Toolbar
    // -------------------------------------------------------------------------

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Picker("View", selection: $viewModel.displayMode) {
                ForEach(HistoryViewModel.DisplayMode.allCases) { mode in
                    Label(
                        mode.rawValue,
                        systemImage: mode == .list ? "list.bullet" : "calendar"
                    )
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .accessibilityLabel("Toggle list or calendar view")
        }
    }

    // -------------------------------------------------------------------------
    // MARK: List content
    // -------------------------------------------------------------------------

    @ViewBuilder
    private var listContent: some View {
        if viewModel.filteredLogs.isEmpty {
            emptyState
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.groupedByMonth, id: \.first?.id) { group in
                        Section {
                            VStack(spacing: Layout.itemSpacing) {
                                ForEach(group) { log in
                                    logRow(for: log)
                                }
                            }
                            .padding(.horizontal, Layout.screenPadding)
                            .padding(.bottom, Layout.sectionSpacing)
                        } header: {
                            monthSectionHeader(for: group)
                        }
                    }
                }
                .padding(.top, Layout.itemSpacing)
            }
        }
    }

    // MARK: Log row with swipe actions

    private func logRow(for log: HeadacheLog) -> some View {
        // Step 11 will replace this with a NavigationLink to LogDetailView.
        // Using a ZStack overlay for the swipe affordance — List's native
        // swipeActions only work inside List, which we avoid here to maintain
        // custom card styling and padding. Instead we use a custom swipe gesture.
        // For MVP we use a contextMenu for delete + open retrospective.
        LogCard(viewModel: viewModel.cardViewModel(for: log))
            .contextMenu {
                Button {
                    logForRetrospective = log
                } label: {
                    Label(
                        log.retrospective == nil ? "Add details" : "Edit details",
                        systemImage: "pencil"
                    )
                }

                Divider()

                Button(role: .destructive) {
                    pendingDeleteIDs = [log.id]
                    showDeleteAlert  = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                // swipeActions only active when inside a List; this is a
                // ScrollView + LazyVStack, so we rely on contextMenu above.
                // The button is included here as a fallback for when the
                // view is embedded inside a List in a future refactor.
                Button(role: .destructive) {
                    pendingDeleteIDs = [log.id]
                    showDeleteAlert  = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(Color.severityAccent(for: 5))
            }
    }

    // MARK: Month section header

    private func monthSectionHeader(for group: [HeadacheLog]) -> some View {
        HStack {
            Text(viewModel.monthHeader(for: group))
                .font(.auraeH2)
                .foregroundStyle(Color.auraeNavy)

            Spacer()

            Text("\(group.count) log\(group.count == 1 ? "" : "s")")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
        }
        .padding(.horizontal, Layout.screenPadding)
        .padding(.vertical, 10)
        .background(Color.auraeBackground)
    }

    // -------------------------------------------------------------------------
    // MARK: Calendar content
    // -------------------------------------------------------------------------

    private var calendarContent: some View {
        ScrollView(showsIndicators: false) {
            CalendarView(viewModel: viewModel)
                .padding(.bottom, Layout.sectionSpacing)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Empty state
    // -------------------------------------------------------------------------

    private var emptyState: some View {
        VStack(spacing: Layout.itemSpacing) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.auraeLavender)
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.auraeTeal)
            }

            Text(viewModel.searchText.isEmpty ? "No headaches logged yet" : "No results")
                .font(.auraeH2)
                .foregroundStyle(Color.auraeNavy)

            Text(
                viewModel.searchText.isEmpty
                    ? "Your history will appear here after your first log."
                    : "Try a different search term."
            )
            .font(.auraeBody)
            .foregroundStyle(Color.auraeMidGray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Layout.screenPadding * 2)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("History — populated list") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    let calendar = Calendar.current
    let today    = Date.now

    // Seed logs across 3 months
    let offsets: [(Int, Int)] = [
        (0, 4), (-1, 2), (-2, 3), (-3, 5), (-7, 1),
        (-14, 3), (-30, 2), (-35, 4), (-45, 5), (-60, 1)
    ]
    for (dayOffset, severity) in offsets {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let log = HeadacheLog(onsetTime: date, severity: severity)
            if dayOffset < 0 {
                log.resolve(at: date.addingTimeInterval(Double.random(in: 1800...14400)))
            }
            container.mainContext.insert(log)
        }
    }

    return HistoryView()
        .modelContainer(container)
}

#Preview("History — empty state") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return HistoryView()
        .modelContainer(container)
}
