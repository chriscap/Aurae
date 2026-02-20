//
//  LogCard.swift
//  Aurae
//
//  History list card representing a single HeadacheLog entry. Displays onset
//  time, severity badge, duration (if resolved), and a summary row of captured
//  context (weather condition, heart rate if available). The card navigates to
//  LogDetailView when tapped.
//
//  This component is self-contained: it accepts plain value types so it can be
//  previewed and tested without a SwiftData environment.
//

import SwiftUI

// MARK: - LogCard view model (plain struct — no SwiftData dependency)

/// Lightweight display model populated by HistoryViewModel from a HeadacheLog.
struct LogCardViewModel: Identifiable {
    let id: UUID
    let onsetTime: Date
    let resolvedTime: Date?
    let severity: Int              // 1–5
    let isActive: Bool

    // Optional enrichment data
    let weatherCondition: String?  // e.g. "Cloudy"
    let weatherTemp: Double?       // Celsius
    let heartRate: Double?         // bpm
    let hasRetrospective: Bool

    // MARK: Computed display properties

    var severityLevel: SeverityLevel {
        SeverityLevel(rawValue: max(1, min(5, severity))) ?? .moderate
    }

    var formattedOnsetTime: String {
        onsetTime.formatted(date: .abbreviated, time: .shortened)
    }

    var durationText: String? {
        guard let resolved = resolvedTime else { return nil }
        let minutes = Int(resolved.timeIntervalSince(onsetTime) / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let rem   = minutes % 60
            return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
        }
    }

    var statusText: String {
        if isActive { return "Ongoing" }
        if let duration = durationText { return duration }
        return "Duration unknown"
    }
}

// MARK: - LogCard

struct LogCard: View {

    let viewModel: LogCardViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Severity indicator bar
            severityBar

            VStack(alignment: .leading, spacing: 6) {
                // Top row: severity label + status badge
                HStack {
                    Text(viewModel.severityLevel.label)
                        .font(.auraeH2)
                        .foregroundStyle(Color.auraeNavy)

                    Spacer()

                    statusBadge
                }

                // Time
                Text(viewModel.formattedOnsetTime)
                    .font(.auraeCaption)
                    .foregroundStyle(Color.auraeMidGray)

                // Context chips (weather + HR)
                if hasContextData {
                    contextRow
                }

                // Retrospective completeness indicator
                if viewModel.hasRetrospective {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.auraeTeal)
                        Text("Retrospective complete")
                            .font(.auraeCaption)
                            .foregroundStyle(Color.auraeTeal)
                    }
                }
            }
        }
        .padding(Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        .shadow(
            color: Color.auraeNavy.opacity(Layout.cardShadowOpacity),
            radius: Layout.cardShadowRadius,
            x: 0,
            y: Layout.cardShadowY
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Sub-views

    private var severityBar: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.severityAccent(for: viewModel.severity))
            .frame(width: 5)
            .frame(maxHeight: .infinity)
    }

    private var statusBadge: some View {
        Text(viewModel.statusText)
            .font(.auraeCaption)
            .foregroundStyle(viewModel.isActive ? Color.auraeTeal : Color.auraeMidGray)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                viewModel.isActive
                    ? Color.auraeSoftTeal
                    : Color.auraeLavender
            )
            .clipShape(Capsule())
    }

    private var hasContextData: Bool {
        viewModel.weatherCondition != nil || viewModel.heartRate != nil
    }

    private var contextRow: some View {
        HStack(spacing: 10) {
            if let condition = viewModel.weatherCondition {
                ContextChip(
                    icon: weatherIcon(for: condition),
                    text: viewModel.weatherTemp.map { "\(Int($0))°" } ?? condition
                )
            }
            if let hr = viewModel.heartRate {
                ContextChip(icon: "heart.fill", text: "\(Int(hr)) bpm")
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append("Headache on \(viewModel.formattedOnsetTime)")
        parts.append("\(viewModel.severityLevel.label) severity")
        parts.append(viewModel.isActive ? "Ongoing" : viewModel.durationText.map { "Duration: \($0)" } ?? "")
        if let condition = viewModel.weatherCondition { parts.append("Weather: \(condition)") }
        if let hr = viewModel.heartRate { parts.append("Heart rate: \(Int(hr)) bpm") }
        return parts.filter { !$0.isEmpty }.joined(separator: ". ")
    }

    // MARK: - Helpers

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear", "sunny":       return "sun.max.fill"
        case "cloudy", "overcast":   return "cloud.fill"
        case "rain", "drizzle":      return "cloud.rain.fill"
        case "snow":                 return "cloud.snow.fill"
        case "storm":                return "cloud.bolt.fill"
        case "fog", "mist":          return "cloud.fog.fill"
        default:                     return "cloud.fill"
        }
    }
}

// MARK: - ContextChip

private struct ContextChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color.auraeMidGray)
            Text(text)
                .font(.auraeCaption)
                .foregroundStyle(Color.auraeMidGray)
        }
    }
}

// MARK: - Preview

#Preview("LogCard examples") {
    ScrollView {
        VStack(spacing: 12) {
            // Active headache
            LogCard(viewModel: LogCardViewModel(
                id: UUID(),
                onsetTime: Date().addingTimeInterval(-1800),
                resolvedTime: nil,
                severity: 4,
                isActive: true,
                weatherCondition: "Cloudy",
                weatherTemp: 14.5,
                heartRate: 82,
                hasRetrospective: false
            ))

            // Resolved with full data
            LogCard(viewModel: LogCardViewModel(
                id: UUID(),
                onsetTime: Date().addingTimeInterval(-86400 * 2),
                resolvedTime: Date().addingTimeInterval(-86400 * 2 + 7200),
                severity: 2,
                isActive: false,
                weatherCondition: "Clear",
                weatherTemp: 22.0,
                heartRate: 68,
                hasRetrospective: true
            ))

            // Minimal data
            LogCard(viewModel: LogCardViewModel(
                id: UUID(),
                onsetTime: Date().addingTimeInterval(-86400 * 5),
                resolvedTime: Date().addingTimeInterval(-86400 * 5 + 3600),
                severity: 5,
                isActive: false,
                weatherCondition: nil,
                weatherTemp: nil,
                heartRate: nil,
                hasRetrospective: false
            ))
        }
        .padding(Layout.screenPadding)
    }
    .background(Color.auraeBackground.ignoresSafeArea())
}
