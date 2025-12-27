//
//  GoogleLiveService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import Foundation
import Combine
import AVFoundation
import Speech
import UIKit
internal import EventKit

/// A native implementation of the Gemini Multimodal Live API.
/// Replaces the Pipecat client to fix audio render errors by using standard AVAudioEngine + URLSession.
class GoogleLiveService: NSObject, ObservableObject {
    static let shared = GoogleLiveService()
    
    // MARK: - Configuration
    private let apiKey = "AIzaSyCUEUdefmjWqwijogDQpwUc7fr3NqEXAsM" // Hardcoded for prototype
    // Gemini Live API model - MUST use a multimodal live audio model
    private let modelName = "models/gemini-2.5-flash-native-audio-preview-12-2025"
    private let host = "generativelanguage.googleapis.com"
    private let path = "/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent" 
    
    // MARK: - State
    @Published var isConnected = false
    @Published var isListening = false
    @Published var isConnecting = false
    @Published var errorMessage: String?
    @Published var didReceiveSetupAck = false
    @Published var isAISpeaking = false
    @Published var isThinking = false
    @Published var isWaitingForFirstResponse = false
    
    // Voice Chat State
    @Published var userTranscript = ""
    @Published var aiResponseText = ""
    @Published var isUserSpeaking = false // Derived from speech activity
    @Published var audioLevel: Float = 0.0
    @Published var pendingMapData: MapData? // To be picked up by the UI
    
    // MARK: - Components
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var audioPlayerNode = AVAudioPlayerNode()
    
    // Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    
    // AI Speech Recognition (Client-Side Transcription)
    private let aiSpeechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var aiRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var aiRecognitionTask: SFSpeechRecognitionTask?
    
    // Dedicated queue for audio processing to avoid blocking main thread
    private let audioQueue = DispatchQueue(label: "com.eclipse.audio", qos: .userInteractive)
    
    // Task to track connection lifecycle
    private var connectionTask: Task<Void, Never>?
    private var keepAliveTask: Task<Void, Never>?
    
    // Audio Playback Tracking
    private var serverTurnFinished = false
    private var pendingAudioBuffers = 0
    private let bufferLock = NSLock()
    
    private override init() {
        super.init()
        // setupAudioSession() // Removed to prevent blocking app launch/previews
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public API
    
    func connect() {
        guard !isConnected && !isConnecting else { return }
        
        isConnecting = true
        
        // Cancel any existing connection task
        connectionTask?.cancel()
        
        // Clean up any existing WebSocket
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        errorMessage = nil
        print("🚀 [Native] Connecting to Gemini Live API...")
        
        // 1. Build Authenticated URL
        var components = URLComponents()
        components.scheme = "wss"
        components.host = host
        components.path = path
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = components.url else {
            handleError("Invalid URL configuration")
            return
        }
        
        print("🔗 [Native] Connecting to: \(url.absoluteString.replacingOccurrences(of: apiKey, with: "***"))")
        
        // 2. Create WebSocket with proper session
        guard let session = urlSession else {
            handleError("URL Session not initialized")
            return
        }
        
        webSocketTask = session.webSocketTask(with: url)
        
        // Set up keep-alive pings every 30 seconds
        webSocketTask?.resume()
        
        // 3. Don't mark as connected until we receive the delegate callback
        // Start listening immediately after resume
        receiveMessage()
        
        // 4. Send setup message - the delegate will confirm connection opened
        // Wait a brief moment for WebSocket handshake to complete
        connectionTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Check if connection is actually running
            guard let task = self.webSocketTask, task.state == .running else {
                await MainActor.run {
                    self.handleError("WebSocket failed to establish connection - state: \(self.webSocketTask?.state.rawValue ?? -1)")
                }
                return
            }
            
        print("✅ [Native] WebSocket running, sending setup...")
            
            // Fetch events on main actor before sending setup
            await MainActor.run {
                self.isConnected = true
                self.isConnecting = false
            }
            
            let events = await MainActor.run {
                return CalendarManager.shared.getUpcomingEvents(days: 7)
            }
            
            self.sendSetupMessage(with: events)
            
            // Start keep-alive pings
            self.startKeepAlive()
        }
    }
    
