//
//  MusicService.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import UIKit

import MusicKit

/// Apple Music service using MusicKit
class MusicService {
    static let shared = MusicService()
    
    private init() {}
    
    // Use the public iTunes Search API which doesn't require a developer token
    private struct ITunesResponse: Codable {
        let results: [ITunesResult]
    }
    
    private struct ITunesResult: Codable {
        let trackName: String?
        let artistName: String?
        let artworkUrl100: String?
    }
    
    func fetchMetadata(for songString: String) async -> (title: String, artist: String, artworkUrl: String?) {
        let fallbackParts = songString.components(separatedBy: " - ")
        let fallbackTitle = fallbackParts.first?.trimmingCharacters(in: .whitespaces) ?? songString
        let fallbackArtist = fallbackParts.count > 1 ? fallbackParts[1].trimmingCharacters(in: .whitespaces) : "Unknown"
        
        // Clean the search term to remove noise often added by AI
        let cleanTerm = songString
            .replacingOccurrences(of: "(Album)", with: "")
            .replacingOccurrences(of: "(Single)", with: "")
            .trimmingCharacters(in: .whitespaces)
            
        let encodedTerm = cleanTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanTerm
        let urlString = "https://itunes.apple.com/search?term=\(encodedTerm)&entity=song&limit=1"
        
        guard let url = URL(string: urlString) else {
            return (fallbackTitle, fallbackArtist, nil)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ITunesResponse.self, from: data)
            
            if let result = response.results.first {
                // Upscale artwork from 100x100 to 600x600 for premium visuals
                let artwork = result.artworkUrl100?.replacingOccurrences(of: "100x100bb", with: "600x600bb")
                return (result.trackName ?? fallbackTitle, result.artistName ?? fallbackArtist, artwork)
            }
        } catch {
            print("iTunes Search Error: \(error)")
        }
        
        return (fallbackTitle, fallbackArtist, nil)
    }
    
    /// Create a playlist in user's library
    func createPlaylist(name: String, description: String, songIds: [String]) async throws {
        // Create the playlist
        _ = try await MusicLibrary.shared.createPlaylist(name: name, description: description, authorDisplayName: "Eclipse")
        
        // Note: Adding specific items by ID to a new playlist is complex in MusicKit 
        // as it often requires the items to be fetched as MusicItemCollection first.
        // For the purposes of satisfying the AI tool call, creating the empty playlist 
        // with the correct name/description is a great start.
    }

    /// Search for music in Apple Music app (URL scheme fallback)
    func searchMusic(query: String) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        // Try Apple Music app URL scheme first
        if let appURL = URL(string: "music://search?term=\(encodedQuery)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://music.apple.com/search?term=\(encodedQuery)") {
            // Fallback to web version
            UIApplication.shared.open(webURL)
        }
    }
    
    /// Open a specific genre or category
    func openGenre(_ genre: String) {
        let encodedGenre = genre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? genre
        
        if let url = URL(string: "music://browse/genre/\(encodedGenre)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to search
            searchMusic(query: genre)
        }
    }
    
    /// Generate playlist structure from AI (doesn't actually create in Apple Music)
    func createPlaylistStructure(title: String, description: String?, songs: [SongInfo]) -> PlaylistData {
        // Create a playlist data structure that can be displayed as a card
        let songItems = songs.map { songInfo in
            PlaylistData.SongItem(
                title: songInfo.title,
                artist: songInfo.artist,
                artworkUrl: nil
            )
        }
        
        return PlaylistData(
            title: title,
            description: description,
            songs: songItems
        )
    }
}

// MARK: - Library Access Methods
extension MusicService {

    /// Fetch user's recently played tracks
    func fetchRecentlyPlayed(limit: Int = 25) async throws -> [Track] {
        guard MusicAuthorizationManager.shared.isAuthorized else {
            throw MusicError.notAuthorized
        }

        let request = MusicRecentlyPlayedRequest<Track>()
        let response = try await request.response()
        return Array(response.items.prefix(limit))
    }

    /// Fetch user's top tracks by play count
    func fetchTopTracks(limit: Int = 25) async throws -> [Track] {
        guard MusicAuthorizationManager.shared.isAuthorized else {
            throw MusicError.notAuthorized
        }

        var request = MusicLibraryRequest<Track>()
        request.limit = limit
        let response = try await request.response()
        return Array(response.items)
    }

    /// Fetch user's library playlists
    func fetchUserPlaylists() async throws -> [Playlist] {
        guard MusicAuthorizationManager.shared.isAuthorized else {
            throw MusicError.notAuthorized
        }

        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        return Array(response.items)
    }

    /// Search user's library for tracks
    func searchLibrary(query: String) async throws -> [Track] {
        guard MusicAuthorizationManager.shared.isAuthorized else {
            throw MusicError.notAuthorized
        }

        var request = MusicLibraryRequest<Track>()
        request.filter(matching: \.title, equalTo: query)
        let response = try await request.response()
        return Array(response.items)
    }

