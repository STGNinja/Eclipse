# Firebase Setup for Appearance Feature

## 🔐 Required Firestore Security Rules

You need to add rules for the `preferences` subcollection.

### Option 1: Add to Existing Rules

If you already have Firestore rules, add this section:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... your existing rules for artifacts ...
    
    // User Preferences (for Appearance feature)
    match /users/{userId}/preferences/{document=**} {
      // Users can only read/write their own preferences
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Validate appearance data structure
      allow create, update: if request.auth != null 
                            && request.auth.uid == userId
                            && request.resource.data.keys().hasAll(['gradient', 'updatedAt'])
                            && request.resource.data.gradient is string
                            && request.resource.data.updatedAt is timestamp;
    }
  }
}
```

### Option 2: Complete Rules (if starting fresh)

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // User Artifacts
    match /users/{userId}/artifacts/{artifactId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
    
    // User Preferences (Appearance)
    match /users/{userId}/preferences/{document=**} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
    
    // User Sessions (if you add chat history sync later)
    match /users/{userId}/sessions/{sessionId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
    }
    
    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 📋 Steps to Apply

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **Firestore Database** in the left sidebar
4. Click the **Rules** tab at the top
5. Paste the appropriate rules (Option 1 or 2)
6. Click **"Publish"**
7. Wait for confirmation

## ✅ Testing the Rules

### Test 1: Rules Playground

In Firebase Console:
1. Go to Firestore → Rules tab
2. Click **"Rules Playground"**
3. Test this scenario:

```
Auth UID: your-user-id
Operation: get
Path: /users/your-user-id/preferences/appearance

Expected: ✅ ALLOW
```

### Test 2: In the App

1. Open your app
2. Go to Settings → Appearance
3. Select a gradient
4. Check console for: `✅ Appearance saved: [Gradient Name]`
5. Force quit app
6. Reopen app
7. Go to Appearance
8. Should show your selected gradient

## 🔍 Verifying Data in Firebase

After selecting a gradient:

1. Go to Firebase Console → Firestore Database
2. Navigate to: `users → {your-user-id} → preferences → appearance`
3. You should see:
   ```
   gradient: "Aurora" (or whatever you selected)
   updatedAt: [timestamp]
   ```

## 🐛 Common Issues

### Issue: "Missing or insufficient permissions"

**Cause**: Rules not published or incorrect userId match

**Solution**:
1. Verify rules are published
2. Check that `userId` in path matches authenticated user's UID
3. Make sure user is signed in

### Issue: "Permission denied" when reading

**Cause**: User not authenticated or trying to access another user's data

**Solution**:
1. Verify user is signed in: `Auth.auth().currentUser?.uid`
2. Check the path includes correct userId
3. Sign out and back in if needed

### Issue: Data not syncing across devices

**Cause**: Might be using different accounts or offline mode

**Solution**:
1. Verify same account on both devices
2. Check internet connection
3. Force refresh by signing out and back in

## 📊 Data Structure

```
users/
  {userId}/                    # User's unique ID from Firebase Auth
    preferences/               # Subcollection for all preferences
      appearance/              # Document for appearance settings
        - gradient: String     # e.g., "Aurora", "Sunset", etc.
        - updatedAt: Timestamp # Last update time
```

## 🔒 Security Features

✅ Users can only access their own preferences
✅ Authentication required for all operations
✅ Data structure validation on writes
✅ Timestamps automatically tracked
✅ No cross-user data access possible

## 🎯 Testing Checklist

After setting up rules:

- [ ] Publish rules in Firebase Console
- [ ] Verify rules in Rules Playground
- [ ] Select gradient in app
- [ ] Check console for success message
- [ ] Verify data in Firestore Console
- [ ] Force quit and reopen app
- [ ] Gradient should persist
- [ ] Test on second device (should sync)

## 🚀 You're All Set!

Once these rules are published, your Appearance feature will:
- ✅ Save selections to Firebase
- ✅ Sync across devices
- ✅ Persist forever
- ✅ Be secure and private

---

**Enjoy your customizable Eclipse!** 🎨
