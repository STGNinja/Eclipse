//
//  VoiceChatSheet.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/16/25.
//

import SwiftUI
import UIKit
import MapKit

struct VoiceChatSheet: View {
    @ObservedObject var liveService = GoogleLiveService.shared
    @ObservedObject var cameraManager = CameraManager.shared
    @Environment(\.dismiss) var dismiss
    var messages: [Message]

    // Track sessions
    @State private var sessionStartIndex: Int = 0
    @State private var sessionMessages: [Message] = []
    @State private var lastUserTranscript: String = ""
    @State private var lastAITranscript: String = ""
    @State private var isCameraMode: Bool = false

    // Visual enhancements

    @State private var blurIntensity: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0
    @State private var showConnectingAnimation = true
    @State private var showConnectionSuccess = false
    
    var body: some View {
        ZStack {
            // MARK: - Background
            if isCameraMode {
                CameraPreviewView()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.6))
                    .transition(.opacity)
                    // Don't blur camera - it loses focus
            } else {
                ReactiveGradientBackground(
                    audioLevel: liveService.audioLevel,
                    isAISpeaking: liveService.isAISpeaking,
                    isUserSpeaking: liveService.isUserSpeaking
                )
                .ignoresSafeArea()
                .blur(radius: blurIntensity)
            }


            
            // MARK: - Main Content
            VStack(spacing: 0) {
                // 1. Header (Top)
                HStack(spacing: 12) {
                    // Enhanced Status Indicator
                    EnhancedStatusIndicator(
                        isConnected: liveService.isConnected,
                        isAISpeaking: liveService.isAISpeaking,
                        isUserSpeaking: liveService.isUserSpeaking
                    )
                    
                    // Camera Button
                    Button {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCameraMode.toggle()
                        }
                        if isCameraMode { cameraManager.startSession() }
                        else { cameraManager.stopSession() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isCameraMode ? "video.fill" : "video")
                                .font(.system(size: 12, weight: .semibold))
                            Text(isCameraMode ? "Hide" : "Camera")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // 2. Transcript (Top - Big and Prominent)
                if !isCameraMode {
                    VoiceTranscriptView(
                        messages: sessionMessages,
                        liveService: liveService
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .black, location: 0.8),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    Spacer()
                }
                
                    // Controls Area
                    VStack(spacing: 30) {
                        // 1. Status Text
                        Text(statusText)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        // 2. Close Button (Bottom)
                        Button {
                            HapticManager.shared.impact(.medium)
                            liveService.disconnect()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 72, height: 72)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        
                        // 3. Reactive Waveform
                        SmoothWaveform(
                            audioLevel: liveService.audioLevel,
                            isAISpeaking: liveService.isAISpeaking,
                            isUserSpeaking: liveService.isUserSpeaking
                        )
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                        
                        Spacer().frame(height: 20)
                    }
                .padding(.bottom, 50)
            }

            // MARK: - Connection Animations
            if showConnectingAnimation && !liveService.isConnected {
                ConnectingAnimation()
            }

            if showConnectionSuccess {
                ConnectionAnimation {
                    showConnectionSuccess = false
                }
            }
        }
        .onAppear {
            sessionStartIndex = messages.count
            liveService.connect()
            HapticManager.shared.connectedSuccess()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    handleSwipeGesture(value)
                }
        )
        .onChange(of: liveService.isConnected) { oldValue, newValue in
            if newValue && !oldValue {
                // Hide connecting animation
                showConnectingAnimation = false

                // Show success animation
                showConnectionSuccess = true

                withAnimation(.easeOut(duration: 0.3)) {
                    glowIntensity = 1.0
                }
                HapticManager.shared.connectedSuccess()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        glowIntensity = 0
                    }
                }
            }
        }
        // Message Handling Logic
        .onChange(of: liveService.isUserSpeaking) { oldValue, newValue in
            // User started speaking
            if !oldValue && newValue {
                HapticManager.shared.userSpeakingAck()
                withAnimation(.easeIn(duration: 0.2)) {
                    blurIntensity = 2
                }
            }
            // User stopped speaking
            else if oldValue && !newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    blurIntensity = 0
                }

                if !liveService.userTranscript.isEmpty {
                    let isAutoHello = liveService.userTranscript.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "hello" && sessionMessages.isEmpty
                    if liveService.userTranscript != lastUserTranscript && !isAutoHello {
                        let userMessage = Message(text: liveService.userTranscript, isUser: true)
                        sessionMessages.append(userMessage)
                        lastUserTranscript = liveService.userTranscript
                    } else if isAutoHello {
                        lastUserTranscript = liveService.userTranscript
                    }
                }
            }
        }
        .onChange(of: liveService.isAISpeaking) { oldValue, newValue in
            // AI started speaking
            if !oldValue && newValue {
                HapticManager.shared.aiSpeakingPulse()
                withAnimation(.easeIn(duration: 0.2)) {
                    blurIntensity = 3
                }
            }
            // AI stopped speaking
            else if oldValue && !newValue {
                withAnimation(.easeOut(duration: 0.4)) {
                    blurIntensity = 0
                }

                if !liveService.aiResponseText.isEmpty {
                    let isInitialGreeting = sessionMessages.isEmpty && lastUserTranscript.lowercased() == "hello"
                    if liveService.aiResponseText != lastAITranscript && !isInitialGreeting {
                        let aiMessage = Message(
                            text: liveService.aiResponseText, 
                            isUser: false, 
                            mapData: liveService.pendingMapData
                        )
                        sessionMessages.append(aiMessage)
                        lastAITranscript = liveService.aiResponseText
                        
                        // Reset map data so it doesn't duplicate
                        liveService.pendingMapData = nil
                    } else if isInitialGreeting {
                        lastAITranscript = liveService.aiResponseText
                    }
                }
            }
        }
    }
    
    private var statusText: String {
        if !liveService.isConnected { return "Connecting..." }
        if liveService.isAISpeaking { return "Eclipse is speaking" }
        if liveService.isUserSpeaking { return "Listening..." }
        return "Ready and listening"
    }

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height

        // Swipe down to dismiss
        if abs(verticalAmount) > abs(horizontalAmount) {
            if verticalAmount > 0 {
                HapticManager.shared.impact(.medium)
                liveService.disconnect()
                dismiss()
            }
        }


    }
}

