# Firebase Password Reset Email Configuration Guide

## Why You're Not Receiving Password Reset Emails

There are several common reasons why Firebase password reset emails might not arrive:

### 1. **Firebase Email Templates Not Configured**
This is the most common issue.

**How to Fix:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Eclipse project
3. Navigate to **Authentication** → **Templates** tab (top of the page)
4. Click on **Password reset** template
5. Customize the template:
   - **Sender name**: "Eclipse" or your app name
   - **Subject**: Customize if desired
   - **Email body**: You can customize the message
6. Click **Save**

### 2. **Email Going to Spam**
Firebase emails often get flagged as spam initially.

**How to Fix:**
- Check your **Spam/Junk** folder
- Mark the email as "Not Spam" if found
- Add `noreply@[your-project-id].firebaseapp.com` to your contacts

### 3. **Email Address Not Registered**
The app now checks if the email is registered and will show an error if it's not.

**How to Fix:**
- Verify you're using the correct email address
- Make sure you've created an account with that email
- Check the Xcode console logs for detailed error messages

### 4. **Firebase Email Delivery Delay**
Sometimes Firebase emails can take a few minutes to arrive.

**How to Fix:**
- Wait 5-10 minutes before trying again
- Check spam folder after waiting

### 5. **Custom Email Domain Not Verified**
If you're using a custom email domain, it needs to be verified.

**How to Fix:**
1. Go to Firebase Console → Authentication → Templates
2. Click "Customize domain" (if applicable)
3. Follow verification steps

## Testing the Password Reset Flow

1. **Run the app** and click "Forgot?" on the login screen
2. **Enter your email** (must be registered)
3. **Check Xcode console** for detailed logs:
   ```
   ✅ Email 'your@email.com' is registered with methods: ["password"]
   ✅ Password reset email sent successfully
   📧 Check your inbox and spam/junk folder
   ```
4. **Check your email**:
   - Inbox first
   - Then spam/junk folder
   - Wait 1-5 minutes if not immediate

## Troubleshooting Steps

### Step 1: Verify Email is Registered
1. Go to Firebase Console → Authentication → Users
2. Search for your email address
3. If not found, create an account first

### Step 2: Check Firebase Logs
1. Go to Firebase Console → Authentication → Usage
2. Look for password reset events
3. Check if emails are being sent

### Step 3: Test with Different Email Provider
- Try with Gmail, Outlook, or another provider
- Some email providers have stricter spam filters

### Step 4: Check Firebase Project Settings
1. Go to Firebase Console → Project Settings
2. Verify the project is properly configured
3. Check that Authentication is enabled

## Default Email Sender

By default, Firebase sends emails from:
```
noreply@[your-project-id].firebaseapp.com
```

Example:
```
noreply@eclipse-app-12345.firebaseapp.com
```

## Custom Email Template Example

You can customize the email template in Firebase Console to match your app's branding:

**Subject:**
```
Reset your Eclipse password
```

**Body:**
```
Hello,

You requested to reset your password for Eclipse.

Click the link below to reset your password:
%LINK%

If you didn't request this, you can safely ignore this email.

Thanks,
The Eclipse Team
```

## Still Not Working?

If you've tried all the above and still not receiving emails:

1. **Check Firebase Console → Authentication → Templates**
   - Make sure the template is enabled
   - Verify sender name is set

2. **Try a different email address**
   - Test with Gmail, Outlook, etc.

3. **Check Firebase quotas**
   - Free tier has email limits
   - Go to Firebase Console → Usage

4. **Contact Firebase Support**
   - If all else fails, contact Firebase support
   - Provide project ID and email address used

## Enhanced Error Messages

The app now provides detailed error messages:
- ✅ "Email is registered" - Email exists in Firebase
- ❌ "Email not registered" - Create an account first
- ❌ "Invalid email format" - Check email syntax
- ❌ "Network error" - Check internet connection

Check the Xcode console for detailed logs when testing!
