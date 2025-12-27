//
//  ContentView.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import SwiftUI
import UIKit
internal import EventKit
import MapKit

struct MusicRecommendationIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FC3C44").opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "#FC3C44"))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
            }
            
            Text("Building your playlist...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: .capsule)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct CanvaCreationIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
            }
            
            Text("Creating your design...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(), in: .capsule)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}




struct ContentView: View {
    @State private var messageText = ""
    @State private var showingGreeting = true
    @State private var showingSidebar = false
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var isGeneratingImage = false
    @State private var isAnalyzingImage = false
    @State private var isCreatingPlaylist = false
    @State private var isCreatingCanva = false
    @State private var isGeneratingTable = false
    @State private var isSearchingWeb = false
    @State private var streamingText = ""
    @State private var streamingMessageID = UUID() // Stable ID for streaming message to prevent blinking
    @State private var showingSettings = false
    @State private var greetingText = ""
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageSourceMenu = false
    @State private var selectedImage: UIImage?
    @State private var foundWebImages: [String]? = nil
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var historyService = HistoryService()
    @State private var currentSessionID = UUID()
    @State private var keyboardHeight: CGFloat = 0
    @State private var isAccessingCalendar = false
    @AppStorage("isCalendarEnabled") private var isCalendarEnabled = false
    @StateObject private var artifactsManager = ArtifactsManager.shared
    @State private var showingArtifacts = false
    @StateObject private var appearanceManager = AppearanceManager.shared
    @State private var showArtifactsIndicator = false
    @State private var showingGlobalCopyToast = false
    @State private var currentChatTitle = "Eclipse"
    @State private var isCodeMode = false
    @State private var showingCodeRunner = false
    @State private var runnableCode = ""
    @State private var runnableLang = ""
    @State private var showingInputMenu = false
    @State private var showingApps = false
    @State private var currentPluginId: String? = nil
    @StateObject private var appManager = AppManager.shared
    @State private var showingCanvaAuth = false
    @State private var suggestions: [String] = []

    
    // Auto-scroll control
    @State private var isAutoScrollEnabled = true
    @State private var showScrollToBottomButton = false
    @State private var lastContentOffset: CGFloat = 0
    @State private var scrollProxy: ScrollViewProxy?
    
    // Task management for cancellation
    @State private var currentStreamingTask: Task<Void, Never>?
    
    private let geminiService = GeminiService()
    private let webSearchService = WebSearchService.shared
    @StateObject private var liveService = GoogleLiveService.shared
    @StateObject private var hybridRouter = HybridAIRouter.shared
    @State private var showingVoiceSheet = false
    @State private var currentAIProvider: AIProvider?
    
    @State private var showingMusicAuth = false
    
    // Greeting templates
    private let morningGreetings = [
        "Good morning!\nHow can I help you today?",
        "Rise and shine!\nWhat can I do for you?",
        "Hello there!\nHow can I assist you this morning?",
        "Morning!\nWhat's on your mind today?",
        "Fresh start!\nHow may I help you?",
        "Welcome back!\nWhat can I create for you this morning?",
        "Good day!\nHow can I assist you?",
        "Bright morning!\nWhat shall we explore today?",
        "New day, new ideas!\nHow can I help?",
        "Morning sunshine!\nWhat brings you here today?",
        "Dawn of possibilities!\nHow may I assist you?",
        "Early bird!\nWhat can I help you with?",
        "Beautiful morning!\nHow can I serve you today?"
    ]
    
    private let afternoonGreetings = [
        "Good afternoon!\nHow can I help you today?",
        "Hello!\nWhat can I do for you this afternoon?",
        "Afternoon!\nHow may I assist you?",
        "Welcome!\nWhat can I help you with today?",
        "Hope your day is going well!\nHow can I help?",
        "Good to see you!\nWhat's on your agenda?",
        "Afternoon energy!\nHow can I assist you?",
        "Midday check-in!\nWhat can I do for you?",
        "Hello there!\nHow may I help you this afternoon?",
        "Perfect timing!\nWhat can I create for you?",
        "Welcome back!\nHow can I assist you today?",
        "Great afternoon!\nWhat shall we work on?",
        "Ready to help!\nWhat do you need today?"
    ]
    
    private let eveningGreetings = [
        "Good evening!\nHow can I help you tonight?",
        "Evening!\nWhat can I do for you?",
        "Hello!\nHow may I assist you this evening?",
        "Welcome!\nWhat brings you here tonight?",
        "Night owl!\nHow can I help you?",
        "Evening creativity!\nWhat shall we create?",
        "Peaceful evening!\nHow may I assist you?",
        "Twilight thoughts!\nWhat can I do for you?",
        "Good evening!\nWhat's on your mind?",
        "Hello there!\nHow can I help you tonight?",
        "Evening vibes!\nWhat can I assist you with?",
        "Settling in!\nHow may I help you?",
        "Welcome back!\nWhat can I create for you tonight?"
    ]
    
    private let nightGreetings = [
        "Burning the midnight oil?\nHow can I help?",
        "Late night session!\nWhat can I do for you?",
        "Night time!\nHow may I assist you?",
        "Hello night owl!\nWhat can I help you with?",
        "Working late?\nHow can I assist you?",
        "Midnight thoughts!\nWhat shall we create?",
        "Late night energy!\nHow can I help?",
        "Moon's up!\nWhat brings you here?",
        "Nocturnal creativity!\nHow may I assist you?",
        "Stars are out!\nWhat can I do for you?",
        "After hours!\nHow can I help you tonight?",
        "Quiet hours!\nWhat's on your mind?"
    ]
    
    // MARK: - Constants
    private static let imageTriggerPrefixes = ["generate image", "create image", "make an image", "draw", "/image", "generate an image", "create an image"]
    private static let calendarKeywords = ["calendar", "schedule", "appointment", "meeting", "events", "agenda"]
    private static let tableKeywords = ["create a table", "make a table", "generate a table", "comparison table", "show this in a table", "data table", "put this in a table", "put that in a table", "in a table", "as a table", "table format", "tabular format", "in table form"]
    private static let artifactsKeywords = ["what's my", "what is my", "my favorite", "my preference", "remember when", "tell me about my", "do i like", "what do i", "remind me", "have i", "did i mention", "you know my", "my usual", "based on what you know"]

    // MARK: - Computed Properties
    @ViewBuilder
    private func gradientBackground(geometry: GeometryProxy) -> some View {
        if !appearanceManager.selectedGradient.colors.isEmpty {
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<appearanceManager.selectedGradient.colors.count, id: \.self) { index in
                        let xOffset: CGFloat = {
                            if index == 0 { return -geo.size.width * 0.3 }
                            if index == 1 { return 0 }
                            return geo.size.width * 0.3
                        }()

                        let yOffset: CGFloat = {
                            if index == 0 { return -200 }
                            if index == 1 { return geo.size.height * 0.3 }
                            return -100
                        }()

                        Circle()
                            .fill(appearanceManager.selectedGradient.colors[index])
                            .blur(radius: 150)
                            .frame(width: 500, height: 500)
                            .offset(x: xOffset, y: yOffset)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func backgroundLayer(geometry: GeometryProxy) -> some View {
        ZStack {
            if !isCodeMode {
                // Static Background
                ZStack {
                    Color.black.ignoresSafeArea()
                    gradientBackground(geometry: geometry)
                    
                    if let data = appearanceManager.customBackgroundData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .ignoresSafeArea()
                            .overlay(Color.black.opacity(0.3))
                            .transition(.opacity)
                    }
                }
                .id("static-bg")
                .transition(.opacity)
            } else {
                 Color.black.ignoresSafeArea()
            }
            
            Color.black
                .ignoresSafeArea()
                .opacity(isCodeMode ? 1 : 0)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: isCodeMode)
    }
     @ViewBuilder
    private var mainContentView: some View {
        let geometryContent = GeometryReader { geometry in
            mainContent(geometry: geometry)
        }
        .ignoresSafeArea()

        geometryContent
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isTextFieldFocused)
            .sheet(isPresented: $showingSettings) {
                SettingsView(historyService: historyService)
            }
            .sheet(isPresented: $showingApps) {
                AppStoreView(onStartPluginChat: { pluginId in
                    startNewChat(withPlugin: pluginId)
                })
            }
            .sheet(isPresented: $showingArtifacts) {
                NavigationStack {
                    ArtifactsView()
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingCodeRunner) {
                CodeRunnerView(code: runnableCode, language: runnableLang)
            }
            .sheet(isPresented: $showingCanvaAuth) {
                CanvaAuthView(onSuccess: {
                    print("✅ Canva connected successfully!")
                })
            }
            .overlay(
                ArtifactSavedNotification(
                    isShowing: $artifactsManager.showArtifactSavedNotification,
                    artifact: artifactsManager.lastSavedArtifact
                )
            )
            .onAppear {
                greetingText = getRandomGreeting()
                
                setupKeyboardObservers()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
    }

    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            sidebarContent
            mainZStackContent(geometry: geometry)
                .frame(width: geometry.size.width)
        }
        .offset(x: showingSidebar ? 0 : -300)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        let sidebarView = SidebarView(
            isShowing: $showingSidebar,
            sessions: historyService.sessions,
            onSelectSession: { session in
                loadSession(session)
            },
            onDeleteSession: { sessionID in
                let wasCurrentSession = (sessionID == currentSessionID)
                historyService.deleteSession(id: sessionID)
                if wasCurrentSession {
                    startNewChat()
                }
            },
            onNewChat: {
                startNewChat()
            },
            onShowSettings: {
                showingSettings = true
            },
            onShowArtifacts: {
                showingArtifacts = true
            },
            onShowApps: {
                showingApps = true
            },
            onStartPluginChat: { pluginId in
                startNewChat(withPlugin: pluginId)
            }
        )

        sidebarView.frame(width: 300)
    }

    @ViewBuilder
    private func mainZStackContent(geometry: GeometryProxy) -> some View {
        ZStack {
            backgroundLayer(geometry: geometry)
            contentLayers(geometry: geometry)
                .onTapGesture {
                    // Dismiss keyboard when tapping anywhere outside the text field
                    if isTextFieldFocused {
                        isTextFieldFocused = false
                    }
                }

            // Dimming layer when sidebar is open, which also handles the tap to dismiss
            if showingSidebar {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingSidebar = false
                        }
                    }
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSidebar)
        .fullScreenCover(isPresented: $showingVoiceSheet, onDismiss: {
            if liveService.isConnected {
                liveService.disconnect()
            }
        }) {
            VoiceChatSheet(messages: messages)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showScrollToBottomButton)
        .overlay(
            Group {
                if showingGlobalCopyToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Copied to Clipboard")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .padding(.top, 60)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .top)))
                    .zIndex(100)
                }
            }
        )
    }

    @ViewBuilder
    private func contentLayers(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top Bar with menu and sidebar toggle
            HStack {
                Button {
                    HapticManager.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showingSidebar.toggle()
                    }
                } label: {
                    Image(systemName: showingSidebar ? "xmark" : "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .glassEffect(.regular.interactive(), in: .circle)
                
                Spacer()
                
                VStack(spacing: 4) {
                    VStack(spacing: 2) {
                        Text(currentChatTitle)
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: 240)
                            .id(currentChatTitle) // Force view refresh for transition
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            ))
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentChatTitle)
                    
                    
                    // Coding Agent Badge
                    if isCodeMode {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 8))
                            Text("Coding Agent")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }

                    // AI Provider Indicator
                    if let provider = currentAIProvider {
                        HStack(spacing: 4) {
                            Image(systemName: provider.icon)
                                .font(.system(size: 8))
                            Text(provider.displayName)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    // Plugin Badge
                    if let pluginId = currentPluginId, let app = appManager.availableApps.first(where: { $0.id == pluginId }) {
                        HStack(spacing: 4) {
                            Image(systemName: app.iconName)
                                .font(.system(size: 8))
                            Text(app.name)
                                .font(.system(size: 10, weight: .bold))
                                .textCase(.uppercase)
                        }
                        .foregroundStyle(Color(hex: app.tintColor))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: app.tintColor).opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: app.tintColor).opacity(0.3), lineWidth: 1)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // New Chat Button
                Button {
                    HapticManager.shared.impact(.light)
                    if showingSidebar {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingSidebar = false
                        }
                    }
                    startNewChat()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.horizontal, 20)
            .padding(.top, max(geometry.safeAreaInsets.top, 20) + 45)
            .padding(.bottom, 12)
            
            // Main Content Area
            if showingGreeting {
                // Greeting View
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        Image("betterlunr")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.white)
                            .onTapGesture {
                                HapticManager.shared.impact(.medium)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    startNewChat()
                                }
                            }

                        Text(greetingText)
                            .font(.system(size: 32, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 140)
                    
                    Spacer()
                }
            } else {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message, 
                                    onCopy: {
                                        triggerGlobalCopyToast()
                                    },
                                    isCodeMode: isCodeMode,
                                    onRunCode: { lang, code in
                                        runnableCode = code
                                        runnableLang = lang
                                        showingCodeRunner = true
                                    },
                                    onImageEdited: { editedImage in
                                        // Create a new message with the edited image
                                        if let imageData = editedImage.jpegData(compressionQuality: 0.8) {
                                            let newMessage = Message(
                                                text: "Here's your edited image:",
                                                isUser: false,
                                                images: [imageData]
                                            )
                                            messages.append(newMessage)
                                            saveCurrentSession()
                                            
                                            // Scroll to the new message
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.easeOut(duration: 0.3)) {
                                                    scrollProxy?.scrollTo(newMessage.id, anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                )
                                    .id(message.id)
                            }
                            
                            // Loading indicators
                            if isLoading || !streamingText.isEmpty {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if isGeneratingImage {
                                            FormingImageIndicator()
                                        } else if isAnalyzingImage {
                                            ImageAnalyzingIndicator()
                                        } else if isGeneratingTable {
                                            TableGenerationIndicator()
                                        } else if isCreatingPlaylist {
                                            MusicRecommendationIndicator()
                                        } else if isCreatingCanva {
                                            CanvaCreationIndicator()
                                        } else {
                                            ThinkingIndicator()
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .frame(minHeight: 40) // Ensure stable height
                                .id("indicators")
                            }
                            
                            // Streaming Message separately for ID stability
                            if !streamingText.isEmpty {
                                MessageBubble(
                                    message: Message(id: streamingMessageID, text: streamingText, isUser: false),
                                    isCodeMode: isCodeMode,
                                    onRunCode: { lang, code in
                                        runnableCode = code
                                        runnableLang = lang
                                        showingCodeRunner = true
                                    }
                                )
                                .id("streaming")
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.bottom, keyboardHeight > 0 ? 20 : 0) // Add padding when keyboard is shown
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                // If user is actively dragging UP, break the loop
                                if value.translation.height > 10 && isAutoScrollEnabled {
                                    print("🛑 USER DRAG DETECTED! Breaking auto-scroll loop! Translation: \(value.translation.height)")
                                    isAutoScrollEnabled = false
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showScrollToBottomButton = true
                                    }
                                }
                            }
                    )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Calculate delta before updating last value
                        let delta = value - lastContentOffset
                        
                        // Update last value
                        lastContentOffset = value
                        
                        // Show button if user scrolls up significantly (delta is positive when scrolling up) when NOT generating
                        if delta > 15 && !isLoading && streamingText.isEmpty && !showScrollToBottomButton && !messages.isEmpty {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showScrollToBottomButton = true
                                isAutoScrollEnabled = false
                            }
                        }
                        
                        // Note: We rely on the button tap to scroll back to bottom and hide itself.
                        // But if user manually scrolls back down, we can hide it too.
                        // Assuming matching "bottom" is hard without content height communication, 
                        // we'll stick to manual dismissal or auto-hide if we detect significant downward scroll near end?
                        // For now, let's keep it simple as requested: "only shows when I'm scrolling up or aren't at the bottom"
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .fullScreenCover(isPresented: $showingMusicAuth) {
                        MusicAuthView(onSuccess: {
                            showingMusicAuth = false
                            // Refresh logic if needed
                        })
                    }
                    .onChange(of: messages.count) { oldCount, newCount in
                        // Only scroll when a NEW message is added AND it's a user message
                        // This prevents scrolling when AI message is finalized (since we're already at bottom from streaming)
                        if isAutoScrollEnabled && newCount > oldCount {
                            if let lastMessage = messages.last, lastMessage.isUser {
                                // Only auto-scroll for user messages
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy?.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: streamingText) { oldValue, newValue in
                        // Only scroll if text is actually growing and auto-scroll is enabled
                        if isAutoScrollEnabled && !newValue.isEmpty {
                            // Immediate scroll with animation during streaming
                            scrollProxy?.scrollTo("streaming", anchor: UnitPoint.bottom)
                        }
                    }
                    .onChange(of: keyboardHeight) { _, newHeight in
                        // Scroll to bottom when keyboard appears/disappears
                        if newHeight > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastMessageId = messages.last?.id {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        scrollProxy?.scrollTo(lastMessageId, anchor: UnitPoint.bottom)
                                    }
                                } else if !streamingText.isEmpty {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        scrollProxy?.scrollTo("streaming", anchor: UnitPoint.bottom)
                                    }
                                }
                            }
                        }
                    }
                }

                .overlay(
                    // Scroll to bottom button - Liquid Glass circular arrow
                    Group {
                        if showScrollToBottomButton {
                            VStack {
                                Spacer()
                                Button {
                                    HapticManager.shared.impact(.light)
                                    isAutoScrollEnabled = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showScrollToBottomButton = false
                                        if !streamingText.isEmpty {
                                            scrollProxy?.scrollTo("streaming", anchor: UnitPoint.bottom)
                                        } else if let lastMessage = messages.last {
                                            scrollProxy?.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .padding(.bottom, 24)
                                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                            }
                        }
                    }
                )
            }

            // Music Mini Player removed as per user request
            // MusicMiniPlayerView()
            //    .zIndex(5)

            // Input Area
            VStack(spacing: 12) {
                // Selected image preview
                if let image = selectedImage {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Button {
                                    selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .offset(x: 8, y: -8),
                                alignment: .topTrailing
                            )
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                
                
                /*
                // Suggestions Chips
                if !suggestions.isEmpty && !isLoading {
                    SuggestionChipsView(suggestions: suggestions) { suggestion in
                        messageText = suggestion
                        sendMessage()
                    }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                */
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Main + button
                    Button {
                        HapticManager.shared.impact(.light)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingInputMenu.toggle()
                        }
                    } label: {
                        Image(systemName: showingInputMenu ? "xmark" : "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(showingInputMenu ? 90 : 0))
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    .overlay(
                        VStack(spacing: 12) {
                            if showingInputMenu {
                                // Coding Agent button
                                Button {
                                    HapticManager.shared.impact(.medium)
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        isCodeMode.toggle()
                                        showingInputMenu = false
                                    }
                                } label: {
                                    ZStack {
                                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(isCodeMode ? .orange : .white)
                                            .frame(width: 44, height: 44)
                                        
                                        if isCodeMode {
                                            Circle()
                                                .fill(.orange)
                                                .frame(width: 8, height: 8)
                                                .offset(x: 14, y: -14)
                                        }
                                    }
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)).combined(with: .offset(y: 20)).animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.08)),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                                
                                // Image picker button
                                Button {
                                    HapticManager.shared.impact(.light)
                                    showingImageSourceMenu = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingInputMenu = false
                                    }
                                } label: {
                                    Image(systemName: "photo")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)).combined(with: .offset(y: 20)).animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.16)),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                                
                                // Voice button
                                Button {
                                    HapticManager.shared.impact(.medium)
                                    showingVoiceSheet = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        showingInputMenu = false
                                    }
                                } label: {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(.white)
                                        .frame(width: 44, height: 44)
                                }
                                .glassEffect(.regular.interactive(), in: .circle)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)).combined(with: .offset(y: 20)).animation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.24)),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.bottom, 56) // Position above the plus button
                        , alignment: .bottom
                    )
                    .zIndex(1) // Ensure it stays on top of other elements if needed
                    
                    // Text field
                    ZStack(alignment: .leading) {
                        if messageText.isEmpty {
                            Text("Message Eclipse")
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.leading, 16)
                        }
                        
                        TextField("", text: $messageText, axis: .vertical)
                            .font(.system(size: 17, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(1...10)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .fixedSize(horizontal: false, vertical: true)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                sendMessage()
                            }
                    }
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
                    
                    // Send/Stop button
                    Button {
                        HapticManager.shared.impact(.medium)
                        if isLoading || !streamingText.isEmpty {
                            // Stop generation
                            stopGeneration()
                        } else {
                            // Send message
                            sendMessage()
                        }
                    } label: {
                        Group {
                            if isLoading || !streamingText.isEmpty {
                                // Stop icon (red square)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white)
                                    .frame(width: 16, height: 16)
                            } else {
                                // Send icon
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: (isLoading || !streamingText.isEmpty) ? [.red, .red.opacity(0.8)] : (messageText.isEmpty && selectedImage == nil ? [.gray, .gray.opacity(0.8)] : [.orange, Color(red: 0.9, green: 0.5, blue: 0.3)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: (isLoading || !streamingText.isEmpty) ? .red.opacity(0.4) : (messageText.isEmpty && selectedImage == nil ? .clear : .orange.opacity(0.4)), radius: 12, x: 0, y: 6)
                    }
                    .disabled(!isLoading && streamingText.isEmpty && messageText.isEmpty && selectedImage == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 8 : max(geometry.safeAreaInsets.bottom, 20) + 12)
            }
            .confirmationDialog("Choose Image Source", isPresented: $showingImageSourceMenu) {
                Button("Camera") {
                    showingCamera = true
                }
                Button("Photo Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    var body: some View {
        mainContentView
            // Google Live service handlers removed - messages stay in VoiceChatSheet only
            .onChange(of: liveService.isConnected) { _, isConnected in
                if !isConnected {
                    // Service disconnected
                }
            }
            .alert("Connection Error", isPresented: Binding(
                get: { liveService.errorMessage != nil },
                set: { if !$0 { liveService.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(liveService.errorMessage ?? "Unknown error")
            }
    }

    // MARK: - Functions
    private func getRandomGreeting() -> String {
        if isCodeMode {
            return "Ready to code!"
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        let greetings: [String]
        switch hour {
        case 5..<12:
            greetings = morningGreetings
        case 12..<17:
            greetings = afternoonGreetings
        case 17..<22:
            greetings = eveningGreetings
        default:
            greetings = nightGreetings
        }
        
        return greetings.randomElement() ?? "Hello!\nHow can I help you today?"
    }
    
    private func stopGeneration() {
        print("🛑 Stopping generation...")
        
        // Cancel the streaming task
        currentStreamingTask?.cancel()
        currentStreamingTask = nil
        
        // Finalize any partial streaming text
        if !streamingText.isEmpty {
            let finalMessage = Message(id: streamingMessageID, text: streamingText, isUser: false)
            messages.append(finalMessage)
            saveCurrentSession()
        }
        
        // Reset state
        isLoading = false
        isGeneratingImage = false
        isAnalyzingImage = false
        isCreatingPlaylist = false
        isCreatingCanva = false
        isGeneratingTable = false
        isSearchingWeb = false
        isAccessingCalendar = false
        showArtifactsIndicator = false
        streamingText = ""
        streamingMessageID = UUID()
        
        print("✅ Generation stopped")
    }
    
    private func sendMessage() {
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageToSend = selectedImage

        guard (!userMessage.isEmpty || imageToSend != nil), !isLoading else { return }

        // Detect @mention for plugins
        var detectedPluginId: String? = nil
        var cleanedMessage = userMessage

        if let mentionMatch = userMessage.range(of: "@(\\w+)", options: .regularExpression) {
            let mention = String(userMessage[mentionMatch]).lowercased()

            // Map @mentions to plugin IDs
            let pluginMapping: [String: String] = [
                "@applemusic": "apple_music",
                "@applemaps": "apple_maps",
                "@canva": "canva",
                "@eclipse": "eclipse_editing",
                "@weather": "weather_plus",
                "@wealthwise": "finance_tracker",
                "@voyager": "travel_planner"
            ]

            if let pluginId = pluginMapping[mention] {
                // Check if app is downloaded
                if appManager.isDownloaded(pluginId) {
                    detectedPluginId = pluginId
                    // Remove the @mention from the message
                    cleanedMessage = userMessage.replacingOccurrences(of: mention, with: "", options: [.regularExpression, .caseInsensitive])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "^,\\s*", with: "", options: .regularExpression)
                }
            }
        }

        // Re-enable auto-scroll when user sends a new message
        isAutoScrollEnabled = true
        showScrollToBottomButton = false
        
        isTextFieldFocused = false
        
        // Scroll to bottom immediately when send is pressed
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.3)) {
                if let lastMessageId = messages.last?.id {
                    scrollProxy?.scrollTo(lastMessageId, anchor: .bottom)
                }
            }
        }
        
        // Add user message with image if present (show original message with @mention to user)
        if let image = imageToSend, let imageData = image.jpegData(compressionQuality: 0.8) {
            let message = Message(text: userMessage.isEmpty ? "" : userMessage, isUser: true, images: [imageData])
            messages.append(message)
        } else {
            let message = Message(text: userMessage, isUser: true)
            messages.append(message)
        }

        // Scroll to the newly added user message immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollProxy?.scrollTo(messages.last?.id, anchor: .bottom)
            }
        }

        // Detect and save important information as artifacts (use cleaned message)
        if !cleanedMessage.isEmpty {
            Task {
                await artifactsManager.detectAndSaveImportantInfo(from: cleanedMessage)
            }
        }

        messageText = ""
        selectedImage = nil
        showingGreeting = false

        // Start loading state

        // If in Live Mode, we only update the UI history, we DO NOT send to REST API
        if liveService.isConnected {
            // Live service already handles the audio I/O
            // We just clear the input (done above) and return
            // Ensure we clear the transcript in service so it doesn't re-trigger
            // Note: Service transcript is replaced on next speech, but good to be clean
            return
        }

        isLoading = true
        suggestions = [] // Clear suggestions on send
        streamingText = ""
        streamingMessageID = UUID() // Reset ID for new response
        showScrollToBottomButton = false

        // Scroll to loading indicator immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollProxy?.scrollTo("indicators", anchor: .bottom)
            }
        }

        // Get conversation history (exclude the just-added user message)
        let historyCount = messages.count - 1
        let conversationHistory = historyCount > 0 ? Array(messages.prefix(historyCount)) : []

        // Store the task so it can be cancelled
        currentStreamingTask = Task {
            // Use cleaned message (without @mention) for processing
            // Use detected plugin if found via @mention, otherwise use current session plugin
            let pluginToUse = detectedPluginId ?? currentPluginId
            
            // Show music indicator if we're using Apple Music plugin
            if pluginToUse == "apple_music" {
                await MainActor.run { isCreatingPlaylist = true }
            }
            
            // Show Canva indicator if we're using Canva plugin and detect design intent
            if pluginToUse == "canva" && detectsCanvaIntent(cleanedMessage) {
                await MainActor.run { isCreatingCanva = true }
            }
            

            
            await processMessage(userMessage: cleanedMessage, imageToSend: imageToSend, conversationHistory: conversationHistory, temporaryPluginId: pluginToUse)
        }
    }
    
    private func detectsCanvaIntent(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        let canvaKeywords = [
            "create a", "make a", "design a", "generate a",
            "flyer", "poster", "banner", "post", "story",
            "instagram", "linkedin", "facebook", "twitter",
            "presentation", "logo", "infographic"
        ]
        
        // Check if message contains creation verbs + design types
        let hasCreationVerb = ["create", "make", "design", "generate"].contains { lowerMessage.contains($0) }
        let hasDesignType = ["flyer", "poster", "banner", "post", "story", "presentation", "logo", "infographic"].contains { lowerMessage.contains($0) }
        
        return hasCreationVerb && hasDesignType
    }

    private func processMessage(userMessage: String, imageToSend: UIImage?, conversationHistory: [Message], temporaryPluginId: String? = nil) async {
        do {
            // Check if we have an image to analyze
            if let image = imageToSend {
                await MainActor.run {
                    isAnalyzingImage = true
                }
                
                let prompt = userMessage.isEmpty ? "Analyze this image in detail." : userMessage
                
                // Pass plugin ID to enable Eclipse Editing context
                for try await chunk in geminiService.analyzeImageStream(image, prompt: prompt, conversationHistory: conversationHistory, pluginId: temporaryPluginId) {
                    await MainActor.run {
                        streamingText += chunk
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    isAnalyzingImage = false
                    
                    // Process image edit UI tags (same as text messages)
                    let (editUiData, cleanText) = extractImageEditData(from: streamingText)
                    let finalText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Attach the original image if we're showing an editor
                    var contextImages: [Data]? = nil
                    if editUiData != nil, let imageData = image.jpegData(compressionQuality: 0.8) {
                        contextImages = [imageData]
                    }
                    
                    let aiMessage = Message(
                        text: finalText,
                        isUser: false,
                        images: contextImages,
                        imageEditData: editUiData
                    )
                    messages.append(aiMessage)
                    streamingText = ""
                    saveCurrentSession()
                }
            } else {
                // Check for image generation intent
                if isImageGenerationInternal(userMessage) {
                    await MainActor.run {
                        isGeneratingImage = true
                    }
                    
                    let prompt = extractImagePrompt(from: userMessage)
                    // Switched to Gemini Image Generation as per user request
                    let images = try await geminiService.generateImage(prompt: prompt)
                    
                    await MainActor.run {
                        isLoading = false
                        isGeneratingImage = false
                        let aiMessage = Message(text: "Here is your generated image:", isUser: false, images: images)
                        messages.append(aiMessage)
                        saveCurrentSession()
                    }
                } else {
                    await MainActor.run {
                        isGeneratingImage = false
                    }
                    
                    // Check for web search intent
                    var messageToSend = userMessage
                    if webSearchService.shouldPerformWebSearch(for: userMessage) {
                        await MainActor.run {
                            isSearchingWeb = true
                        }
                        
                        do {
                            let (searchResults, images) = try await webSearchService.search(query: userMessage)
                            
                            // Capture found images
                            await MainActor.run {
                                self.foundWebImages = images
                            }
                            
                            messageToSend += "\n\n[Web Search Results:\n\(searchResults)]"
                            print("✅ Web search completed successfully")
                            
                            // Keep the indicator visible for a moment so user sees it completed
                            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                        } catch {
                            print("❌ Web search failed: \(error.localizedDescription)")
                            // Continue without search results
                        }
                        
                await MainActor.run {
                            isSearchingWeb = false
                        }
                    }
                    
                    // 2. Check for Apple Weather queries
                    if temporaryPluginId == "apple_weather" || userMessage.lowercased().contains("weather") {
                        if userMessage.lowercased().contains("weather") || userMessage.lowercased().contains("temperature") {
                            // Fetch weather
                            Task {
                                do {
                                    let weather = try await AppleWeatherManager.shared.getCurrentWeather()
                                    
                                    await MainActor.run {
                                        let weatherMsg = Message(
                                            text: "Here is the current weather.", // Short text, as visual card does the heavy lifting
                                            isUser: false,
                                            weatherData: weather // Attach structured data
                                        )
                                        messages.append(weatherMsg)
                                        saveCurrentSession()
                                    }
                                } catch {
                                    await MainActor.run {
                                        let errorMsg = Message(
                                            text: "I couldn't get the weather. Please make sure location access is enabled.",
                                            isUser: false
                                        )
                                        messages.append(errorMsg)
                                    }
                                }
                            }
                            return // Stop further processing locally, or let AI add more context if needed
                        }
                    }
                    
                    // 3. Check for specific plugin commands (e.g. Canva)
                    // Check for Maps intent if plugin is Apple Maps
                    if temporaryPluginId == "apple_maps" {
                        let query = MapsService.shared.extractQuery(from: userMessage)
                        if !query.isEmpty {
                            do {
                                // Request user's current location for "nearest" searches
                                let userLocation = await LocationService.shared.getCurrentLocation()
                                if let userLocation = userLocation {
                                    let locations = try await MapsService.shared.searchPlaces(query: query, near: userLocation)
                                    if !locations.isEmpty {
                                        let mapsContext = locations.prefix(3).map { $0.formattedString }.joined(separator: "\n\n")
                                        messageToSend += "\n\n[System Info: Nearby Locations Found for '\(query)']:\n\(mapsContext)"
                                        print("✅ Maps search completed successfully")
                                    }
                                } else {
                                    print("⚠️ No user location available for Maps search")
                                }
                            } catch {
                                print("❌ Maps search failed: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    // Check for calendar intent
                    if isCalendarEnabled && isCalendarIntentInternal(userMessage) {
                        await MainActor.run {
                            isAccessingCalendar = true
                        }
                        let events = CalendarManager.shared.getUpcomingEvents()
                        let eventString: String
                        if events.isEmpty {
                            eventString = "No upcoming events found."
                        } else {
                            let eventDescriptions = events.map { "\($0.title ?? "Event"): \($0.startDate.formatted())" }
                            eventString = eventDescriptions.joined(separator: "\n")
                        }
                        messageToSend += "\n\n[System Info: User's Upcoming Calendar Events:\n\(eventString)]"
                        
                        // Short delay to show the indicator interaction
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                    
                    if isTableIntentInternal(userMessage) {
                        await MainActor.run {
                            isGeneratingTable = true
                        }
                    }
                    
                    // Extract first name for AI context
                    let fullName = AuthManager.shared.userName
                    let firstName = fullName.components(separatedBy: " ").first ?? fullName
                    
                    // Show artifacts indicator only if:
                    // 1. We have artifacts saved
                    // 2. The user is asking about their personal information
                    let hasArtifacts = !artifactsManager.artifacts.isEmpty
                    let isAskingAboutPersonalInfo = isAskingAboutArtifacts(userMessage)
                    
                    if hasArtifacts && isAskingAboutPersonalInfo {
                        await MainActor.run {
                            showArtifactsIndicator = true
                        }
                        // Show for 2 seconds before streaming starts
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                    
                    var isFirstChunk = true
                    for try await chunk in geminiService.sendMessageStream(messageToSend, conversationHistory: conversationHistory, userName: firstName, isCodeMode: isCodeMode, pluginId: temporaryPluginId) {
                        await MainActor.run {
                            if isFirstChunk {
                                isLoading = false
                                isFirstChunk = false
                            }
                            streamingText += chunk
                            isAccessingCalendar = false // Hide indicator once streaming starts
                            isSearchingWeb = false // Hide search indicator once streaming
                            showArtifactsIndicator = false // Hide artifacts indicator once streaming
                            isCreatingPlaylist = false // Hide music indicator once streaming
                            isCreatingCanva = false // Hide Canva indicator once streaming
                        }
                    }
                    
                    await MainActor.run {
                        isLoading = false
                        isGeneratingTable = false
                        isAccessingCalendar = false
                        isSearchingWeb = false
                        showArtifactsIndicator = false
                        isCreatingPlaylist = false
                        isCreatingCanva = false
                        
                        // Only re-enable auto-scroll if button is not visible (user hasn't manually scrolled up)
                        if !showScrollToBottomButton {
                            isAutoScrollEnabled = true
                        }
                        
                        print("DEBUG: 🚀 Processing final AI response (Length: \(streamingText.count))")
                        print("DEBUG: Raw text: [\(streamingText)]")
                        
                        // Process interactions
                        processCalendarEventCreation(from: streamingText)
                        
                        // Check for ambience
                        let textAfterAmbience = streamingText
                        
                        // Check for maps
                        let (mapData, textWithoutMap) = extractMapData(from: textAfterAmbience)
                        
                        // Check for playlist (Retired, but keeping detection to prevent errors if AI hallucinates it)
                        let (_, textAfterPlaylist) = extractPlaylistData(from: textWithoutMap)

                        // Check for music embed
                        var musicEmbeds: [MusicEmbedData]? = nil
                        let (embeds, cleaned) = extractMusicEmbedData(from: textAfterPlaylist)
                        musicEmbeds = embeds
                        var textAfterMusic = cleaned
                        
                        // IMPORTANT: Force cleanup of any lingering tags if regex missed them (safety net)
                        textAfterMusic = textAfterMusic.replacingOccurrences(of: "\\[MUSIC_EMBED:.*?\\]", with: "", options: .regularExpression)
                        
                        // Check for Canva design creation
                        print("DEBUG: Checking for Canva design creation...")
                        processCanvaDesignCreation(from: textAfterMusic)
                        
                        // If we detected Canva intent earlier and haven't created a design yet, do it now
                        if temporaryPluginId == "canva" && detectsCanvaIntent(userMessage) {
                            print("DEBUG: Canva intent detected, triggering automatic design creation")
                            Task {
                                await createCanvaDesignFromIntent(userMessage: userMessage)
                            }
                        }
                        
                        // Remove Canva command from text to prevent it from showing in the bubble
                        let textAfterCanva = cleanCanvaTags(from: textAfterMusic)
                        print("DEBUG: Text after Canva cleanup: [\(textAfterCanva)]")
                        
                        // Check for image edit UI
                        let (editUiData, cleanText) = extractImageEditData(from: textAfterCanva)
                        
                        // Check for Health Widget
                        let (healthData, textFinal) = extractHealthData(from: cleanText)
                        
                        // Final clean up
                        let finalText = textFinal.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("DEBUG: Final text to display: [\(finalText)]")
                        
                        var contextImages: [Data]? = nil
                        if editUiData != nil {
                            // Find the last message with an image to edit
                            if let lastMsgWithImage = messages.last(where: { $0.images != nil && !($0.images?.isEmpty ?? true) }) {
                                contextImages = lastMsgWithImage.images
                            }
                        }
                        
                        let aiMessage = Message(
                            id: streamingMessageID,
                            text: finalText, 
                            isUser: false, 
                            images: contextImages,
                            mapData: mapData,
                            playlist: nil, // Retired
                            musicEmbeds: musicEmbeds,
                            imageEditData: editUiData,
                            canvaDesigns: nil,
                            weatherData: nil,
                            healthData: healthData,
                            webImageUrls: self.foundWebImages
                        )
                        
                        // Reset found images
                        self.foundWebImages = nil
                        
                        messages.append(aiMessage)
                        streamingText = ""
                        // Save session
                        saveCurrentSession()
                        
                        // Generate new suggestions after delay
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                            let newSuggestions = await geminiService.generateSuggestions(history: conversationHistory + [aiMessage])
                            await MainActor.run {
                                withAnimation {
                                    suggestions = newSuggestions
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                isGeneratingImage = false
                isAnalyzingImage = false
                isGeneratingTable = false
                streamingText = ""
                let errorMessage = Message(
                    text: "Sorry, I encountered an error: \(error.localizedDescription)",
                    isUser: false
                )
                messages.append(errorMessage)
                saveCurrentSession()
            }
        }
    }
    
    private func triggerGlobalCopyToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingGlobalCopyToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showingGlobalCopyToast = false
            }
        }
    }
    


    private func extractMapData(from text: String) -> (MapData?, String) {
        // Pattern: MAP_LOCATION: [lat, lng, "Title", "Subtitle"]
        let pattern = #"MAP_LOCATION:\s*\[\s*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*,\s*"([^"]+)"\s*(?:,\s*"([^"]*)")?\s*\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        if let match = regex.firstMatch(in: text, options: [], range: range) {
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
            
            // Remove the command from the text
            let cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (mapData, cleanedText)
        }
        
        return (nil, text)
    }
    
    // Add this helper method
    private func extractPlaylistData(from text: String) -> (PlaylistData?, String) {
        // Tag format: [PLAYLIST_UI:Title|Description|Song1,Song2]
        let pattern = #"\[PLAYLIST_UI:(.+?)\|(.+?)\|(.+?)(?:\]|$)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = matches.first {
            let title = nsString.substring(with: match.range(at: 1))
            let description = nsString.substring(with: match.range(at: 2))
            let songsString = nsString.substring(with: match.range(at: 3))
            
            let songStrings = songsString.components(separatedBy: ",")
            let songs = songStrings.map { str -> PlaylistData.SongItem in
                let parts = str.components(separatedBy: " - ")
                return PlaylistData.SongItem(
                    title: parts.first?.trimmingCharacters(in: .whitespaces) ?? str,
                    artist: parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : "Unknown",
                    artworkUrl: nil
                )
            }
            
            let playlistData = PlaylistData(title: title, description: description, songs: songs)
            
            // Clean text
            let cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: match.range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (playlistData, cleanedText)
        }
        
        return (nil, text)
    }
    
    // Helper method for Music Embed extraction
    private func extractMusicEmbedData(from text: String) -> ([MusicEmbedData]?, String) {
        // Tag format: [MUSIC_EMBED:Title|Artist] or [MUSIC_EMBED:Title|Artist|ID]
        let pattern = #"\[MUSIC_EMBED:(.+?)\|(.+?)(?:\|(.+?))?\]"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if matches.isEmpty {
            return (nil, text)
        }
        
        var embeds: [MusicEmbedData] = []
        for match in matches {
            let title = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            let artist = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            
            var catalogId: String? = nil
            if match.numberOfRanges > 3 && match.range(at: 3).location != NSNotFound {
                catalogId = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces)
            }
            
            var embedUrl: String? = nil
            if let id = catalogId {
                embedUrl = "https://embed.music.apple.com/us/album/placeholder/\(id)?i=\(id)"
            }
            
            embeds.append(MusicEmbedData(title: title, artist: artist, catalogId: catalogId, embedUrl: embedUrl))
        }
        
        // Clean all matches from text
        let cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: nsString.length), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (embeds, cleanedText)
    }
    
    // Helper method for Image Edit UI extraction
    private func extractImageEditData(from text: String) -> (ImageEditData?, String) {
        // Tag format: [IMAGE_EDIT_UI:Type|InitialValue]
        let pattern = #"\[IMAGE_EDIT_UI:(.+?)\|(.+?)(?:\]|$)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = matches.first {
            let typeString = nsString.substring(with: match.range(at: 1))
            let valueString = nsString.substring(with: match.range(at: 2))
            
            let value = Double(valueString) ?? 0.0
            
            // Map string to AdjustmentType
            let type: AdjustmentType
            switch typeString.lowercased() {
            case "brightness": type = .brightness
            case "blur": type = .blur
            case "contrast": type = .contrast
            case "saturation": type = .saturation
            default: type = .brightness // Default fallback
            }
            
            let editData = ImageEditData(type: type, initialValue: value)
            
            // Clean text
            let cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: match.range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (editData, cleanedText)
        }
        
        return (nil, text)
    }
    
    // Helper method for Health Widget extraction
    private func extractHealthData(from text: String) -> ([HealthWidgetData]?, String) {
        // Tag format: [HEALTH_WIDGET:type|value|unit]
        let pattern = #"\[HEALTH_WIDGET:(.+?)\|(.+?)\|(.+?)(?:\]|$)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return (nil, text)
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard !matches.isEmpty else {
            return (nil, text)
        }
        
        var widgets: [HealthWidgetData] = []
        
        for match in matches {
            let type = nsString.substring(with: match.range(at: 1))
            let value = nsString.substring(with: match.range(at: 2))
            let unit = nsString.substring(with: match.range(at: 3))
            
            let widgetData = HealthWidgetData(type: type, value: value, unit: unit)
            widgets.append(widgetData)
        }
        
        // Remove ALL tags from the text
        let cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: nsString.length), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (widgets, cleanedText)
    }
    
    // MARK: - Helper Methods
    
    private func isImageGenerationInternal(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        return Self.imageTriggerPrefixes.contains(where: { lowerMessage.hasPrefix($0) })
    }
    
    
    private func extractImagePrompt(from message: String) -> String {
        var prompt = message
        for prefix in Self.imageTriggerPrefixes {
            if message.lowercased().hasPrefix(prefix) {
                prompt = String(message.dropFirst(prefix.count))
                break
            }
        }
        
        prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if prompt.lowercased().hasPrefix("of ") {
            prompt = String(prompt.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return prompt
    }
    
    private func isCalendarIntentInternal(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        return Self.calendarKeywords.contains(where: { lowerMessage.contains($0) })
    }
    
    private func isTableIntentInternal(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        return Self.tableKeywords.contains(where: { lowerMessage.contains($0) })
    }
    
    private func isAskingAboutArtifacts(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        return Self.artifactsKeywords.contains(where: { lowerMessage.contains($0) })
    }
    
    // Robust cleanup using NSRegularExpression to handle multiline and variants
    // Remove the [CANVA_DESIGN:...] tag from the displayed text
    private func cleanCanvaTags(from text: String) -> String {
        // Tag to remove: [CANVA_DESIGN:...]
        // Simple string finding
        if let rangeStart = text.range(of: "[CANVA_DESIGN:"),
           let rangeEnd = text.range(of: "]", range: rangeStart.upperBound..<text.endIndex) {
            
            let fullRange = rangeStart.lowerBound..<rangeEnd.upperBound
            var newText = text
            newText.removeSubrange(fullRange)
            return newText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return text
    }
    
    private func createCanvaDesignFromIntent(userMessage: String) async {
        print("🎨 Creating Canva design from user intent: \(userMessage)")
        
        // Show Canva creation indicator
        await MainActor.run {
            isCreatingCanva = true
        }
        
        // Check if user is authenticated
        if !CanvaService.shared.isAuthenticated() {
            await MainActor.run {
                showingCanvaAuth = true
                isCreatingCanva = false
            }
            return
        }
        
        // Extract design type from message
        let lowerMessage = userMessage.lowercased()
        var templateType = "presentation" // Default fallback
        
        if lowerMessage.contains("instagram") {
            if lowerMessage.contains("story") {
                templateType = "instagram_story"
            } else {
                templateType = "instagram_post"
            }
        } else if lowerMessage.contains("linkedin") {
            templateType = "linkedin_post"
        } else if lowerMessage.contains("facebook") {
            templateType = "facebook_post"
        } else if lowerMessage.contains("twitter") {
            templateType = "twitter_post"
        } else if lowerMessage.contains("logo") {
            templateType = "logo"
        } else if lowerMessage.contains("infographic") {
            templateType = "infographic"
        } else if lowerMessage.contains("presentation") {
            templateType = "presentation"
        } else if lowerMessage.contains("flyer") || lowerMessage.contains("poster") || lowerMessage.contains("banner") {
            templateType = "presentation" // Use presentation for general designs
        }
        
        // Extract title (use first few words after "create/make/design")
        var title = "Design"
        let words = userMessage.split(separator: " ")
        if let createIndex = words.firstIndex(where: { ["create", "make", "design", "generate"].contains($0.lowercased()) }) {
            let titleWords = words.dropFirst(createIndex + 1).prefix(5)
            title = titleWords.joined(separator: " ")
        }
        
        // Use the full message as content
        let content = userMessage
        
        print("🎨 Extracted - Type: \(templateType), Title: \(title)")
        
        do {
            let design = try await CanvaService.shared.createDesign(
                template: templateType,
                title: title,
                content: content
            )
            
            let designId = design.design.id
            let editUrl = design.design.urls.edit_url
            let viewUrl = design.design.urls.view_url
            let thumbnailUrl = design.design.thumbnail?.url
            
            await MainActor.run {
                isCreatingCanva = false
                HapticManager.shared.notification(.success)
                
                let canvaData = CanvaDesignData(
                    designId: designId,
                    title: title,
                    editUrl: editUrl,
                    viewUrl: viewUrl,
                    thumbnailUrl: thumbnailUrl
                )
                
                let aiMessage = Message(
                    text: "I've created your Canva design!",
                    isUser: false,
                    canvaDesigns: [canvaData]
                )
                messages.append(aiMessage)
                saveCurrentSession()
            }
        } catch {
            print("❌ Failed to create Canva design: \(error.localizedDescription)")
            await MainActor.run {
                isCreatingCanva = false
                let errorMessage = Message(
                    text: "I couldn't create the Canva design. Please make sure you're connected to Canva.",
                    isUser: false
                )
                messages.append(errorMessage)
            }
        }
    }
    
    private func processCanvaDesignCreation(from text: String) {
        // Tag format: [CANVA_DESIGN:templateType|Title 1,Title 2,Title 3]
        guard let parsed = geminiService.parseCanvaDesignTag(text) else { return }
        
        let templateType = parsed.template
        let titles = parsed.titles
        
        print("🎨 Detected Canva design request - Type: \(templateType), Titles: \(titles)")
        
        Task {
            // Show Canva creation indicator
            await MainActor.run {
                isCreatingCanva = true
            }
            
            // Check if user is authenticated
            if !CanvaService.shared.isAuthenticated() {
                await MainActor.run {
                    showingCanvaAuth = true
                }
                return
            }
            
            var createdDesigns: [CanvaDesignData] = []
            
            // We now search for real templates for the first title found (most relevant)
            // Or we could loop through all, but searching for the first one gives the best "list" of results usually
            if let firstTitle = titles.first {
                 do {
                     // 1. Try to find real templates with thumbnails
                     let designs = try await CanvaService.shared.findTemplates(from: "\(templateType) \(firstTitle)")
                     createdDesigns.append(contentsOf: designs)
                     
                     print("✅ Found \(designs.count) real templates via Web Search")
                     
                 } catch {
                     // 2. Fallback to Visual Proxy if search fails
                     print("⚠️ Template search failed: \(error). Falling back to deep link.")
                     
                     let searchUrl = CanvaService.shared.searchTemplatesURL(query: firstTitle, type: templateType)
                     let fallbackDesign = CanvaDesignData(
                        designId: UUID().uuidString,
                        title: firstTitle,
                        editUrl: searchUrl,
                        viewUrl: searchUrl,
                        thumbnailUrl: nil
                     )
                     createdDesigns.append(fallbackDesign)
                 }
            }
            
            await MainActor.run {
                isCreatingCanva = false
                
                if !createdDesigns.isEmpty {
                    HapticManager.shared.notification(.success)
                    
                    let aiMessage = Message(
                        text: "I've found these templates for you:",
                        isUser: false,
                        canvaDesigns: createdDesigns
                    )
                    messages.append(aiMessage)
                    saveCurrentSession()
                } else {
                    // Fallback (should theoretically not happen with this logic)
                    let errorMessage = Message(
                        text: "I couldn't find any templates right now.",
                        isUser: false
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func processCalendarEventCreation(from text: String) {
        // Pattern: CALENDAR_EVENT: [title] | [date/time]
        let pattern = #"CALENDAR_EVENT:\s*(.+?)\s*\|\s*(.+?)(?:\n|$)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges == 3 {
                let titleRange = match.range(at: 1)
                let dateRange = match.range(at: 2)
                
                let title = nsString.substring(with: titleRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let dateDescription = nsString.substring(with: dateRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("📅 Detected calendar event - Title: \(title), Date: \(dateDescription)")
                
                // Parse the date
                if let eventDate = CalendarManager.shared.parseDateTime(from: dateDescription) {
                    // Create a pending message immediately to show responsiveness? No, wait for success.
                    
                    Task {
                        let success = await CalendarManager.shared.addEvent(
                            title: title,
                            date: eventDate,
                            durationSeconds: 3600,
                            notes: "Created by Eclipse AI"
                        )
                        
                        if success {
                            print("✅ Calendar event created successfully")
                            await MainActor.run {
                                HapticManager.shared.notification(.success)
                                
                                // proper event data
                                let eventData = CalendarEventData(
                                    title: title, 
                                    date: eventDate, 
                                    duration: 3600, 
                                    notes: "Created by Eclipse AI"
                                )
                                
                                let aiMessage = Message(
                                    text: "I've added that to your calendar.",
                                    isUser: false,
                                    calendarEvent: eventData
                                )
                                messages.append(aiMessage)
                                saveCurrentSession()
                            }
                        } else {
                            print("❌ Failed to create calendar event")
                            await MainActor.run {
                                let errorMessage = Message(text: "I couldn't create that event. Please check your calendar permissions in Settings.", isUser: false)
                                messages.append(errorMessage)
                            }
                        }
                    }
                } else {
                    print("⚠️ Could not parse date: \(dateDescription)")
                }
            }
        }
    }
    
    private func startNewChat(withPlugin pluginId: String? = nil) {
        currentSessionID = UUID()
        currentPluginId = pluginId
        messages.removeAll()
        messageText = ""
        streamingText = ""
        showingGreeting = true
        isTextFieldFocused = false
        showingSidebar = false
        greetingText = getRandomGreeting()
        
        if let pluginId = pluginId, let app = appManager.availableApps.first(where: { $0.id == pluginId }) {
            currentChatTitle = app.name
        } else {
            currentChatTitle = isCodeMode ? "Technical Session" : "Eclipse"
        }
        
        isAutoScrollEnabled = true
    }
    
    private func saveCurrentSession() {
        guard !messages.isEmpty else { return }
        
        Task {
            // Generate AI title if we have at least 2 messages (one from user, one from AI)
            var title: String
            if messages.count >= 2 {
                do {
                    title = try await geminiService.generateChatTitle(from: messages)
                    // Limit title length
                    if title.count > 60 {
                        title = String(title.prefix(57)) + "..."
                    }
                } catch {
                    // Fallback to first user message if title generation fails
                    let firstUserMessage = messages.first(where: { $0.isUser })?.text ?? "New conversation"
                    title = String(firstUserMessage.prefix(50))
                }
            } else {
                // Use first message as title for new conversations
                let firstUserMessage = messages.first(where: { $0.isUser })?.text ?? "New conversation"
                title = String(firstUserMessage.prefix(50))
            }
            
            let preview = messages.last?.text.prefix(100).description ?? ""
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.currentChatTitle = title
                }
                historyService.saveSession(
                    id: currentSessionID,
                    title: title,
                    preview: preview,
                    messages: messages,
                    pluginId: currentPluginId
                )
            }
        }
    }
    
    private func loadSession(_ session: ChatSession) {
        currentSessionID = session.id
        currentPluginId = session.pluginId
        messages = session.messages
        currentChatTitle = session.title
        showingGreeting = false
        showingSidebar = false
        isAutoScrollEnabled = true
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    

}


// MARK: - Message Bubble View

struct MessageBubble: View {
    let message: Message
    var onCopy: (() -> Void)? = nil
    var isCodeMode: Bool = false
    var onRunCode: ((String, String) -> Void)? = nil
    var onImageEdited: ((UIImage) -> Void)? = nil
    @State private var showingSaveSuccess = false
    @State private var contentHeight: CGFloat = 40 // Initial estimated height
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                
                if let images = message.images, !images.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: images[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .contextMenu {
                                        imageContextMenu(for: uiImage)
                                    }
                            }
                        }
                        
                        if !message.text.isEmpty {
                            Text(message.text)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contextMenu {
                                    textContextMenu(for: message.text)
                                }
                        }
                    }
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
                } else if let calendarEvent = message.calendarEvent {
                     VStack(alignment: .leading, spacing: 12) {
                         if !message.text.isEmpty {
                             Text(message.text)
                                 .font(.system(size: 16))
                                 .foregroundStyle(.white)
                                 .padding(.horizontal, 16)
                                 .padding(.top, 12)
                         }
                         
                         CalendarEventPreview(event: calendarEvent)
                             .padding(.bottom, 8)
                             .padding(.horizontal, 8)
                     }
                     .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
                } else {
                    
                    Text(message.text)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
                        .contextMenu {
                            textContextMenu(for: message.text)
                        }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if let editData = message.imageEditData,
                       let images = message.images,
                       let firstImageData = images.first,
                       let uiImage = UIImage(data: firstImageData) {
                        
                        InteractiveImageEditorView(
                            image: uiImage,
                            adjustmentType: editData.type,
                            initialValue: editData.initialValue,
                            onApply: { editedImage in
                                // Save the edited image as a new message
                                onImageEdited?(editedImage)
                            },
                            onCancel: {
                                // Handle cancel - could dismiss the editor if needed
                            }
                        )
                        .frame(maxWidth: 300)
                        
                        if !message.text.isEmpty {
                            Text(message.text)
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))

                        }
                        
                    } else if let images = message.images, !images.isEmpty {
                        ForEach(images.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: images[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .contextMenu {
                                        imageContextMenu(for: uiImage)
                                    }
                            }
                        }
                    }
                    
                        LatexMarkdownView(
                            text: message.text, 
                            dynamicHeight: $contentHeight,
                            isCodeMode: isCodeMode,
                            onRunCode: onRunCode
                        )
                            .frame(height: contentHeight)
                            .padding(.horizontal, 0) // Full width support
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                            .contextMenu {
                                aiTextContextMenu(for: message.text)
                            }
                        
                        if let canvaDesigns = message.canvaDesigns, !canvaDesigns.isEmpty {
                            CanvaDesignCarousel(designs: canvaDesigns)
                                .padding(.bottom, 8)
                        } else if let mapData = message.mapData {
                            MapPreview(data: mapData)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        } else if let weatherData = message.weatherData {
                             WeatherCardView(data: weatherData)
                                .padding(.bottom, 12)
                        } else if let playlist = message.playlist {
                            PlaylistBubbleView(playlist: playlist)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                        } else if let musicEmbeds = message.musicEmbeds {
                            VStack(spacing: 8) {
                                ForEach(musicEmbeds) { embed in
                                    MusicEmbedBubbleView(data: embed)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                        } else if let healthDataList = message.healthData, !healthDataList.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(healthDataList) { healthData in
                                    HealthWidgetView(
                                        type: .init(rawValue: healthData.type) ?? .unknown,
                                        value: healthData.value,
                                        unit: healthData.unit
                                    )
                                }
                            }
                                .padding(.bottom, 12)
                        } 
                        
                        // NEW: Web Images (More Prominent)
                        if let webImages = message.webImageUrls, !webImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(webImages, id: \.self) { urlString in
                                        if let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.white.opacity(0.1))
                                                        .frame(width: 280, height: 200)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 280, height: 200)
                                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                        )
                                                case .failure:
                                                     RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.white.opacity(0.1))
                                                        .frame(width: 280, height: 200)
                                                        .overlay(
                                                            Image(systemName: "photo")
                                                                .font(.system(size: 24))
                                                                .foregroundStyle(.white.opacity(0.4))
                                                        )
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }// Action Toolbar
                        HStack(spacing: 8) {
                            Spacer()
                            actionButton(icon: "doc.on.doc", action: copyMessage)
                            actionButton(icon: "square.and.arrow.up", action: shareMessage)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 4)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .overlay(
            ZStack {
                if showingSaveSuccess {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Saved to Photos")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .padding(.top, 40)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .top)))
                }
            }
            )
    }

    
    // Action Button for Toolbar
    @ViewBuilder
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.05))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.text
        HapticManager.shared.notification(.success)
        onCopy?()
    }
    
    private func shareMessage() {
        HapticManager.shared.impact(.light)
        let av = UIActivityViewController(activityItems: [message.text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(av, animated: true, completion: nil)
        }
    }
    
    // Context menu for text messages
    @ViewBuilder
    private func textContextMenu(for text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            HapticManager.shared.notification(.success)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
    }
    
    // Context menu for AI-generated text (with regenerate option)
    @ViewBuilder
    private func aiTextContextMenu(for text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            HapticManager.shared.notification(.success)
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        Button {
            // Regenerate functionality would be handled by the parent view
            HapticManager.shared.impact(.medium)
        } label: {
            Label("Regenerate", systemImage: "arrow.clockwise")
        }
    }
    
    // Context menu for images
    @ViewBuilder
    private func imageContextMenu(for image: UIImage) -> some View {
        Button {
            UIPasteboard.general.image = image
            HapticManager.shared.notification(.success)
        } label: {
            Label("Copy Image", systemImage: "doc.on.doc")
        }
        
        Button {
            EclipseImageSaver.shared.saveImage(image) { success, error in
                if success {
                    HapticManager.shared.notification(.success)
                    withAnimation {
                        showingSaveSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSaveSuccess = false
                        }
                    }
                } else {
                    HapticManager.shared.notification(.error)
                    // Could show an error alert here
                }
            }
        } label: {
            Label("Save to Photos", systemImage: "square.and.arrow.down")
        }
        Button {
            // Share sheet would go here
            HapticManager.shared.impact(.light)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}



// MARK: - Image Generation Indicator (Liquid Glass Pill)

struct ImageGenerationIndicator: View {
        @State private var animationPhase: CGFloat = 0
        @State private var progress: CGFloat = 0
        @State private var currentTextIndex = 0
        @State private var shimmerOffset: CGFloat = -1.5
        
        private let statusTexts = [
            "Using imagination",
            "Magnifying details",
            "Crafting pixels",
            "Adding magic",
            "Shaping vision",
            "Dreaming in color",
            "Painting reality",
            "Conjuring visuals",
            "Weaving light",
            "Sculpting beauty",
            "Channeling creativity",
            "Mixing pigments",
            "Rendering dreams",
            "Forging artistry",
            "Summoning pixels",
            "Brewing colors",
            "Etching details",
            "Composing scenes",
            "Distilling essence",
            "Crafting wonder",
            "Molding perception",
            "Awakening visions",
            "Harmonizing hues",
            "Crystallizing ideas",
            "Infusing soul",
            "Assembling moments",
            "Polishing perfection",
            "Refining brilliance",
            "Kindling inspiration",
            "Orchestrating beauty",
            "Manifesting thoughts",
            "Birthing creation",
            "Illuminating concepts",
            "Capturing essence",
            "Designing reality",
            "Blending dimensions",
            "Invoking wonder",
            "Transcribing visions",
            "Fusing imagination",
            "Materializing dreams",
            "Arranging photons",
            "Generating wonder",
            "Bending light",
            "Coding beauty",
            "Processing magic",
            "Computing artistry",
            "Synthesizing vision",
            "Calculating wonder",
            "Analyzing aesthetics",
            "Optimizing beauty"
        ]
        
        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Animated sparkle icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .opacity(0.7 + Double(sin(animationPhase * .pi * 2)) * 0.3)
                        .scaleEffect(0.9 + Double(sin(animationPhase * .pi * 2)) * 0.1)
                    
                    // Rotating status text
                    Text(statusTexts[currentTextIndex])
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .id(currentTextIndex)
                }
                .frame(maxWidth: .infinity)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 3)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.8))
                            .frame(width: geometry.size.width * progress, height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                    
                    // Shimmer effect
                    LinearGradient(
                        colors: [
                            .white.opacity(0),
                            .white.opacity(0.15),
                            .white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            .frame(maxWidth: 300)
            .onAppear {
                // Sparkle animation
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    animationPhase = 1
                }
                
                // Progress animation
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    progress = 0.9
                }
                
                // Shimmer animation
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.5
                }
                
                // Text rotation timer
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentTextIndex = (currentTextIndex + 1) % statusTexts.count
                    }
                }
            }
        }
    }