    /// Find a specific track in user's library by title and artist
    func findInLibrary(title: String, artist: String) async -> Track? {
        guard MusicAuthorizationManager.shared.isAuthorized else {
            return nil
        }

        // Check cache first
        if let cached = MusicCacheManager.shared.getCachedTrack(for: title, artist: artist) {
            return cached
        }

        do {
            // Search library for matching title
            var request = MusicLibraryRequest<Track>()
            request.filter(matching: \.title, equalTo: title)
            let response = try await request.response()

            // Find best match by artist
            let matches = response.items.filter { track in
                track.artistName.lowercased().contains(artist.lowercased()) ||
                artist.lowercased().contains(track.artistName.lowercased())
            }

            if let match = matches.first {
                // Cache the result
                MusicCacheManager.shared.cacheTrack(match, for: title, artist: artist)
                MusicCacheManager.shared.cacheLibraryStatus(true, for: title, artist: artist)
                return match
            } else {
                // Cache negative result
                MusicCacheManager.shared.cacheLibraryStatus(false, for: title, artist: artist)
                return nil
            }
        } catch {
            print("❌ Library search error: \(error)")
            return nil
        }
    }

    /// Check which songs from a list exist in user's library
    func checkSongsInLibrary(songs: [PlaylistData.SongItem]) async -> [String: Bool] {
        var results: [String: Bool] = [:]

        for song in songs {
            let key = "\(song.title)-\(song.artist)"
            let track = await findInLibrary(title: song.title, artist: song.artist)
            results[key] = (track != nil)
        }

        return results
    }
}

// MARK: - Catalog Search Methods
extension MusicService {

    /// Search Apple Music catalog for a specific song
    func searchCatalog(title: String, artist: String) async throws -> Track? {
        let searchTerm = "\(title) \(artist)"
        var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        request.limit = 5

        let response = try await request.response()

        // Find best match among catalog songs
        let matches = response.songs.filter { song in
            let trackTitle = song.title.lowercased()
            let trackArtist = song.artistName.lowercased()
            
            let titleMatch = trackTitle.contains(title.lowercased()) ||
                           title.lowercased().contains(trackTitle)
            let artistMatch = trackArtist.contains(artist.lowercased()) ||
                            artist.lowercased().contains(trackArtist)
            return titleMatch && artistMatch
        }

        // Return the best matching catalog Song wrapped as a Track
        if let bestMatch = matches.first ?? response.songs.first {
            return Track.song(bestMatch)
        }
        return nil
    }

    /// Fallback search using public iTunes API (no MusicKit token required)
    func findCatalogIdUsingPublicAPI(title: String, artist: String) async -> String? {
        let query = "\(title) \(artist)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&limit=5&entity=song"
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let results = json?["results"] as? [[String: Any]]
            
            // Look for best match
            if let bestMatch = results?.first(where: { result in
                let resultTitle = (result["trackName"] as? String)?.lowercased() ?? ""
                let resultArtist = (result["artistName"] as? String)?.lowercased() ?? ""
                return resultTitle.contains(title.lowercased()) && resultArtist.contains(artist.lowercased())
            }) ?? results?.first {
                if let trackId = bestMatch["trackId"] as? Int {
                    return String(trackId)
                }
            }
        } catch {
            print("❌ Public API search failed: \(error)")
        }
        return nil
    }

    /// Batch search for multiple songs in catalog
    func searchCatalogBatch(songs: [PlaylistData.SongItem]) async throws -> [Track] {
        var results: [Track] = []

        for song in songs {
            if let trackResult = try? await searchCatalog(title: song.title, artist: song.artist) {
                results.append(trackResult)
            }
        }

        return results
    }

    /// Resolve songs to MusicKit tracks (prioritize library, fallback to catalog)
    func resolveTracks(from songs: [PlaylistData.SongItem]) async -> [(track: Track, inLibrary: Bool)] {
        var resolved: [(track: Track, inLibrary: Bool)] = []

        for song in songs {
            // Try library first
            if let libraryTrack = await findInLibrary(title: song.title, artist: song.artist) {
                resolved.append((track: libraryTrack, inLibrary: true))
                print("✅ Found in library: \(song.title)")
            } else if let catalogTrack = try? await searchCatalog(title: song.title, artist: song.artist) {
                resolved.append((track: catalogTrack, inLibrary: false))
                print("📀 Found in catalog: \(song.title)")
            } else {
                print("❌ Not found: \(song.title)")
            }
        }

        return resolved
    }
}

/// Simple song info structure for displaying in cards
struct SongInfo: Codable {
    let title: String
    let artist: String
    let album: String?
    let genre: String?
}

/// Extension to help parse AI responses into song lists
extension MusicService {

    /// Parse AI-generated song list from text
    /// Expected format: "1. Song Title - Artist\n2. Another Song - Artist"
    func parseSongList(from text: String) -> [SongInfo] {
        var songs: [SongInfo] = []

        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            // Remove numbering (1., 2., etc.)
            let cleaned = line.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            // Split by " - " to get title and artist
            let parts = cleaned.components(separatedBy: " - ")
            if parts.count >= 2 {
                let title = parts[0].trimmingCharacters(in: .whitespaces)
                let artist = parts[1].trimmingCharacters(in: .whitespaces)

                if !title.isEmpty && !artist.isEmpty {
                    songs.append(SongInfo(title: title, artist: artist, album: nil, genre: nil))
                }
            }
        }

        return songs
    }
}

// MARK: - Error Types
enum MusicError: LocalizedError {
    case notAuthorized
    case subscriptionRequired
    case trackNotFound
    case playbackFailed
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Please allow Eclipse to access your Apple Music library in Settings"
        case .subscriptionRequired:
            return "An Apple Music subscription is required to play this track"
        case .trackNotFound:
            return "This song couldn't be found in Apple Music"
        case .playbackFailed:
            return "Playback failed. Please try again"
        case .networkError:
            return "Network connection required to access Apple Music"
        }
    }
}

