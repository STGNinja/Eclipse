# Custom Password Reset - Setup Guide

## What We Built

A beautiful, branded password reset experience that matches your Eclipse app theme. Instead of the basic Firebase web page, users now see a custom view with:

✨ **Features:**
- Purple-to-blue gradient background matching your app
- Real-time password strength indicator
- Visual password requirements checklist
- Elegant glass-effect input fields
- Success animation with haptic feedback
- Full validation and error handling

---

## How It Works

### Old Flow (Basic):
1. User clicks email link → Opens basic Firebase web page
2. Enters new password on generic white page
3. Redirected back to Firebase

### New Flow (Custom):
1. User clicks email link → Opens directly in your Eclipse app
2. Beautiful custom UI matching your brand appears
3. Password reset happens in-app with full validation
4. Success animation, then returns to login

---

## Setup Instructions

### Step 1: Configure Firebase Console (5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your **Eclipse** project
3. Navigate to **Authentication** → **Templates** (tab at the top)
4. Click on **Password reset**

#### Option A: Dynamic Links (Recommended)
5. Scroll down to **"Customize action URL"**
6. Enter: `https://eclipse-2a42b.firebaseapp.com/__/auth/action`
7. Enable **"Open the link using a mobile app"**
8. Select **iOS app** → Choose your Eclipse app
9. Click **Save**

#### Option B: Universal Links (More Complex)
If you want to use your own domain (e.g., `app.eclipse.com`):
1. Set up [Firebase Dynamic Links](https://firebase.google.com/docs/dynamic-links)
2. Configure your domain in Firebase Console
3. Add Apple App Site Association (AASA) file to your domain
4. Update `handleIncomingURL` in EclipseApp.swift to handle your domain

---

## Testing the Feature

### Test 1: Request Password Reset
1. Build and run your app
2. Tap "Forgot?" on login screen
3. Enter your email address
4. Tap "Send Reset Link"
5. Check console for confirmation:
   ```
   ✅ Password reset email sent successfully to user@example.com
   ```

### Test 2: Open Email Link
1. Open the email on your iOS device
2. Tap "Reset Password" button
3. **Expected**: Your Eclipse app should open automatically
4. **You should see**: Custom password reset screen with your branding

### Test 3: Reset Password
1. Enter a new password (must meet requirements):
   - At least 8 characters
   - One uppercase letter
   - One lowercase letter
   - One number
2. Watch the password strength indicator update
3. Confirm the password (must match)
4. Tap "Reset Password"
5. **Expected**: Success animation with checkmark
6. Tap "Return to Sign In"
7. Sign in with your new password

---

## Visual Features

### Password Strength Indicator
- **Weak** (Red): Basic password, doesn't meet all requirements
- **Medium** (Orange): Meets basic requirements
- **Strong** (Green): Long password with special characters

### Real-time Validation
- ✅ Green checkmarks show requirements met
- ⚪ Gray circles show requirements not yet met
- Password match indicator turns green when passwords match

### Animations
- Smooth transitions between screens
- Success animation with radial gradient glow
- Haptic feedback on success and errors

---

## Troubleshooting

### Issue: Email link opens in Safari instead of app
**Solution 1**: Make sure you saved changes in Firebase Console under "Open the link using a mobile app"

**Solution 2**: Check that your Info.plist includes the custom URL scheme:
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>eclipse</string>
</array>
```

### Issue: "Invalid action code" error
**Causes:**
- Link was already used
- Link expired (valid for 1 hour)
- Wrong Firebase project

**Solution**: Request a new password reset link

### Issue: Password requirements not validating
**Check that you have:**
- At least 8 characters ✓
- One uppercase letter (A-Z) ✓
- One lowercase letter (a-z) ✓
- One number (0-9) ✓
- Both password fields match ✓

---

## Files Created/Modified

### New Files:
1. **PasswordResetHandlerView.swift**
   - Custom password reset UI
   - Password strength calculator
   - Success animation
   - Full validation logic

### Modified Files:
1. **EclipseApp.swift**
   - Added `onOpenURL` handler
   - Deep link parsing logic
   - Sheet presentation for reset view

2. **Info.plist**
   - Added custom URL scheme: `eclipse://`
   - Enables deep linking to app

---

## Advanced: Custom Email Template

You can also customize the email itself in Firebase Console:

### Email Customization:
1. Firebase Console → Authentication → Templates → Password reset
2. Customize:
   - **Sender name**: "Eclipse Team"
   - **Subject line**: "Reset your Eclipse password"
   - **Email body**: Add your branding, logo, colors

### Email Variables Available:
- `%LINK%` - The password reset link
- `%EMAIL%` - The user's email address
- `%APP_NAME%` - Your app name

Example custom email body:
```html
<div style="background: linear-gradient(135deg, #7C3AED 0%, #3B82F6 100%); padding: 40px; text-align: center;">
  <h1 style="color: white;">Reset Your Eclipse Password</h1>
  <p style="color: rgba(255,255,255,0.9);">
    We received a request to reset your password for %EMAIL%
  </p>
  <a href="%LINK%" style="
    background: white;
    color: #7C3AED;
    padding: 16px 32px;
    text-decoration: none;
    border-radius: 12px;
    display: inline-block;
    margin: 20px 0;
    font-weight: bold;
  ">Reset Password</a>
  <p style="color: rgba(255,255,255,0.7); font-size: 14px;">
    If you didn't request this, you can safely ignore this email.
  </p>
</div>
```

---

## Security Features

### Built-in Security:
- ✅ One-time use codes (can't reuse reset link)
- ✅ 1-hour expiration on reset links
- ✅ Password strength requirements enforced
- ✅ Firebase Auth handles all token validation
- ✅ Secure HTTPS-only connections

### Password Requirements Enforced:
- Minimum 8 characters
- Must contain uppercase letter
- Must contain lowercase letter
- Must contain number
- Passwords must match

---

## Console Logging

When you tap a password reset link, check Xcode console:

### Success Pattern:
```
🔗 Received URL: https://eclipse-2a42b.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=...
✅ Password reset link detected
   Code: [code-here]
🔄 Confirming password reset with code...
✅ Password reset successful!
```

### Error Pattern:
```
🔗 Received URL: https://eclipse-2a42b.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=...
✅ Password reset link detected
   Code: [code-here]
🔄 Confirming password reset with code...
❌ Password reset failed: The action code is invalid...
```

---

## What's Next?

Your password reset is now fully branded and matches your beautiful Eclipse design!

Users will experience:
1. Seamless transition from email → app
2. Beautiful, familiar UI matching your brand
3. Clear password requirements
4. Instant feedback and validation
5. Satisfying success animation

No more generic Firebase pages! 🎉

---

**Status**: ✅ Implemented and ready to configure
**Last Updated**: December 17, 2025
**Location**:
- View: `Eclipse/Views/Auth/PasswordResetHandlerView.swift`
- Handler: `Eclipse/EclipseApp.swift:62-84`
- Config: `Eclipse/Info.plist:15-24`
