# Firebase Setup Guide for Eclipse

## ✅ What I've Already Done:

1. **Created Authentication System**
   - `AuthManager.swift` - Handles all Firebase authentication
   - `AuthenticationView.swift` - Sign in/Sign up UI
   - Integrated auth state into `EclipseApp.swift`
   - Connected Settings view with logout functionality
   - Added user profile display in sidebar

2. **Added Haptic Feedback**
   - All buttons now have haptic feedback
   - Light haptics for normal buttons
   - Medium haptics for important actions
   - Success/error haptics for authentication

3. **Created Settings View**
   - Matches your screenshot design
   - Shows user email
   - Profile, Billing, Capabilities sections
   - Appearance, Speech language, Notifications
   - Haptic feedback toggle
   - Log out with confirmation

## 🔧 What You Need to Do:

### Step 1: Add Firebase SDK to Your Project

**Option A: Using Swift Package Manager (Recommended)**

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version **11.0.0** or later
4. Select these packages:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseCore**
   - (Optional) FirebaseFirestore if you want to store data later

**IMPORTANT: Also add Google Sign-In SDK**

1. In Xcode, go to **File → Add Package Dependencies...** again
2. Enter this URL: `https://github.com/google/GoogleSignIn-iOS`
3. Select version **7.0.0** or later
4. Select **GoogleSignIn** package

**Option B: Using CocoaPods**

Add to your `Podfile`:
```ruby
pod 'Firebase/Auth'
pod 'Firebase/Core'
pod 'GoogleSignIn'
```

Then run: `pod install`

---

### Step 2: Download GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your **Eclipse** project
3. Click the **iOS** app (or create one if you haven't)
4. Download the **`GoogleService-Info.plist`** file
5. **Drag and drop** it into your Xcode project
   - ⚠️ Make sure "Copy items if needed" is **checked**
   - ⚠️ Make sure "Add to targets" includes your main app target

---

### Step 3: Enable Authentication in Firebase Console

1. In Firebase Console, go to **Authentication**
2. Click **Get Started** (if not already enabled)
3. Go to **Sign-in method** tab
4. Enable **Email/Password**
   - Toggle it **ON**
   - Save
5. Enable **Google Sign-In**
   - Click on **Google** provider
   - Toggle it **ON**
   - Enter your project support email
   - Save

---

### Step 4: Configure Google Sign-In URL Scheme

1. In Xcode, open your project settings
2. Select your app target
3. Go to the **Info** tab
4. Expand **URL Types**
5. Click **+** to add a new URL Type
6. In **URL Schemes**, add your **REVERSED_CLIENT_ID**
   - Find this in your `GoogleService-Info.plist` file
   - Look for the key `REVERSED_CLIENT_ID`
   - Copy the value (looks like: `com.googleusercontent.apps.123456789-abc`)
   - Paste it in the URL Schemes field

**Example:**
```
URL Schemes: com.googleusercontent.apps.123456789-abc
Identifier: (leave blank or use your bundle ID)
Role: Editor
```

---

### Step 5: Update Info.plist (If Needed)

Firebase should work automatically, but if you encounter issues, add this to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

(Get `YOUR_REVERSED_CLIENT_ID` from `GoogleService-Info.plist`)

---

## 🚀 How It Works Now:

### Authentication Flow

1. **App Launch**
   - `EclipseApp.swift` checks `AuthManager.isAuthenticated`
   - If **not authenticated** → Shows `AuthenticationView` (Sign In/Sign Up)
   - If **authenticated** → Shows `ContentView` (Main app)

2. **Sign Up**
   - User enters name, email, password
   - Creates Firebase account
   - Sets display name
   - Automatically signs in
   - Shows main app

3. **Sign In**
   - User enters email, password
   - Authenticates with Firebase
   - Shows main app

4. **Sign Out**
   - User clicks their name in sidebar → Opens Settings
   - Clicks "Log out" → Confirmation alert
   - Confirms → Signs out → Returns to Sign In screen

### User Profile Integration

- **Sidebar** shows user's name and initial
- **Settings** shows user's email
- Both update automatically from Firebase Auth

---

## 🎨 New Features Added:

### Haptic Feedback
- All buttons have tactile feedback
- Can be toggled in Settings → Haptic feedback

### Settings Screen
Includes all sections from your screenshot:
- ✅ Email display
- ✅ Profile
- ✅ Billing (with "Pro plan" badge)
- ✅ Capabilities
- ✅ Connectors
- ✅ Permissions
- ✅ Appearance (with System/Light/Dark selector)
- ✅ Speech language (EN)
- ✅ Notifications
- ✅ Privacy
- ✅ Shared links
- ✅ Haptic feedback toggle
- ✅ Log out button

---

## 🧪 Testing:

Once you've completed the setup:

1. **Run the app**
2. You should see the **Sign Up** screen
3. Create an account with:
   - Name: Your name
   - Email: Any valid email
   - Password: At least 6 characters
4. You should see the main Eclipse chat interface
5. Click your name in the sidebar → Settings should open
6. Test logging out

---

## 📝 Console Logs:

The app will print helpful messages:

- `✅ Successfully signed in: user@email.com`
- `✅ Successfully created account: user@email.com`
- `✅ Successfully signed out`
- `❌ Sign in error: [error message]`

Plus the Gemini model information on launch!

---

## 🐛 Troubleshooting:

**Problem:** "Could not find module 'Firebase'"
- **Solution:** Make sure you've added the Firebase SDK (Step 1)

**Problem:** "The default Firebase app has not yet been configured"
- **Solution:** Make sure `GoogleService-Info.plist` is in your project

**Problem:** Sign up fails with "weak password"
- **Solution:** Use at least 6 characters for password

**Problem:** "Email already in use"
- **Solution:** Use Sign In instead, or use a different email

---

## 🎉 Next Steps:

After Firebase is working, you could add:

1. **Firestore Integration** - Store chat history in the cloud
2. **Password Reset** - Already implemented in `AuthManager`, just wire up the UI
3. **Profile Editing** - Update display name, email
4. **Google Sign-In** - Add OAuth authentication
5. **Profile Photos** - Upload and display user avatars

Let me know when you've added the Firebase SDK and `GoogleService-Info.plist` and I'll help you test it!

---

## 🌟 NEW: Google Sign-In Added!

### What's New:

✅ **Google Sign-In Integration**
- "Continue with Google" button on Sign In screen
- "Continue with Google" button on Sign Up screen
- One-tap authentication with your Google account
- Automatic account creation if user doesn't exist
- Same experience as email/password sign-in

### How It Works:

1. User clicks **"Continue with Google"**
2. Google Sign-In popup appears
3. User selects their Google account
4. Automatically signed in to Eclipse
5. Display name and email pulled from Google account

### Setup Requirements:

1. **Add GoogleSignIn-iOS SDK** (Step 1 above)
2. **Enable Google provider in Firebase** (Step 3 above)
3. **Configure URL Scheme** (Step 4 above)
   - This is **REQUIRED** for Google Sign-In to work
   - Add your `REVERSED_CLIENT_ID` to URL Types

### UI Design:

The Google Sign-In button features:
- Clean, modern design with glass effect
- Globe icon
- "Continue with Google" text
- Positioned below email/password fields
- Separated by "OR" divider
- Same on both Sign In and Sign Up screens

### Benefits:

- ⚡️ Faster sign-in (no password typing)
- 🔒 More secure (Google handles authentication)
- 📱 Better UX (familiar Google login flow)
- ✨ Automatic account creation
- 🎯 Fewer form fields to fill

---
