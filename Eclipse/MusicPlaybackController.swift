//
//  MusicPlaybackController.swift
//  Eclipse
//
//  Created by Claude on 12/21/25.
//

import Foundation
import MusicKit
import UIKit

/// Controller for music playback operations
class MusicPlaybackController {
    static let shared = MusicPlaybackController()
    private let player = SystemMusicPlayer.shared
    private let playerState = MusicPlayerState.shared

    private init() {}

    // MARK: - Playlist Playback

    /// Queue and play entire playlist
    func playPlaylist(playlist: PlaylistData, songs: [Track]) async throws {
        guard !songs.isEmpty else {
            throw MusicError.trackNotFound
        }

        // Add haptic feedback
        await MainActor.run {
            HapticManager.shared.impact(.medium)
        }

        // If playing catalog items, check if subscription is active
        let containsCatalogItems = songs.contains { track in
            // Library track IDs in MusicKit typically start with "i."
            // Catalog IDs are usually just numbers.
            !track.id.rawValue.hasPrefix("i.")
        }
        
        if containsCatalogItems && !MusicAuthorizationManager.shared.hasSubscription {
            print("⚠️ Playing catalog items without active subscription might fail")
        }

        // Set queue
        player.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: songs.first)

        // Update state
        await MainActor.run {
            playerState.setCurrentPlaylist(id: playlist.id, title: playlist.title, tracks: songs)
        }

        // Start playback
        try await player.play()

        // Success haptic
        await MainActor.run {
            HapticManager.shared.notification(.success)
        }

        print("🎵 Playing playlist: \(playlist.title) (\(songs.count) tracks)")
    }

    /// Add playlist to existing queue
    func queuePlaylist(playlist: PlaylistData, songs: [Track]) async throws {
        guard !songs.isEmpty else {
            throw MusicError.trackNotFound
        }

        // Add haptic feedback
        await MainActor.run {
            HapticManager.shared.impact(.light)
        }

        // Insert tracks at end of queue
        for song in songs {
            try await player.queue.insert(song, position: .tail)
        }

        await MainActor.run {
            HapticManager.shared.notification(.success)
        }

        print("🎵 Queued playlist: \(playlist.title) (\(songs.count) tracks)")
    }

    /// Play specific song from playlist
    func playSong(at index: Int, in playlist: PlaylistData, songs: [Track]) async throws {
        guard index < songs.count else {
            throw MusicError.trackNotFound
        }

        // Add haptic feedback
        await MainActor.run {
            HapticManager.shared.impact(.medium)
        }

        let selectedSong = songs[index]

        // Check if catalog track and subscription status
        let isCatalog = !selectedSong.id.rawValue.hasPrefix("i.")
        if isCatalog && !MusicAuthorizationManager.shared.hasSubscription {
            // If they don't have a subscription, opening in Apple Music app is the best experience
            openInAppleMusicApp(with: [selectedSong])
            return
        }

        // Set queue starting at selected song
        player.queue = SystemMusicPlayer.Queue(for: songs, startingAt: selectedSong)

        // Update state
        await MainActor.run {
            playerState.setCurrentPlaylist(id: playlist.id, title: playlist.title, tracks: songs)
            playerState.currentIndex = index
        }

        // Start playback
        do {
            try await player.play()
            
            // Success haptic
            await MainActor.run {
                HapticManager.shared.notification(.success)
            }
            
            print("🎵 Playing: \(selectedSong.title) - \(selectedSong.artistName)")
        } catch {
            print("❌ Playback failed: \(error)")
            // If failed, try opening in the official app as a last resort
            openInAppleMusicApp(with: [selectedSong])
            throw error
        }
    }

    // MARK: - Playback Controls

    /// Play or resume playback
    func play() async throws {
        try await player.play()

        await MainActor.run {
            HapticManager.shared.impact(.light)
        }
    }

    /// Pause playback
    func pause() async throws {
        player.pause()

        await MainActor.run {
            HapticManager.shared.impact(.light)
        }
    }

    /// Skip to next track
    func skipToNext() async throws {
        do {
            try await player.skipToNextEntry()

            await MainActor.run {
                HapticManager.shared.impact(.light)
                if playerState.currentIndex < playerState.queue.count - 1 {
                    playerState.currentIndex += 1
                }
            }
        } catch {
            print("❌ Skip to next failed: \(error)")
            throw MusicError.playbackFailed
        }
    }

    /// Skip to previous track
    func skipToPrevious() async throws {
        do {
            // If more than 3 seconds into track, restart it
            if playerState.playbackTime > 3 {
                try await player.restartCurrentEntry()
            } else {
                try await player.skipToPreviousEntry()

                await MainActor.run {
                    if playerState.currentIndex > 0 {
                        playerState.currentIndex -= 1
                    }
                }
            }

            await MainActor.run {
                HapticManager.shared.impact(.light)
            }
        } catch {
            print("❌ Skip to previous failed: \(error)")
            throw MusicError.playbackFailed
        }
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) async throws {
        // Note: ApplicationMusicPlayer doesn't have a direct seek method
        // This functionality may require using MPMusicPlayerController instead
        // For now, we'll skip this feature
        await MainActor.run {
            HapticManager.shared.impact(.light)
        }
        print("⚠️ Seek functionality not available in ApplicationMusicPlayer")
    }

    /// Stop playback and clear queue
    func stop() {
        player.pause()
        // Clearing queue by setting empty queue
        Task {
            player.queue = ApplicationMusicPlayer.Queue(for: [Track]())
            await MainActor.run {
                playerState.clearPlaylist()
                HapticManager.shared.impact(.light)
            }
        }

        print("🎵 Playback stopped")
    }

    // MARK: - Deep Linking

    /// Open playlist in Apple Music app with tracks queued
    func openInAppleMusicApp(with tracks: [Track]) {
        guard let firstTrack = tracks.first else { return }

        // Try to open with the track's native URL first (most reliable)
        if let trackUrl = firstTrack.url {
            UIApplication.shared.open(trackUrl)
            HapticManager.shared.impact(.medium)
            print("🎵 Opened track deep link: \(firstTrack.title)")
            return
        }

        // Fallback to search query
        let searchQuery = "\(firstTrack.title) \(firstTrack.artistName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    // MARK: - Queue Management

    /// Get current queue
    var currentQueue: [Track] {
        playerState.queue
    }

    /// Check if currently playing
    var isPlaying: Bool {
        playerState.isPlaying
    }

    /// Check if specific playlist is playing
    func isPlaylistPlaying(_ playlistId: UUID) -> Bool {
        playerState.currentPlaylistId == playlistId && playerState.isPlaying
    }
}
