//
//  PDFExportService.swift
//  Aurae
//
//  Generates PDF reports from HeadacheLog data entirely on-device using PDFKit.
//  No data is ever transmitted to an external service.
//
//  Free tier  — generateSummaryPDF(logs:) async -> Data
//    Produces a summary table: Date | Time | Severity | Duration |
//    Weather | Medication | Notes (truncated to 40 chars)
//
//  Premium tier — generateFullPDF(logs:) async -> Data
//    Stub that returns the summary PDF. Expanded in Step 16.
//
//  Swift 6 / Sendable note
//  -----------------------
//  HeadacheLog is a SwiftData @Model class and is NOT Sendable. All data is
//  therefore extracted into a plain `LogRow` value type on the calling actor
//  (the @MainActor) before being handed to the off-main render work. The
//  CGContext drawing loop only ever touches Sendable value types.
//
//  Page format: A4 (595 × 842 pt), portrait, 40 pt margins.
//

import Foundation
import PDFKit
import UIKit

// MARK: - LogRow (Sendable value type for cross-actor transfer)

/// A snapshot of a HeadacheLog's displayable fields.
/// Created on the calling actor; passed to the renderer without SwiftData types.
private struct LogRow: Sendable {
    let date:       String
    let time:       String
    let severity:   String
    let duration:   String
    let weather:    String
    let medication: String
    let notes:      String
}

// MARK: - PDFExportService

final class PDFExportService: Sendable {

    static let shared = PDFExportService()
    private init() {}

    // MARK: - Page geometry

    private let pageSize   = CGSize(width: 595, height: 842)   // A4 portrait
    private let margin: CGFloat = 40

    private var contentWidth: CGFloat { pageSize.width - margin * 2 }

    // MARK: - Colour palette (CGColor from design system hex values)