// MARK: - Reactive Gradient Background
struct ReactiveGradientBackground: View {
    var audioLevel: Float
    var isAISpeaking: Bool
    var isUserSpeaking: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in // Limited to 20fps for battery
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                // Base Dark Background
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.05, green: 0.05, blue: 0.08)))
                
                // Dynamic Blobs
                // 1. Primary Blob (Reacts to AI)
                let aiLevel = isAISpeaking ? Double(audioLevel) * 2.0 : 0.0
                let aiColor = Color.purple.opacity(0.4)
                drawBlob(
                    context: context,
                    center: CGPoint(x: size.width * 0.5 + sin(now) * 50, y: size.height * 0.4 + cos(now * 1.2) * 50),
                    baseRadius: size.width * 0.6,
                    expansion: aiLevel * 100,
                    color: aiColor,
                    blur: 120
                )
                
                // 2. Secondary Blob (Reacts to User)
                let userLevel = isUserSpeaking ? Double(audioLevel) * 2.5 : 0.0
                let userColor = Color.blue.opacity(0.3)
                drawBlob(
                    context: context,
                    center: CGPoint(x: size.width * 0.2 + cos(now * 0.8) * 60, y: size.height * 0.7 + sin(now) * 40),
                    baseRadius: size.width * 0.5,
                    expansion: userLevel * 100,
                    color: userColor,
                    blur: 100
                )
                
                // 3. Ambient Blob (Always moving)
                drawBlob(
                    context: context,
                    center: CGPoint(x: size.width * 0.8 + sin(now * 0.5) * 40, y: size.height * 0.6 + cos(now * 0.6) * 60),
                    baseRadius: size.width * 0.4,
                    expansion: sin(now) * 20,
                    color: Color.teal.opacity(0.2),
                    blur: 80
                )
            }
        }
    }
    
    func drawBlob(context: GraphicsContext, center: CGPoint, baseRadius: Double, expansion: Double, color: Color, blur: Double) {
        context.drawLayer { ctx in
            var path = Path()
            path.addEllipse(in: CGRect(
                x: center.x - (baseRadius + expansion) / 2,
                y: center.y - (baseRadius + expansion) / 2,
                width: baseRadius + expansion,
                height: baseRadius + expansion
            ))
            
            ctx.addFilter(.blur(radius: blur))
            ctx.fill(path, with: .color(color))
        }
    }
}

