//
//  ArtifactsManager.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct Artifact: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
    let category: String // e.g., "personal", "preferences", "facts", etc.
    
    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), category: String = "personal") {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.category = category
    }
}

@MainActor
class ArtifactsManager: ObservableObject {
    static let shared = ArtifactsManager()
    
    @Published var artifacts: [Artifact] = []
    @Published var isLoading = false
    @Published var showArtifactSavedNotification = false
    @Published var lastSavedArtifact: Artifact?
    
    private let db = Firestore.firestore()
    
    private init() {
        loadArtifacts()
    }
    
    // MARK: - Load Artifacts
    
    func loadArtifacts() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No user logged in")
            return
        }
        
        isLoading = true
        
        db.collection("users")
            .document(userID)
            .collection("artifacts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error loading artifacts: \(error.localizedDescription)")
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    return
                }
                
                Task { @MainActor in
                    self.artifacts = documents.compactMap { doc -> Artifact? in
                        let data = doc.data()
                        guard let content = data["content"] as? String,
                              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                              let category = data["category"] as? String,
                              let idString = data["id"] as? String,
                              let id = UUID(uuidString: idString) else {
                            return nil
                        }
                        return Artifact(id: id, content: content, timestamp: timestamp, category: category)
                    }
                    self.isLoading = false
                    print("✅ Loaded \(self.artifacts.count) artifacts")
                }
            }
    }
    
    // MARK: - Save Artifact
    
    func saveArtifact(_ content: String, category: String = "personal") async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ArtifactsManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let artifact = Artifact(content: content, category: category)
        
        let artifactData: [String: Any] = [
            "id": artifact.id.uuidString,
            "content": artifact.content,
            "timestamp": Timestamp(date: artifact.timestamp),
            "category": artifact.category
        ]
        
        try await db.collection("users")
            .document(userID)
            .collection("artifacts")
            .document(artifact.id.uuidString)
            .setData(artifactData)
        
        // Update local state
        await MainActor.run {
            self.lastSavedArtifact = artifact
            self.showArtifactSavedNotification = true
            
            // Auto-hide notification after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    self.showArtifactSavedNotification = false
                }
            }
        }
        
        print("✅ Artifact saved: \(content)")
    }
    
    // MARK: - Delete Artifact
    
    func deleteArtifact(_ artifact: Artifact) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ArtifactsManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await db.collection("users")
            .document(userID)
            .collection("artifacts")
            .document(artifact.id.uuidString)
            .delete()
        
        print("✅ Artifact deleted: \(artifact.id)")
    }
    
    // MARK: - Get Artifacts Context for AI
    
    func getArtifactsContext() -> String {
        guard !artifacts.isEmpty else {
            return ""
        }
        
        var context = "\n\nUser Artifacts (Important Information About the User):\n"
        for artifact in artifacts.prefix(10) { // Limit to 10 most recent
            context += "- \(artifact.content)\n"
        }
        
        return context
    }
    
    // MARK: - AI Detection of Important Information
    
    func detectAndSaveImportantInfo(from message: String) async {
        // Keywords that indicate important personal information
        let importantKeywords = [
            "my name is", "i am", "i'm", "call me",
            "i like", "i love", "i prefer", "i enjoy",
            "my favorite", "i hate", "i don't like",
            "remember that", "remember this", "don't forget",
            "important:", "note:", "fyi:",
            "i live in", "i work at", "i study",
            "my birthday", "my phone", "my email"
        ]
        
        // Keywords that indicate questions or requests (not personal info to save)
        let questionKeywords = [
            "what", "why", "how", "when", "where", "who",
            "can you", "could you", "would you", "will you",
            "please", "help", "show me", "tell me",
            "explain", "describe", "is there", "are there",
            "do you", "does", "did"
        ]
        
        let lowercasedMessage = message.lowercased()
        
        // First check if this is a question or request - if so, don't save
        let isQuestion = questionKeywords.contains { keyword in
            lowercasedMessage.contains(keyword)
        }
        
        // Skip if it's a question (even if it contains important keywords)
        guard !isQuestion else {
            print("💬 [Artifacts] Skipped question/request: \(message.prefix(50))...")
            return
        }
        
        // Check if message contains any important keywords
        let containsImportantInfo = importantKeywords.contains { keyword in
            lowercasedMessage.contains(keyword)
        }
        
        if containsImportantInfo {
            // Try to save as artifact
            do {
                try await saveArtifact(message)
                print("✅ [Artifacts] Saved important info: \(message.prefix(50))...")
            } catch {
                print("❌ Error saving artifact: \(error.localizedDescription)")
            }
        }
    }
}
