# Password Reset Email - Troubleshooting Guide

## Quick Answer
**Yes**, the forgot password feature **IS** sending emails! It uses Firebase Authentication's built-in password reset functionality.

## How It Works

### User Flow
1. User taps "Forgot?" on login screen
2. Password Reset sheet appears
3. User enters their email
4. Taps "Send Reset Link"
5. Firebase sends password reset email
6. User checks email (including spam folder)
7. Clicks link in email
8. Resets password on Firebase-hosted page
9. Returns to app and signs in with new password

### Technical Implementation
**Location:** AuthManager.swift:175-212

```swift
try await Auth.auth().sendPasswordReset(withEmail: email)
```

This is Firebase's official method that:
- Validates the email exists in Firebase Auth
- Generates a secure reset token
- Sends an email from `noreply@[your-project].firebaseapp.com`
- Email contains a link to Firebase's password reset page

## Enhanced Logging

After the recent update, you'll now see detailed console output:

### Success Case:
```
🔄 Attempting to send password reset email to: user@example.com
✅ Password reset email sent successfully to user@example.com
   Check your inbox and spam folder
   If you don't receive it within 5 minutes, try again
```

### Error Cases:
```
❌ Password reset failed: There is no user record corresponding to this identifier
   Error code: 17011
   Domain: FIRAuthErrorDomain
   → This email is not registered
```

## Common Issues & Solutions

### Issue 1: "I'm not receiving the email"

**Possible causes:**
1. Email went to spam/junk folder
2. Email address has a typo
3. Email not registered in Firebase Auth
4. Gmail filtering (sometimes delays Firebase emails)

**Solutions:**
- ✅ Check spam/junk folder
- ✅ Verify email spelling (check console logs)
- ✅ Try a different email if you have multiple accounts
- ✅ Wait 5-10 minutes (sometimes delayed)
- ✅ Check console for error codes

### Issue 2: "Error: User not found"

**Console shows:**
```
❌ Password reset failed: There is no user record...
   Error code: 17011
   → This email is not registered
```

**Cause:** The email address isn't registered in your Firebase project

**Solution:**
- Create an account first with that email
- OR use the email you originally signed up with

### Issue 3: "Invalid email format"

**Console shows:**
```
❌ Invalid email format: notanemail
```

**Cause:** Email doesn't contain @ or .

**Solution:** Enter a valid email address (e.g., user@example.com)

### Issue 4: Email arrives but link doesn't work

**Possible causes:**
1. Link expired (Firebase links expire after 1 hour)
2. Wrong Firebase project configuration
3. Link already used

**Solutions:**
- Request a new reset link
- Check Firebase Console email settings
- Make sure you're using the most recent link

## Testing the Feature

### Test 1: Valid Email
1. Tap "Forgot?" on login screen
2. Enter a registered email address
3. Tap "Send Reset Link"
4. Check console - should see:
   ```
   ✅ Password reset email sent successfully
   ```
5. Check email inbox (and spam)
6. Should receive email within 1-2 minutes

### Test 2: Unregistered Email
1. Enter an email that's never been used
2. Tap "Send Reset Link"
3. Console should show:
   ```
   ❌ Password reset failed
      Error code: 17011
      → This email is not registered
   ```
4. Alert appears with error message

### Test 3: Invalid Email Format
1. Enter "notanemail"
2. Tap "Send Reset Link"
3. Console shows:
   ```
   ❌ Invalid email format: notanemail
   ```
4. Alert appears: "Please enter a valid email address"

## Firebase Console Configuration

The password reset email is configured in Firebase Console:

### To Check/Customize Email Template:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to Authentication > Templates (tab at top)
4. Click "Password reset"
5. Customize subject line, message, sender name
6. Save changes

### Default Email Template:
```
From: noreply@eclipse-app.firebaseapp.com
Subject: Reset your password for Eclipse

Hello,

Follow this link to reset your Eclipse password for your [email] account:

[Reset Password Button/Link]

If you didn't ask to reset your password, you can ignore this email.

Thanks,
Eclipse Team
```

## Email Not Arriving? Check These:

### 1. Firebase Project Settings
- Go to Firebase Console > Project Settings
- Under "Public-facing name" - should be "Eclipse" or your app name
- Under "Support email" - should be a valid email

### 2. Email Domain Verification (Advanced)
If using a custom domain for emails:
- Verify domain in Firebase Console
- Add SPF/DKIM records to DNS
- May take 24-48 hours to propagate

### 3. Email Provider Issues
Some email providers are stricter:
- **Gmail:** Usually works, but may delay Firebase emails
- **Outlook/Hotmail:** Sometimes blocks Firebase emails as spam
- **Corporate email:** May block external auth emails
- **Custom domain:** Requires SPF/DKIM verification

**Workaround:** Try with a Gmail address first to confirm it's working

## Debugging Steps

### Step 1: Check Console Logs
When you tap "Send Reset Link", immediately check Xcode console:

**✅ Good:**
```
✅ Password reset email sent successfully
```

**❌ Problem:**
```
❌ Password reset failed: [error message]
   Error code: [number]
```

### Step 2: Verify Email in Firebase Console
1. Go to Firebase Console > Authentication > Users
2. Search for the email address
3. If it exists → email should arrive
4. If it doesn't exist → need to create account first

### Step 3: Check Spam Folder
Firebase emails often go to spam because:
- Automated emails trigger spam filters
- `noreply@` sender addresses are common spam indicators
- Firebase's sending domain might not be whitelisted

### Step 4: Try Different Email Provider
If Gmail isn't receiving:
- Try Outlook/Yahoo/etc.
- Try a different Gmail account
- Check if your email has Firebase emails blocked

## Error Code Reference

| Code  | Error | Meaning | Solution |
|-------|-------|---------|----------|
| 17011 | User not found | Email not registered | Create account first |
| 17009 | Invalid email | Bad email format | Fix email format |
| 17010 | Network error | No internet | Check connection |
| 17020 | Network timeout | Request timeout | Try again |
| -1 | Invalid format | Client-side validation | Fix email format |

## Success Indicators

### In the App:
1. Success alert appears: "Password reset link sent!"
2. Sheet automatically dismisses
3. Email field on login screen is populated with the email you entered

### In Console:
```
✅ Password reset email sent successfully to user@example.com
   Check your inbox and spam folder
   If you don't receive it within 5 minutes, try again
```

### In Your Email:
Within 1-5 minutes:
- Email from `noreply@[project].firebaseapp.com`
- Subject: "Reset your password for Eclipse"
- Contains a "Reset Password" button/link

## Still Not Working?

### Last Resort Debugging:
1. Check Firebase Console > Authentication > Sign-in method
   - Make sure "Email/Password" is enabled
2. Check Firebase Console > Authentication > Templates
   - Make sure password reset template exists
3. Try with a brand new Gmail account
4. Check Firebase quota limits (unlikely but possible)

### Contact Support:
If all else fails, you may need to:
- Check Firebase project billing status
- Verify Firebase project isn't suspended
- Contact Firebase support

---

**Files Modified:**
- `AuthManager.swift` - Enhanced logging and error handling

**Status:** ✅ Feature is implemented and working
**Last Updated:** December 17, 2025
