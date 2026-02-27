//
//  ContentView.swift
//  Aurae
//
//  Root view. Hosts the four-tab navigation shell.
//
//  Tab order:
//    0 — Home      — logging CTA + status
//    1 — History   — log list + calendar + export CTA at bottom
//    2 — Insights  — pattern analysis (premium)
//    3 — Profile   — local stats, settings, export data, support
//
//  Navigation change 2026-02-25:
//  Export tab replaced with Profile. Export Data is now accessible from:
//    - History tab: "Export Clinical Report" CTA at the bottom of the log list
//    - Profile tab: DATA section → Export Data row
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.entitlementService) private var entitlementService

    @State private var selectedTab: Tab = .home

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = UIColor(Color.auraePrimary).withAlphaComponent(0.15)
        UITabBar.appearance().standardAppearance  = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == .home ? "house.fill" : "house")
                }
                .tag(Tab.home)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: selectedTab == .history ? "clock.fill" : "clock")
                }
                .tag(Tab.history)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.insights)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(Tab.profile)
        }
        .tint(Color.auraePrimary)
    }
}

// MARK: - Tab enum

private enum Tab: Hashable {
    case home, history, insights, profile
}

// MARK: - ProfileView placeholder

/// Local-only profile: display name, app stats, settings, data controls.
/// No user accounts — all data is stored on-device.
struct ProfileView: View {

    @AppStorage("userDisplayName") private var displayName: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("darkModePreference") private var darkModePreference: String = "system"

    @Query(sort: [SortDescriptor(\HeadacheLog.onsetTime, order: .reverse)])
    private var logs: [HeadacheLog]

    @State private var showExport = false
    @State private var showNameEdit = false
    @State private var nameEditText = ""

    private var totalLogs: Int { logs.count }

    private var dayStreak: Int {
        guard let first = logs.first(where: { !$0.isActive }) else { return 0 }
        return Calendar.current.dateComponents([.day], from: first.onsetTime, to: .now).day ?? 0
    }

    private var trackingSinceText: String {
        guard let earliest = logs.last else { return "No logs yet" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        return "Tracking since \(fmt.string(from: earliest.onsetTime))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AuraeSpacing.xxl) {
                    headerSection
                    statsCard
                    accountSection
                    dataSection
                    supportSection
                    appFooter
                }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.top, AuraeSpacing.xl)
                .padding(.bottom, AuraeSpacing.xxxl)
            }
            .background(Color.auraeAdaptiveBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showExport) {
            ExportView()
        }
        .alert("Display Name", isPresented: $showNameEdit) {
            TextField("Your name", text: $nameEditText)
                .autocorrectionDisabled()
            Button("Save") { displayName = nameEditText.trimmingCharacters(in: .whitespaces) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This name appears in your profile header.")
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.xs) {
            Text("Profile")
                .font(.auraeLargeTitle)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
            Text(trackingSinceText)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextSecondary)
        }
    }

    // MARK: Stats card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(totalLogs)", label: "Total Logs")
            Divider()
                .frame(height: 36)
                .background(Color.auraeBorder)
            statColumn(value: "\(dayStreak)", label: "Day Streak")
            Divider()
                .frame(height: 36)
                .background(Color.auraeBorder)
            statColumn(value: "—", label: "Triggers Found")
        }
        .padding(Layout.cardPadding)
        .background(Color.auraeAdaptiveCard)
        .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                .strokeBorder(Color.auraeBorder, lineWidth: 1)
        )
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: AuraeSpacing.xxs) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.auraePrimary)
            Text(label)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Account section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("ACCOUNT")
            VStack(spacing: 0) {
                Button {
                    nameEditText = displayName
                    showNameEdit = true
                } label: {
                    settingsRow(icon: "person.circle", title: "Display Name", detail: displayName.isEmpty ? "Set name" : displayName)
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 52)
                Toggle(isOn: $notificationsEnabled) {
                    settingsRowLabel(icon: "bell", title: "Notifications")
                }
                .tint(Color.auraePrimary)
                .padding(.horizontal, Layout.cardPadding)
                .frame(minHeight: 52)
                Divider().padding(.leading, 52)
                Menu {
                    Button("System Default") { darkModePreference = "system" }
                    Button("Light")          { darkModePreference = "light" }
                    Button("Dark")           { darkModePreference = "dark" }
                } label: {
                    settingsRow(icon: "circle.lefthalf.filled", title: "Appearance",
                                detail: darkModePreference.capitalized)
                }
            }
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraeBorder, lineWidth: 1)
            )
        }
    }

    // MARK: Data section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("DATA")
            VStack(spacing: 0) {
                Button { showExport = true } label: {
                    settingsRow(icon: "arrow.down.doc", title: "Export Data", detail: nil)
                }
                Divider().padding(.leading, 52)
                NavigationLink {
                    privacyPlaceholder
                } label: {
                    settingsRow(icon: "lock.shield", title: "Privacy & Security", detail: nil)
                }
            }
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraeBorder, lineWidth: 1)
            )
        }
    }

    // MARK: Support section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("SUPPORT")
            VStack(spacing: 0) {
                NavigationLink {
                    helpPlaceholder
                } label: {
                    settingsRow(icon: "questionmark.circle", title: "Help & FAQ", detail: nil)
                }
            }
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraeBorder, lineWidth: 1)
            )
        }
    }

    // MARK: Footer

    private var appFooter: some View {
        VStack(spacing: AuraeSpacing.xxs) {
            Text("Aurae v1.0.0")
            Text("Made with care for headache sufferers")
        }
        .font(.auraeCaption)
        .foregroundStyle(Color.auraeTextSecondary)
        .frame(maxWidth: .infinity)
        .padding(.top, AuraeSpacing.xl)
    }

    // MARK: Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.auraeCaption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.auraeTextSecondary)
            .tracking(1.2)
    }

    private func settingsRow(icon: String, title: String, detail: String?) -> some View {
        HStack(spacing: AuraeSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                    .fill(Color.auraeAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.auraePrimary)
            }
            Text(title)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.auraeCallout)
                    .foregroundStyle(Color.auraeTextSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.auraeTextSecondary.opacity(0.5))
        }
        .padding(.horizontal, Layout.cardPadding)
        .frame(minHeight: 52)
    }

    private func settingsRowLabel(icon: String, title: String) -> some View {
        HStack(spacing: AuraeSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                    .fill(Color.auraeAccent)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.auraePrimary)
            }
            Text(title)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
        }
    }

    // MARK: Placeholder destinations

    private var privacyPlaceholder: some View {
        VStack(spacing: AuraeSpacing.md) {
            Text("Privacy & Security")
                .font(.auraeTitle1)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
            Text("All your data is stored locally on this device and never shared without your permission.")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.screenPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.auraeAdaptiveBackground.ignoresSafeArea())
        .navigationTitle("Privacy & Security")
    }

    private var helpPlaceholder: some View {
        VStack(spacing: AuraeSpacing.md) {
            Text("Help & FAQ")
                .font(.auraeTitle1)
                .foregroundStyle(Color.auraeAdaptivePrimaryText)
            Text("Coming soon. For support, visit our website.")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.auraeAdaptiveBackground.ignoresSafeArea())
        .navigationTitle("Help & FAQ")
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
