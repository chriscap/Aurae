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
//    3 — Profile   — preferences, subscription, data controls, support
//
//  Navigation change 2026-02-25:
//  Export tab replaced with Profile. Export Data is now accessible from:
//    - History tab: "Export Clinical Report" CTA at the bottom of the log list
//    - Profile tab: DATA section → Export Data row
//
//  Navigation change 2026-02-27:
//  SettingsView (previously a sheet from HomeView's gear icon) merged into
//  ProfileView. All settings content is now accessible from the Profile tab.
//  HomeView gear icon removed. SettingsView.swift retired.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(\.entitlementService) private var entitlementService

    @State private var selectedTab: Tab = .home

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "1A2332") : UIColor(hex: "FFFFFF")
        }
        appearance.shadowColor = UIColor(Color.auraePrimary).withAlphaComponent(0.15)

        // Unselected item color
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "8A9BAD") : UIColor(hex: "6B7280")
        }
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: "8A9BAD") : UIColor(hex: "6B7280")
            }
        ]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

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

// MARK: - ProfileView

/// Unified profile + settings screen.
/// No user accounts — all data is stored on-device.
struct ProfileView: View {

    // -------------------------------------------------------------------------
    // MARK: Environment
    // -------------------------------------------------------------------------

    @Environment(\.modelContext) private var modelContext
    @Environment(\.entitlementService) private var entitlementService

    // -------------------------------------------------------------------------
    // MARK: Persistent state
    // -------------------------------------------------------------------------

    @AppStorage("userDisplayName")     private var displayName: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("darkModePreference")  private var darkModePreference: String = "system"
    @AppStorage("temperatureUnit")     private var temperatureUnit: String = "C"

    @Query(sort: [SortDescriptor(\HeadacheLog.onsetTime, order: .reverse)])
    private var logs: [HeadacheLog]

    // -------------------------------------------------------------------------
    // MARK: Local view state
    // -------------------------------------------------------------------------

    /// Local mirror of NotificationService.shared.preferredDelay.
    /// Loaded asynchronously on appear; written back via Task { await }.
    @State private var selectedDelay: FollowUpDelay = .oneHour

    @State private var showExport            = false
    @State private var showNameEdit          = false
    @State private var nameEditText          = ""
    @State private var showMedicalEscalation = false
    @State private var showDisclaimer        = false
    @State private var showDeleteConfirmation = false

    // -------------------------------------------------------------------------
    // MARK: Computed properties
    // -------------------------------------------------------------------------

    private var totalLogs: Int { logs.count }

    private var dayStreak: Int {
        guard let first = logs.first(where: { !$0.isActive }) else { return 0 }
        return Calendar.current.dateComponents([.day], from: first.onsetTime, to: .now).day ?? 0
    }

