//
//  WeatherService.swift
//  Aurae
//
//  Fetches current weather data from the Open-Meteo API (free, no API key
//  required) and assembles a WeatherSnapshot value.
//
//  Design rules enforced here:
//  - No API key required — Open-Meteo is a free, open service.
//  - Single endpoint fires for all current metrics:
//      temperature_2m, relative_humidity_2m, surface_pressure,
//      uv_index, weather_code
//  - Weather failure returns nil for the entire capture.
//  - Location coordinates flow in as parameters and are never stored.
//  - No health data is included in any request.
//  - All network errors are caught internally; the caller receives nil
//    on any failure and never sees an error throw.
//  - AQI is not available from this endpoint and is left as nil.
//

import Foundation

// MARK: - WeatherService

actor WeatherService {

    // -------------------------------------------------------------------------
    // MARK: Shared instance
    // -------------------------------------------------------------------------

    static let shared = WeatherService()

    // -------------------------------------------------------------------------
    // MARK: Private state
    // -------------------------------------------------------------------------

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 10
        config.timeoutIntervalForResource = 20
        session = URLSession(configuration: config)
    }

    // -------------------------------------------------------------------------
    // MARK: Base URL
    // -------------------------------------------------------------------------

    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    // =========================================================================
    // MARK: - Public API
    // =========================================================================

    /// Fetches current weather for the given coordinate and returns a
    /// fully-populated `WeatherSnapshot`.
    ///
    /// Returns `nil` if the request fails or the response cannot be decoded.
    /// This method never throws to the caller.
    func capture(latitude: Double, longitude: Double) async -> WeatherSnapshot? {
        guard let response = await fetchCurrentWeather(lat: latitude, lon: longitude) else {
            return nil
        }

        let current       = response.current
        let pressure      = current.surface_pressure
        let pressureTrend = derivePressureTrend(from: pressure)
        let condition     = WeatherSnapshot.condition(fromWMOCode: current.weather_code)
        let uvIndex       = current.uv_index ?? 0.0

        return WeatherSnapshot(
            temperature:   current.temperature_2m,
            humidity:      current.relative_humidity_2m,
            pressure:      pressure,
            pressureTrend: pressureTrend,
            uvIndex:       uvIndex,
            aqi:           nil,   // Open-Meteo current endpoint does not expose AQI
            condition:     condition,
            capturedAt:    Date.now
        )
    }

    // =========================================================================
    // MARK: - Network request
    // =========================================================================

    private func fetchCurrentWeather(
        lat: Double,
        lon: Double
    ) async -> OpenMeteoCurrentResponse? {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude",  value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(
                name:  "current",
                value: "temperature_2m,relative_humidity_2m,surface_pressure,uv_index,weather_code"
            )
        ]
        return await get(url: components.url, as: OpenMeteoCurrentResponse.self)
    }

    // -------------------------------------------------------------------------
    // MARK: Generic GET helper
    // -------------------------------------------------------------------------

    /// Performs a GET request, decodes the JSON response into `T`, and returns
    /// nil on any network or decoding error. Never throws.
    private func get<T: Decodable>(url: URL?, as type: T.Type) async -> T? {
        guard let url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else { return nil }

            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // Network errors and decoding errors both produce nil.
            // Logging the error type (not values) is safe and useful during
            // development but must never include location coordinates.
            return nil
        }
    }

    // =========================================================================
    // MARK: - Mapping helpers
    // =========================================================================

    // -------------------------------------------------------------------------
    // MARK: Pressure trend
    // -------------------------------------------------------------------------

    /// Derives a pressure trend label from a single pressure reading.
    ///
    /// Thresholds per task specification:
    /// - < 1005 hPa → "falling"  (low pressure system, likely weather change)
    /// - > 1015 hPa → "rising"   (high pressure system, generally stable)
    /// - Otherwise  → "stable"
    ///
    /// A single-point reading cannot truly determine direction of change; this
    /// heuristic correlates absolute pressure with typical weather patterns and
    /// matches the model's intent. A future enhancement would compare to the
    /// prior log's pressure to compute a true trend.
    private func derivePressureTrend(from pressure: Double) -> String {
        if pressure < 1005 { return "falling" }
        if pressure > 1015 { return "rising" }
        return "stable"
    }
}

// ============================================================================
// MARK: - Open-Meteo Response models (Codable, private to this file)
// ============================================================================
//
// These types mirror the Open-Meteo JSON structure exactly so the decoder can
// use automatic synthesis. They are private — no response type leaks above
// this file. HomeViewModel and WeatherSnapshot only ever see WeatherSnapshot.

// MARK: Root response — https://api.open-meteo.com/v1/forecast

private struct OpenMeteoCurrentResponse: Decodable {
    let current: OpenMeteoCurrent
}

// MARK: Current weather block

private struct OpenMeteoCurrent: Decodable {
    let temperature_2m:        Double
    let relative_humidity_2m:  Double
    let surface_pressure:      Double
    let uv_index:              Double?   // May be absent when sun is below horizon
    let weather_code:          Int
}
