# 🔧 Eclipse App - Build & Run Guide

## 🚀 Quick Start

1. **Clean Build Folder**: Press `⌘⇧K`
2. **Build**: Press `⌘B`
3. **Run**: Press `⌘R`

That's it! Your app should launch perfectly!

---

## ✅ Files Checklist

Make sure these files exist and are added to your target:

### Required Files:
- [ ] **ContentView.swift** - Main UI
- [ ] **GeminiService.swift** - API service
- [ ] **HistoryService.swift** - Storage
- [ ] **EclipseApp.swift** - App entry

### How to Check:
1. Select each file in Project Navigator
2. Open File Inspector (right sidebar)
3. Under "Target Membership", ensure "Eclipse" is checked ✅

---

## 🐛 Common Issues & Fixes

### Issue 1: "Cannot find ContentView"
**Fix:**
1. Select `ContentView.swift`
2. File Inspector → Target Membership
3. Check ✅ Eclipse

### Issue 2: "Cannot find type GeminiService"
**Fix:**
1. Select `GeminiService.swift`
2. File Inspector → Target Membership
3. Check ✅ Eclipse

### Issue 3: "Cannot find type HistoryService"
**Fix:**
1. Select `HistoryService.swift`
2. File Inspector → Target Membership
3. Check ✅ Eclipse
4. Make sure `import Combine` is at the top

### Issue 4: Streaming doesn't work / 404 errors
**Current Status:** Should be fixed with `gemini-pro:streamGenerateContent`
**Backup:** If streaming fails, the API has a fallback non-streaming mode

**To test without streaming (if needed):**
The `sendMessage()` function automatically falls back to collecting all chunks if streaming fails.

### Issue 5: Image not showing
**Fix:**
1. Make sure `betterlunr.PNG` is in your project
2. Check File Inspector → Target Membership → Eclipse ✅
3. Exact filename: `betterlunr.PNG` (capital PNG)

If image still doesn't show:
- The app shows a moon icon as fallback
- No crash, graceful degradation

### Issue 6: History not saving
**Check:**
1. Are you sending messages and getting responses?
2. Open sidebar - do you see conversations?
3. Close app completely (not just backgrounding)
4. Reopen - conversations should still be there

**Debug:**
```swift
// Add to ContentView to verify saving
private func saveCurrentSession() {
    guard !messages.isEmpty else { return }
    print("Saving session with \(messages.count) messages") // Add this
    // ... rest of function
}
```

---

## 🎯 Expected Behavior

### When You Type & Send:
1. Keyboard dismisses ✅
2. Your message appears ✅
3. Brief loading indicator ✅
4. AI response streams in (word by word) ✅
5. Auto-scroll follows ✅
6. Complete response saved ✅
7. Appears in sidebar history ✅

### When You Tap Text Field:
1. Keyboard slides up ✅
2. Logo shrinks (120→80pt) ✅
3. Text shrinks (32→24pt) ✅
4. Top space compresses (180→40pt) ✅
5. Smooth spring animation ✅

### When You Tap Outside:
1. Keyboard dismisses ✅
2. Logo grows back (80→120pt) ✅
3. Text grows back (24→32pt) ✅
4. Space expands (40→180pt) ✅
5. Smooth reverse animation ✅

### When You Open Sidebar:
1. Drawer slides in ✅
2. Main content scales down ✅
3. Main content fades ✅
4. Real conversations shown ✅
5. Can tap to load any chat ✅

---

## 📱 Testing Checklist

### Basic Functionality:
- [ ] App launches without crashes
- [ ] Greeting screen shows
- [ ] Can type in text field
- [ ] Send button works
- [ ] AI responds (may take 2-5 seconds)
- [ ] Response appears in chat

### Streaming (Real-time):
- [ ] Type: "Count from 1 to 10"
- [ ] Watch numbers appear one by one
- [ ] Auto-scroll follows

### Keyboard Animation:
- [ ] Tap text field
- [ ] Logo smoothly shrinks
- [ ] Text smoothly shrinks
- [ ] Tap outside
- [ ] Everything smoothly returns

### History:
- [ ] Have 2-3 conversations
- [ ] Open sidebar
- [ ] See all conversations listed
- [ ] Tap one to load it
- [ ] Close app completely
- [ ] Reopen app
- [ ] Sidebar still has conversations

### Markdown:
- [ ] Ask: "Show me **bold** and *italic*"
- [ ] See formatted text
- [ ] Text selection works

---

## 🔍 Debug Mode

### Enable Detailed Logging:

Add to `GeminiService.swift` in `sendMessageStream`:

```swift
for try await line in bytes.lines {
    print("Received line: \(line)") // Add this
    if line.hasPrefix("data: ") {
        // ... existing code
    }
}
```

Add to `ContentView.swift` in `sendMessage`:

```swift
for try await chunk in geminiService.sendMessageStream(userMessage) {
    print("Chunk received: \(chunk)") // Add this
    await MainActor.run {
        streamingText += chunk
    }
}
```

---

## 🌐 API Status

### Check if API is Working:

Test URL in browser or Postman:
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:streamGenerateContent?key=AIzaSyB15ga2_2OF9a6_vIpiKhhHJZLow_F17Ms

Body:
{
  "contents": [{
    "parts": [{
      "text": "Hello"
    }]
  }]
}
```

**Expected:** Streaming response with text chunks

---

## 💡 Pro Tips

### Performance:
- History saved in background thread (won't block UI)
- Streaming uses minimal memory
- Auto-scroll is optimized

### Keyboard:
- Tap anywhere to dismiss (background, scroll area, buttons)
- Return key also sends
- Send button disabled while sending

### History:
- Sessions auto-save after each message
- Oldest sessions stay at bottom
- Delete with trash icon in sidebar

---

## 📞 If Nothing Works

### Nuclear Option (Start Fresh):

1. **Delete all files**
2. **Re-add from scratch**:
   - ContentView.swift ✅
   - GeminiService.swift ✅
   - HistoryService.swift ✅
   - EclipseApp.swift ✅

3. **Verify target membership** for each
4. **Clean Build Folder** (⌘⇧K)
5. **Build** (⌘B)
6. **Run** (⌘R)

### Check Basic Setup:
- iOS Deployment Target: iOS 17.0+
- Swift Language Version: Swift 5.9+
- Xcode Version: 15.0+

---

## ✨ Success!

When everything works, you'll have:
- 🌙 Beautiful greeting screen
- 💬 Real-time streaming chat
- 📝 Markdown formatted responses
- 💾 Persistent history
- 🎨 Smooth animations
- 🎯 Professional polish

**Enjoy your Eclipse AI app!** 🚀
