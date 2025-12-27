//
//  PlaylistBubbleView.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import SwiftUI
import MusicKit

struct PlaylistBubbleView: View {
    let playlist: PlaylistData
    @State private var playlistItems: [PlaylistData.SongItem] = []
    @State private var isExpanded = false
    @State private var isFetchingMetadata = false

    // NEW: Playback state
    @State private var resolvedTracks: [Track] = []
    @State private var isResolvingTracks = false
    @State private var libraryMatchStatus: [String: Bool] = [:]
    @StateObject private var playerState = MusicPlayerState.shared
    @StateObject private var authManager = MusicAuthorizationManager.shared
    @State private var showingAuthPrompt = false
    @State private var isPlayable = false
    @State private var libraryCount = 0
    @State private var catalogCount = 0

    init(playlist: PlaylistData) {
        self.playlist = playlist
        _playlistItems = State(initialValue: playlist.songs)
        _isPlayable = State(initialValue: playlist.isPlayable)
        _libraryCount = State(initialValue: playlist.libraryMatchCount)
        _catalogCount = State(initialValue: playlist.catalogMatchCount)
    }

    // Apple Music Icon URL
    private let musicIconUrl = "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Apple_Music_icon.svg/512px-Apple_Music_icon.svg.png"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 16) {
                // Actual Apple Music logo
                AsyncImage(url: URL(string: musicIconUrl)) { image in
                    image.resizable()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color(hex: "#FC3C44"), Color(hex: "#FF6B6B")], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.title)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    if let description = playlist.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Text("\(playlistItems.count) songs")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FC3C44"))
                }
                
                Spacer()
                
                // Pulsing indicator
                Circle()
                    .fill(Color(hex: "#FC3C44"))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#FC3C44").opacity(0.5), lineWidth: 4)
                            .scaleEffect(1.2)
                    )
            }
            .padding(20)
            
            // Song list (first 5 or all if expanded)
            VStack(alignment: .leading, spacing: 0) {
                let displaySongs = isExpanded ? playlistItems : Array(playlistItems.prefix(5))
                
                ForEach(displaySongs.indices, id: \.self) { index in
                    let song = displaySongs[index]
                    Button {
                        HapticManager.shared.impact(.light)
                        Task {
                            await playSong(at: index)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Artwork or Track number
                            ZStack {
                                if let artworkUrl = song.artworkUrl, let url = URL(string: artworkUrl) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.white.opacity(0.1)
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 40, height: 40)

                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }

                            // Song info
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(song.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    // Library badge
                                    if song.isInLibrary == true {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.green)
                                    }
                                }

                                Text(song.artist)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .lineLimit(1)

                                // Album name if available
                                if let album = song.albumName {
                                    Text(album)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.3))
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            Task { await playSong(at: index) }
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }

                        Button {
                            Task { await addToQueue(at: index) }
                        } label: {
                            Label("Add to Queue", systemImage: "text.badge.plus")
                        }

                        Button {
                            MusicService.shared.searchMusic(query: "\(song.title) \(song.artist)")
                        } label: {
                            Label("Open in Apple Music", systemImage: "apple.logo")
                        }
                    }
                }
                
                // Show more/less button
                if playlistItems.count > 5 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(isExpanded ? "Show less" : "View all tracks")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "#FC3C44"))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "#FC3C44"))
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            
            // Playback info banner
            if isPlayable && (libraryCount > 0 || catalogCount > 0) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))

                    if libraryCount > 0 && catalogCount > 0 {
                        Text("\(libraryCount) in library • \(catalogCount) in catalog")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    } else if libraryCount > 0 {
                        Text("\(libraryCount) in your library")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Text("\(catalogCount) available in Apple Music")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
            }

            // Action buttons
            HStack(spacing: 12) {
                // Play All / Pause button (if playable)
                if isPlayable {
                    Button {
                        Task {
                            await playAllSongs()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isResolvingTracks {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: playerState.currentPlaylistId == playlist.id && playerState.isPlaying ? "pause.fill" : "play.fill")
                            }
                            Text(playerState.currentPlaylistId == playlist.id && playerState.isPlaying ? "Pause" : "Play All")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "#FC3C44").opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .disabled(isResolvingTracks)

                    // Queue button
                    Button {
                        Task {
                            await queueAllSongs()
                        }
                    } label: {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(14)
                    }
                    .disabled(isResolvingTracks)
                } else {
                    // Fallback to "Open Music" if not playable
                    Button {
                        HapticManager.shared.impact(.medium)
                        MusicService.shared.searchMusic(query: playlist.title)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                            Text("Open Music")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FC3C44"), Color(hex: "#FF2D55")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "#FC3C44").opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                }

                Button {
                    HapticManager.shared.impact(.light)
                    sharePlaylist()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(14)
                }
            }
            .padding(20)
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .task {
            // Fetch artwork for any items that don't have it yet
            if playlistItems.contains(where: { $0.artworkUrl == nil }) {
                await fetchArtwork()
            }

            // Resolve tracks for playback
            await resolveTracks()
        }
        .alert("Music Library Access Required", isPresented: $showingAuthPrompt) {
            Button("Open Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow Eclipse to access your Apple Music library in Settings to play music.")
        }
    }

    // MARK: - Playback Methods

    private func resolveTracks() async {
        guard !isResolvingTracks else { return }
        if !authManager.isAuthorized {
            // Try to request authorization
            let authorized = await authManager.ensureAuthorization()
            if !authorized {
                await MainActor.run {
                    showingAuthPrompt = true
                }
                return
            }
        }

        await MainActor.run {
            isResolvingTracks = true
        }

        // Resolve tracks (library first, then catalog)
        let resolutionResults = await MusicService.shared.resolveTracks(from: playlistItems)
        let tracks = resolutionResults.map { $0.track }

        // Update song items with metadata
        var updatedItems = playlistItems
        for (index, result) in resolutionResults.enumerated() {
            if index < updatedItems.count {
                let track = result.track
                updatedItems[index].musicKitId = track.id.rawValue
                
                // Update library status from resolution result
                updatedItems[index].isInLibrary = result.inLibrary
                
                // Track properties (available in MusicKit)
                if case .song(let song) = track {
                    updatedItems[index].albumName = song.albumTitle
                    updatedItems[index].isExplicit = song.contentRating == .explicit
                    updatedItems[index].duration = song.duration
                }
            }
        }

        // Update counts
        let libCount = resolutionResults.filter { $0.inLibrary }.count
        let totalResolved = resolutionResults.count

        await MainActor.run {
            resolvedTracks = tracks
            playlistItems = updatedItems
            isPlayable = !tracks.isEmpty
            libraryCount = libCount
            catalogCount = totalResolved - libCount
            isResolvingTracks = false
        }

        print("🎵 Resolved \(totalResolved) tracks (\(libCount) in library, \(totalResolved - libCount) in catalog)")
    }

    private func playAllSongs() async {
        guard !resolvedTracks.isEmpty else { return }

        // Check if this playlist is already playing
        if playerState.currentPlaylistId == playlist.id && playerState.isPlaying {
            // Pause
            do {
                try await MusicPlaybackController.shared.pause()
            } catch {
                print("❌ Pause failed: \(error)")
            }
        } else {
            // Play
            do {
                var playlistData = playlist
                playlistData.songs = playlistItems // Use updated items with metadata
                try await MusicPlaybackController.shared.playPlaylist(playlist: playlistData, songs: resolvedTracks)
            } catch {
                print("❌ Playback failed: \(error)")
                if case MusicError.notAuthorized = error {
                    await MainActor.run {
                        showingAuthPrompt = true
                    }
                }
            }
        }
    }

    private func queueAllSongs() async {
        guard !resolvedTracks.isEmpty else { return }

        do {
            var playlistData = playlist
            playlistData.songs = playlistItems
            try await MusicPlaybackController.shared.queuePlaylist(playlist: playlistData, songs: resolvedTracks)
        } catch {
            print("❌ Queue failed: \(error)")
        }
    }

    private func playSong(at index: Int) async {
        guard index < resolvedTracks.count else { return }

        do {
            var playlistData = playlist
            playlistData.songs = playlistItems
            try await MusicPlaybackController.shared.playSong(at: index, in: playlistData, songs: resolvedTracks)
        } catch {
            print("❌ Play song failed: \(error)")
            if case MusicError.notAuthorized = error {
                await MainActor.run {
                    showingAuthPrompt = true
                }
            }
        }
    }

    private func addToQueue(at index: Int) async {
        guard index < resolvedTracks.count else { return }

        let track = resolvedTracks[index]
        let player = ApplicationMusicPlayer.shared

        do {
            try await player.queue.insert(track, position: .tail)

            await MainActor.run {
                HapticManager.shared.notification(.success)
            }

            print("🎵 Added to queue: \(track.title)")
        } catch {
            print("❌ Failed to add to queue: \(error)")
        }
    }

    // MARK: - Helpers

    private func fetchArtwork() async {
        guard !isFetchingMetadata else { return }
        isFetchingMetadata = true
        
        var updatedItems = playlistItems
        for i in 0..<updatedItems.count {
            // Skip if we already have artwork (possibly loaded from history)
            if updatedItems[i].artworkUrl != nil && !updatedItems[i].artworkUrl!.contains("unsplash") {
                continue 
            }
            
            let songStr = "\(updatedItems[i].title) - \(updatedItems[i].artist)"
            let metadata = await MusicService.shared.fetchMetadata(for: songStr)
            
            // If artworkUrl is still nil (e.g. iTunes error), use a consistent high-quality fallback
            if let artwork = metadata.artworkUrl {
                updatedItems[i].artworkUrl = artwork
            } else {
                let hash = abs(songStr.hashValue) % 500
                // Use a generic but high-quality music-themed placeholder from Unsplash
                updatedItems[i].artworkUrl = "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&h=300&fit=crop&q=80&sig=\(hash)"
            }
            
            let result = updatedItems
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    playlistItems = result
                }
            }
        }
        
        isFetchingMetadata = false
    }
    
    private func sharePlaylist() {
        var text = "🎵 \(playlist.title)\n"
        if let description = playlist.description {
            text += "\(description)\n"
        }
        text += "\n"
        
        for (index, song) in playlistItems.enumerated() {
            text += "\(index + 1). \(song.title) - \(song.artist)\n"
        }
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