    // auraeNavy    #0D1B2A — headings and table headers
    private let navyColor    = UIColor(red: 13/255,  green: 27/255,  blue: 42/255,  alpha: 1).cgColor
    // auraeTeal    #2D7D7D — accent rule and header bar
    private let tealColor    = UIColor(red: 45/255,  green: 125/255, blue: 125/255, alpha: 1).cgColor
    // auraeMidGray #6B7280 — body text and metadata
    private let grayColor    = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1).cgColor
    // auraeBackground #F5F6F8 — alternating row tint
    private let rowTintColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1).cgColor

    // MARK: - Column definitions

    private struct Column: Sendable {
        let title: String
        let width: CGFloat
    }

    private func makeColumns() -> [Column] {
        let w = contentWidth
        return [
            Column(title: "Date",       width: w * 0.14),
            Column(title: "Time",       width: w * 0.10),
            Column(title: "Sev",        width: w * 0.07),
            Column(title: "Duration",   width: w * 0.11),
            Column(title: "Weather",    width: w * 0.18),
            Column(title: "Medication", width: w * 0.18),
            Column(title: "Notes",      width: w * 0.22),
        ]
    }

    // MARK: - Heights (constants, not stored properties, so nonisolated safe)

    private var headerHeight:       CGFloat { 72 }
    private var columnHeaderHeight: CGFloat { 22 }
    private var rowHeight:          CGFloat { 26 }
    private var footerHeight:       CGFloat { 18 }

    // MARK: - Public API

    /// Generates the free-tier summary PDF.
    /// Must be called on an actor (e.g. @MainActor) so HeadacheLog can be
    /// read safely. Data extraction happens before the detached render task.
    func generateSummaryPDF(logs: [HeadacheLog]) async -> Data {
        let rows     = logs
            .sorted { $0.onsetTime > $1.onsetTime }
            .map { makeRow($0) }
        let header   = makeHeaderMeta(logs: logs)
        let columns  = makeColumns()

        return await Task.detached(priority: .userInitiated) { [self] in
            self.render(rows: rows, headerMeta: header, columns: columns)
        }.value
    }

    /// Premium-tier full export stub (Step 16).
    func generateFullPDF(logs: [HeadacheLog]) async -> Data {
        await generateSummaryPDF(logs: logs)
    }

    // MARK: - Row extraction (runs on calling actor — safe to read @Model)

    private func makeRow(_ log: HeadacheLog) -> LogRow {
        let df = DateFormatter()

        df.dateFormat = "MMM d, yyyy"
        let date = df.string(from: log.onsetTime)

        df.dateFormat = "h:mm a"
        let time = df.string(from: log.onsetTime)

        let severity = "\(log.severity)/5"
        let duration = log.formattedDuration ?? "Active"

        let weather: String = {
            guard let w = log.weather else { return "—" }
            let temp = String(format: "%.0f°", w.temperature)
            let cond = w.condition
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            return "\(temp) \(cond)"
        }()

        let medication = log.retrospective?.medicationName ?? "—"

        let notes: String = {
            guard let raw = log.retrospective?.notes, !raw.isEmpty else { return "—" }
            return raw.count > 40 ? String(raw.prefix(40)) + "…" : raw
        }()

        return LogRow(
            date:       date,
            time:       time,
            severity:   severity,
            duration:   duration,
            weather:    weather,
            medication: medication,
            notes:      notes
        )
    }

    // MARK: - Header metadata extraction

    private struct HeaderMeta: Sendable {
        let dateRange: String
        let count:     Int
    }

    private func makeHeaderMeta(logs: [HeadacheLog]) -> HeaderMeta {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        let dates = logs.map(\.onsetTime)
        let range: String = {
            guard !dates.isEmpty, let oldest = dates.min(), let newest = dates.max() else {
                return "No logs"
            }
            if Calendar.current.isDate(oldest, inSameDayAs: newest) {
                return df.string(from: oldest)
            }
            return "\(df.string(from: oldest)) – \(df.string(from: newest))"
        }()
        return HeaderMeta(dateRange: range, count: logs.count)
    }

    // MARK: - Renderer (nonisolated, only touches Sendable types)

    private func render(rows: [LogRow], headerMeta: HeaderMeta, columns: [Column]) -> Data {
        let format     = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Aurae",
            kCGPDFContextTitle   as String: "Aurae Headache Report"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        let data = renderer.pdfData { ctx in
            var pageNumber = 1
            var yOffset: CGFloat = 0

            func startNewPage() {
                ctx.beginPage()
                yOffset = margin
                drawHeader(ctx: ctx.cgContext, meta: headerMeta)
                yOffset += headerHeight + 8
                drawColumnHeaders(ctx: ctx.cgContext, y: yOffset, columns: columns)
                yOffset += columnHeaderHeight + 4
                pageNumber += 1
            }

            // First page
            ctx.beginPage()
            yOffset = margin
            drawHeader(ctx: ctx.cgContext, meta: headerMeta)
            yOffset += headerHeight + 8
            drawColumnHeaders(ctx: ctx.cgContext, y: yOffset, columns: columns)
            yOffset += columnHeaderHeight + 4

            for (index, row) in rows.enumerated() {
                let nearBottom = pageSize.height - margin - footerHeight - 8
                if yOffset + rowHeight > nearBottom {
                    drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
                    startNewPage()
                }
                drawRow(ctx: ctx.cgContext, row: row, index: index, y: yOffset, columns: columns)
                yOffset += rowHeight
            }

            drawFooter(ctx: ctx.cgContext, pageNumber: pageNumber)
        }

        return data
    }

    // MARK: - Header drawing

    private func drawHeader(ctx: CGContext, meta: HeaderMeta) {
        let x = margin
        var y = margin

        // Teal accent bar
        ctx.setFillColor(tealColor)
        ctx.fill(CGRect(x: x, y: y, width: contentWidth, height: 3))
        y += 10

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Fraunces72pt-Bold", size: 20)
                ?? UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]
        NSAttributedString(string: "Aurae Headache Report", attributes: titleAttrs)
            .draw(at: CGPoint(x: x, y: y))
        y += 26

        // Subtitle: date range + count
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PlusJakartaSans-Regular", size: 11)
                ?? UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]
        let countLabel = "\(meta.count) headache\(meta.count == 1 ? "" : "s")"
        NSAttributedString(
            string: "\(meta.dateRange)  ·  \(countLabel)",
            attributes: subtitleAttrs
        ).draw(at: CGPoint(x: x, y: y))
        y += 16

        // Bottom rule
        ctx.setStrokeColor(grayColor.copy(alpha: 0.25) ?? grayColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + contentWidth, y: y))
        ctx.strokePath()
    }

    // MARK: - Column header drawing

    private func drawColumnHeaders(ctx: CGContext, y: CGFloat, columns: [Column]) {
        ctx.setFillColor(rowTintColor)
        ctx.fill(CGRect(x: margin, y: y, width: contentWidth, height: columnHeaderHeight))

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PlusJakartaSans-SemiBold", size: 9)
                ?? UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor(cgColor: navyColor)
        ]

        var xCursor = margin + 4
        for col in columns {
            NSAttributedString(string: col.title.uppercased(), attributes: attrs)
                .draw(at: CGPoint(x: xCursor, y: y + 6))
            xCursor += col.width
        }

        ctx.setStrokeColor(grayColor.copy(alpha: 0.3) ?? grayColor)
        ctx.setLineWidth(0.5)
        let ruleY = y + columnHeaderHeight
        ctx.move(to: CGPoint(x: margin, y: ruleY))
        ctx.addLine(to: CGPoint(x: margin + contentWidth, y: ruleY))
        ctx.strokePath()
    }

    // MARK: - Data row drawing

    private func drawRow(ctx: CGContext, row: LogRow, index: Int, y: CGFloat, columns: [Column]) {
        if index % 2 == 0 {
            ctx.setFillColor(rowTintColor)
            ctx.fill(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight))
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PlusJakartaSans-Regular", size: 9)
                ?? UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]

        let values = [
            row.date, row.time, row.severity, row.duration,
            row.weather, row.medication, row.notes
        ]

        var xCursor = margin + 4
        for (col, value) in zip(columns, values) {
            ctx.saveGState()
            ctx.clip(to: CGRect(x: xCursor - 4, y: y, width: col.width, height: rowHeight))
            NSAttributedString(string: value, attributes: attrs)
                .draw(at: CGPoint(x: xCursor, y: y + 8))
            ctx.restoreGState()
            xCursor += col.width
        }
    }

    // MARK: - Footer drawing

    private func drawFooter(ctx: CGContext, pageNumber: Int) {
        let y = pageSize.height - margin - footerHeight

        ctx.setStrokeColor(grayColor.copy(alpha: 0.25) ?? grayColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: y))
        ctx.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        ctx.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PlusJakartaSans-Regular", size: 8)
                ?? UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor(cgColor: grayColor)
        ]

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        let leftText = NSAttributedString(
            string: "Generated by Aurae · \(df.string(from: .now)) · Informational use only — not medical advice.",
            attributes: attrs
        )
        leftText.draw(at: CGPoint(x: margin, y: y + 5))

        let pageStr = NSAttributedString(string: "Page \(pageNumber)", attributes: attrs)
        let strSize = pageStr.size()
        pageStr.draw(at: CGPoint(x: pageSize.width - margin - strSize.width, y: y + 5))
    }
}
