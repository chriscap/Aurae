//
//  AuraeApp.swift
//  Aurae
//
//  Application entry point. Configures the SwiftData ModelContainer with all
//  four persistent models and injects it into the SwiftUI environment.
//
//  Model registration order does not affect correctness, but it is kept
//  alphabetical for consistency. All four models must be listed; omitting one
//  causes SwiftData to ignore its schema when building the persistent store.
//

import SwiftUI
import SwiftData

@main
struct AuraeApp: App {

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for:
                    HeadacheLog.self,
                    HealthSnapshot.self,
                    RetrospectiveEntry.self,
                    WeatherSnapshot.self
            )
        } catch {
            // A failure here means the on-disk store is irrecoverably corrupted.
            // In production this should be presented to the user with a recovery
            // option (delete and rebuild). For MVP we crash loudly so it is
            // caught immediately during development.
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