// MARK: - Text Generation Indicator (Clean Minimalist)

struct TextGenerationIndicator: View {
        @State private var animationPhase: CGFloat = 0
        @State private var pulsePhase: CGFloat = 0
        @State private var shimmerOffset: CGFloat = -1.5
        
        var body: some View {
            HStack(spacing: 12) {
                // Animated thinking icon with pulse
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .opacity(0.6 + Double(sin(pulsePhase * .pi * 2)) * 0.3)
                    .scaleEffect(0.95 + Double(sin(pulsePhase * .pi * 2)) * 0.05)
                
                // Three animated dots with more dynamic movement
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.white)
                            .frame(width: 7, height: 7)
                            .opacity(dotOpacity(for: index))
                            .scaleEffect(dotScale(for: index))
                            .offset(y: dotOffset(for: index))
                    }
                }
                
                Text("Thinking")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.04))
                    
                    // Shimmer effect
                    LinearGradient(
                        colors: [
                            .white.opacity(0),
                            .white.opacity(0.1),
                            .white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            .onAppear {
                // Dot animation
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    animationPhase = 1
                }
                
                // Pulse animation for icon
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    pulsePhase = 1
                }
                
                // Shimmer animation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.5
                }
            }
        }
        
        private func dotOffset(for index: Int) -> CGFloat {
            let delay = Double(index) * 0.25
            let progress = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
            return CGFloat(sin(progress * .pi * 2)) * -5
        }
        
        private func dotOpacity(for index: Int) -> Double {
            let delay = Double(index) * 0.25
            let progress = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
            return 0.4 + (sin(progress * .pi * 2) * 0.5 + 0.5) * 0.6
        }
        
        private func dotScale(for index: Int) -> CGFloat {
            let delay = Double(index) * 0.25
            let progress = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
            return 0.7 + CGFloat((sin(progress * .pi * 2) * 0.5 + 0.5)) * 0.3
        }
    }

