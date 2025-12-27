//
//  MusicEmbedBubbleView.swift
//  Eclipse
//
//  Created by Antigravity on 12/21/25.
//

import SwiftUI
import WebKit
import MusicKit

struct MusicEmbedBubbleView: View {
    let data: MusicEmbedData
    @State private var isPlayingNatively = false
    @State private var isLoading = true
    @State private var resolvedEmbedUrl: URL?
    @State private var resolutionFailed = false
    @StateObject private var playerState = MusicPlayerState.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var musicAuth = MusicAuthorizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User Account Context removed
            
            // Header for the specific track
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(data.artist)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Play Full Button (Only for subscribers)
                if musicAuth.hasSubscription {
                    Button {
                        playNatively()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Play Full")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: Color(hex: "#FC3C44").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Embed WebView or Fallback
            ZStack {
                if let url = resolvedEmbedUrl ?? (data.embedUrl != nil ? URL(string: data.embedUrl!) : nil) {
                    MusicWidgetWebView(url: url, isLoading: $isLoading)
                        .frame(height: 155)
                        .cornerRadius(14)
                        .opacity(isLoading ? 0 : 1)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                } else if resolutionFailed {
                    // Fallback UI
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.2))
                        
                        Text("Search Apple Music for this track")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        Button {
                            openInMusicApp()
                        } label: {
                            Text("Open App")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "#FC3C44"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().stroke(Color(hex: "#FC3C44"), lineWidth: 1.5))
                        }
                    }
                    .frame(height: 155)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                } else {
                    // Loading State
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 155)
                        .overlay(
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.white)
                                Text("Syncing with Apple Music...")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
                
                if isLoading && (resolvedEmbedUrl != nil || data.embedUrl != nil) && !resolutionFailed {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .onAppear {
            if data.embedUrl == nil && resolvedEmbedUrl == nil { resolveMetadata() } else { isLoading = false }
        }
    }

    // UserProfileHeader removed
    
    private func playNatively() {
        HapticManager.shared.impact(.medium)
        Task {
            do {
                // IMPORTANT: Search CATALOG, not Library, for full playback availability
                // This ensures we get a playable Song object from Apple Music
                if let track = try await MusicService.shared.searchCatalog(title: data.title, artist: data.artist) {
                    
                    // Verify if we can play catalog content
                    let subscription = try await MusicSubscription.current
                    if subscription.canPlayCatalogContent {
                        let tempPlaylist = PlaylistData(title: "Single Track", description: nil, songs: [PlaylistData.SongItem(title: data.title, artist: data.artist)])
                        try await MusicPlaybackController.shared.playSong(at: 0, in: tempPlaylist, songs: [track])
                    } else {
                        // Fallback if they have 'Authorized' status but no active subscription capability
                         print("⚠️ User authorized but cannot play catalog content. Opening app.")
                         openInMusicApp()
                    }
                } else { 
                    print("⚠️ Track not found in catalog for playback. Opening app.")
                    openInMusicApp() 
                }
            } catch { 
                print("❌ Playback error: \(error)")
                openInMusicApp() 
            }
        }
    }
    
    private func openInMusicApp() {
        let query = "\(data.title) \(data.artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "music://music.apple.com/search?term=\(query)") { UIApplication.shared.open(url) }
    }
    
    private func resolveMetadata() {
        Task {
            var trackId: String?
            do {
                if let track = try await MusicService.shared.searchCatalog(title: data.title, artist: data.artist) {
                    if case .song(let song) = track {
                        trackId = song.id.rawValue
                    }
                }
            } catch { print("⚠️ MusicKit search failed, trying public fallback") }
            
            if trackId == nil {
                trackId = await MusicService.shared.findCatalogIdUsingPublicAPI(title: data.title, artist: data.artist)
            }
            
            await MainActor.run {
                if let id = trackId {
                    self.resolvedEmbedUrl = URL(string: "https://embed.music.apple.com/us/album/placeholder/\(id)?i=\(id)&theme=auto")
                    self.isLoading = true
                } else {
                    self.resolutionFailed = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct MusicWidgetWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        // Important for sign-in popups and interactions
        
        let js = """
        var style = document.createElement('style');
        style.innerHTML = `
            .footer, .upsell-banner, .listen-on-apple-music, .action-footer, footer, 
            [class*="footer"], [class*="upsell"] { 
                display: none !important; 
            }
            body { background: transparent !important; }
        `;
        document.head.appendChild(style);
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator // Delegate UI handling to coordinator
        
        // Use a generic dark theme for the embed
        var request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: MusicWidgetWebView
        
        init(_ parent: MusicWidgetWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        // Handle popup windows (like the Apple Music sign-in)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            
            let popupWebView = WKWebView(frame: .zero, configuration: configuration)
            popupWebView.navigationDelegate = self
            popupWebView.uiDelegate = self
            
            let viewController = UIViewController()
            viewController.view = popupWebView
            
            // Presenting the popup on the top-most view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                
                // Find the top presented view controller
                var topController = rootVC
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                
                topController.present(viewController, animated: true)
            }
            
            return popupWebView
        }
        
        // Close the popup window when done
        func webViewDidClose(_ webView: WKWebView) {
            // Dismiss the view controller presenting this webview
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                
                 // Find the top presented view controller
                 var topController = rootVC
                 while let presented = topController.presentedViewController {
                     topController = presented
                 }
                 
                 // If the top controller is presenting something (likely our popup), dismiss it
                 topController.dismiss(animated: true)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
