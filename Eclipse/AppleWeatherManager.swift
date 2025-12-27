import Foundation
import CoreLocation

class AppleWeatherManager: NSObject, CLLocationManagerDelegate {
    static let shared = AppleWeatherManager()
    
    // Core Location
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    /// Requests the user's current location once
    func requestLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        case .authorizedWhenInUse, .authorizedAlways:
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                locationManager.requestLocation()
            }
        case .denied, .restricted:
            throw NSError(domain: "AppleWeatherManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access denied"])
        @unknown default:
            throw NSError(domain: "AppleWeatherManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown location status"])
        }
    }
    
    // MARK: - Weather Fetching
    
    /// Fetches the current weather using Web Search as a fallback for WeatherKit
    func getCurrentWeather() async throws -> WeatherData {
        let location = try await requestLocation()
        
        // 1. Get City Name
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        let city = placemarks.first?.locality ?? "Current Location"
        let state = placemarks.first?.administrativeArea ?? ""
        let locationString = "\(city) \(state)".trimmingCharacters(in: .whitespaces)
        
        // 2. Perform Web Search
        let query = "current weather in \(locationString)"
        let items = try await WebSearchService.shared.searchItems(query: query)
        
        guard let firstItem = items.first else {
            throw NSError(domain: "AppleWeatherManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No weather data found"])
        }
        
        // 3. Parse Result
        // Typical text: "72°F · Cloudy · Humidity rule..." or "10 Day Weather... 36°/24°. Snow showers..."
        let snippet = firstItem.snippet
        var temperature = "Forecast" // Shorter default
        
        // Strategy 1: Find "XX°F" or "XX°C" directly (cleanest)
        // We look for a standalone number followed by degree symbol
        if let range = snippet.range(of: "\\b\\d{1,3}°[FC]", options: .regularExpression) {
            temperature = String(snippet[range])
        }
        // Strategy 2: Find "High/Low" style like "36°/24°"
        else if let range = snippet.range(of: "\\d+°\\/\\d+°", options: .regularExpression) {
            temperature = String(snippet[range])
        }
        // Strategy 3: Find "High 36F" or similar common weather text patterns
        else if let range = snippet.range(of: "High \\d+[FC]", options: [.regularExpression, .caseInsensitive]) {
             // Extract just the number + unit
             let match = String(snippet[range])
             if let tempRange = match.range(of: "\\d+[FC]", options: .regularExpression) {
                 temperature = String(match[tempRange]) + "°" // Add degree symbol for consistency
             }
        }
        
        // Use the snippet as the condition/description
        // We'll clean it up slightly if it's very long
        let condition = snippet.count > 120 ? String(snippet.prefix(117)) + "..." : snippet
        
        return WeatherData(
            temperature: temperature,
            condition: condition,
            symbolName: "cloud.sun.fill", // Fallback icon
            isDaylight: true // Fallback
        )
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            if let continuation = locationContinuation {
                continuation.resume(throwing: NSError(domain: "AppleWeatherManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access denied"]))
                locationContinuation = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, let continuation = locationContinuation {
            continuation.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let continuation = locationContinuation {
            continuation.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

// Simple model to pass back to UI
struct WeatherData: Codable {
    let temperature: String
    let condition: String
    let symbolName: String
    let isDaylight: Bool
}
