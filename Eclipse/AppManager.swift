//
//  AppManager.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - AppManager

class AppManager: ObservableObject {
    static let shared = AppManager()
    
    @Published var downloadedAppIds: Set<String> = []
    @Published var availableApps: [EclipseAppInfo] = []
    
    private let storageKey = "com.eclipse.downloadedApps"
    
    init() {
        loadDownloadedApps()
        setupStore()
    }
    
    func isDownloaded(_ appId: String) -> Bool {
        return downloadedAppIds.contains(appId)
    }
    
    func downloadApp(_ app: EclipseAppInfo) {
        downloadedAppIds.insert(app.id)
        saveDownloadedApps()
        objectWillChange.send()
    }
    
    func removeApp(_ appId: String) {
        downloadedAppIds.remove(appId)
        saveDownloadedApps()
        objectWillChange.send()
    }
    
    private func saveDownloadedApps() {
        UserDefaults.standard.set(Array(downloadedAppIds), forKey: storageKey)
    }
    
    private func loadDownloadedApps() {
        if let saved = UserDefaults.standard.stringArray(forKey: storageKey) {
            downloadedAppIds = Set(saved)
        }
    }
    
    private func setupStore() {
        availableApps = [
            EclipseAppInfo(
                id: "apple_music",
                name: "Apple Music",
                iconName: "music.note",
                description: "Build playlists and find music",
                developer: "Apple",
                category: "Music",
                tintColor: "#FC3C44",
                logoUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Apple_Music_icon.svg/512px-Apple_Music_icon.svg.png",
                commandPreview: "@AppleMusic play top hits",
                appStoreUrl: "https://apps.apple.com/us/app/apple-music/id1108187390",
                previewImages: ["1apprev.png", "2apprev.png"],
                sampleQueries: [
                    "Make me a playlist for a coding session",
                    "What's some good 80s synthpop?",
                    "Find some chill lo-fi beats",
                    "Can you make me a playlist for my workout?",
                    "What's currently trending in alternative rock?"
                ]
            ),
            EclipseAppInfo(
                id: "apple_maps",
                name: "Apple Maps",
                iconName: "map.fill",
                description: "Find nearby places and get directions",
                developer: "Apple",
                category: "Navigation",
                tintColor: "#34C759",
                logoUrl: "maps.png",
                commandPreview: "@AppleMaps find coffee shops",
                appStoreUrl: "maps://"
            ),
            EclipseAppInfo(
                id: "canva",
                name: "Canva",
                iconName: "paintbrush.fill",
                description: "Make designs and flyers",
                developer: "Canva",
                category: "Productivity",
                tintColor: "#00C4CC",
                logoUrl: "canvalog 2.png",
                commandPreview: "@Canva create social posts",
                appStoreUrl: "https://apps.apple.com/us/app/canva-design-photo-video/id897446215",
                previewImages: ["canvaprev1.png", "canvaprev2.png"],
                sampleQueries: [
                    "Design a poster for a car wash",
                    "Create a social media post for summer sale",
                    "Make a birthday party invitation",
                    "Design a business card for a bakery"
                ]
            ),
            EclipseAppInfo(
                id: "eclipse_editing",
                name: "Eclipse Editing",
                iconName: "wand.and.stars", // System icon
                description: "Generate and edit images with AI",
                developer: "Eclipse AI",
                category: "Design",
                tintColor: "#AF52DE", // Purple/Indigo
                logoUrl: "betterlunr.png", // New logo
                commandPreview: "@Eclipse create a futuristic city",
                appStoreUrl: nil, // Built-in feature
                previewImages: ["3apprev.png"], // Placeholder usage
                sampleQueries: [
                    "Generate a logo for my startup",
                    "Create a cyberpunk street scene",
                    "Draw a cute cat astronaut",
                    "Design a modern house exterior"
                ]
            ),
            EclipseAppInfo(
                id: "apple_weather", // Changed ID to reflect new name
                name: "Apple Weather",
                iconName: "cloud.sun.fill", // Keep SF Symbol as fallback or generic icon reference
                description: "Forecasts and conditions",
                developer: "Apple",
                category: "Weather",
                tintColor: "#00A2FF",
                logoUrl: "weather.png", // User requested "weather.png"
                commandPreview: "@Weather forecast for tomorrow",
                appStoreUrl: nil // Built-in
            ),
            EclipseAppInfo(
                id: "finance_tracker",
                name: "WealthWise",
                iconName: "chart.line.uptrend.xyaxis",
                description: "Track stocks and crypto",
                developer: "Finance Core",
                category: "Finance",
                tintColor: "#34C759",
                logoUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/IOS_14_App_Icon_%E2%80%94_Stocks.png/512px-IOS_14_App_Icon_%E2%80%94_Stocks.png",
                commandPreview: "@WealthWise check BTC price"
            ),
            EclipseAppInfo(
                id: "travel_planner",
                name: "Voyager",
                iconName: "airplane",
                description: "Plan trips and flights",
                developer: "Global Explorer",
                category: "Travel",
                tintColor: "#5856D6",
                logoUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/IOS_14_App_Icon_%E2%80%94_App_Store.png/512px-IOS_14_App_Icon_%E2%80%94_App_Store.png",
                commandPreview: "@Voyager plan trip to Paris"
            ),
            EclipseAppInfo(
                id: "health_kit",
                name: "Health",
                iconName: "heart.fill",
                description: "Wellness & sleep tracking",
                developer: "Eclipse AI",
                category: "Health & Fitness",
                tintColor: "#FF2D55", // Pink/Red
                logoUrl: "health.png",
                commandPreview: "@Health how did I sleep?",
                appStoreUrl: nil 
            )
        ]
    }
    
    var myApps: [EclipseAppInfo] {
        availableApps.filter { downloadedAppIds.contains($0.id) }
    }
}
