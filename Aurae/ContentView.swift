//
//  ContentView.swift
//  Aurae
//
//  Root view. Hosts the four-tab navigation shell.
//
//  Tab order (matches PRD section 5.1):
//    0 — Home      — logging CTA (built: Step 3)
//    1 — History   — log list + calendar (Step 10)
//    2 — Insights  — premium pattern analysis (Step 15)
//    3 — Settings  — export, preferences, disclaimer (Step 17)
//
//  Placeholder tabs carry a consistent empty-state treatment so the
//  tab bar looks correct during development. Each placeholder will be
//  replaced by its real view in the appropriate build step.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(Tab.history)

            InsightsPlaceholderView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.insights)

            ExportView()
                .tabItem {
                    Label("Export", systemImage: "arrow.up.doc")
                }
                .tag(Tab.settings)
        }
        .tint(Color.auraeTeal)
    }
}

// MARK: - Tab enum

private enum Tab: Hashable {
    case home, history, insights, settings
}

// MARK: - Placeholder views
//
// These stand in until the real views are built. Each is a minimal but
// correctly-styled screen — not a blank white box — so the tab bar can
// be validated visually at any point during development.

private struct InsightsPlaceholderView: View {
    var body: some View {
        PlaceholderScreen(
            icon: "chart.line.uptrend.xyaxis",
            title: "Insights",
            subtitle: "Log 5 or more headaches to unlock pattern analysis.",
            isLocked: true
        )
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        PlaceholderScreen(
            icon: "gearshape",
            title: "Settings",
            subtitle: "Preferences, export, and data controls."
        )
    }
}

// MARK: - PlaceholderScreen

/// Consistent empty-state template used by all placeholder tabs.
private struct PlaceholderScreen: View {

    let icon: String
    let title: String
    let subtitle: String
    var isLocked: Bool = false

    var body: some View {
        ZStack {
            Color.auraeBackground.ignoresSafeArea()

            VStack(spacing: Layout.itemSpacing) {
                ZStack {
                    Circle()
                        .fill(Color.auraeLavender)
                        .frame(width: 72, height: 72)

                    Image(systemName: isLocked ? "lock" : icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.auraeTeal)
                }

                Text(title)
                    .font(.auraeH2)
                    .foregroundStyle(Color.auraeNavy)

                Text(subtitle)
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeMidGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Layout.screenPadding * 2)
            }
        }
    }
}

// MARK: - Preview

#Preview("ContentView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return ContentView()
        .modelContainer(container)
}
