//
//  AppDetailView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI

struct AppDetailView: View {
    let app: EclipseAppInfo
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appManager = AppManager.shared
    var onConnect: (() -> Void)? = nil
    @State private var showingConnectionSheet = false
    @State private var showingCanvaAuth = false
    @State private var showingMusicAuth = false
    @State private var showingHealthAuth = false
    @State private var connectedUserName: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(alignment: .top, spacing: 20) {
                        AppIconView(app: app, size: 80)
                            .shadow(radius: 10)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(app.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            
                            if appManager.isDownloaded(app.id) {
                                HStack {
                                    Button {
                                        HapticManager.shared.impact(.medium)
                                        appManager.removeApp(app.id)
                                        CanvaService.shared.signOut()
                                        connectedUserName = nil
                                    } label: {
                                        Text("Disconnect")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                    }
                                    .background(Color.red.opacity(0.2))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1))
                                    
                                    if let name = connectedUserName {
                                        Text(name)
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                            } else {
                                Button {
                                    HapticManager.shared.impact(.light)
                                    print("🕵️ [Debugger] AppDetail: Connect button tapped. showingConnectionSheet = true")
                                    showingConnectionSheet = true
                                } label: {
                                    Text("Connect")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                }
                                .glassEffect(.regular.tint(.white), in: .capsule)
                                .sheet(isPresented: $showingConnectionSheet) {
                                    ConnectionSheetView(app: app, onShowCanvaAuth: {
                                        print("🕵️ [Debugger] AppDetail: onShowCanvaAuth callback received from ConnectionSheet")
                                        showingConnectionSheet = false
                                        print("🕵️ [Debugger] AppDetail: Dismissed ConnectionSheet. Waiting 0.3s...")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            print("🕵️ [Debugger] AppDetail: Setting showingCanvaAuth = true")
                                            showingCanvaAuth = true
                                        }
                                    }, onShowMusicAuth: {
                                        print("🕵️ [Debugger] AppDetail: onShowMusicAuth callback received from ConnectionSheet")
                                        showingConnectionSheet = false
                                        print("🕵️ [Debugger] AppDetail: Dismissed ConnectionSheet. Waiting 0.3s...")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            print("🕵️ [Debugger] AppDetail: Setting showingMusicAuth = true")
                                            showingMusicAuth = true
                                        }
                                    }, onShowHealthAuth: {
                                        print("🕵️ [Debugger] AppDetail: onShowHealthAuth callback received")
                                        showingConnectionSheet = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            showingHealthAuth = true
                                        }
                                    }) {
                                        print("🕵️ [Debugger] AppDetail: onConnect callback received")
                                        onConnect?()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Text(app.description)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                    
                    // Screenshots Carousel
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Real screenshots if available
                            if let previews = app.previewImages, !previews.isEmpty {
                                ForEach(previews, id: \.self) { imageName in
                                    AppScreenshotView(imageName: imageName)
                                }
                            } else {
                                // Fallback mock screenshots
                                ForEach(0..<2) { index in
                                    ImagePreviewCard(index: index, tint: app.tintColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Sample Queries Section
                    if let queries = app.sampleQueries, !queries.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Try asking")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(queries, id: \.self) { query in
                                        Text(query)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .glassEffect(.regular.tint(.white.opacity(0.1)), in: .capsule)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("With this app, Eclipse can connect to \(app.name) so you can search the catalog, generate assets, and interact with your data—no subscription required. All users can discover more.")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        
                        InfoRow(label: "Category", value: app.category)
                        InfoRow(label: "Developer", value: app.developer)
                        InfoRow(label: "Capabilities", value: "Interactive, Writes")
                        
                        // App Store Link
                        if let appStoreUrl = app.appStoreUrl, let url = URL(string: appStoreUrl) {
                            Button {
                                HapticManager.shared.impact(.light)
                                UIApplication.shared.open(url)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.forward.app.fill")
                                        .foregroundStyle(Color(hex: app.tintColor))
                                    Text("View in App Store")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(16)
                            }
                            .glassEffect(.regular.tint(.white.opacity(0.05)), in: .rect(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Load stored name if available
            connectedUserName = CanvaService.shared.getStoredUserName()
            
            // If connected but no name stored, fetch it
            if app.id == "canva" && appManager.isDownloaded(app.id) && connectedUserName == nil {
                Task {
                    do {
                        let profile = try await CanvaService.shared.getUserProfile()
                        await MainActor.run {
                            connectedUserName = profile.display_name
                        }
                    } catch {
                        print("Failed to fetch profile on appear: \(error)")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                }
                .glassEffect(.regular.tint(.white.opacity(0.1)), in: .circle)
            }
        }
        .sheet(isPresented: $showingCanvaAuth) {
            CanvaAuthView(onSuccess: {
                print("🕵️ [Debugger] AppDetail: CanvaAuthView onSuccess callback")
                print("✅ Canva connected successfully!")
                // Download the app now that OAuth is complete
                appManager.downloadApp(app)
                
                // Fetch profile to show name
                Task {
                    do {
                        let profile = try await CanvaService.shared.getUserProfile()
                        await MainActor.run {
                            connectedUserName = profile.display_name
                        }
                    } catch {
                        print("Failed to fetch profile: \(error)")
                    }
                }
                
                onConnect?()
            })
        }
        .fullScreenCover(isPresented: $showingMusicAuth) {
            MusicAuthView(onSuccess: {
                print("🕵️ [Debugger] AppDetail: MusicAuthView onSuccess callback")
                print("✅ Apple Music connected successfully!")
                // Refresh logic if needed or just trigger connect callback
                appManager.downloadApp(app) // Ensure it's marked as downloaded if not already
                onConnect?()
                showingMusicAuth = false
            })
        }
        .sheet(isPresented: $showingHealthAuth) {
            HealthAuthView(onSuccess: {
                print("✅ HealthKit authorized!")
                appManager.downloadApp(app)
                onConnect?()
            })
        }
    }
}

struct ImagePreviewCard: View {
    let index: Int
    let tint: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [Color(hex: tint).opacity(0.3), Color(hex: tint).opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 280, height: 400)
            .overlay(
                VStack {
                    // Mock UI content
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 40)
                        .padding(20)
                    
                    ForEach(0..<4) { _ in
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 120, height: 12)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 80, height: 12)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    Spacer()
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct AppScreenshotView: View {
    let imageName: String
    
    var body: some View {
        ZStack {
            // Smooth rainbow gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.6, blue: 1.0),      // Soft blue
                    Color(red: 0.5, green: 0.4, blue: 0.9),      // Purple
                    Color(red: 0.9, green: 0.4, blue: 0.6),      // Pink
                    Color(red: 1.0, green: 0.6, blue: 0.4),      // Coral
                    Color(red: 1.0, green: 0.8, blue: 0.4)       // Gold
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Image content
            if let uiImage = loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(20)
            } else {
                // Fallback placeholder
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("Preview Unavailable")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 280, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func loadImage() -> UIImage? {
        // 1. Try named asset (no extension)
        if let image = UIImage(named: imageName) {
            return image
        }
        
        // 2. Try with extension in bundle if it was provided as just name
        let extensions = ["png", "jpg", "jpeg", "webp"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: imageName, ofType: ext),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        
        // 3. Try literal name if extensions were included in the string
        if let path = Bundle.main.path(forResource: imageName, ofType: nil),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        return nil
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundStyle(.white)
        }
        .font(.system(size: 15))
        .padding(.vertical, 8)
        .overlay(
            Divider().background(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}
