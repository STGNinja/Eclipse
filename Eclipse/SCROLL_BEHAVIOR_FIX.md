# Scroll Behavior Fix - Break Auto-Scroll Loop

## Problem
When the AI was generating text, users were stuck in an auto-scroll loop. If they tried to scroll up to read previous messages, the auto-scroll would immediately pull them back down. The scroll-to-bottom button would only appear during generation and disappear as soon as the AI finished, making it hard to navigate back.

## Solution
Implemented a smart scroll-breaking mechanism with persistent button visibility:

### Key Changes

#### 1. **Button Visibility** (Line ~770)
- **Before**: Button only showed if `showScrollToBottomButton && (isLoading || !streamingText.isEmpty)`
- **After**: Button shows whenever `showScrollToBottomButton` is true (no extra conditions)
- **Impact**: Button persists after generation completes, giving users time to click it

#### 2. **Generation Completion** (Line ~1413)
- **Before**: Automatically re-enabled auto-scroll and hid button when AI finished
- **After**: Only re-enables auto-scroll if button isn't visible (respects user's scroll position)
```swift
// Only re-enable auto-scroll if button is not visible (user hasn't manually scrolled up)
if !showScrollToBottomButton {
    isAutoScrollEnabled = true
}
```

#### 3. **New Message Reset** (Line ~1097)
- Added logic to reset the scroll state when user sends a new message
- Ensures clean slate for next generation cycle
```swift
isAutoScrollEnabled = true
showScrollToBottomButton = false
```

#### 4. **Enhanced Scroll Detection** (Line ~701)
Added three distinct scroll behaviors:

**A. During Generation (Breaking the loop)**
```swift
// If user scrolls UP during generation, disable auto-scroll and show button
if (isLoading || !streamingText.isEmpty) && delta > 2 && isAutoScrollEnabled {
    isAutoScrollEnabled = false
    showScrollToBottomButton = true
}
```

**B. General Navigation (When not generating)**
```swift
// Show button if user scrolls up significantly when NOT generating
if delta > 50 && !isLoading && streamingText.isEmpty && !showScrollToBottomButton {
    showScrollToBottomButton = true
}
```

**C. Auto-Hide Near Bottom**
```swift
// Hide button if user manually scrolls back near the bottom
if delta < -20 && showScrollToBottomButton && !isLoading && streamingText.isEmpty {
    showScrollToBottomButton = false
    isAutoScrollEnabled = true
}
```

#### 5. **Improved Scroll Target** (Line ~780)
- **Before**: Scrolled to `"indicators"` which might not exist
- **After**: Scrolls to last actual message if streaming is done
```swift
if !streamingText.isEmpty {
    scrollProxy?.scrollTo("streaming", anchor: UnitPoint.bottom)
} else if let lastMessage = messages.last {
    scrollProxy?.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
}
```

## User Experience Flow

### Scenario 1: Breaking Auto-Scroll During Generation
1. AI starts generating → Auto-scroll enabled
2. User scrolls up → Auto-scroll **disabled**, button **appears**
3. AI finishes generating → Button **stays visible**
4. User clicks button → Scroll to bottom, button **hides**

### Scenario 2: Reading Old Messages
1. User scrolls up 50+ points → Button **appears**
2. User continues reading
3. User scrolls back down near bottom → Button **auto-hides**

### Scenario 3: Fresh Start
1. User sends new message → Button **hides**, auto-scroll **enabled**
2. Clean slate for next generation

## Technical Notes

**Delta Values:**
- `delta > 2`: Sensitive trigger during generation (catches small upward scrolls)
- `delta > 50`: General navigation trigger (avoids false positives from small movements)
- `delta < -20`: Near-bottom threshold (auto-hides button when user scrolls close to bottom)

**Scroll Direction:**
- Positive delta = Scrolling UP (content moving down)
- Negative delta = Scrolling DOWN (content moving up)

## Testing Checklist
- [x] Can break auto-scroll during AI generation
- [x] Button appears when scrolling up during generation
- [x] Button persists after generation completes
- [x] Button works to scroll back to bottom
- [x] Button hides when user sends new message
- [x] Button appears/hides during general navigation
- [x] Auto-scroll re-enables correctly after button click
- [x] No infinite loops or stuck states

## Files Modified
- `ContentView.swift`: Lines ~701, ~770, ~780, ~1097, ~1413
