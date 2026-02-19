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
//    3 — Export    — PDF export, data controls (Step 12/17)
//
//  Entitlement gating (Step 14 → 15):
//  - The Insights tab is always navigable — no tab-level intercept.
//  - InsightsView owns its own locked-state rendering when !isPro:
//    a blurred overlay + "Unlock Insights" CTA that presents PaywallView.
//  - This is cleaner than intercepting tab selection here because it avoids
//    the one-frame selectedTab snap-back flicker and keeps all Insights-gating
//    logic colocated in InsightsView.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.entitlementService) private var entitlementService

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

            InsightsView()
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
// SettingsPlaceholderView stays until Step 17 ships the real Settings screen.

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
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.auraeLavender)
                        .frame(width: 72, height: 72)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.auraeTeal)
                        .frame(width: 72, height: 72)

                    if isLocked {
                        ZStack {
                            Circle()
                                .fill(Color.auraeNavy)
                                .frame(width: 22, height: 22)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 4, y: -4)
                    }
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
        .environment(\.entitlementService, EntitlementService.shared)
}