    private func startKeepAlive() {
        keepAliveTask?.cancel()
        keepAliveTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                guard let task = self.webSocketTask, task.state == .running else {
                    print("⚠️ [Native] Keep-alive: WebSocket not running, stopping pings")
                    break
                }
                
                // Send a ping to keep connection alive
                task.sendPing { error in
                    if let error = error {
                        print("⚠️ [Native] Keep-alive ping failed: \(error.localizedDescription)")
                    } else {
                        print("🏓 [Native] Keep-alive ping sent")
                    }
                }
            }
        }
    }
    
    func disconnect(reason: String = "User Request") {
        print("🔌 [Native] Disconnecting (Reason: \(reason))...")
        
        // Cancel connection task if still running
        connectionTask?.cancel()
        connectionTask = nil
        
        // Cancel keep-alive task
        keepAliveTask?.cancel()
        keepAliveTask = nil
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        stopAudio()
        
        Task { @MainActor [weak self] in
            self?.isConnected = false
            self?.isConnecting = false
            self?.isListening = false
            self?.didReceiveSetupAck = false
            self?.isAISpeaking = false
            self?.isWaitingForFirstResponse = false
            self?.userTranscript = ""
            self?.aiResponseText = ""
            self?.isThinking = false
        }
    }
    
    func toggleSession() {
        if isConnected || isConnecting {
            disconnect(reason: "User Toggled Off")
        } else {
            connect()
        }
    }
    
    // MARK: - WebSocket Logic
    
    private func sendSetupMessage(with events: [EKEvent] = []) {
        // Gemini Live API setup configuration
        // Based on: https://ai.google.dev/api/multimodal-live
        // The API infers audio format from the MIME type sent with each audio chunk
        
        var systemText = "You are Eclipse. Your text output must match your audio response exactly."
        
        // Capabilities Instruction - Updated to match chat AI format
        systemText += """
        
        [CAPABILITIES]
        1. CALENDAR EVENT CREATION:
           When the user asks you to create, schedule, or add a calendar event, you MUST include this exact format in your response:
           CALENDAR_EVENT: [event title] | [date and time description]
           
           Examples:
           - User: "Schedule a meeting tomorrow at 2pm"
             Your response should include: CALENDAR_EVENT: Meeting | tomorrow at 2pm
           
           - User: "Remind me to call mom on Friday at 3:30pm"
             Your response should include: CALENDAR_EVENT: Call mom | Friday at 3:30pm
           
           - User: "Add dentist appointment next Monday at 10am"
             Your response should include: CALENDAR_EVENT: Dentist appointment | next Monday at 10am
           
           IMPORTANT: Always include this marker when creating events. The system will automatically create the calendar event.
           After including the marker, verbally confirm: "I've added that to your calendar."

        2. MAPS & LOCATIONS:
           When providing location information from search results, you can show an interactive map by including:
           MAP_LOCATION: [latitude, longitude, "Name", "Address"]
           Use the coordinates provided in the MAP_DATA fields of the search results.

        3. PREMIUM DESIGN AESTHETICS:
           Smartly integrate these enhancements naturally into your responses to ensure a premium, visual, and beautiful experience:
           - ICONS: Use [icon:icon-name] for headers, list items, or emphasis (e.g., [icon:sparkles], [icon:brain], [icon:cpu]).
           - PROGRESS: Use [progress:VALUE:LABEL] ONLY for tasks, difficulty, or clear stats (e.g., [progress:85:Analysis]).
           - MERMAID: Use ```mermaid blocks for diagrams (labels in quotes, no newlines).
        """
        
        // Inject Calendar Context
        if !events.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMM d, h:mm a"
            
            let eventStrings = events.map { event in
                "• \(event.title ?? "Event") at \(dateFormatter.string(from: event.startDate))"
            }
            
            let calendarContext = "\n\n[USER'S UPCOMING SCHEDULE]\n" + eventStrings.joined(separator: "\n")
            systemText += calendarContext
            systemText += "\n\nIf the user asks about their schedule, use the above information. If there are no events in the list for a specific query, say so comfortably."
        } else {
            // Optional: You could mention there are no upcoming events found if you want
             if CalendarManager.shared.permissionStatus == .authorized || CalendarManager.shared.permissionStatus == .fullAccess {
                 systemText += "\n\n[USER'S UPCOMING SCHEDULE]\nNo upcoming events found for the next 7 days."
             }
        }
        
        // Add current date context
        let todayFormatter = DateFormatter()
        todayFormatter.dateStyle = .full
        todayFormatter.timeStyle = .short
        systemText += "\n\nCurrent Date: \(todayFormatter.string(from: Date()))"

        systemText += """
        
        [BEHAVIOR: BREVITY]
        - BE CONCISE. Avoid rambling. This is a voice interface; short responses are better.
        - Do not use conversational filler (e.g., "I'd be happy to help", "Certainly").
        - Get straight to the point. If a question has a 5-word answer, give a 5-word answer.
        """

        // Get selected voice from preferences
        let voicePreference = VoicePreferencesManager.shared.selectedVoice
        let selectedVoice = voicePreference.rawValue

        print("🎤 [Setup] Configuring Gemini Live with voice: \(voicePreference.displayName) (\(selectedVoice))")

        let setupJSON: [String: Any] = [
            "setup": [
                "model": modelName,
                "generationConfig": [
                    "responseModalities": ["AUDIO"],
                    "maxOutputTokens": 500, // Limit voice responses to prevent rambling
                    "speechConfig": [
                        "voiceConfig": [
                            "prebuiltVoiceConfig": [
                                "voiceName": selectedVoice
                            ]
                        ]
                    ]
                ],
                "system_instruction": [
                    "parts": [
                        ["text": systemText]
                    ]
                ]
            ]
        ]
        
        print("📤 [Native] Sending setup with calendar context: \(events.count) events")
        send(json: setupJSON, allowBeforeSetupAck: true)
    }
    
    private func send(json: [String: Any], allowBeforeSetupAck: Bool = false) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else { 
            print("⚠️ [Native] Failed to serialize JSON")
            return 
        }
        
        // Only allow setup before ack; drop other messages until setupComplete
        if !allowBeforeSetupAck && !didReceiveSetupAck {
            if json["setup"] == nil {
                // Not a setup message and setup not acknowledged yet
                print("⚠️ [Native] Dropping message - setup not complete")
                return
            }
        }
        
        // Check connection state before sending
        guard let task = webSocketTask else {
            print("⚠️ [Native] Cannot send - WebSocket task is nil")
            return
        }
        
        // Check the actual state
        let state = task.state
        guard state == .running else {
            print("⚠️ [Native] Cannot send - WebSocket state: \(state.rawValue) (0=running, 1=suspended, 2=canceling, 3=completed)")
            if state == .completed {
                disconnect(reason: "WebSocket completed unexpectedly")
            }
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        task.send(message) { [weak self] error in
            if let error = error {
                let nsError = error as NSError
                print("❌ [Native] Send Error: \(error.localizedDescription)")
                print("   Error Code: \(nsError.code), Domain: \(nsError.domain)")
                
                // Error Code 57 = Socket is not connected
                // Error Code 54 = Connection reset by peer
                if nsError.code == 57 {
                    print("⚠️ [Native] Error 57: Socket is not connected - likely WebSocket closed before send completed")
                    self?.disconnect(reason: "Socket Not Connected (Error 57)")
                } else if nsError.code == 54 {
                    print("⚠️ [Native] Error 54: Connection reset by peer")
                    self?.disconnect(reason: "Connection Reset (Error 54)")
                } else {
                    self?.handleError("Send failed: \(error.localizedDescription)")
                }
            } else {
                // Successful send - only log for non-audio messages to reduce spam
                if json["realtimeInput"] == nil {
                    print("✅ [Native] Message sent successfully")
                }
            }
        }
    }
    
    private func receiveMessage() {
        guard let task = webSocketTask, task.state == .running else {
            print("⚠️ [Native] Cannot receive - WebSocket not running")
            return
        }
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handle(message: message)
                if self.isConnected && self.webSocketTask?.state == .running {
                    self.receiveMessage() // Continue loop
                }
            case .failure(let error):
                // If we executed disconnect(), webSocketTask might be nil or we are not connected
                // In that case, this error is expected (task cancelled).
                if self.webSocketTask == nil || !self.isConnected {
                     print("ℹ️ [Native] Receive loop ended (disconnected).")
                     return
                }
                
                let nsError = error as NSError
                print("❌ [Native] Receive Error: \(error.localizedDescription) (Code: \(nsError.code), Domain: \(nsError.domain))")
                
                // Provide more specific error information
                if nsError.code == 57 {
                    print("⚠️ [Native] Error 57: Socket is not connected")
                } else if nsError.code == 54 {
                    print("⚠️ [Native] Error 54: Connection reset by peer")
                }
                
                self.disconnect(reason: "Receive Error") // Auto disconnect on socket error
                self.handleError("Connection lost: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleSetupComplete(source: String) {
        print("✅ [Native] Setup complete (\(source)), starting audio capture")
        
        Task { @MainActor [weak self] in
            self?.didReceiveSetupAck = true
            self?.isListening = true
            self?.isWaitingForFirstResponse = true
            
            // Visually reflect the initial greeting in the UI
            // This triggers ContentView to type "Hello" and "send" it
            self?.userTranscript = "Hello"
            self?.isUserSpeaking = true
            
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s delay
            self?.isUserSpeaking = false
        }
        
        // Send an initial "Hello" to force the model to speak first
        let initialMsg: [String: Any] = [
            "clientContent": [
                "turns": [
                    [
                        "role": "user",
                        "parts": [["text": "Hello"]]
                    ]
                ],
                "turnComplete": true
            ]
        ]
        print("👋 [Native] Sending initial greeting...")
        self.send(json: initialMsg, allowBeforeSetupAck: true)
        
        startAudio()
    }
    
    private func handle(message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            handle(json: json)
            
        case .data(let data):
            // Gemini sometimes sends JSON as binary-encoded text
            if let text = String(data: data, encoding: .utf8) {
                // Try to parse the binary text as JSON
                if let jsonData = text.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    handle(json: json)
                } else {
                    print("⚠️ [Native] Received Binary-Encoded Text that isn't JSON: \(text)")
                }
            } else {
                print("⚠️ [Native] Received unexpected binary data: \(data.count) bytes")
            }
            
        @unknown default:
            break
        }
    }
    
    private func handle(json: [String: Any]) {
        // Detect setupComplete acknowledgement
        if json["setupComplete"] != nil {
            handleSetupComplete(source: "json")
            return
        }
        
        // Handle Server Content (Audio)
        if let serverContent = json["serverContent"] as? [String: Any],
           let modelTurn = serverContent["modelTurn"] as? [String: Any],
           let parts = modelTurn["parts"] as? [[String: Any]] {
            
            for part in parts {
                if let inlineData = part["inlineData"] as? [String: Any],
                   let base64String = inlineData["data"] as? String,
                   let audioData = Data(base64Encoded: base64String) {
                    
                    // Play received audio
                    print("🔊 [Native] Received audio chunk: \(audioData.count) bytes")
                    
                    Task { @MainActor [weak self] in
                        self?.isWaitingForFirstResponse = false
                        self?.isThinking = false
                        self?.isAISpeaking = true
                        self?.serverTurnFinished = false
                    }
                    
                    self.playAudio(data: audioData)
                }
                
                // Extract Text Content (if available) for Voice Chat UI
                if let rawText = part["text"] as? String {
                     // Check for MAP_LOCATION command
                     let mapPattern = #"MAP_LOCATION:\s*\[\s*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*,\s*"([^"]+)"\s*(?:,\s*"([^"]*)")?\s*\]"#
                     if let regex = try? NSRegularExpression(pattern: mapPattern, options: []) {
                         let nsString = rawText as NSString
                         let match = regex.firstMatch(in: rawText, options: [], range: NSRange(location: 0, length: nsString.length))
                         
                         if let match = match {
                             let latString = nsString.substring(with: match.range(at: 1))
                             let lngString = nsString.substring(with: match.range(at: 2))
                             let title = nsString.substring(with: match.range(at: 3))
                             var subtitle: String? = nil
                             if match.numberOfRanges > 4 && match.range(at: 4).location != NSNotFound {
                                 subtitle = nsString.substring(with: match.range(at: 4))
                             }
                             
                             let lat = Double(latString) ?? 0.0
                             let lng = Double(lngString) ?? 0.0
                             
                             let mapData = MapData(latitude: lat, longitude: lng, title: title, subtitle: subtitle)
                             print("🗺️ [Native] AI Requesting Map: \(title) at \(lat), \(lng)")
                             
                             Task { @MainActor [weak self] in
                                 self?.pendingMapData = mapData
                             }
                             
                             // Clean text for display/speech
                             let displayableText = regex.stringByReplacingMatches(in: rawText, options: [], range: NSRange(location: 0, length: nsString.length), withTemplate: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines)
                             
                             if !displayableText.isEmpty {
                                 Task { @MainActor [weak self] in
                                      if self?.aiResponseText.isEmpty == true {
                                          self?.aiResponseText = displayableText
                                      } else {
                                          self?.aiResponseText += displayableText
                                      }
                                 }
                             }
                             continue
                         }
                     }

                     // Check for CALENDAR_EVENT command (matching chat AI format)
                     let pattern = #"CALENDAR_EVENT:\s*(.+?)\s*\|\s*(.+?)(?:\n|$)"#
                     if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                         let nsString = rawText as NSString
                         let matches = regex.matches(in: rawText, options: [], range: NSRange(location: 0, length: nsString.length))
                         
                         for match in matches {
                             if match.numberOfRanges == 3 {
                                 let titleRange = match.range(at: 1)
                                 let dateRange = match.range(at: 2)
                                 
                                 let title = nsString.substring(with: titleRange).trimmingCharacters(in: .whitespacesAndNewlines)
                                 let dateString = nsString.substring(with: dateRange).trimmingCharacters(in: .whitespacesAndNewlines)
                                 
                                 print("📅 [Native] AI Requesting Event: \(title) at \(dateString)")
                                 
                                 // Parse date and create event
                                 Task {
                                     if let date = CalendarManager.shared.parseDateTime(from: dateString) {
                                         let success = await CalendarManager.shared.addEvent(title: title, date: date, notes: "Created by Eclipse AI")
                                         if success {
                                             print("✅ [Native] Event created successfully by AI")
                                         }
                                     } else {
                                         print("⚠️ [Native] Could not parse date: \(dateString)")
                                     }
                                 }
                             }
                         }
                         
                         // Clean the text for display (remove the command)
                         if matches.count > 0 {
                             let displayableText = regex.stringByReplacingMatches(in: rawText, options: [], range: NSRange(location: 0, length: nsString.length), withTemplate: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines)
                             
                             if !displayableText.isEmpty {
                                 Task { @MainActor [weak self] in
                                      if self?.aiResponseText.isEmpty == true {
                                          self?.aiResponseText = displayableText
                                      } else {
                                          self?.aiResponseText += displayableText
                                      }
                                 }
                             }
                             continue // Skip normal processing for this part
                         }
                     }
                     
                     // Clean text instead of ignoring it
                     // Models sometimes mix thoughts and speech: "**Thought** Speech"
                     var cleanedText = rawText
                     
                     // Remove bolded thought blocks (e.g., **Title**)
                     // Simple approach: Remove textual content between ** and **
                     // Note: This matches "**...**"
                     if let regex = try? NSRegularExpression(pattern: "\\*\\*.*?\\*\\*", options: []) {
                         let range = NSRange(location: 0, length: cleanedText.utf16.count)
                         cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
                     }
                     
                     // Remove residual lines or markers if needed
                     cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                     
                     if cleanedText.isEmpty {
                         print("🧠 [Native] Filtered out internal thought: \(rawText.prefix(20))...")
                         continue
                     }
                     
                     Task { @MainActor [weak self] in
                         // If empty, just set it.
                         if self?.aiResponseText.isEmpty == true {
                             self?.aiResponseText = cleanedText
                         } else {
                             self?.aiResponseText += cleanedText
                         }
                     }
                }
            }
        }
        
        // Handle turn complete
        if let serverContent = json["serverContent"] as? [String: Any],
           serverContent["turnComplete"] != nil {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.serverTurnFinished = true
                
                // Only mark as finished speaking if audio playback caught up
                self.bufferLock.lock()
                let pending = self.pendingAudioBuffers
                self.bufferLock.unlock()
                
                if pending == 0 {
                    self.isAISpeaking = false
                }
            }
        }
    }

    
    private func handleError(_ message: String) {
        Task { @MainActor [weak self] in
            self?.errorMessage = message
        }
    }
    
    // MARK: - Audio Engine (The Fix)
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // CRITICAL FIX: Use .default mode to DISABLE Voice Processing I/O (VPIO).
            // This prevents the "render err: -1" crash on specific hardware/configs.
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
            
            // Try to set to 16kHz as preferred, but be ready to handle others
            try audioSession.setPreferredSampleRate(16000.0)
            try audioSession.setPreferredIOBufferDuration(0.01)
            
            try audioSession.setActive(true)
            print("✅ [Native] AVAudioSession Configured (Default Mode)")
        } catch {
            print("❌ [Native] Audio Session Error: \(error)")
        }
        
        // Re-create engine if needed
        if audioEngine.isRunning { audioEngine.stop() }
        
        inputNode = audioEngine.inputNode
        audioEngine.attach(audioPlayerNode)
        
        // Define the expected format from Gemini (24kHz Mono)
        // Connect the player using this format so the mixer handles upmixing to stereo/output
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true)
        audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)
    }
    
    private func startAudio() {
        setupAudioSession() // Ensure session is active
        
        do {
            try audioEngine.start()
            print("✅ [Native] Audio Engine Started")
        } catch {
            print("❌ [Native] Engine Start Error: \(error)")
            handleError("Audio Initializtion Failed")
            return
        }
        
        // Initialize Speech Recognition
        // Initialize Speech Recognition (User)
        startRecognition()
        
        // Initialize Speech Recognition (AI) - Disabled in favor of server text
        // startAIRecognition()
        
        // Install Output Tap (for AI audio visualization + Transcription)
        audioPlayerNode.removeTap(onBus: 0)
        audioPlayerNode.installTap(onBus: 0, bufferSize: 1024, format: audioPlayerNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            guard let self = self, self.isAISpeaking else { return }
            self.calculateRMS(buffer: buffer)
            
            // Append to AI Transcriber - Disabled
            // self.aiRecognitionRequest?.append(buffer)
        }
        
        // Install Tap to capture mic input
        guard let inputNode = inputNode else { return }
        let format = inputNode.inputFormat(forBus: 0) // Use native hardware format
        
        inputNode.removeTap(onBus: 0) // Safety removal
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] (buffer, time) in
            guard let self = self else { return }
            // CRITICAL FIX: Gate audio input to prevent Echo/Self-Interruption
            // Only send audio to API if AI is NOT speaking
            if !self.isAISpeaking {
                self.processInputAudio(buffer: buffer)
                self.calculateRMS(buffer: buffer)
                self.recognitionRequest?.append(buffer)
            }
        }
    }
    
    private func startRecognition() {
        // Cancel existing task if any
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep recognition running even if user pauses briefly
        // We will manually manage "turns" in the UI based on silence/interaction
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor in
                    self.userTranscript = result.bestTranscription.formattedString
                    self.isUserSpeaking = true
                    self.isThinking = false
                    self.aiResponseText = "" // Clear previous AI response when user starts new turn
                    self.resetSilenceTimer()
                }
            }
            
            if let error = error {
                print("🎤 [Speech] Recognition error: \(error.localizedDescription)")
                self.stopRecognition()
            }
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isUserSpeaking {
                    print("🎤 [Speech] Silence detected - User finished speaking")
                    self.isUserSpeaking = false
                    self.isThinking = true // Trigger thinking state
                }
            }
        }
    }
    
    private func stopRecognition() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
    }
    
    private func stopAudio() {
        inputNode?.removeTap(onBus: 0)
        audioPlayerNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioPlayerNode.stop()
        stopRecognition()
        stopAIRecognition()
    }
    
    private func startAIRecognition() {
        // Cancel existing task if any
        aiRecognitionTask?.cancel()
        aiRecognitionTask = nil
        
        aiRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let aiRecognitionRequest = aiRecognitionRequest else { return }
        aiRecognitionRequest.shouldReportPartialResults = true
        
        // Use the AI speech recognizer
        aiRecognitionTask = aiSpeechRecognizer?.recognitionTask(with: aiRecognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                Task { @MainActor in
                    // Only update if we are currently "speaking" or recently spoke
                    // This is the source of truth now
                    self.aiResponseText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("🎤 [AI Speech] Recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopAIRecognition() {
        aiRecognitionTask?.cancel()
        aiRecognitionTask = nil
        aiRecognitionRequest?.endAudio()
        aiRecognitionRequest = nil
    }
    
    // MARK: - Audio Processing
    
    private var hasLoggedInputFormat = false
    
    // ...
    
    private func processInputAudio(buffer: AVAudioPCMBuffer) {
        let sampleRate = Int(buffer.format.sampleRate)
        
        // 1. Log format & amplitude once or periodically
        if !hasLoggedInputFormat {
            print("🎤 [Native] Input Format: \(sampleRate)Hz, \(buffer.format.channelCount) ch")
            hasLoggedInputFormat = true
        }
        
        // 2. Simple RMS calculation to check for silence
        if let channelData = buffer.floatChannelData {
           // Check first channel only for efficiency
           let channelPointer = channelData[0]
           let frameLength = Int(buffer.frameLength)
           var sum: Float = 0
           for i in 0..<frameLength {
               let sample = channelPointer[i]
               sum += sample * sample
           }
           let rms = sqrt(sum / Float(frameLength))
           let db = 20 * log10(rms)
           
           // Log only if it's "loud" enough or periodically to show it's working
           // -160dB is silence. -20dB is conversational.
           if frameLength > 0 && rms > 0.01 { // threshold
               // print("🎤 [Native] Audio Level: \(String(format: "%.2f", db)) dB") // Uncomment to see constant volume logs
           } else if rms == 0 {
                // print("🎤 [Native] Silence detected (0.0)")
           }
        }

        // 3. Send to WebSocket
        let audioData = self.toData(buffer: buffer)
        
        // Send to WebSocket
        let msg: [String: Any] = [
            "realtimeInput": [
                "mediaChunks": [
                    [
                        "mimeType": "audio/pcm;rate=\(sampleRate)",
                        "data": audioData.base64EncodedString()
                    ]
                ]
            ]
        ]
        
        // Throttle sending or just send (WebSocket is fast)
        self.send(json: msg) 
    }
    
    // MARK: - Video Input
    
    // Throttle video frames to ~2 FPS to avoid flooding the socket
    private var lastFrameTime: Date = Date.distantPast
    
    func sendVideoFrame(image: UIImage) {
        let now = Date()
        guard now.timeIntervalSince(lastFrameTime) > 0.5 else { return } // 500ms throttle
        lastFrameTime = now
        
        // Resize to something manageable (e.g. 512px max dimension)
        guard let resizedImage = image.resized(toMaxDimension: 512),
              let jpegData = resizedImage.jpegData(compressionQuality: 0.5) else { return }
        
        let base64String = jpegData.base64EncodedString()
        
        let msg: [String: Any] = [
            "realtimeInput": [
                "mediaChunks": [
                    [
                        "mimeType": "image/jpeg",
                        "data": base64String
                    ]
                ]
            ]
        ]
        
        // Send asynchronously
        Task {
            self.send(json: msg)
        }
        // print("📷 [Native] Sent video frame: \(jpegData.count) bytes")
    }
    

    
    private func calculateRMS(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelPointer = channelData[0]
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelPointer[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // Normalize (RMS is usually very small, e.g. 0.0 to 0.5)
        // Boost it for UI visibility
        let boostedLevel = min(rms * 5.0, 1.0)
        
        Task { @MainActor in
            self.audioLevel = boostedLevel
        }
    }
    
    private func playAudio(data: Data) {
        // Convert Data -> PCM Buffer
        // Assuming Gemini sends 24kHz PCM 16-bit Mono (standard)
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true)!
        
        guard let buffer = toPCMBuffer(data: data, format: format) else {
            return
        }
        
        bufferLock.lock()
        pendingAudioBuffers += 1
        bufferLock.unlock()
        
        audioPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            guard let self = self else { return }
            self.bufferLock.lock()
            self.pendingAudioBuffers -= 1
            let pending = self.pendingAudioBuffers
            self.bufferLock.unlock()
            
            if pending == 0 && self.serverTurnFinished {
                Task { @MainActor in
                    self.isAISpeaking = false
                }
            }
        })
        if !audioPlayerNode.isPlaying { audioPlayerNode.play() }
    }
    
    // MARK: - Helpers
    
    private func toData(buffer: AVAudioPCMBuffer) -> Data {
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        // Check if we need conversion from Float -> Int16
        if buffer.format.commonFormat == .pcmFormatFloat32 {
            // Allocate a new buffer for Int16 samples
            let dataSize = frameLength * channelCount * MemoryLayout<Int16>.size
            var pcmData = Data(count: dataSize)
            
            pcmData.withUnsafeMutableBytes { body in
                guard let destPtr = body.bindMemory(to: Int16.self).baseAddress else { return }
                
                if let floatChannelData = buffer.floatChannelData {
                    for i in 0..<frameLength {
                        for channel in 0..<channelCount {
                            let floatSample = floatChannelData[channel][i]
                            // Convert Float (-1.0 to 1.0) to Int16
                            // Clamp to prevent overflow
                            var intSample = Int16(max(min(floatSample, 1.0), -1.0) * 32767.0)
                            destPtr[i * channelCount + channel] = intSample
                        }
                    }
                }
            }
            return pcmData
        } else if buffer.format.commonFormat == .pcmFormatInt16 {
             // Already Int16, just copy
            if let int16ChannelData = buffer.int16ChannelData {
                let dataSize = frameLength * channelCount * MemoryLayout<Int16>.size
                return Data(bytes: int16ChannelData[0], count: dataSize)
            }
        }
        
        return Data()
    }
    
    private func toPCMBuffer(data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame) else { return nil }
        
        buffer.frameLength = buffer.frameCapacity
        let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: Int(format.channelCount))
        // Rebind Int16 pointer to UInt8 to copy bytes safely
        channels[0].withMemoryRebound(to: UInt8.self, capacity: data.count) { bytePtr in
            data.copyBytes(to: bytePtr, count: data.count)
        }
        return buffer
    }
}

// MARK: - URLSessionWebSocketDelegate
extension GoogleLiveService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol proto: String?) {
        print("✅ [Native] WebSocket Opened Successfully")
        print("   Protocol: \(proto ?? "none")")
        print("   State: \(webSocketTask.state.rawValue)")
        
        Task { @MainActor [weak self] in
            self?.isConnected = true
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason provided"
        print("🔌 [Native] WebSocket Closed")
        print("   Close Code: \(closeCode.rawValue)")
        print("   Reason: \(reasonString)")
        
        Task { @MainActor [weak self] in
            self?.isConnected = false
            self?.isListening = false
            self?.didReceiveSetupAck = false
            
            // Set error message if unexpected closure
            if closeCode != .normalClosure && closeCode != .goingAway {
                self?.errorMessage = "Connection closed unexpectedly: \(reasonString)"
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            print("❌ [Native] URLSession Task Error")
            print("   Error: \(error.localizedDescription)")
            print("   Code: \(nsError.code), Domain: \(nsError.domain)")
            
            Task { @MainActor [weak self] in
                self?.handleError("Connection error: \(error.localizedDescription)")
            }
            self.disconnect(reason: "Task completed with error")
        }
    }
}

