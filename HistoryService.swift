//
//  HistoryService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

struct ChatSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    var title: String
    var preview: String
    var messages: [Message]
    var pluginId: String? // Added for Eclipse Apps support
    
    // Convert to dictionary for Firestore
    var dictionary: [String: Any] {
        let messagesArray = messages.map { $0.dictionary }
        var dict: [String: Any] = [
            "id": id.uuidString,
            "date": Timestamp(date: date),
            "title": title,
            "preview": preview,
            "messages": messagesArray
        ]
        if let pluginId = pluginId {
            dict["pluginId"] = pluginId
        }
        return dict
    }
    
    // Init from Firestore document
    init?(dictionary: [String: Any]) {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = dictionary["date"] as? Timestamp,
              let title = dictionary["title"] as? String,
              let preview = dictionary["preview"] as? String,
              let messagesArray = dictionary["messages"] as? [[String: Any]] else {
            return nil
        }
        
        self.id = id
        self.date = timestamp.dateValue()
        self.title = title
        self.preview = preview
        self.messages = messagesArray.compactMap { Message(dictionary: $0) }
        self.pluginId = dictionary["pluginId"] as? String
    }
    
    // Manual init for app usage
    init(id: UUID, date: Date, title: String, preview: String, messages: [Message], pluginId: String? = nil) {
        self.id = id
        self.date = date
        self.title = title
        self.preview = preview
        self.messages = messages
        self.pluginId = pluginId
    }
}

// Extension to help with Message serialization
private extension Message {
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "text": text,
            "isUser": isUser,
            "timestamp": Timestamp(date: timestamp)
        ]
        
        // Serialize metadata using JSON as a fallback for complex types in Firestore
        if let playlist = playlist, let data = try? JSONEncoder().encode(playlist), 
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["playlist"] = json
        }
        
        if let mapData = mapData, let data = try? JSONEncoder().encode(mapData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["mapData"] = json
        }
        
        if let calendarEvent = calendarEvent, let data = try? JSONEncoder().encode(calendarEvent),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["calendarEvent"] = json
        }
        
        if let imageEditData = imageEditData, let data = try? JSONEncoder().encode(imageEditData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["imageEditData"] = json
        }
        
        if let canvaDesigns = canvaDesigns, let data = try? JSONEncoder().encode(canvaDesigns),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["canvaDesigns"] = json
        }
        
        if let weatherData = weatherData, let data = try? JSONEncoder().encode(weatherData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["weatherData"] = json
        }
        
        if let musicEmbeds = musicEmbeds, let data = try? JSONEncoder().encode(musicEmbeds),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            dict["musicEmbeds"] = json
        }
        
        if let healthData = healthData, let data = try? JSONEncoder().encode(healthData),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] { // Array of dicts
            dict["healthData"] = json
        }
        
        if let webImageUrls = webImageUrls {
            dict["webImageUrls"] = webImageUrls
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let text = dictionary["text"] as? String,
              let isUser = dictionary["isUser"] as? Bool,
              let timestamp = dictionary["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp.dateValue()
        self.images = nil
        
        // Deserialize metadata
        if let playlistDict = dictionary["playlist"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: playlistDict),
           let playlist = try? JSONDecoder().decode(PlaylistData.self, from: data) {
            self.playlist = playlist
        } else {
            self.playlist = nil
        }
        
        if let mapDict = dictionary["mapData"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: mapDict),
           let mapData = try? JSONDecoder().decode(MapData.self, from: data) {
            self.mapData = mapData
        } else {
            self.mapData = nil
        }
        
        if let calDict = dictionary["calendarEvent"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: calDict),
           let calendarEvent = try? JSONDecoder().decode(CalendarEventData.self, from: data) {
            self.calendarEvent = calendarEvent
        } else {
            self.calendarEvent = nil
        }
        
        if let editDict = dictionary["imageEditData"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: editDict),
           let imageEditData = try? JSONDecoder().decode(ImageEditData.self, from: data) {
            self.imageEditData = imageEditData
        } else {
            self.imageEditData = nil
        }
        
        if let canvaDict = dictionary["canvaDesigns"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: canvaDict),
           let canvaDesigns = try? JSONDecoder().decode([CanvaDesignData].self, from: data) {
            self.canvaDesigns = canvaDesigns
        } else {
            self.canvaDesigns = nil
        }
        
        if let weatherDict = dictionary["weatherData"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: weatherDict),
           let weatherData = try? JSONDecoder().decode(WeatherData.self, from: data) {
            self.weatherData = weatherData
        } else {
            self.weatherData = nil
        }
        
        if let musicDicts = dictionary["musicEmbeds"] as? [[String: Any]],
           let data = try? JSONSerialization.data(withJSONObject: musicDicts),
           let musicEmbeds = try? JSONDecoder().decode([MusicEmbedData].self, from: data) {
            self.musicEmbeds = musicEmbeds
        } else {
            self.musicEmbeds = nil
        }
        
        if let healthDicts = dictionary["healthData"] as? [[String: Any]], // Expect array of dicts
           let data = try? JSONSerialization.data(withJSONObject: healthDicts),
           let healthData = try? JSONDecoder().decode([HealthWidgetData].self, from: data) {
            self.healthData = healthData
        } else {
            self.healthData = nil
        }
        if let webUrls = dictionary["webImageUrls"] as? [String] {
            self.webImageUrls = webUrls
        } else {
            self.webImageUrls = nil
        }
    }
}

