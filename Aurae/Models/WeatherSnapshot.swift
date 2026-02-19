//
//  WeatherSnapshot.swift
//  Aurae
//
//  SwiftData model representing a point-in-time weather capture made at the
//  moment of headache onset. Populated by WeatherService from the Open-Meteo
//  API. The location used for the query is NOT persisted here — only the
//  resolved meteorological values.
//

import Foundation
import SwiftData

@Model
final class WeatherSnapshot {

    // MARK: - Core measurements

    /// Ambient temperature at capture time, in degrees Celsius.
    var temperature: Double

    /// Relative humidity, 0–100 %.
    var humidity: Double

    /// Atmospheric (surface) pressure in hPa (millibars).
    var pressure: Double

    /// Direction of pressure change over the preceding hour.
    /// Raw values: "rising" | "falling" | "stable"
    var pressureTrend: String

    /// UV index (0–11+) at capture time.
    var uvIndex: Double

    /// Air Quality Index. Nil when the data source does not provide it.
    var aqi: Int?

    /// General sky condition mapped from the Open-Meteo WMO weather code.
    /// Examples: "clear", "partly_cloudy", "cloudy", "rain", "snow", "storm", "fog"
    var condition: String

    // MARK: - Provenance

    /// Timestamp when the weather data was fetched from the API.
    var capturedAt: Date

    // MARK: - Init

    init(
        temperature: Double,
        humidity: Double,
        pressure: Double,
        pressureTrend: String,
        uvIndex: Double,
        aqi: Int? = nil,
        condition: String,
        capturedAt: Date = .now
    ) {
        self.temperature    = temperature
        self.humidity       = humidity
        self.pressure       = pressure
        self.pressureTrend  = pressureTrend
        self.uvIndex        = uvIndex
        self.aqi            = aqi
        self.condition      = condition
        self.capturedAt     = capturedAt
    }
}

// MARK: - Pressure trend helpers

extension WeatherSnapshot {

    enum PressureTrend: String {
        case rising  = "rising"
        case falling = "falling"
        case stable  = "stable"
    }

    var pressureTrendEnum: PressureTrend {
        PressureTrend(rawValue: pressureTrend) ?? .stable
    }

    /// Human-readable summary suitable for display in a log card or detail view.
    var displaySummary: String {
        let tempFormatted = String(format: "%.0f°C", temperature)
        let trendSymbol: String
        switch pressureTrendEnum {
        case .rising:  trendSymbol = "↑"
        case .falling: trendSymbol = "↓"
        case .stable:  trendSymbol = "→"
        }
        return "\(tempFormatted)  \(condition.replacingOccurrences(of: "_", with: " ").capitalized)  \(String(format: "%.0f", pressure)) hPa \(trendSymbol)"
    }
}

// MARK: - WMO code mapping (Open-Meteo)

extension WeatherSnapshot {

    /// Converts an Open-Meteo WMO weather interpretation code to a canonical
    /// condition string stored in `condition`.
    static func condition(fromWMOCode code: Int) -> String {
        switch code {
        case 0:            return "clear"
        case 1, 2:         return "partly_cloudy"
        case 3:            return "cloudy"
        case 45, 48:       return "fog"
        case 51, 53, 55:   return "drizzle"
        case 61, 63, 65:   return "rain"
        case 71, 73, 75:   return "snow"
        case 77:           return "snow"
        case 80, 81, 82:   return "rain"
        case 85, 86:       return "snow"
        case 95:           return "storm"
        case 96, 99:       return "storm"
        default:           return "cloudy"
        }
    }
}
