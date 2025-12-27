//
//  VoicePreferencesManager.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/17/25.
//

import Foundation
import Combine
import FirebaseFirestore

class VoicePreferencesManager: ObservableObject {
    static let shared = VoicePreferencesManager()
    
    @Published var selectedVoice: GeminiVoice = .puck
    
    private let db = Firestore.firestore()
    private let userDefaultsKey = "selectedGeminiVoice"
    
    private init() {
        loadVoicePreference()

        // Listen for auth state changes to reload preferences
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateChange),
            name: Notification.Name("AuthStateChanged"),
            object: nil
        )
    }

    @objc private func handleAuthStateChange() {
        print("🔄 Auth state changed, reloading voice preferences")
        loadVoicePreference()
    }

    // MARK: - Load Voice Preference
    func loadVoicePreference() {
        // Check if user is signed in
        let userEmail = AuthManager.shared.userEmail
        if !userEmail.isEmpty {
            print("📱 User signed in, loading from Firebase: \(userEmail)")
            // Load from Firebase
            loadFromFirebase(userEmail: userEmail)
        } else {
            print("📱 No user signed in, loading from UserDefaults")
            // Load from UserDefaults
            loadFromUserDefaults()
        }
    }
    
    // MARK: - Save Voice Preference
    func saveVoicePreference(_ voice: GeminiVoice) {
        selectedVoice = voice
        
        // Check if user is signed in
        let userEmail = AuthManager.shared.userEmail
        if !userEmail.isEmpty {
            // Save to Firebase
            saveToFirebase(userEmail: userEmail, voice: voice)
        } else {
            // Save to UserDefaults
            saveToUserDefaults(voice: voice)
        }
    }
    
    // MARK: - Firebase Operations
    private func loadFromFirebase(userEmail: String) {
        print("🔄 Loading voice preference from Firebase for: \(userEmail)")

        db.collection("users").document(userEmail).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error loading voice preference from Firebase: \(error.localizedDescription)")
                // Fallback to UserDefaults
                self.loadFromUserDefaults()
                return
            }

            guard let data = snapshot?.data() else {
                print("⚠️ No Firebase data found for user, using default")
                self.loadFromUserDefaults()
                return
            }

            // Try new field first, then fall back to old field
            let voiceRawValue = data["voicePreference"] as? String ?? data["selectedVoice"] as? String

            if let voiceRawValue = voiceRawValue,
               let voice = GeminiVoice(rawValue: voiceRawValue) {
                print("✅ Loaded voice preference from Firebase: \(voice.displayName)")
                DispatchQueue.main.async {
                    self.selectedVoice = voice
                }
            } else {
                print("⚠️ No valid voice preference in Firebase, using default or UserDefaults")
                // Try UserDefaults as fallback
                self.loadFromUserDefaults()
            }
        }
    }
    
    private func saveToFirebase(userEmail: String, voice: GeminiVoice) {
        print("🔄 Attempting to save voice preference to Firebase...")
        print("   User: \(userEmail)")
        print("   Voice: \(voice.rawValue)")

        let data: [String: Any] = [
            "voicePreference": voice.rawValue,
            "voicePreferenceUpdatedAt": Date().timeIntervalSince1970
        ]

        db.collection("users").document(userEmail).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Error saving voice preference to Firebase: \(error.localizedDescription)")
                print("   Error code: \((error as NSError).code)")
                print("   Full error: \(error)")

                // Fallback to UserDefaults
                self.saveToUserDefaults(voice: voice)
            } else {
                print("✅ Voice preference saved to Firebase successfully!")
                print("   Confirmed: \(voice.displayName)")

                // Also save to UserDefaults as backup
                self.saveToUserDefaults(voice: voice)
            }
        }
    }
    
    // MARK: - UserDefaults Operations
    private func loadFromUserDefaults() {
        if let savedVoiceRawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
           let voice = GeminiVoice(rawValue: savedVoiceRawValue) {
            print("✅ Loaded voice from UserDefaults: \(voice.displayName)")
            selectedVoice = voice
        } else {
            print("⚠️ No voice in UserDefaults, using default: Puck")
            selectedVoice = .puck
        }
    }

    private func saveToUserDefaults(voice: GeminiVoice) {
        UserDefaults.standard.set(voice.rawValue, forKey: userDefaultsKey)
        print("✅ Voice preference saved to UserDefaults: \(voice.displayName)")

        // Verify it was saved
        if let verified = UserDefaults.standard.string(forKey: userDefaultsKey) {
            print("   Verified in UserDefaults: \(verified)")
        }
    }
}

// MARK: - Gemini Voice Options
enum GeminiVoice: String, CaseIterable, Identifiable {
    case puck = "Puck"
    case charon = "Charon"
    case kore = "Kore"
    case fenrir = "Fenrir"
    case aoede = "Aoede"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var description: String {
        switch self {
        case .puck:
            return "Friendly and approachable"
        case .charon:
            return "Deep and authoritative"
        case .kore:
            return "Warm and expressive"
        case .fenrir:
            return "Clear and professional"
        case .aoede:
            return "Melodic and engaging"
        }
    }
    
    var icon: String {
        switch self {
        case .puck:
            return "sparkles"
        case .charon:
            return "moon.stars"
        case .kore:
            return "sun.max"
        case .fenrir:
            return "bolt"
        case .aoede:
            return "music.note"
        }
    }
}
