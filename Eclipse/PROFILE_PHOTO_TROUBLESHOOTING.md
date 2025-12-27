# Profile Photo Troubleshooting Guide

## Issue: Profile photo not persisting after app restart

### ✅ What I Fixed:

1. **Added Metadata to Upload**: Now includes cache control and content type
2. **Force Reload User**: After upload, explicitly reloads Firebase Auth user data
3. **Better State Management**: Clears local selected image after upload
4. **Fixed Haptic Feedback**: Removed HapticManager dependency, using UIKit directly
5. **Enhanced Logging**: More detailed console logs to debug issues

### 🔍 Debug Steps:

#### Step 1: Check Console Logs
When you upload a photo, look for these logs in Xcode console:

```
✅ Upload URL: https://firebasestorage.googleapis.com/...
✅ Profile photo uploaded and saved to Firebase Auth
✅ Profile updated in UI
```

If you see errors, note what they say.

#### Step 2: Verify in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Storage**
4. Navigate to `profile_photos/`
5. You should see a file named `{your-user-id}.jpg`
6. Click it and verify the image looks correct

#### Step 3: Check Firebase Auth Profile

1. In Firebase Console, go to **Authentication**
2. Click on **Users** tab
3. Find your user account
4. Check if the **Photo URL** field is populated
5. Copy the URL and paste it in a browser - does the image load?

#### Step 4: Test Scenarios

**Test 1: Upload and Stay in App**
- Upload photo
- Navigate away from Profile
- Come back to Profile
- Does the photo persist? ✅ or ❌

**Test 2: Upload and Force Quit**
- Upload photo
- Force quit the app (swipe up from app switcher)
- Reopen the app
- Go to Profile
- Does the photo show? ✅ or ❌

**Test 3: Check Sidebar**
- Upload photo
- Go back to main chat view
- Check the profile pill in sidebar
- Does it show the new photo? ✅ or ❌

### 🐛 Common Issues & Solutions:

#### Issue: "Permission denied" error
**Solution:**
- Check Firebase Storage rules are published
- Verify rules allow write for authenticated users
- Make sure the path is `profile_photos/{userId}.jpg`

#### Issue: Photo uploads but doesn't persist
**Solution:**
- The photo might be uploaded but not saved to Firebase Auth
- Check Authentication console for Photo URL
- The issue is likely in the `commitChanges()` step

#### Issue: Photo shows in Profile but not Sidebar
**Solution:**
- This is an AuthManager refresh issue
- The sidebar likely needs to re-read the user data
- Try signing out and back in to test

#### Issue: AsyncImage not loading
**Solution:**
- Could be a cache issue
- Try adding a cache-busting parameter: `?t=\(Date().timeIntervalSince1970)`
- Or clear AsyncImage cache

### 🔧 Additional Fixes to Try:

#### Fix 1: Add Cache Busting to AsyncImage

In ProfileView.swift and wherever you show the profile photo:

```swift
AsyncImage(url: URL(string: "\(photoURL.absoluteString)?t=\(Date().timeIntervalSince1970)")) { image in
    // ...
}
```

#### Fix 2: Force Refresh on View Appear

Add this to ProfileView:

```swift
.onAppear {
    Task {
        await authManager.refreshUserData()
    }
}
```

#### Fix 3: Add Debug Button

Temporarily add this button to see what's stored:

```swift
Button("Debug Photo URL") {
    if let url = Auth.auth().currentUser?.photoURL {
        print("📸 Current Photo URL: \(url.absoluteString)")
    } else {
        print("⚠️ No photo URL stored")
    }
}
```

### 📋 Checklist Before Testing:

- [ ] Firebase Storage rules are published
- [ ] Firebase Authentication is enabled
- [ ] Storage bucket exists in Firebase Console
- [ ] Internet connection is working
- [ ] User is signed in
- [ ] Photo picker permission granted

### 🧪 Test Script:

1. Open the app
2. Sign in (if not already)
3. Go to Settings → Profile
4. Tap the pencil icon on profile picture
5. Select a photo
6. Wait for upload (watch for progress indicator)
7. Check console logs for success message
8. Force quit the app
9. Reopen the app
10. Go to Profile again
11. **Result**: Photo should be there

### 📝 What to Report:

If it's still not working after these fixes, tell me:

1. What console logs you see when uploading
2. Whether the file appears in Firebase Storage console
3. Whether the Photo URL is populated in Firebase Authentication
4. Which test scenario fails (Test 1, 2, or 3)
5. Any error messages

### 🎯 Expected Behavior:

After uploading a photo:
1. ✅ Progress indicator shows during upload
2. ✅ Success haptic feedback
3. ✅ Photo appears immediately in Profile view
4. ✅ Photo appears in sidebar pill
5. ✅ Photo persists after force quit
6. ✅ Photo syncs across devices (if signed in on multiple devices)

---

**Pro Tip**: Check the Xcode console logs carefully. They'll tell you exactly where the process is failing!
