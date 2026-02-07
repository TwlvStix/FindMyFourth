# Firestore Rules Update Required

## Issue
The alertSubs collection is returning "permission-denied" errors when users try to read their subscriptions.

## Required Firestore Rules

Add these rules to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... existing rules ...
    
    // Alert Subscriptions - users can read/write their own subscriptions
    match /alertSubs/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
  }
}
```

## How to Deploy

1. Open Firebase Console
2. Go to Firestore Database
3. Click "Rules" tab
4. Add the alertSubs rule above
5. Click "Publish"

## Alternative: Update via Firebase CLI

If you're using Firebase CLI:

```bash
# Edit firestore.rules file
# Add the alertSubs match block
# Then deploy:
firebase deploy --only firestore:rules
```

## Verify

After deploying, test by:
1. Opening Notification Settings
2. Enabling Game Alerts
3. Tapping "Configure filters"
4. Should load without permission errors

## Current Workaround

The app has been updated to handle permission errors gracefully:
- Uses default alert subscription if read fails
- Allows user to configure and save
- Creates the document on first save

So the app will work, but won't load existing alert subscriptions until rules are updated.
