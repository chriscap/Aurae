//
//  SettingsView.swift
//  Aurae
//
//  Settings screen. Presented as a sheet from HomeView.
//
//  Sections:
//    1. Notifications  — follow-up reminder delay (30 min / 1 hr / 2 hrs)
//    2. Subscription   — Pro status, restore purchases
//    3. Data           — temperature unit toggle, delete all data
//    4. About          — version, privacy policy link, medical disclaimer
//
//  Architecture notes:
//  - NotificationService is an actor. preferredDelay cannot be read
//    synchronously from the SwiftUI main thread. A local @State mirror
//    is loaded via .task on appear and written back with Task { await }.
//  - EntitlementService is @Observable and injected via \.entitlementService
//    (custom EnvironmentKey defined in EntitlementService.swift).
//  - "Delete All Data" uses a confirmationDialog (iOS HIG) rather than an alert.
//  - No PHI is logged anywhere in this file.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    // -------------------------------------------------------------------------
    // MARK: Environment
    // -------------------------------------------------------------------------

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.entitlementService) private var entitlementService

    // -------------------------------------------------------------------------
    // MARK: Persistent state
    // -------------------------------------------------------------------------

    /// Temperature unit preference. "C" = Celsius, "F" = Fahrenheit.
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "C"

    // -------------------------------------------------------------------------
    // MARK: Local view state
    // -------------------------------------------------------------------------

    /// Local mirror of NotificationService.shared.preferredDelay.
    /// Loaded asynchronously in .task and written back on change.
    @State private var selectedDelay: FollowUpDelay = .oneHour

    /// Controls the delete-all confirmation dialog.
    @State private var showDeleteConfirmation = false

    /// Controls the medical disclaimer sheet.
    @State private var showDisclaimer = false

    /// Controls the "When to Seek Medical Care" safety screen sheet.
    @State private var showMedicalEscalation = false

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                subscriptionSection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeTealAccessible)
                }
            }
            .confirmationDialog(
                "Delete all headache logs?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This cannot be undone. All headache logs, weather snapshots, and health data stored on this device will be permanently removed.")
            }
            .sheet(isPresented: $showDisclaimer) {
                disclaimerSheet
            }
            .sheet(isPresented: $showMedicalEscalation) {
                MedicalEscalationView()
            }
            .task {
                // Load the actor-isolated preferredDelay onto the main thread
                // once on appear. Subsequent changes write back via Task { await }.
                selectedDelay = await NotificationService.shared.preferredDelay
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Notifications section
    // -------------------------------------------------------------------------

    private var notificationsSection: some View {
        Section {
            HStack {
                Text("Follow-up reminder")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Spacer()

                Picker("Follow-up reminder", selection: $selectedDelay) {
                    ForEach(FollowUpDelay.allCases) { delay in
                        Text(delay.label).tag(delay)
                    }
                }
                .pickerStyle(.menu)
                .font(.auraeBody)
                .foregroundStyle(Color.auraeTealAccessible)
                .labelsHidden()
                .onChange(of: selectedDelay) { _, newValue in
                    Task {
                        await NotificationService.shared.setPreferredDelay(newValue)
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("Notifications")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeMidGray)
                .textCase(nil)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Subscription section
    // -------------------------------------------------------------------------

    private var subscriptionSection: some View {
        Section {
            if entitlementService.isPro {
                // Pro row
                HStack(spacing: 12) {
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

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.auraeTealAccessible)
                        .font(.system(size: 18))
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Aurae Pro — Active")
            } else {
                // Free row — status badge
                HStack(spacing: 12) {
                    Text("Subscription")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Text("Free")
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeMidGray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.auraeAdaptiveSecondary)
                        .clipShape(Capsule())

                    Spacer()
                }
                .padding(.vertical, 2)

                // Restore purchases button
                AuraeButton(
                    "Restore Purchases",
                    style: .secondary,
                    isLoading: entitlementService.isRestoring
                ) {
                    Task {
                        do {
                            try await entitlementService.restorePurchases()
                        } catch {
                            // errorMessage is set on EntitlementService by restorePurchases()
                            // and displayed below. No additional handling needed here.
                        }
                    }
                }
                .padding(.vertical, 4)

                // Error message below the button when restore fails
                if let errorMessage = entitlementService.errorMessage {
                    Text(errorMessage)
                        .font(.auraeCaption)
                        .foregroundStyle(Color.auraeDestructive)
                        .padding(.vertical, 2)
                        .accessibilityLabel("Error: \(errorMessage)")
                }
            }
        } header: {
            Text("Subscription")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeMidGray)
                .textCase(nil)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Data section
    // -------------------------------------------------------------------------

    private var dataSection: some View {
        Section {
            // Temperature unit segmented picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Temperature unit")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Picker("Temperature unit", selection: $temperatureUnit) {
                    Text("°C").tag("C")
                    Text("°F").tag("F")
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            // Delete all data row
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Text("Delete All Data")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeDestructive)
                    Spacer()
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.auraeDestructive)
                }
                .padding(.vertical, 2)
            }
            .accessibilityLabel("Delete All Data")
            .accessibilityHint("Shows a confirmation before permanently deleting all headache logs")
        } header: {
            Text("Data")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeMidGray)
                .textCase(nil)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: About section
    // -------------------------------------------------------------------------

    private var aboutSection: some View {
        Section {
            // Version row
            HStack {
                Text("Version")
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeAdaptivePrimaryText)

                Spacer()

                Text(versionString)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Version \(versionString)")

            // Privacy Policy row
            Link(destination: URL(string: "https://aurae.app/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.auraeMidGray)
                }
                .padding(.vertical, 2)
            }
            .accessibilityLabel("Privacy Policy — opens in browser")

            // When to Seek Medical Care row — D-18 secondary entry point
            Button {
                showMedicalEscalation = true
            } label: {
                HStack {
                    Text("When to Seek Medical Care")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.auraeMidGray)
                }
                .padding(.vertical, 2)
            }
            .accessibilityLabel("When to Seek Medical Care")
            .accessibilityHint("Opens the medical safety information screen")

            // Medical Disclaimer row
            Button {
                showDisclaimer = true
            } label: {
                HStack {
                    Text("Medical Disclaimer")
                        .font(.auraeBody)
                        .foregroundStyle(Color.auraeAdaptivePrimaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.auraeMidGray)
                }
                .padding(.vertical, 2)
            }
            .accessibilityLabel("Medical Disclaimer")
            .accessibilityHint("Opens disclaimer text")
        } header: {
            Text("About")
                .font(.auraeLabel)
                .foregroundStyle(Color.auraeMidGray)
                .textCase(nil)
        }
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

                    Text(
                        "Aurae is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease. Always consult a qualified healthcare provider for medical advice."
                    )
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
                    Button("Done") {
                        showDisclaimer = false
                    }
                    .font(.auraeBody)
                    .foregroundStyle(Color.auraeTealAccessible)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Helpers
    // -------------------------------------------------------------------------

    /// Formatted version string: "1.0 (42)"
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    /// Deletes all HeadacheLog records from the SwiftData context.
    /// Cascade delete rules on HeadacheLog remove associated WeatherSnapshot,
    /// HealthSnapshot, and RetrospectiveEntry records automatically.
    private func deleteAllData() {
        do {
            try modelContext.delete(model: HeadacheLog.self)
            try modelContext.save()
        } catch {
            // Deletion failure is non-fatal for the UX; the context will
            // remain intact. No PHI is logged here.
        }
    }
}

// MARK: - NotificationService actor extension for SwiftUI writes

/// The actor's `preferredDelay` setter cannot be called directly from
/// a SwiftUI onChange closure. This nonisolated convenience method
/// wraps the hop so call sites read cleanly.
extension NotificationService {
    func setPreferredDelay(_ delay: FollowUpDelay) {
        preferredDelay = delay
    }
}

// MARK: - Previews

#Preview("Settings — Free user") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return SettingsView()
        .modelContainer(container)
        .environment(\.entitlementService, EntitlementService.shared)
}

#Preview("Settings — Pro user") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: HeadacheLog.self, WeatherSnapshot.self,
            HealthSnapshot.self, RetrospectiveEntry.self,
        configurations: config
    )
    return SettingsView()
        .modelContainer(container)
        .environment(\.entitlementService, EntitlementService.shared)
}
