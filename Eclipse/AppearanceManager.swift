//
//  AppearanceManager.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Combine

enum GradientStyle: String, CaseIterable, Codable {
    case none = "None"
    case aurora = "Aurora"
    case sunset = "Sunset"
    case ocean = "Ocean"
    case forest = "Forest"
    case cosmic = "Cosmic"
    case lavender = "Lavender"
    case fire = "Fire"
    case rose = "Rose"
    
    var colors: [Color] {
        switch self {
        case .none:
            return []
        case .aurora:
            return [.green.opacity(0.3), .blue.opacity(0.4), .purple.opacity(0.3)]
        case .sunset:
            return [.orange.opacity(0.3), .pink.opacity(0.4), .purple.opacity(0.3)]
        case .ocean:
            return [.blue.opacity(0.3), .cyan.opacity(0.4), .teal.opacity(0.3)]
        case .forest:
            return [.green.opacity(0.3), .mint.opacity(0.4), .teal.opacity(0.3)]
        case .cosmic:
            return [.purple.opacity(0.3), .indigo.opacity(0.4), .blue.opacity(0.3)]
        case .lavender:
            return [.purple.opacity(0.3), .pink.opacity(0.4), .indigo.opacity(0.3)]
        case .fire:
            return [.red.opacity(0.3), .orange.opacity(0.4), .yellow.opacity(0.3)]
        case .rose:
            return [.pink.opacity(0.3), .red.opacity(0.4), .purple.opacity(0.3)]
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return "xmark.circle"
        case .aurora:
            return "sparkles"
        case .sunset:
            return "sun.horizon"
        case .ocean:
            return "water.waves"
        case .forest:
            return "leaf"
        case .cosmic:
            return "moon.stars"
        case .lavender:
            return "cloud"
        case .fire:
            return "flame"
        case .rose:
            return "heart"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .none:
            return .gray
        case .aurora:
            return .green
        case .sunset:
            return .orange
        case .ocean:
            return .blue
        case .forest:
            return .green
        case .cosmic:
            return .purple
        case .lavender:
            return .purple
        case .fire:
            return .red
        case .rose:
            return .pink
        }
    }
}

@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @Published var selectedGradient: GradientStyle = .none
    @Published var customBackgroundData: Data? = nil
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    private init() {
        self.customBackgroundData = UserDefaults.standard.data(forKey: "customBackgroundData")
        loadAppearance()
    }
    
    // MARK: - Load Appearance
    
    func loadAppearance() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No user logged in")
            return
        }
        
        isLoading = true
        
        db.collection("users")
            .document(userID)
            .collection("preferences")
            .document("appearance")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error loading appearance: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    return
                }
                
                guard let data = snapshot?.data(),
                      let gradientString = data["gradient"] as? String,
                      let gradient = GradientStyle(rawValue: gradientString) else {
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    return
                }
                
                Task { @MainActor in
                    self.selectedGradient = gradient
                    self.isLoading = false
                    print("✅ Loaded appearance: \(gradient.rawValue)")
                }
            }
    }
    
    // MARK: - Save Appearance
    
    func saveAppearance(_ gradient: GradientStyle) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppearanceManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let data: [String: Any] = [
            "gradient": gradient.rawValue,
            "hasCustomBackground": customBackgroundData != nil,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users")
            .document(userID)
            .collection("preferences")
            .document("appearance")
            .setData(data, merge: true)
        
        await MainActor.run {
            self.selectedGradient = gradient
        }
        
        print("✅ Appearance saved: \(gradient.rawValue)")
    }
    
    func setCustomBackground(_ data: Data?) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppearanceManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Save locally for performance and to avoid Firestore size limits
        if let data = data {
            UserDefaults.standard.set(data, forKey: "customBackgroundData")
        } else {
            UserDefaults.standard.removeObject(forKey: "customBackgroundData")
        }
        
        let dataSync: [String: Any] = [
            "hasCustomBackground": data != nil,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users")
            .document(userID)
            .collection("preferences")
            .document("appearance")
            .setData(dataSync, merge: true)
        
        await MainActor.run {
            self.customBackgroundData = data
        }
        
        print("✅ Custom Background \(data == nil ? "removed" : "saved")")
    }
}
