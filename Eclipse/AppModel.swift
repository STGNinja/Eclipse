//
//  AppModel.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation

struct EclipseAppInfo: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let iconName: String // System name or asset name
    let description: String
    let developer: String
    let category: String
    let tintColor: String // Hex string
    let logoUrl: String? // Optional URL for remote logo
    let commandPreview: String? // e.g. "@App create something"
    let appStoreUrl: String?
    let previewImages: [String]? // Added for app store screenshots
    let sampleQueries: [String]? // Added for usage examples

    init(id: String, name: String, iconName: String, description: String, developer: String, category: String, tintColor: String, logoUrl: String? = nil, commandPreview: String? = nil, appStoreUrl: String? = nil, previewImages: [String]? = nil, sampleQueries: [String]? = nil) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.description = description
        self.developer = developer
        self.category = category
        self.tintColor = tintColor
        self.logoUrl = logoUrl
        self.commandPreview = commandPreview
        self.appStoreUrl = appStoreUrl
        self.previewImages = previewImages
        self.sampleQueries = sampleQueries
    }
}

protocol AppPlugin {
    var appId: String { get }
    var systemPromptExtension: String { get }
    func handleToolCall(name: String, arguments: [String: Any]) async throws -> String?
}
