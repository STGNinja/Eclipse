//
//  MusicCacheManager.swift
//  Eclipse
//
//  Created by Claude on 12/21/25.
//

import Foundation
import MusicKit

/// Manager for caching music data to improve performance
class MusicCacheManager {
    static let shared = MusicCacheManager()

    // Track caches
    private var trackCache: [String: Track] = [:]
    private var libraryStatusCache: [String: Bool] = [:]
    private var artworkURLCache: [String: URL] = [:]

    // Cache timestamps for expiration
    private var trackCacheTimestamps: [String: Date] = [:]
    private var libraryCacheTimestamp: Date?

    // Cache expiration times
    private let trackCacheExpiration: TimeInterval = 3600 // 1 hour
    private let libraryCacheExpiration: TimeInterval = 600 // 10 minutes

    private init() {
        // Start cleanup timer
        startCacheCleanup()
    }

    // MARK: - Track Caching

    /// Cache a track by title and artist
    func cacheTrack(_ track: Track, for title: String, artist: String) {
        let key = makeKey(title: title, artist: artist)
        trackCache[key] = track
        trackCacheTimestamps[key] = Date()
    }

    /// Get cached track
    func getCachedTrack(for title: String, artist: String) -> Track? {
        let key = makeKey(title: title, artist: artist)

        // Check if cache is expired
        if let timestamp = trackCacheTimestamps[key],
           Date().timeIntervalSince(timestamp) > trackCacheExpiration {
            // Expired, remove from cache
            trackCache.removeValue(forKey: key)
            trackCacheTimestamps.removeValue(forKey: key)
            return nil
        }

        return trackCache[key]
    }

    // MARK: - Library Status Caching

    /// Cache library status for a song
    func cacheLibraryStatus(_ isInLibrary: Bool, for title: String, artist: String) {
        let key = makeKey(title: title, artist: artist)
        libraryStatusCache[key] = isInLibrary
        libraryCacheTimestamp = Date()
    }

    /// Get cached library status
    func getCachedLibraryStatus(for title: String, artist: String) -> Bool? {
        // Check if cache is expired
        if let timestamp = libraryCacheTimestamp,
           Date().timeIntervalSince(timestamp) > libraryCacheExpiration {
            // Expired, clear cache
            libraryStatusCache.removeAll()
            libraryCacheTimestamp = nil
            return nil
        }

        let key = makeKey(title: title, artist: artist)
        return libraryStatusCache[key]
    }

    // MARK: - Artwork Caching

    /// Cache artwork URL
    func cacheArtworkURL(_ url: URL, for title: String, artist: String) {
        let key = makeKey(title: title, artist: artist)
        artworkURLCache[key] = url
    }

    /// Get cached artwork URL
    func getCachedArtworkURL(for title: String, artist: String) -> URL? {
        let key = makeKey(title: title, artist: artist)
        return artworkURLCache[key]
    }

    // MARK: - Cache Management

    /// Clear all caches
    func clearAll() {
        trackCache.removeAll()
        libraryStatusCache.removeAll()
        artworkURLCache.removeAll()
        trackCacheTimestamps.removeAll()
        libraryCacheTimestamp = nil
        print("🗑️ All music caches cleared")
    }

    /// Clear expired entries
    private func clearExpired() {
        let now = Date()

        // Clear expired tracks
        for (key, timestamp) in trackCacheTimestamps {
            if now.timeIntervalSince(timestamp) > trackCacheExpiration {
                trackCache.removeValue(forKey: key)
                trackCacheTimestamps.removeValue(forKey: key)
            }
        }

        // Clear expired library cache
        if let timestamp = libraryCacheTimestamp,
           now.timeIntervalSince(timestamp) > libraryCacheExpiration {
            libraryStatusCache.removeAll()
            libraryCacheTimestamp = nil
        }

        print("🧹 Cleared expired music caches")
    }

    /// Start periodic cache cleanup
    private func startCacheCleanup() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.clearExpired()
        }
    }

    // MARK: - Helper

    private func makeKey(title: String, artist: String) -> String {
        return "\(title.lowercased())-\(artist.lowercased())"
    }

    // MARK: - Cache Stats

    var stats: CacheStats {
        CacheStats(
            trackCacheSize: trackCache.count,
            libraryCacheSize: libraryStatusCache.count,
            artworkCacheSize: artworkURLCache.count
        )
    }
}

struct CacheStats {
    let trackCacheSize: Int
    let libraryCacheSize: Int
    let artworkCacheSize: Int

    var description: String {
        "Tracks: \(trackCacheSize), Library: \(libraryCacheSize), Artwork: \(artworkCacheSize)"
    }
}
