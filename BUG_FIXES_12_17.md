# Bug Fixes - December 17, 2024

> **Note:** This document covers the first round of fixes. For additional fixes including the final streaming text fix, keyboard avoidance, redesigned orb, and delete all chats feature, see `BUG_FIXES_AND_FEATURES_12_17_PART2.md`

## Overview
Fixed three major bugs in the Eclipse AI app related to artifacts, text streaming, and UI design.

---

## Bug #1: Artifacts Auto-Saving Questions ❌→✅

### Problem
When asking questions like "why is the nba app taking up so much space on my device", the system was incorrectly saving these as artifacts. The artifact detection was too aggressive and wasn't distinguishing between user questions and actual personal information.

### Root Cause
The `detectAndSaveImportantInfo()` function in `ArtifactsManager.swift` only checked for keywords like "my", "I", etc., but didn't filter out questions or requests.

### Solution
Added intelligent question detection that checks for question keywords (what, why, how, when, where, who, can you, etc.) and skips saving if the message is clearly a question or request, even if it contains personal pronouns.

**Changes made in:** `ArtifactsManager.swift`

```swift
// Added question keyword detection
let questionKeywords = [
    "what", "why", "how", "when", "where", "who",
    "can you", "could you", "would you", "will you",
    "please", "help", "show me", "tell me",
    "explain", "describe", "is there", "are there",
    "do you", "does", "did"
]

// Skip if it's a question
guard !isQuestion else {
    print("💬 [Artifacts] Skipped question/request: \(message.prefix(50))...")
    return
}
```

### Result
✅ Questions are no longer incorrectly saved as artifacts
✅ Only genuine personal information is saved (e.g., "My name is John", "I love basketball")
✅ Better logging to track what's being skipped vs saved

---

## Bug #2: Text Blinking During AI Generation 🔄→✨

### Problem
When the AI was generating text, the streaming text would blink in and out during the generation process, creating a jarring visual experience.

### Root Cause
The `onChange(of: streamingText)` modifier was using `withAnimation { }` to scroll, which caused the entire message bubble to re-render with animation on every character change. This created a flickering/blinking effect.

### Solution
Removed the animation wrapper from the streaming text scroll behavior. Now the scroll happens smoothly without triggering visual animations on the text itself.

**Changes made in:** `ContentView.swift`

```swift
// Before:
.onChange(of: streamingText) { _, _ in
    if isAutoScrollEnabled {
        withAnimation {
            proxy.scrollTo("loading", anchor: .bottom)
        }
    }
}

// After:
.onChange(of: streamingText) { _, newValue in
    if isAutoScrollEnabled && !newValue.isEmpty {
        // Scroll without animation to prevent blinking
        proxy.scrollTo("loading", anchor: .bottom)
    }
}
```

### Result
✅ Streaming text appears smoothly without blinking
✅ Auto-scroll still works perfectly
✅ Better performance during text generation

---

## Bug #3: Missing Liquid Glass on Voice/Live Header Buttons 🔘→💎

### Problem
The header buttons in the Voice Chat and Gemini Live feature were using standard `.ultraThinMaterial` backgrounds instead of the modern Liquid Glass design with interactive effects.

### Root Cause
The buttons were manually styled with `.background(.ultraThinMaterial, in: Circle())` instead of using the newer `.glassEffect()` modifier with `.interactive()`.

### Solution
Replaced all header button backgrounds with proper Liquid Glass implementation using `.glassEffect(.regular.interactive(), in: .circle)`.

**Changes made in:** `VoiceChatSheet.swift`

#### Status Pill
```swift
// Before:
.background(.ultraThinMaterial, in: Capsule())

// After:
.glassEffect(.regular.interactive())
```

#### Camera Toggle Button
```swift
// Before:
.background(isCameraMode ? AnyShapeStyle(Color.white.opacity(0.2)) : AnyShapeStyle(.ultraThinMaterial), in: Circle())
.overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))

// After:
.glassEffect(.regular.interactive(), in: .circle)
```

#### Close Button
```swift
// Before:
.background(.ultraThinMaterial, in: Circle())
.overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))

// After:
.glassEffect(.regular.interactive(), in: .circle)
```

### Result
✅ All header buttons now use Liquid Glass design
✅ Interactive touch/pointer reactions enabled
✅ Consistent with modern iOS design language
✅ Automatic glass blurring, color reflection, and fluid animations
✅ Better visual hierarchy and depth

---

## Benefits of Liquid Glass

The Liquid Glass implementation provides:
- **Blur Effects**: Content behind the buttons is beautifully blurred
- **Color Reflection**: Buttons reflect surrounding colors and light
- **Interactive Reactions**: Responds to touch and pointer interactions in real-time
- **Fluid Morphing**: Can smoothly morph between shapes during transitions
- **Performance**: Optimized rendering by SwiftUI
- **Consistency**: Matches system UI patterns across iOS

---

## Testing Checklist

- [x] Artifacts no longer save questions
- [x] Streaming text displays without blinking
- [x] Voice chat header buttons have Liquid Glass
- [x] Interactive effects work on button press
- [x] No performance regressions
- [x] Logging shows proper artifact filtering

---

## Files Modified

1. **ArtifactsManager.swift** - Enhanced artifact detection logic
2. **ContentView.swift** - Fixed streaming text scroll animation
3. **VoiceChatSheet.swift** - Implemented Liquid Glass on header elements

---

## Additional Notes

These fixes improve the overall user experience by:
1. Preventing pollution of the artifacts database with irrelevant data
2. Creating a smoother, more professional text streaming experience
3. Adopting modern iOS design patterns for a premium feel

All changes maintain backward compatibility and don't affect existing functionality.
