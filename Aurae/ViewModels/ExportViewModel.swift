//
//  ExportViewModel.swift
//  Aurae
//
//  Drives ExportView. Responsibilities:
//    - Holds the user-selected date range
//    - Filters the full log list passed in from @Query in the view
//    - Triggers PDF generation via PDFExportService (summary and full)
//    - Produces temp-file URLs for SwiftUI ShareLink
//
//  Architecture note: @Query lives in ExportView (never in a ViewModel).
//  ExportView passes the current query result to updateLogs(_:) on appear
//  and onChange. This keeps the VM a plain @Observable class with no
//  SwiftData coupling.
//
//  The summary export (isGenerating / shareURL) and the full export
//  (isGeneratingFull / shareURLFull) use independent state so both buttons
//  can be active simultaneously without one overwriting the other's result.
//

import Foundation
import Observation

// MARK: - ExportViewModel

@Observable
@MainActor
final class ExportViewModel {

    // MARK: - Date range

    /// Start of the export window. Defaults to 30 days ago.
    var dateRangeStart: Date = Calendar.current.date(
        byAdding: .day, value: -30, to: .now
    ) ?? .now

    /// End of the export window. Defaults to end of today.
    var dateRangeEnd: Date = Calendar.current.startOfDay(for: .now)
        .addingTimeInterval(86399)   // 23:59:59

    // MARK: - Summary export state

    var isGenerating: Bool = false
    var generatedPDFData: Data? = nil
    var errorMessage: String? = nil

    // MARK: - Full export state (independent — does not affect summary state)

    var isGeneratingFull: Bool = false
    var generatedFullPDFData: Data? = nil
    var errorMessageFull: String? = nil

    // MARK: - Private log store

    /// Full list fed in from @Query in the view.
    private var allLogs: [HeadacheLog] = []

    // MARK: - Derived

    /// Logs whose onset falls within the selected date range.
    var selectedLogs: [HeadacheLog] {
        allLogs.filter { log in
            log.onsetTime >= dateRangeStart && log.onsetTime <= dateRangeEnd
        }
        .sorted { $0.onsetTime > $1.onsetTime }
    }

    /// User-facing description of how many logs are in the current window.
    var logCountDescription: String {
        let n = selectedLogs.count
        switch n {
        case 0:  return "No headaches in this period"
        case 1:  return "1 headache in this period"
        default: return "\(n) headaches in this period"
        }
    }

    // MARK: - Log updates

    /// Called by ExportView via .onAppear and .onChange(of:).
    func updateLogs(_ logs: [HeadacheLog]) {
        allLogs = logs
    }

    // MARK: - Summary PDF generation

    /// Generates the free-tier summary PDF and stores the result in
    /// `generatedPDFData`. Safe to call from a SwiftUI button action.
    func generate() {
        guard !isGenerating else { return }
        generatedPDFData = nil
        errorMessage     = nil
        isGenerating     = true

        Task {
            let data = await PDFExportService.shared.generateSummaryPDF(
                logs: selectedLogs
            )
            isGenerating     = false
            generatedPDFData = data
        }
    }

    // MARK: - Full PDF generation (premium)

    /// Generates the full premium PDF and stores the result in
    /// `generatedFullPDFData`. Uses independent state so the two
    /// export buttons do not interfere with each other.
    func generateFull() {
        guard !isGeneratingFull else { return }
        generatedFullPDFData = nil
        errorMessageFull     = nil
        isGeneratingFull     = true

        // Capture the logs on @MainActor before the async boundary.
        let logsToExport = selectedLogs

        Task {
            let data = await PDFExportService.shared.generateFullPDF(
                logs: logsToExport
            )
            isGeneratingFull     = false
            generatedFullPDFData = data
        }
    }

    // MARK: - Share URLs

    /// Writes the generated summary PDF to a deterministic temp-directory
    /// location and returns the URL for use with SwiftUI's ShareLink.
    /// Returns nil if no PDF has been generated yet.
    var shareURL: URL? {
        guard let data = generatedPDFData else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Aurae_Headache_Report.pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Writes the generated full PDF to a deterministic temp-directory
    /// location and returns the URL for use with SwiftUI's ShareLink.
    /// Returns nil if no full PDF has been generated yet.
    var shareURLFull: URL? {
        guard let data = generatedFullPDFData else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Aurae_Full_Report.pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Reset

    /// Clears the last generated summary PDF so the button becomes active again.
    func resetExport() {
        generatedPDFData = nil
        errorMessage     = nil
    }

    /// Clears the last generated full PDF so the button becomes active again.
    func resetFullExport() {
        generatedFullPDFData = nil
        errorMessageFull     = nil
    }
}
