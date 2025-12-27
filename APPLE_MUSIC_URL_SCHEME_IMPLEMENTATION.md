# Apple Music Plugin - URL Scheme Implementation

## Summary
Successfully migrated Apple Music integration from MusicKit API (requires paid developer account) to URL schemes (no developer account needed). The AI can now create beautiful playlist cards that users can search for in Apple Music.

## Changes Made

### 1. **AppManager.swift**
- ✅ Removed Apple Music official logo URL
- ✅ Now uses SF Symbol `music.note` instead
- ✅ Updated command preview to showcase playlist creation

```swift
logoUrl: nil, // Use SF Symbols instead of official logo
commandPreview: "@AppleMusic create playlist with top pop songs"
```

### 2. **MusicAppPlugin.swift**
- ✅ Removed `import MusicKit` dependency
- ✅ Updated system prompt for URL scheme workflow
- ✅ AI now generates playlists using `[PLAYLIST_UI:Title|Description|Song1 - Artist1,Song2 - Artist2,...]` format
- ✅ Playlists are displayed as beautiful cards (not actually created in Apple Music)

**How it works:**
- User asks: "@applemusic create a workout playlist"
- AI generates 15-25 songs and formats them with the PLAYLIST_UI tag
- ContentView extracts the playlist data and shows a card
- User can tap "Search in Apple Music" to find the songs

### 3. **MusicService.swift**
- ✅ Replaced MusicKit API calls with URL schemes
- ✅ `searchMusic(query:)` - Opens Apple Music app with search
- ✅ `openGenre(_:)` - Opens specific genre/category
- ✅ `createPlaylistStructure()` - Creates displayable playlist data
- ✅ Helper function to parse song lists from AI responses

**URL Schemes used:**
- `music://search?term=query` - Search in Apple Music app
- `https://music.apple.com/search?term=query` - Web fallback

### 4. **PlaylistBubbleView.swift**
- ✅ Complete redesign matching Eclipse's dark theme
- ✅ Gradient music icon (red/pink theme)
- ✅ Expandable song list (shows 5 by default, can expand to all)
- ✅ Track numbers and song/artist display
- ✅ "Search in Apple Music" button opens Apple Music app
- ✅ Share button to export playlist as text
- ✅ Beautiful glass effect styling

**Features:**
- Shows playlist title, description, and song count
- Lists all songs with title and artist
- Expands/collapses for long playlists
- Opens Apple Music with search query when tapped
- Share playlist via iOS share sheet

### 5. **MusicCardViews.swift** (NEW)
- ✅ Created helper views for music/map/calendar cards
- ✅ `PlaylistBubbleView` - Main playlist card component
- ✅ `MapPreview` - Map location card
- ✅ `CalendarEventPreview` - Calendar event card
- ✅ Reusable design components

### 6. **AppleMusicPlugin.swift** (NEW)
- ✅ Standalone helper service for URL scheme operations
- ✅ Search music functionality
- ✅ Open genre/category
- ✅ Create playlist structures
- ✅ Parse song lists from text

## How to Use

### As a User:
1. Connect Apple Music plugin from App Store
2. Start a new chat or type `@applemusic` in any chat
3. Ask to create a playlist: "create a chill study playlist"
4. AI generates 15-25 songs and displays them in a beautiful card
5. Tap "Search in Apple Music" to find the songs
6. Optionally share the playlist as text

### As a Developer:
The system automatically:
- Detects `@applemusic` mentions
- Passes `pluginId: "apple_music"` to GeminiService
- AI uses special prompt to format playlist data
- ContentView extracts `[PLAYLIST_UI:...]` tags
- Creates `PlaylistData` structure
- Renders `PlaylistBubbleView` card

## Benefits

✅ **No paid developer account needed**
✅ **No MusicKit token errors**
✅ **Beautiful UI with playlist cards**
✅ **AI can suggest playlists intelligently**
✅ **Users can search/share playlists**
✅ **Clean integration with Apple Music app**
✅ **SF Symbols icon (no copyright issues)**

## Limitations

❌ Cannot actually create playlists in Apple Music (requires MusicKit + paid account)
❌ Cannot search Apple Music API from within app
❌ Users must manually create playlist after seeing suggestions
❌ No access to user's Apple Music library

## Example Interaction

**User:** "@applemusic create a playlist with top pop songs"

**AI Response:**
```
[PLAYLIST_UI:Top Pop Hits 2024|The hottest pop songs dominating the charts right now|Anti-Hero - Taylor Swift,As It Was - Harry Styles,Flowers - Miley Cyrus,Kill Bill - SZA,Cruel Summer - Taylor Swift,Vampire - Olivia Rodrigo,Paint The Town Red - Doja Cat,Snooze - SZA,Greedy - Tate McRae,Lovin On Me - Jack Harlow,Used To Be Young - Miley Cyrus,Strangers - Kenya Grace,Water - Tyla,What Was I Made For? - Billie Eilish,Get Him Back! - Olivia Rodrigo]

I've created an amazing pop playlist for you! It features 15 chart-topping hits from Taylor Swift, Harry Styles, Miley Cyrus, and more. Tap "Search in Apple Music" to start listening!
```

**Result:** Beautiful card appears with all songs listed, expandable, with button to search Apple Music.

---

## Files Modified/Created

**Modified:**
- `AppManager.swift` - Removed logo URL
- `MusicAppPlugin.swift` - URL scheme system prompt
- `MusicService.swift` - URL scheme implementation
- `PlaylistBubbleView.swift` - Enhanced UI design

**Created:**
- `MusicCardViews.swift` - Helper view components
- `AppleMusicPlugin.swift` - URL scheme service

**No changes needed:**
- `ContentView.swift` - Already has playlist extraction logic
- `Message.swift` - Already has PlaylistData model
- `GeminiService.swift` - Already has plugin integration