class HistoryService: ObservableObject {
    @Published var sessions: [ChatSession] = []
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        // Listen for auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.setupFirestoreListener(for: user.uid)
            } else {
                self?.stopFirestoreListener()
                self?.sessions = [] // Clear history on logout
            }
        }
    }
    
    // MARK: - Firestore Sync
    
    private func setupFirestoreListener(for userId: String) {
        listenerRegistration?.remove()

        let collectionRef = db.collection("users").document(userId).collection("chats")

        print("🔥 Setting up Firestore listener for user: \(userId)")

        // Listen to real-time updates
        listenerRegistration = collectionRef.order(by: "date", descending: true).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("❌ Firestore listener error: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No documents found in snapshot")
                return
            }

            print("📥 Received \(documents.count) chat session(s) from Firestore")

            let cloudSessions = documents.compactMap { doc -> ChatSession? in
                return ChatSession(dictionary: doc.data())
            }

            DispatchQueue.main.async {
                self.sessions = cloudSessions
                print("✓ Updated local sessions: \(cloudSessions.count) session(s)")
            }
        }
    }
    
    private func stopFirestoreListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    // MARK: - CRUD Operations
    
    func saveSession(id: UUID, title: String, preview: String, messages: [Message], pluginId: String? = nil) {
        // Prepare session object
        let session = ChatSession(id: id, date: Date(), title: title, preview: preview, messages: messages, pluginId: pluginId)

        if let user = Auth.auth().currentUser {
            // Cloud Save
            let docRef = db.collection("users").document(user.uid).collection("chats").document(id.uuidString)
            // Use merge to preserve the original creation date if it exists
            docRef.setData(session.dictionary, merge: false) { error in
                if let error = error {
                    print("Error saving session to cloud: \(error.localizedDescription)")
                } else {
                    print("✓ Session saved to cloud: \(title)")
                }
            }
        } else {
            // Ephemeral (In-Memory) Save for unauthenticated users
            if let index = sessions.firstIndex(where: { $0.id == id }) {
                sessions[index] = session
                // Re-sort locally
                let movedSession = sessions.remove(at: index)
                sessions.insert(movedSession, at: 0)
            } else {
                sessions.insert(session, at: 0)
            }
        }
    }
    
    func deleteSession(id: UUID) {
        if let user = Auth.auth().currentUser {
            // Cloud Delete
            db.collection("users").document(user.uid).collection("chats").document(id.uuidString).delete { error in
                if let error = error {
                    print("Error deleting session from cloud: \(error.localizedDescription)")
                }
            }
        } else {
            // Ephemeral Delete
            sessions.removeAll(where: { $0.id == id })
        }
    }
    
    func clearAll() {
        if let user = Auth.auth().currentUser {
            // Cloud Clear
            let collectionRef = db.collection("users").document(user.uid).collection("chats")
            collectionRef.getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else { return }
                
                let batch = self.db.batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit()
            }
        } else {
             // Ephemeral Clear
             sessions.removeAll()
        }
    }
}
