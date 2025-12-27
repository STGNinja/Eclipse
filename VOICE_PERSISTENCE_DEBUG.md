# Voice Preference Persistence - Debug Guide

## Problem Statement
Voice selection changes correctly in Settings, works in the current session, but reverts to default (Puck) when the app is reopened.

## Root Cause Analysis

### Issue 1: Race Condition
**Problem:** `VoicePreferencesManager` was being initialized lazily (on first access), which could happen AFTER `GoogleLiveService` tried to read the voice preference.

**Sequence:**
1. App launches
2. GoogleLiveService.shared initializes (reads voice → gets default "Puck")
3. VoicePreferencesManager.shared initializes later (loads saved preference)
4. Voice is already set to Puck in the connection

**Fix:** Initialize `VoicePreferencesManager` early in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`

**Location:** EclipseApp.swift:17-19

### Issue 2: Silent Load Failures
**Problem:** No logging to see if preferences were actually being loaded from UserDefaults or Firebase.

**Fix:** Added comprehensive logging throughout load/save cycle.

**Locations:**
- VoicePreferencesManager.swift:136-141 (UserDefaults load)
- VoicePreferencesManager.swift:145-151 (UserDefaults save)
- VoicePreferencesManager.swift:54-86 (Firebase load)
- VoicePreferencesManager.swift:89-115 (Firebase save)

### Issue 3: No Verification
**Problem:** No way to confirm voice preference was actually read when setting up connection.

**Fix:** Added logging in GoogleLiveService when reading voice preference.

**Location:** GoogleLiveService.swift:284

## Enhanced Logging

### App Launch Sequence
You should now see this in Xcode console when app starts:

```
🎤 Voice preferences manager initialized on app launch
📱 User signed in, loading from Firebase: user@example.com
🔄 Loading voice preference from Firebase for: user@example.com
✅ Loaded voice preference from Firebase: Charon
```

OR (if Firebase fails):

```
🎤 Voice preferences manager initialized on app launch
📱 User signed in, loading from Firebase: user@example.com
🔄 Loading voice preference from Firebase for: user@example.com
❌ Error loading voice preference from Firebase: [error]
✅ Loaded voice from UserDefaults: Charon
```

OR (if not signed in):

```
🎤 Voice preferences manager initialized on app launch
📱 No user signed in, loading from UserDefaults
✅ Loaded voice from UserDefaults: Charon
```

### Voice Selection
When you select a voice in settings:

```
🔄 Attempting to save voice preference to Firebase...
   User: user@example.com
   Voice: Charon
✅ Voice preference saved to Firebase successfully!
   Confirmed: Charon
✅ Voice preference saved to UserDefaults: Charon
   Verified in UserDefaults: Charon
```

### Voice Chat Connection
When you start a voice chat:

```
🎤 [Setup] Configuring Gemini Live with voice: Charon (Charon)
```

## Testing Protocol

### Test 1: Fresh Install
1. Delete app from device
2. Reinstall
3. Sign in
4. Check console - should see:
   ```
   🎤 Voice preferences manager initialized on app launch
   📱 User signed in, loading from Firebase: [email]
   ⚠️ No Firebase data found for user, using default
   ⚠️ No voice in UserDefaults, using default: Puck
   ```
5. Voice should be Puck (default)

### Test 2: Change Voice
1. Go to Settings > Capabilities > Eclipse Live
2. Select "Charon"
3. Check console - should see Firebase save AND UserDefaults save
4. Start voice chat
5. Check console - should see:
   ```
   🎤 [Setup] Configuring Gemini Live with voice: Charon (Charon)
   ```

### Test 3: Restart App
1. Force quit app (swipe up from app switcher)
2. Reopen app
3. Check console immediately after launch:
   ```
   🎤 Voice preferences manager initialized on app launch
   📱 User signed in, loading from Firebase: [email]
   🔄 Loading voice preference from Firebase for: [email]
   ✅ Loaded voice preference from Firebase: Charon
   ```
4. Start voice chat
5. Verify voice is still Charon in console and by listening

### Test 4: Cross-Device Sync (if you have multiple devices)
1. Device A: Select "Fenrir"
2. Wait 3 seconds
3. Device B: Close and reopen app
4. Device B console should show:
   ```
   ✅ Loaded voice preference from Firebase: Fenrir
   ```

### Test 5: Offline Mode
1. Enable Airplane Mode
2. Select a voice
3. Console should show:
   ```
   ❌ Error saving voice preference to Firebase: [network error]
   ✅ Voice preference saved to UserDefaults: [voice]
   ```
4. Disable Airplane Mode
5. Select voice again - should sync to Firebase

## Debugging Checklist

If voice still doesn't persist after app restart:

### ✅ Check Console on App Launch
Look for:
```
🎤 Voice preferences manager initialized on app launch
```

**If missing:** VoicePreferencesManager isn't being initialized early enough

### ✅ Check Load Sequence
After the init line, you should see ONE of:
- `✅ Loaded voice preference from Firebase: [voice]`
- `✅ Loaded voice from UserDefaults: [voice]`
- `⚠️ No voice in UserDefaults, using default: Puck`

**If all missing:** Preferences aren't loading at all (check if init method is being called)

### ✅ Check Voice Selection
When changing voice, you should see:
- `🔄 Attempting to save voice preference to Firebase...`
- Either success OR error with UserDefaults fallback

**If missing:** Save method isn't being called (check button connection)

### ✅ Check Voice Application
When starting voice chat:
```
🎤 [Setup] Configuring Gemini Live with voice: [name] ([rawValue])
```

**If shows "Puck" when you selected something else:**
- Preference loaded too late
- Preference save failed
- Wrong preference being read

### ✅ Verify UserDefaults Directly
In Xcode console, run:
```swift
print(UserDefaults.standard.string(forKey: "selectedGeminiVoice") ?? "nil")
```

Should print the voice name (e.g., "Charon")

**If prints "nil":** UserDefaults save is failing

## Common Issues & Solutions

### Issue: Voice is Puck every time, even after changing
**Possible causes:**
1. UserDefaults save failing
2. Preferences loaded before Firebase completes
3. App using cached GoogleLiveService instance

**Solution:** Check console for save confirmation. Should see:
```
✅ Voice preference saved to UserDefaults: [voice]
   Verified in UserDefaults: [voice]
```

### Issue: Voice changes but only for current session
**Possible cause:** Firebase saves but UserDefaults doesn't, and Firebase takes too long to load

**Solution:** Verify you see BOTH saves:
```
✅ Voice preference saved to Firebase successfully!
✅ Voice preference saved to UserDefaults: [voice]
```

### Issue: Firebase errors every time
**Possible causes:**
1. Firestore security rules blocking writes
2. Network issues
3. Auth token issues

**Solution:** UserDefaults fallback should still work. If it doesn't, there's a second issue.

## Firebase Security Rules

If you see permission errors, update Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null &&
                            request.auth.token.email == userId;
    }
  }
}
```

## Files Modified

1. **EclipseApp.swift** - Early initialization of VoicePreferencesManager
2. **VoicePreferencesManager.swift** - Enhanced logging throughout
3. **GoogleLiveService.swift** - Log which voice is being used

## Success Criteria

After these fixes, you should:
1. ✅ See voice preference load on app start
2. ✅ See voice preference save when changed
3. ✅ Have voice persist across app restarts
4. ✅ Have voice sync across devices (if signed in)
5. ✅ Have complete visibility into what's happening via logs

---

Last Updated: December 17, 2025
Status: Testing Required
