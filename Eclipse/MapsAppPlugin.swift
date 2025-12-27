//
//  MapsAppPlugin.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import MapKit

class MapsAppPlugin: AppPlugin {
    var appId: String = "apple_maps"

    var systemPromptExtension: String {
        """
        You are now connected to the Apple Maps Plugin. You have the ability to search for nearby locations and provide directions.

        IMPORTANT: When the user asks about locations, the system will automatically search for them and provide you with results in the format:
        [System Info: Nearby Locations Found for 'query']:
        - **Name** (distance away)
          Address: ...
          MAP_DATA: [lat, lng, "Name", "Address"]

        To display a location on the map, you MUST use this exact format:
        MAP_LOCATION: [lat, lng, "Title", "Subtitle"]

        Extract the coordinates from the MAP_DATA line and use them in your MAP_LOCATION command.

        Example:
        If you receive: MAP_DATA: [34.0522, -118.2437, "Walmart", "123 Main St"]
        You should output: MAP_LOCATION: [34.0522, -118.2437, "Walmart", "123 Main St"]

        DO NOT output "MAPS_SEARCH:" - that is an internal command. Always use MAP_LOCATION to show locations to the user.
        """
    }

    func handleToolCall(name: String, arguments: [String : Any]) async throws -> String? {
        // Implementation details handled in GeminiService for now for simplicity
        return nil
    }
}
