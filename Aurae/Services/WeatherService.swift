//
//  WeatherService.swift
//  Aurae
//
//  Fetches current weather, UV index, and air quality data from the
//  OpenWeatherMap API and assembles a WeatherSnapshot value.
//
//  Design rules enforced here:
//  - API key is read from Secrets.swift (gitignored). Never hardcoded.
//  - Three OWM endpoints fire concurrently with async let:
//      1. Current Weather  — /data/2.5/weather
//      2. UV Index         — /data/2.5/uvi
//      3. Air Pollution    — /data/2.5/air_pollution
//  - UV and AQI failures produce default values (0.0 and nil); weather
//    failure returns nil for the entire capture.
//  - Location coordinates flow in as parameters and are never stored.
//  - No health data is included in any request.
//  - All network errors are caught internally; the caller receives nil
//    on any failure and never sees an error throw.
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
    // MARK: Base URL & API key
    // -------------------------------------------------------------------------

    private let baseURL = "https://api.openweathermap.org/data/2.5"

    private var apiKey: String {
        Secrets.openWeatherMapAPIKey
    }

    // =========================================================================
    // MARK: - Public API
    // =========================================================================

    /// Fetches weather, UV index, and air quality for the given coordinate
    /// and returns a fully-populated `WeatherSnapshot`.
    ///
    /// Returns `nil` if the primary weather request fails. UV and AQI failures
    /// are non-fatal: the snapshot is still returned with `uvIndex = 0.0` and
    /// `aqi = nil` respectively.
    ///
    /// This method never throws to the caller.
    func capture(latitude: Double, longitude: Double) async -> WeatherSnapshot? {
        guard !apiKey.isEmpty, apiKey != "YOUR_OWM_API_KEY_HERE" else {
            return nil
        }

        // Fire all three requests concurrently.
        async let weatherResponse = fetchCurrentWeather(lat: latitude, lon: longitude)
        async let uvResponse      = fetchUVIndex(lat: latitude, lon: longitude)
        async let aqiResponse     = fetchAirQuality(lat: latitude, lon: longitude)

        guard let weather = await weatherResponse else {
            // Primary weather call failed — cannot build a meaningful snapshot.
            return nil
        }

        let uv  = await uvResponse
        let aqi = await aqiResponse

        let pressure      = weather.main.pressure
        let pressureTrend = derivePressureTrend(from: pressure)
        let condition     = mapCondition(from: weather.weather.first?.main ?? "")
        let uvIndex       = uv?.value ?? 0.0
        let aqiValue      = aqi?.list.first?.main.aqi

        return WeatherSnapshot(
            temperature:   weather.main.temp,
            humidity:      weather.main.humidity,
            pressure:      pressure,
            pressureTrend: pressureTrend,
            uvIndex:       uvIndex,
            aqi:           aqiValue,
            condition:     condition,
            capturedAt:    Date.now
        )
    }

    // =========================================================================
    // MARK: - Network requests
    // =========================================================================

    private func fetchCurrentWeather(
        lat: Double,
        lon: Double
    ) async -> OWMCurrentWeatherResponse? {
        var components = URLComponents(string: "\(baseURL)/weather")!
        components.queryItems = [
            URLQueryItem(name: "lat",   value: String(lat)),
            URLQueryItem(name: "lon",   value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        return await get(url: components.url, as: OWMCurrentWeatherResponse.self)
    }

    private func fetchUVIndex(
        lat: Double,
        lon: Double
    ) async -> OWMUVResponse? {
        var components = URLComponents(string: "\(baseURL)/uvi")!
        components.queryItems = [
            URLQueryItem(name: "lat",   value: String(lat)),
            URLQueryItem(name: "lon",   value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        return await get(url: components.url, as: OWMUVResponse.self)
    }

    private func fetchAirQuality(
        lat: Double,
        lon: Double
    ) async -> OWMAirQualityResponse? {
        var components = URLComponents(string: "\(baseURL)/air_pollution")!
        components.queryItems = [
            URLQueryItem(name: "lat",   value: String(lat)),
            URLQueryItem(name: "lon",   value: String(lon)),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        return await get(url: components.url, as: OWMAirQualityResponse.self)
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

    // -------------------------------------------------------------------------
    // MARK: OWM condition → canonical condition string
    // -------------------------------------------------------------------------

    /// Maps an OpenWeatherMap `weather[0].main` string to the canonical
    /// condition strings used throughout the app.
    ///
    /// OWM condition groups (as of API v2.5):
    ///   Thunderstorm, Drizzle, Rain, Snow, Mist, Smoke, Haze, Dust,
    ///   Fog, Sand, Ash, Squall, Tornado, Clear, Clouds
    private func mapCondition(from owmMain: String) -> String {
        switch owmMain.lowercased() {
        case "clear":
            return "clear"
        case "clouds":
            return "cloudy"
        case "rain":
            return "rain"
        case "drizzle":
            return "rain"
        case "thunderstorm":
            return "storm"
        case "snow":
            return "snow"
        case "mist", "fog":
            return "fog"
        case "haze", "smoke", "dust", "sand", "ash":
            return "haze"
        case "squall", "tornado":
            return "storm"
        default:
            return "cloudy"
        }
    }
}

// ============================================================================
// MARK: - OWM Response models (Codable, private to this file)
// ============================================================================
//
// These types mirror the OWM JSON structure exactly so the decoder can use
// automatic synthesis. They are private — no OWM type leaks above this file.
// HomeViewModel and WeatherSnapshot only ever see the canonical WeatherSnapshot.

// MARK: Current Weather — /data/2.5/weather

private struct OWMCurrentWeatherResponse: Decodable {
    let main:    OWMMain
    let weather: [OWMWeatherCondition]
}

private struct OWMMain: Decodable {
    let temp:     Double
    let humidity: Double
    let pressure: Double
}

private struct OWMWeatherCondition: Decodable {
    let main:        String   // e.g. "Clear", "Rain", "Clouds"
    let description: String   // e.g. "light rain" — not used but decoded for completeness
    let icon:        String   // e.g. "10d" — not used
}

// MARK: UV Index — /data/2.5/uvi

private struct OWMUVResponse: Decodable {
    let value: Double

    // OWM returns a flat object: { "lat": ..., "lon": ..., "value": 3.5 }
    private enum CodingKeys: String, CodingKey {
        case value
    }
}

// MARK: Air Pollution — /data/2.5/air_pollution

private struct OWMAirQualityResponse: Decodable {
    let list: [OWMAirQualityEntry]
}

private struct OWMAirQualityEntry: Decodable {
    let main: OWMAQIMain
}

private struct OWMAQIMain: Decodable {
    let aqi: Int
    // OWM AQI scale: 1 (Good) – 5 (Very Poor)
    // Stored directly — no conversion needed for the model.
}