// MARK: - Image Analyzing Indicator

struct ImageAnalyzingIndicator: View {
        @State private var animationPhase: CGFloat = 0
        @State private var progress: CGFloat = 0
        @State private var currentTextIndex = 0
        @State private var shimmerOffset: CGFloat = -1.5
        
        private let statusTexts = [
            "Analyzing masterpiece",
            "Decoding visuals",
            "Interpreting imagery",
            "Reading the scene",
            "Understanding composition",
            "Examining details",
            "Processing artwork",
            "Studying aesthetics",
            "Inspecting elements",
            "Discovering nuances",
            "Evaluating artistry",
            "Perceiving depth",
            "Observing patterns",
            "Detecting features",
            "Recognizing subjects",
            "Appraising beauty",
            "Scanning pixels",
            "Comprehending vision",
            "Assessing quality",
            "Identifying themes",
            "Exploring content",
            "Measuring brilliance",
            "Investigating scene",
            "Parsing imagery",
            "Reviewing composition"
        ]
        
        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Animated eye icon
                    Image(systemName: "eye")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .opacity(0.7 + Double(sin(animationPhase * .pi * 2)) * 0.3)
                        .scaleEffect(0.9 + Double(sin(animationPhase * .pi * 2)) * 0.1)
                    
                    // Rotating status text
                    Text(statusTexts[currentTextIndex])
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .id(currentTextIndex)
                }
                .frame(maxWidth: .infinity)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 3)
                        
                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                    
                    // Shimmer effect
                    LinearGradient(
                        colors: [
                            .white.opacity(0),
                            .orange.opacity(0.15),
                            .white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            .frame(maxWidth: 300)
            .onAppear {
                // Eye animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animationPhase = 1
                }
                
                // Progress animation
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    progress = 0.85
                }
                
                // Shimmer animation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.5
                }
                
                // Text rotation timer
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentTextIndex = (currentTextIndex + 1) % statusTexts.count
                    }
                }
            }
        }
    }

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        @Environment(\.dismiss) var dismiss
        var sourceType: UIImagePickerController.SourceType
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let selectedImage = info[.originalImage] as? UIImage {
                    parent.image = selectedImage
                }
                parent.dismiss()
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.dismiss()
            }
        }
    }

