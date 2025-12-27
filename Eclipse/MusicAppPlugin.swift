//
//  MusicAppPlugin.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import UIKit

class MusicAppPlugin: AppPlugin {
    var appId: String = "apple_music"

    var systemPromptExtension: String {
        // Generate personalized prompt based on user's library
        let personalizationPrompt = Task {
            await MusicPersonalizationService.shared.generatePersonalizationPrompt()
        }

        // For now, use synchronous fallback (personalization will be added asynchronously)
        return """
        You are now connected to the Apple Music Plugin with FULL LIBRARY ACCESS and PLAYBACK CAPABILITIES.

        ## ENHANCED CAPABILITIES:
        - Access user's music library (recently played, favorites, top tracks)
        - Create PLAYABLE playlists that mix user's library with Apple Music catalog
        - Smart personalized recommendations based on user's listening history
        - Direct playback within the app

        ## USER'S MUSIC PROFILE:
        When creating playlists, consider the user's music taste from their library.
        Prioritize songs they already love and suggest similar new discoveries.

        ## HOW TO RECOMMEND MUSIC:
        You MUST use the [MUSIC_EMBED] tag for ALL music suggestions. Do NOT use any other playlist UI or custom tags.
        - For a single song: Use [MUSIC_EMBED:Song Title|Artist Name]
        - For multiple songs/playlists: Provide a sequence of [MUSIC_EMBED] tags, one for each song.
        
        ## MUSIC_EMBED FORMAT:
        [MUSIC_EMBED:Song Title|Artist Name]
        
        Example for a single song: [MUSIC_EMBED:Blinding Lights|The Weeknd]
        
        Example for a 'playlist' request (3 songs): 
        [MUSIC_EMBED:Song 1|Artist 1]
        [MUSIC_EMBED:Song 2|Artist 2]
        [MUSIC_EMBED:Song 3|Artist 3]

        ## MARKING LIBRARY SONGS:
        If you know or suspect a song is in the user's library, you can add a note in the text, but the tag remains:
        [MUSIC_EMBED:Song Title|Artist Name]
        
        However, the app will automatically detect library songs, so this is optional.

        ## CRITICAL RULES:
        - Use commas to separate individual songs
        - Format each song as: "Song Title - Artist Name"
        - Include 15-25 songs for a complete playlist
        - ALWAYS include this tag when creating a playlist
        - After the tag, add friendly text like "I've created this playlist for you! Tap 'Play All' to start listening."

        ## PLAYBACK FEATURES:
        - Playlists are now PLAYABLE directly in the app
        - Songs from user's library will be prioritized
        - Missing songs will be found in Apple Music catalog
        - Users can tap "Play All" to start listening immediately
        - Individual songs can be tapped to play
        - Songs can be added to queue

        ## EXAMPLE RESPONSE:
        [PLAYLIST_UI:Morning Energy Boost|Uplifting tracks to start your day with positive vibes|Good Vibrations - The Beach Boys,Three Little Birds - Bob Marley,Here Comes the Sun - The Beatles,Walking on Sunshine - Katrina and The Waves,Don't Stop Me Now - Queen,I Gotta Feeling - The Black Eyed Peas,Happy - Pharrell Williams,Lovely Day - Bill Withers,Best Day of My Life - American Authors,Can't Stop the Feeling - Justin Timberlake,Counting Stars - OneRepublic,Shut Up and Dance - Walk the Moon,On Top of the World - Imagine Dragons,Good Life - OneRepublic,September - Earth Wind & Fire]

        I've created a perfect morning playlist to boost your energy! Your music library has been checked, and matching songs will play directly. Tap "Play All" to start your day with great vibes!

        ## SMART RECOMMENDATIONS:
        - Suggest playlists based on time of day, mood, or activity
        - Create cohesive playlists that flow well
        - Balance familiar favorites with new discoveries
        - Consider tempo, energy, and genre compatibility
        - Personalize based on user's listening patterns
        """
    }

    func handleToolCall(name: String, arguments: [String : Any]) async throws -> String? {
        // URL scheme-based implementation - no actual API calls needed
        return nil
    }
}
