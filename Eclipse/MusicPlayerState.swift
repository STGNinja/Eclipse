//
//  MusicPlayerState.swift
//  Eclipse
//
//  Created by Claude on 12/21/25.
//

import Foundation
import MusicKit
import SwiftUI
import Combine

/// Observable state manager for music playback
class MusicPlayerState: ObservableObject {
    static let shared = MusicPlayerState()

    @Published var isPlaying: Bool = false
    @Published var currentTrack: Track? = nil
    @Published var currentArtworkURL: URL? = nil
    @Published var playbackTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var currentPlaylistId: UUID? = nil
    @Published var currentPlaylistTitle: String? = nil

    // Queue management
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0

    // Playback state details
    @Published var isBuffering: Bool = false
    @Published var playbackRate: Float = 1.0

    private var cancellables = Set<AnyCancellable>()
    private var playbackObserver: Any?

    private var timer: Timer?

    private init() {
        startObservingPlayback()
    }

    deinit {
        stopObservingPlayback()
        timer?.invalidate()
    }

    // MARK: - Playback Observation

    /// Start observing system music player state
    func startObservingPlayback() {
        let player = SystemMusicPlayer.shared

        // Observe playback state changes
        player.state.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFromSystemPlayer()
            }
            .store(in: &cancellables)

        // Observe queue changes
        player.queue.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFromSystemPlayer()
            }
            .store(in: &cancellables)

        // Start timer for progress updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackTime()
            }
        }

        // Initial update
        updateFromSystemPlayer()

        print("🎵 Started observing music playback")
    }

    /// Stop observing playback
    func stopObservingPlayback() {
        cancellables.removeAll()
        timer?.invalidate()
        print("🎵 Stopped observing music playback")
    }

    /// Update state from system player
    @MainActor
    func updateFromSystemPlayer() {
        let player = SystemMusicPlayer.shared
        let state = player.state

        // Update playing status
        isPlaying = (state.playbackStatus == .playing)

        // Update current track from queue
        if let currentEntry = player.queue.currentEntry,
           let track = currentEntry.item as? Track {
            if currentTrack?.id != track.id {
                currentTrack = track
                currentArtworkURL = track.artwork?.url(width: 600, height: 600)
                totalDuration = track.duration ?? 0
                
                // Update current index if we have a queue
                if let index = queue.firstIndex(where: { $0.id == track.id }) {
                    currentIndex = index
                }
            }
        } else {
            // No current entry or track
            currentTrack = nil
            currentArtworkURL = nil
            totalDuration = 0
        }
        
        updatePlaybackTime()
    }

    @MainActor
    private func updatePlaybackTime() {
        playbackTime = SystemMusicPlayer.shared.playbackTime
    }

    // MARK: - Queue Management

    /// Set the current playlist being played
    func setCurrentPlaylist(id: UUID, title: String, tracks: [Track]) {
        currentPlaylistId = id
        currentPlaylistTitle = title
        queue = tracks
        currentIndex = 0
    }

    /// Clear current playlist
    func clearPlaylist() {
        currentPlaylistId = nil
        currentPlaylistTitle = nil
        queue = []
        currentIndex = 0
    }

    /// Get next track in queue
    var nextTrack: Track? {
        guard currentIndex + 1 < queue.count else { return nil }
        return queue[currentIndex + 1]
    }

    /// Get previous track in queue
    var previousTrack: Track? {
        guard currentIndex > 0 else { return nil }
        return queue[currentIndex - 1]
    }

    // MARK: - Helpers

    /// Format playback time as MM:SS
    var formattedPlaybackTime: String {
        formatTime(playbackTime)
    }

    /// Format total duration as MM:SS
    var formattedDuration: String {
        formatTime(totalDuration)
    }

    /// Progress as 0-1 value
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return playbackTime / totalDuration
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
