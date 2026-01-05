# PushUp - Fitness Training Management App

A Flutter mobile application connecting Coaches with Athletes for fitness training management.

## 📱 Features

### For Coaches
- Create and manage training plans
- Add athletes and track their progress
- View detailed analytics and statistics
- Send motivational notifications to athletes
- Access achievement system to motivate athletes

### For Athletes
- View assigned training plans
- Log workout activities
- Track progress with charts and statistics
- Receive notifications from coaches
- Earn achievements for consistency

## 🏗️ Architecture

This project follows **Clean Architecture** principles with the following layers:

```
lib/
├── core/                    # Shared utilities, themes, widgets
│   ├── constants/
│   ├── router/
│   ├── theme/
│   └── widgets/
├── features/                # Feature modules
│   ├── auth/               # Authentication (login, register)
│   ├── coach/              # Coach-specific features
│   ├── athlete/            # Athlete-specific features
│   ├── plans/              # Training plans management
│   ├── achievements/       # Achievements system
│   └── notifications/      # In-app notifications
└── app.dart                # Main app widget
```

Each feature follows the structure:
- `domain/` - Entities and repository interfaces
- `data/` - Repository implementations
- `presentation/` - Screens, providers, widgets

## 🛠️ Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** Riverpod 2.x
- **Navigation:** GoRouter
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging)
- **Charts:** FL Chart

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.x
- Android Studio / VS Code
- Firebase project configured

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd pushup_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add Android and iOS apps to your project
   - Download and add the configuration files:
     - Android: `google-services.json` to `android/app/`
     - iOS: `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## 🧪 Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

Run specific test file:
```bash
flutter test test/features/auth/domain/entities/user_entity_test.dart
```

## 📦 Building for Release

### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 📂 Project Structure Details

### Core Layer

- **constants/** - App-wide constants and enums
- **router/** - GoRouter configuration with auth guards
- **theme/** - Colors, typography, spacing system
- **widgets/** - Reusable UI components (buttons, text fields, cards)

### Feature Layers

Each feature module is self-contained:

- **Auth** - Firebase authentication, login/register screens
- **Coach** - Dashboard, athlete management, analytics
- **Athlete** - Dashboard, workout logging, progress tracking
- **Plans** - Training plan CRUD operations
- **Achievements** - Gamification with unlockable achievements
- **Notifications** - In-app notification center

## 🔒 Security

- Firebase Authentication for secure user management
- Firestore security rules for data access control
- Role-based access (Coach vs Athlete)

## 📈 Analytics

- Weekly activity charts
- Monthly progress tracking
- Workout type distribution
- Coach analytics dashboard

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.
