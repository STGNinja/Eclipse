//
//  MapsService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/18/25.
//

import Foundation
import MapKit

class MapsService {
    static let shared = MapsService()
    
    // Perform a natural language search (e.g., "coffee shops") near a specific coordinate
    func searchPlaces(query: String, near location: CLLocation, radiusMeters: Double = 5000) async throws -> [MapLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radiusMeters,
            longitudinalMeters: radiusMeters
        )
        request.region = region
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems.map { item in
            let distance = location.distance(from: item.placemark.location ?? location)
            return MapLocation(
                name: item.name ?? "Unknown Place",
                address: formatAddress(placemark: item.placemark),
                coordinate: item.placemark.coordinate,
                distanceMeters: distance,
                phoneNumber: item.phoneNumber,
                url: item.url
            )
        }
    }
    
    private func formatAddress(placemark: MKPlacemark) -> String {
        return [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
    
    // MARK: - Intent Analysis
    
    func shouldPerformMapSearch(for query: String) -> Bool {
        let lowerQuery = query.lowercased()
        let triggers = [
            "where is", "where's", "nearest", "nearby", "closest",
            "find a", "find the", "search for", "directions to",
            "location of", "distance to", "how far is"
        ]
        
        return triggers.contains { lowerQuery.contains($0) }
    }
    
    func extractQuery(from message: String) -> String {
        var query = message
        let lower = message.lowercased()
        
        // Remove trigger phrases to clean up the query
        let prefixes = [
            "where is the nearest", "where is the", "where is", "where's",
            "find the nearest", "find a", "find",
            "search for", "show me",
            "what is the nearest", "closest", "nearby"
        ]
        
        for prefix in prefixes {
            if let range = lower.range(of: prefix) {
                // If the prefix is at the start (ignoring case), remove it
                // We use the range form the lowercased string to find the index in the original string
                // But this is tricky with indices. Simple replacement is safer for now.
                // Or better: just replace occurrences (case insensitive)
                query = query.replacingOccurrences(of: prefix, with: "", options: .caseInsensitive)
            }
        }
        
        return query.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "?!."))
    }
}

// Simple struct to pass data back to AI context
struct MapLocation: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Double
    let phoneNumber: String?
    let url: URL?
    
    var formattedString: String {
        let dist = String(format: "%.1f km", distanceMeters / 1000)
        var details = "- **\(name)** (\(dist) away)\n  Address: \(address)"
        if let phone = phoneNumber {
            details += "\n  Phone: \(phone)"
        }
        if let link = url {
            details += "\n  Website: \(link.absoluteString)"
        }
        // Include the raw command for the AI to use if it wants to show the map
        details += "\n  MAP_DATA: [\(coordinate.latitude), \(coordinate.longitude), \"\(name)\", \"\(address)\"]"
        return details
    }
}
