//
//  MusicPersonalizationService.swift
//  Eclipse
//
//  Created by Claude on 12/21/25.
//

import Foundation
import MusicKit

/// Service for analyzing user's music taste and providing personalized recommendations
class MusicPersonalizationService {
    static let shared = MusicPersonalizationService()

    private init() {}

    // MARK: - Music Profile Generation

    /// Analyze user's listening history and create a profile
    func analyzeListeningHistory() async throws -> MusicPreferenceProfile {
        guard MusicAuthorizationManager.shared.isAuthorized else {
            throw MusicError.notAuthorized
        }

        // Fetch recent and top tracks
        let recentTracks = try await MusicService.shared.fetchRecentlyPlayed(limit: 50)
        let topTracks = try await MusicService.shared.fetchTopTracks(limit: 50)

        // Extract genres
        var genreCounts: [String: Int] = [:]
        for track in recentTracks + topTracks {
            for genre in track.genreNames {
                genreCounts[genre, default: 0] += 1
            }
        }
        let topGenres = genreCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }

        // Extract artists
        var artistCounts: [String: Int] = [:]
        for track in recentTracks + topTracks {
            artistCounts[track.artistName, default: 0] += 1
        }
        let topArtists = artistCounts.sorted { $0.value > $1.value }.prefix(10).map { $0.key }

        // Get recently played track names
        let recentlyPlayed = recentTracks.prefix(10).map { "\($0.title) - \($0.artistName)" }

        // Analyze decades (release years)
        var decadeCounts: [Int: Int] = [:]
        for track in topTracks {
            if let year = track.releaseDate?.year {
                let decade = (year / 10) * 10
                decadeCounts[decade, default: 0] += 1
            }
        }
        let favoredDecades = decadeCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

        return MusicPreferenceProfile(
            topGenres: Array(topGenres),
            topArtists: Array(topArtists),
            recentlyPlayed: Array(recentlyPlayed),
            favoredDecades: favoredDecades
        )
    }

    /// Generate a prompt extension for AI based on user's library
    func generatePersonalizationPrompt() async -> String {
        do {
            let profile = try await analyzeListeningHistory()

            var prompt = """
            ## USER'S MUSIC TASTE PROFILE:

            **Favorite Genres:**
            \(profile.topGenres.joined(separator: ", "))

            **Top Artists:**
            \(profile.topArtists.prefix(5).joined(separator: ", "))

            **Recently Played:**
            \(profile.recentlyPlayed.prefix(5).joined(separator: "\n"))

            **Preferred Decades:**
            \(profile.favoredDecades.map { "\($0)s" }.joined(separator: ", "))

            **Recommendation Strategy:**
            - When creating playlists, prioritize artists and genres the user already loves
            - Mix familiar songs from their library with new similar discoveries
            - Consider their decade preferences when suggesting throwback tracks
            - For workout/focus playlists, adapt to their usual energy levels
            - Include songs from their library when appropriate (mark with [LIBRARY] tag)
            """

            return prompt
        } catch {
            print("❌ Failed to analyze listening history: \(error)")
            return """
            ## USER'S MUSIC TASTE PROFILE:
            Music library access not available. Create playlists based on general preferences.
            """
        }
    }

    // MARK: - Smart Recommendations

    /// Get user's top genres
    func getTopGenres(limit: Int = 5) async throws -> [String] {
        let tracks = try await MusicService.shared.fetchTopTracks(limit: 50)
        var genreCounts: [String: Int] = [:]

        for track in tracks {
            for genre in track.genreNames {
                genreCounts[genre, default: 0] += 1
            }
        }

        return genreCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    /// Get user's top artists
    func getTopArtists(limit: Int = 10) async throws -> [String] {
        let tracks = try await MusicService.shared.fetchTopTracks(limit: 50)
        var artistCounts: [String: Int] = [:]

        for track in tracks {
            artistCounts[track.artistName, default: 0] += 1
        }

        return artistCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    /// Find similar songs in user's library
    func findSimilarInLibrary(to track: Track, limit: Int = 10) async throws -> [Track] {
        // Get tracks from same artist
        let allTracks = try await MusicService.shared.fetchTopTracks(limit: 200)

        // Filter by same artist or genre
        let similar = allTracks.filter { libraryTrack in
            libraryTrack.artistName == track.artistName ||
            !Set(libraryTrack.genreNames).isDisjoint(with: Set(track.genreNames))
        }

        return Array(similar.prefix(limit))
    }
}

// MARK: - Music Preference Profile

struct MusicPreferenceProfile {
    let topGenres: [String]
    let topArtists: [String]
    let recentlyPlayed: [String]
    let favoredDecades: [Int]

    /// Get a summary description
    var summary: String {
        var parts: [String] = []

        if !topGenres.isEmpty {
            parts.append("Loves \(topGenres.prefix(3).joined(separator: ", "))")
        }

        if !topArtists.isEmpty {
            parts.append("Frequently listens to \(topArtists.prefix(3).joined(separator: ", "))")
        }

        if !favoredDecades.isEmpty {
            parts.append("Enjoys music from the \(favoredDecades.map { "\($0)s" }.joined(separator: ", "))")
        }

        return parts.joined(separator: ". ")
    }
}

// MARK: - Date Extensions

extension Date {
    var year: Int? {
        let calendar = Calendar.current
        return calendar.component(.year, from: self)
    }
}