    private var trackingSinceText: String {
        guard let earliest = logs.last else { return "Start logging to build your history." }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM yyyy"
        return "Tracking since \(fmt.string(from: earliest.onsetTime))"
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AuraeSpacing.xxl) {
                    headerSection
                    statsCard
                    preferencesSection
                    subscriptionSection
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
        .task {
            selectedDelay = await NotificationService.shared.preferredDelay
        }
        .sheet(isPresented: $showExport) {
            ExportView()
        }
        .sheet(isPresented: $showMedicalEscalation) {
            MedicalEscalationView()
        }
        .sheet(isPresented: $showDisclaimer) {
            disclaimerSheet
        }
        .alert("Display Name", isPresented: $showNameEdit) {
            TextField("Your name", text: $nameEditText)
                .autocorrectionDisabled()
            Button("Save") { displayName = nameEditText.trimmingCharacters(in: .whitespaces) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This name appears in your daily greeting on the home screen.")
        }
        .confirmationDialog(
            "Delete all logs?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all headache logs and associated data stored in Aurae on this device. This cannot be undone. Your Apple Health data is not affected.")
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Header
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // MARK: Stats card
    // -------------------------------------------------------------------------

    private var statsCard: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(totalLogs)", label: "Total Logs")
            Divider()
                .frame(height: 36)
                .background(Color.auraeBorder)
            statColumn(value: "\(dayStreak)", label: "Headache-free days")
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

    // -------------------------------------------------------------------------
    // MARK: Preferences section
    // (Display name, follow-up reminder, notifications, appearance)
    // -------------------------------------------------------------------------

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("PREFERENCES")
            VStack(spacing: 0) {

                // Display name
                Button {
                    nameEditText = displayName
                    showNameEdit = true
                } label: {
                    settingsRow(icon: "person.circle",
                                title: "Display Name",
                                detail: displayName.isEmpty ? "Set name" : displayName)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                // Follow-up reminder delay
                Menu {
                    ForEach(FollowUpDelay.allCases) { delay in
                        Button(delay.label) {
                            selectedDelay = delay
                            Task { await NotificationService.shared.setPreferredDelay(delay) }
                        }
                    }
                } label: {
                    settingsRow(icon: "bell.badge",
                                title: "Follow-up Reminder",
                                detail: selectedDelay.label)
                }

                Divider().padding(.leading, 52)

                // Notifications toggle
                Toggle(isOn: $notificationsEnabled) {
                    settingsRowLabel(icon: "bell", title: "Notifications")
                }
                .tint(Color.auraePrimary)
                .padding(.horizontal, Layout.cardPadding)
                .frame(minHeight: 52)

                Divider().padding(.leading, 52)

                // Appearance
                Menu {
                    Button("System Default") { darkModePreference = "system" }
                    Button("Light")          { darkModePreference = "light" }
                    Button("Dark")           { darkModePreference = "dark" }
                } label: {
                    settingsRow(icon: "circle.lefthalf.filled",
                                title: "Appearance",
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

    // -------------------------------------------------------------------------
    // MARK: Subscription section
    // -------------------------------------------------------------------------

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("SUBSCRIPTION")
            VStack(spacing: 0) {
                if entitlementService.isPro {
                    // Pro active row
                    HStack(spacing: AuraeSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                                .fill(Color.auraePrimary.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.auraePrimary)
                        }
                        Text("Aurae Pro")
                            .font(.auraeBody)
                            .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        Text("Active")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTealAccessible)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.auraeAdaptiveSoftTeal)
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.horizontal, Layout.cardPadding)
                    .frame(minHeight: 52)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Aurae Pro — Active")
                } else {
                    // Free tier row + restore
                    HStack(spacing: AuraeSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                                .fill(Color.auraePrimary.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.auraePrimary)
                        }
                        Text("Subscription")
                            .font(.auraeBody)
                            .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        Text("Free")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.auraeAdaptiveSecondary)
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.horizontal, Layout.cardPadding)
                    .frame(minHeight: 52)

                    Divider().padding(.leading, 52)

                    // Restore purchases
                    Button {
                        Task {
                            do {
                                try await entitlementService.restorePurchases()
                            } catch { }
                        }
                    } label: {
                        HStack {
                            if entitlementService.isRestoring {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                            }
                            Text("Restore Purchases")
                                .font(.auraeBody)
                                .foregroundStyle(Color.auraePrimary)
                            Spacer()
                        }
                        .padding(.horizontal, Layout.cardPadding)
                        .frame(minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Restore Purchases")

                    if let errorMessage = entitlementService.errorMessage {
                        Text(errorMessage)
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeDestructive)
                            .padding(.horizontal, Layout.cardPadding)
                            .padding(.bottom, AuraeSpacing.sm)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }
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

    // -------------------------------------------------------------------------
    // MARK: Data section
    // (Temperature unit, export, privacy, delete)
    // -------------------------------------------------------------------------

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("YOUR DATA")
            VStack(spacing: 0) {

                // Temperature unit
                Menu {
                    Button("Celsius (°C)")    { temperatureUnit = "C" }
                    Button("Fahrenheit (°F)") { temperatureUnit = "F" }
                } label: {
                    settingsRow(icon: "thermometer.medium",
                                title: "Temperature",
                                detail: temperatureUnit == "C" ? "°C" : "°F")
                }

                Divider().padding(.leading, 52)

                // Export data
                Button { showExport = true } label: {
                    settingsRow(icon: "arrow.down.doc", title: "Export Data", detail: nil)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                // Privacy & Security
                NavigationLink {
                    privacyPlaceholder
                } label: {
                    settingsRow(icon: "lock.shield", title: "Privacy & Security", detail: nil)
                }

                Divider().padding(.leading, 52)

                // Delete all data — destructive
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: AuraeSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                                .fill(Color.auraeDestructive.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.auraeDestructive)
                        }
                        Text("Delete All Data")
                            .font(.auraeBody)
                            .foregroundStyle(Color.auraeDestructive)
                        Spacer()
                    }
                    .padding(.horizontal, Layout.cardPadding)
                    .frame(minHeight: 52)
                }
                .accessibilityLabel("Delete All Data")
                .accessibilityHint("Shows a confirmation before permanently deleting all headache logs")
            }
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraeBorder, lineWidth: 1)
            )
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Support section
    // (Safety, disclaimer, help, privacy policy)
    // -------------------------------------------------------------------------

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: AuraeSpacing.sm) {
            sectionHeader("SUPPORT")
            VStack(spacing: 0) {

                // When to Seek Medical Care
                Button { showMedicalEscalation = true } label: {
                    settingsRow(icon: "cross.circle", title: "When to Seek Medical Care", detail: nil)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                // Medical Disclaimer
                Button { showDisclaimer = true } label: {
                    settingsRow(icon: "doc.text", title: "Medical Disclaimer", detail: nil)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                // Help & FAQ
                NavigationLink {
                    helpPlaceholder
                } label: {
                    settingsRow(icon: "questionmark.circle", title: "Help & FAQ", detail: nil)
                }

                Divider().padding(.leading, 52)

                // Privacy Policy — external link
                Link(destination: URL(string: "https://aurae.app/privacy")!) {
                    HStack(spacing: AuraeSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                                .fill(Color.auraePrimary.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "hand.raised")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.auraePrimary)
                        }
                        Text("Privacy Policy")
                            .font(.auraeBody)
                            .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.auraeTextSecondary.opacity(0.5))
                    }
                    .padding(.horizontal, Layout.cardPadding)
                    .frame(minHeight: 52)
                }
                .accessibilityLabel("Privacy Policy — opens in browser")

                Divider().padding(.leading, 52)

                // Version — non-interactive
                HStack(spacing: AuraeSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AuraeRadius.xs, style: .continuous)
                            .fill(Color.auraePrimary.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.auraePrimary)
                    }
                    Text("Version")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    Spacer()
                    Text(versionString)
                        .font(.auraeCallout)
                        .foregroundStyle(Color.auraeTextSecondary)
                }
                .padding(.horizontal, Layout.cardPadding)
                .frame(minHeight: 52)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Version \(versionString)")
            }
            .background(Color.auraeAdaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuraeRadius.md, style: .continuous)
                    .strokeBorder(Color.auraeBorder, lineWidth: 1)
            )
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Footer
    // -------------------------------------------------------------------------

    private var appFooter: some View {
        VStack(spacing: AuraeSpacing.sm) {
            AuraeLogoLockup(
                markSize: 24,
                wordmarkSize: 13,
                wordmarkColor: Color.auraeTextSecondary,
                ringCount: 2
            )
            Text("Your patterns, privately yours.")
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeTextSecondary)
            Text("v1.0.0")
                .font(.system(size: 10))
                .foregroundStyle(Color.auraeTextSecondary.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AuraeSpacing.xl)
    }

    // -------------------------------------------------------------------------
    // MARK: Medical disclaimer sheet
    // -------------------------------------------------------------------------

    private var disclaimerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    Text("Medical Disclaimer")
                        .font(.auraeH1)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)
                    Text("Aurae is a personal tracking tool, not a medical device. It is not intended to diagnose, treat, cure, or prevent any medical condition. Always consult a qualified healthcare provider for medical advice about your headaches.")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)
                        .lineSpacing(4)
                    Spacer()
                }
                .padding(Layout.screenPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.auraeAdaptiveBackground.ignoresSafeArea())
            .navigationTitle("Medical Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showDisclaimer = false }
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeTealAccessible)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------------------

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
                    .fill(Color.auraePrimary.opacity(0.12))
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
                    .fill(Color.auraePrimary.opacity(0.12))
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

    // -------------------------------------------------------------------------
    // MARK: Placeholder destinations
    // -------------------------------------------------------------------------

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
            Text("For help or feedback, email support@aurae.app")
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.auraeAdaptiveBackground.ignoresSafeArea())
        .navigationTitle("Help & FAQ")
    }

    // -------------------------------------------------------------------------
    // MARK: Data deletion
    // -------------------------------------------------------------------------

    private func deleteAllData() {
        do {
            try modelContext.delete(model: HeadacheLog.self)
            try modelContext.save()
        } catch {
            // Deletion failure is non-fatal for the UX.
        }
    }
}

// MARK: - NotificationService convenience extension

extension NotificationService {
    func setPreferredDelay(_ delay: FollowUpDelay) {
        preferredDelay = delay
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