// MARK: - Prominent Voice Transcript View
struct VoiceTranscriptView: View {
    var messages: [Message]
    @ObservedObject var liveService: GoogleLiveService
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 20)

                    // Historical Messages
                    ForEach(messages) { message in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(message.text)
                                .font(.system(size: 28, weight: message.isUser ? .regular : .semibold, design: .rounded))
                                .foregroundStyle(message.isUser ? .white.opacity(0.6) : .white)
                            
                            if let mapData = message.mapData {
                                MapPreview(data: mapData)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                            
                            if let calendarEvent = message.calendarEvent {
                                CalendarEventPreview(event: calendarEvent)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .id(message.id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Live AI Response with pulsing glow
                    if !liveService.aiResponseText.isEmpty {
                        Text(liveService.aiResponseText)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(
                                color: liveService.isAISpeaking ? .purple.opacity(0.6) : .clear,
                                radius: liveService.isAISpeaking ? 20 : 0
                            )
                            .shadow(
                                color: liveService.isAISpeaking ? .purple.opacity(0.4) : .clear,
                                radius: liveService.isAISpeaking ? 40 : 0
                            )
                            .scaleEffect(liveService.isAISpeaking ? 1.0 + pulsePhase * 0.02 : 1.0)
                            .id("pendingAI")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if liveService.isThinking {
                        ThinkingIndicator()
                            .id("thinkingProp")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    // Live User Inputs with subtle pulse
                    if !liveService.userTranscript.isEmpty {
                        Text(liveService.userTranscript)
                            .font(.system(size: 28, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .shadow(
                                color: liveService.isUserSpeaking ? .blue.opacity(0.4) : .clear,
                                radius: liveService.isUserSpeaking ? 15 : 0
                            )
                            .id("pendingUser")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 32)
            }
            .onChange(of: messages.count) { _ in
                if let lastId = messages.last?.id {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: liveService.aiResponseText) { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    proxy.scrollTo("pendingAI", anchor: .bottom)
                }
            }
            .onChange(of: liveService.userTranscript) { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    proxy.scrollTo("pendingUser", anchor: .bottom)
                }
            }
            .onAppear {
                // Continuous pulse animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.0
                }
            }
            .onChange(of: liveService.isThinking) { _ in
                 if liveService.isThinking {
                     withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                         proxy.scrollTo("thinkingProp", anchor: .bottom)
                     }
                 }
            }
        }
    }
}

// MARK: - Professional Voice Waveform Visualization
struct SmoothWaveform: View {
    var audioLevel: Float
    var isAISpeaking: Bool
    var isUserSpeaking: Bool

    private let barCount = 40 // Reduced from 60 for performance

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in // 30fps instead of 60fps
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    VoiceWaveformBar(
                        index: index,
                        totalBars: barCount,
                        audioLevel: audioLevel,
                        isAISpeaking: isAISpeaking,
                        isUserSpeaking: isUserSpeaking,
                        time: timeline.date.timeIntervalSinceReferenceDate
                    )
                }
            }
            .shadow(color: shadowColor.opacity(0.8), radius: 12, y: 6)
            .shadow(color: shadowColor.opacity(0.4), radius: 24, y: 10)
        }
    }

    private var shadowColor: Color {
        if isAISpeaking {
            return .purple
        } else if isUserSpeaking {
            return .blue
        } else {
            return .white.opacity(0.2)
        }
    }
}

struct VoiceWaveformBar: View {
    let index: Int
    let totalBars: Int
    let audioLevel: Float
    let isAISpeaking: Bool
    let isUserSpeaking: Bool
    let time: TimeInterval
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: barHeight)
            .animation(
                .interpolatingSpring(stiffness: 300, damping: 20),
                value: barHeight
            )
    }
    
    private var gradientColors: [Color] {
        if isAISpeaking {
            return [
                Color.purple.opacity(0.8),
                Color.purple.opacity(1.0),
                Color(red: 0.8, green: 0.4, blue: 1.0)
            ]
        } else if isUserSpeaking {
            return [
                Color.blue.opacity(0.8),
                Color.blue.opacity(1.0),
                Color.cyan.opacity(0.9)
            ]
        } else {
            return [
                Color.white.opacity(0.2),
                Color.white.opacity(0.3),
                Color.white.opacity(0.25)
            ]
        }
    }
    
    private var barHeight: CGFloat {
        let isSpeaking = isAISpeaking || isUserSpeaking
        let normalizedIndex = Double(index) / Double(totalBars)
        
        if isSpeaking {
            // Active speaking - realistic voice visualization
            let level = max(0.1, Double(audioLevel))
            
            // Create natural wave patterns with multiple frequencies
            let primaryWave = sin(normalizedIndex * .pi * 4 + time * 4) * level
            let secondaryWave = cos(normalizedIndex * .pi * 6 - time * 3) * level * 0.5
            let tertiaryWave = sin(normalizedIndex * .pi * 8 + time * 5) * level * 0.3
            
            // Add some randomness for organic feel
            let noise = sin(time * 10 + Double(index)) * 0.1 * level
            
            // Combine all waves
            let combinedWave = primaryWave + secondaryWave + tertiaryWave + noise
            
            // Calculate final height with natural scaling
            let baseHeight: CGFloat = 12
            let amplification: CGFloat = 30
            let waveHeight = combinedWave * amplification
            
            // Smooth clamping
            let finalHeight = baseHeight + waveHeight
            return max(3, min(65, finalHeight))
        } else {
            // Idle state - subtle breathing animation
            let breathPhase = sin(time * 1.2) * 0.3 + 0.7
            let breathWave = sin(normalizedIndex * .pi * 2 + time * 0.8) * 2 * breathPhase
            return 5 + breathWave
        }
    }
}

// MARK: - Camera Helper
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        let previewLayer = CameraManager.shared.previewLayer
        previewLayer?.frame = view.bounds
        if let previewLayer = previewLayer { view.layer.addSublayer(previewLayer) }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = CameraManager.shared.previewLayer, layer.superlayer == nil {
            layer.frame = uiView.bounds
            uiView.layer.addSublayer(layer)
        }
    }
}
