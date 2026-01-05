# Firebase Setup Guide for PushUp App

This guide walks you through setting up Firebase for the PushUp application.

## Prerequisites

- [Firebase CLI](https://firebase.google.com/docs/cli) installed
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) installed
- A Google account

## Step 1: Install Firebase Tools

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 2: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" (or "Add project")
3. Enter project name: `pushup-app` (or your preferred name)
4. Enable/disable Google Analytics as desired
5. Click "Create project"

## Step 3: Enable Firebase Services

### Authentication
1. In Firebase Console, go to **Build → Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable **Email/Password** provider

### Firestore Database
1. Go to **Build → Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (for development)
4. Choose a Cloud Firestore location closest to your users
5. Click "Enable"

## Step 4: Configure FlutterFire

Navigate to your Flutter project directory and run:

```bash
cd d:\MobileITT632\pushup_app
flutterfire configure
```

This will:
- Automatically register your app with Firebase
- Generate the `firebase_options.dart` file with correct configuration
- Set up platform-specific files (google-services.json for Android, GoogleService-Info.plist for iOS)

### During Configuration:
1. Select your Firebase project from the list
2. Select platforms to configure (Android, iOS, Web, etc.)
3. Confirm the app IDs (default: `com.pushup.pushup_app`)

## Step 5: Verify Configuration

After running `flutterfire configure`, verify these files exist:
- `lib/firebase_options.dart` (auto-generated with real values)
- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS, if targeting iOS)

## Firestore Security Rules

For development, update your Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      // Users can write their own document
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Coaches can read their athletes
    match /users/{userId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
    }
  }
}
```

## Firestore Indexes

Create the following composite indexes in Firebase Console under **Firestore → Indexes**:

### Users Collection
| Collection | Fields Indexed | Query Scope |
|------------|---------------|-------------|
| users | coachId (Ascending), displayName (Ascending) | Collection |
| users | role (Ascending), createdAt (Descending) | Collection |

## Step 6: Run the App

After Firebase is configured:

```bash
cd d:\MobileITT632\pushup_app
flutter run
```

## Troubleshooting

### "Firebase app not initialized"
- Ensure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`
- Verify `firebase_options.dart` has valid configuration

### "Google services file missing"
- Re-run `flutterfire configure`
- Ensure you selected the correct platforms

### Authentication errors
- Verify Email/Password sign-in is enabled in Firebase Console
- Check that the API key is valid

### Firestore permission denied
- Update Firestore security rules as shown above
- Ensure user is authenticated before accessing Firestore

## Next Steps

After Firebase is set up:
1. Run the app on your device/emulator
2. Test registration with a new account
3. Verify user document is created in Firestore
4. Test login with created account

## Production Considerations

Before going to production:
1. Update Firestore security rules for production
2. Enable App Check for additional security
3. Configure Firebase Analytics (if needed)
4. Set up Firebase Crashlytics for crash reporting
5. Configure proper backup and retention policies
