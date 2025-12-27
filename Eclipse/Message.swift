//
//  Message.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/16/25.
//

import Foundation
import SwiftUI

struct HealthWidgetData: Codable, Identifiable {
    var id: UUID = UUID()
    let type: String // steps, sleep, heart_rate, active_energy
    let value: String
    let unit: String
}

struct CalendarEventData: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let date: Date
    let duration: TimeInterval
    let notes: String?
}

struct MapData: Codable, Identifiable {
    var id: UUID = UUID()
    let latitude: Double
    let longitude: Double
    let title: String
    let subtitle: String?
}

struct MusicEmbedData: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let artist: String
    var catalogId: String?
    var embedUrl: String?
}

struct PlaylistData: Codable, Identifiable {
    struct SongItem: Codable, Identifiable {
        var id: UUID = UUID()
        let title: String
        let artist: String
        var artworkUrl: String?

        // Playback metadata
        var isInLibrary: Bool?          // Is song in user's library?
        var musicKitId: String?          // MusicKit Track ID (if available)
        var catalogId: String?           // Apple Music Catalog ID
        var isExplicit: Bool?            // Content rating
        var albumName: String?           // Album info
        var releaseYear: Int?            // Release year
        var duration: TimeInterval?      // Track duration in seconds
    }

    var id: UUID = UUID()
    let title: String
    let description: String?
    var songs: [SongItem]

    // Playback capabilities
    var isPlayable: Bool = false               // Can this playlist be played?
    var totalDuration: TimeInterval?           // Total playlist duration
    var libraryMatchCount: Int = 0             // How many songs are in library?
    var catalogMatchCount: Int = 0             // How many found in catalog?
    var resolvedAt: Date?                      // When tracks were last resolved

    // For UI convenience, we might want fully resolved Song objects,
    // but for persistence, IDs are safer. We'll resolve them in the View or Service.
    // For this prototype, we'll store basic display info in the IDs if needed or rely on a helper.
}

struct ImageEditData: Codable, Identifiable {
    var id: UUID = UUID()
    let type: AdjustmentType
    let initialValue: Double
    
    // Custom coding keys to handle the enum
    enum CodingKeys: String, CodingKey {
        case id, type, initialValue
    }
    
    init(id: UUID = UUID(), type: AdjustmentType, initialValue: Double) {
        self.id = id
        self.type = type
        self.initialValue = initialValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        
        let typeString = try container.decode(String.self, forKey: .type)
        type = AdjustmentType(rawValue: typeString) ?? .brightness
        
        initialValue = try container.decode(Double.self, forKey: .initialValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(initialValue, forKey: .initialValue)
    }
}

struct CanvaDesignData: Codable, Identifiable {
    var id: UUID = UUID()
    let designId: String // Canva design ID for fetching fresh thumbnails
    let title: String
    let editUrl: String
    let viewUrl: String
    let thumbnailUrl: String? // Initial thumbnail (expires after 15 min)
}

struct Message: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    let images: [Data]?
    let calendarEvent: CalendarEventData?
    let mapData: MapData?
    let playlist: PlaylistData?
    let musicEmbeds: [MusicEmbedData]?
    let imageEditData: ImageEditData?
    let canvaDesigns: [CanvaDesignData]?
    let weatherData: WeatherData?
    let healthData: [HealthWidgetData]? // Changed to array for multiple widgets
    let webImageUrls: [String]? // URLs for images found via web search
    
    // Coding Keys for persistence
    enum CodingKeys: String, CodingKey {
        case id, text, isUser, timestamp, images, calendarEvent, mapData, playlist, musicEmbeds, imageEditData, canvaDesigns, weatherData, healthData, webImageUrls
    }
    
    // Main Initializer
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date(), images: [Data]? = nil, calendarEvent: CalendarEventData? = nil, mapData: MapData? = nil, playlist: PlaylistData? = nil, musicEmbeds: [MusicEmbedData]? = nil, imageEditData: ImageEditData? = nil, canvaDesigns: [CanvaDesignData]? = nil, weatherData: WeatherData? = nil, healthData: [HealthWidgetData]? = nil, webImageUrls: [String]? = nil) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.images = images
        self.calendarEvent = calendarEvent
        self.mapData = mapData
        self.playlist = playlist
        self.musicEmbeds = musicEmbeds
        self.imageEditData = imageEditData
        self.canvaDesigns = canvaDesigns
        self.weatherData = weatherData
        self.healthData = healthData
        self.webImageUrls = webImageUrls
    }
    
    // Helper init for UI usage (single image)
    init(text: String, isUser: Bool, image: UIImage? = nil) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
        if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
            self.images = [data]
        } else {
            self.images = nil
        }
        self.calendarEvent = nil
        self.mapData = nil
        self.playlist = nil
        self.musicEmbeds = nil
        self.imageEditData = nil
        self.canvaDesigns = nil

        self.weatherData = nil

        self.healthData = nil
        self.webImageUrls = nil
    }
    
    // Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isUser = try container.decode(Bool.self, forKey: .isUser)
        images = try container.decodeIfPresent([Data].self, forKey: .images)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        calendarEvent = try container.decodeIfPresent(CalendarEventData.self, forKey: .calendarEvent)
        mapData = try container.decodeIfPresent(MapData.self, forKey: .mapData)
        playlist = try container.decodeIfPresent(PlaylistData.self, forKey: .playlist)
        musicEmbeds = try container.decodeIfPresent([MusicEmbedData].self, forKey: .musicEmbeds)
        imageEditData = try container.decodeIfPresent(ImageEditData.self, forKey: .imageEditData)
        canvaDesigns = try container.decodeIfPresent([CanvaDesignData].self, forKey: .canvaDesigns)
        weatherData = try container.decodeIfPresent(WeatherData.self, forKey: .weatherData)
        healthData = try container.decodeIfPresent([HealthWidgetData].self, forKey: .healthData)
        webImageUrls = try container.decodeIfPresent([String].self, forKey: .webImageUrls)
    }
}