// MARK: - Table Generation Indicator (Liquid Glass Pill)

struct TableGenerationIndicator: View {
        @State private var animationPhase: CGFloat = 0
        @State private var progress: CGFloat = 0
        @State private var currentTextIndex = 0
        @State private var shimmerOffset: CGFloat = -1.5
        
        private let statusTexts = [
            "Structuring data",
            "Organizing columns",
            "Building grid",
            "Aligning cells",
            "Formatting rows",
            "Calculating layout",
            "Arranging content",
            "Designing table",
            "Sorting elements",
            "Compiling view",
            "Processing fields",
            "Indexing data"
        ]
        
        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Animated grid icon
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .opacity(0.7 + Double(sin(animationPhase * .pi * 2)) * 0.3)
                        .scaleEffect(0.9 + Double(sin(animationPhase * .pi * 2)) * 0.1)
                    
                    // Rotating status text
                    Text(statusTexts[currentTextIndex])
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .id(currentTextIndex)
                }
                .frame(maxWidth: .infinity)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                            .shadow(color: .blue.opacity(0.5), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 4)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(width: 280)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.04))
                    
                    // Shimmer effect
                    LinearGradient(
                        colors: [
                            .white.opacity(0),
                            .white.opacity(0.1),
                            .white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset * 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            .onAppear {
                // Pulse animation for icon
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animationPhase = 1
                }
                
                // Progress animation
                withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                    progress = 0.8
                }
                
                // Shimmer animation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.5
                }
                
                // Text rotation timer
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentTextIndex = (currentTextIndex + 1) % statusTexts.count
                    }
                }
            }
        }
    }

// MARK: - Calendar Access Indicator

struct CalendarAccessIndicator: View {
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .scaleEffect(iconScale)
            
            Text("Checking Schedule")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
                // Shimmer effect
                LinearGradient(
                    colors: [
                        .white.opacity(0),
                        .white.opacity(0.15),
                        .white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset * 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        )
        .onAppear {
            // Icon animation
            withAnimation(.spring(duration: 0.6, bounce: 0.4).repeatForever(autoreverses: true)) {
                iconScale = 1.1
            }
            
            // Shimmer animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
}

// MARK: - Artifacts Access Indicator

struct ArtifactsAccessIndicator: View {
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .scaleEffect(iconScale)
            
            Text("Recalling Information")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
                // Shimmer effect
                LinearGradient(
                    colors: [
                        .white.opacity(0),
                        .purple.opacity(0.15),
                        .white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset * 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        )
        .onAppear {
            // Icon animation
            withAnimation(.spring(duration: 0.6, bounce: 0.4).repeatForever(autoreverses: true)) {
                iconScale = 1.1
            }
            
            // Shimmer animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
}


// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }



