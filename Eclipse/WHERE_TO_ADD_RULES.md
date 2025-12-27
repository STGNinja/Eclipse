# Where to Add the Rules - Quick Guide

## ✅ Firestore Database Rules (for Appearance Feature)

### Location: **Firestore Database** → **Rules** tab

The Appearance feature saves user preferences to **Firestore Database**, so you need to update **Firestore Rules**.

### Steps:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **"Firestore Database"** in left sidebar (NOT Storage!)
4. Click the **"Rules"** tab at the top
5. You should see existing rules (probably for artifacts)
6. Add the new rules for preferences

### The Rules to Add:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // User Artifacts (you probably already have this)
    match /users/{userId}/artifacts/{artifactId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ADD THIS NEW SECTION 👇
    // User Preferences (for Appearance feature)
    match /users/{userId}/preferences/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

7. Click **"Publish"** button (blue button top right)

---

## 📊 Summary of Your Firebase Setup

You now have rules in **TWO places**:

### 1. **Storage Rules** (for profile photos)
- Location: **Storage** → **Rules** tab
- Controls: Profile photo uploads
- Path: `profile_photos/{userId}.jpg`

### 2. **Firestore Database Rules** (for data)
- Location: **Firestore Database** → **Rules** tab
- Controls: 
  - Artifacts (user's saved information)
  - Preferences (appearance gradients)
- Paths: 
  - `users/{userId}/artifacts/{artifactId}`
  - `users/{userId}/preferences/{document}`

---

## 🎯 Quick Check

After adding the rules:

### Test in Firebase Console:
1. Go to Firestore Database → Rules tab
2. Click **"Rules Playground"**
3. Test:
   - Auth UID: `your-user-id`
   - Path: `/users/your-user-id/preferences/appearance`
   - Operation: `write`
   - Expected: ✅ **ALLOW**

### Test in Your App:
1. Open app
2. Go to Settings → Appearance
3. Select a gradient
4. Check console: `✅ Appearance saved: [Gradient Name]`
5. Check Firestore Console for new data

---

## 🔍 Visual Guide

```
Firebase Console
├── Storage (for files like images)
│   └── Rules tab → Profile photo rules ✅ (already done)
│
└── Firestore Database (for JSON data)
    └── Rules tab → Add preference rules here! 👈
```

---

## ✅ You're Adding Rules To:

**Firestore Database** (NOT Storage!)

- Storage = Files (images, videos, etc.)
- Firestore = Data (JSON documents)

The Appearance feature saves a JSON document like:
```json
{
  "gradient": "Aurora",
  "updatedAt": "2025-12-15T..."
}
```

This is **data**, so it goes in **Firestore Database**!

---

**Now go add those rules and your Appearance feature will work perfectly!** 🎨
