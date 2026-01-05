# Notifications & Messaging System Documentation

This document explains how the PushUp App implements notifications and real-time messaging using Firebase Cloud Services.

---

## 📱 Cloud Services Used

The app uses **3 Firebase Cloud Services**:

| Service | Purpose | Status |
|---------|---------|--------|
| **Firebase Authentication** | User sign-in/sign-up, role management | ✅ Fully Implemented |
| **Cloud Firestore** | Database for all app data | ✅ Fully Implemented |
| **Firebase Cloud Messaging (FCM)** | Push notifications | ✅ Fully Implemented |

---

## 🔔 Notifications System

### Overview

The notification system allows coaches to send notifications to their athletes. Notifications are stored in Firestore and can also trigger push notifications via FCM.

### How It Works

```
┌─────────────┐     ┌─────────────────────┐     ┌─────────────┐
│   Coach     │────▶│  Firestore          │────▶│   Athlete   │
│   (Sender)  │     │  (notifications)    │     │  (Receiver) │
└─────────────┘     └─────────────────────┘     └─────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  FCM Push Service   │
                    │  (Background/       │
                    │   Foreground)       │
                    └─────────────────────┘
```

### Notification Types

1. **Welcome** - Sent when athlete joins a coach's team
2. **Plan Assigned** - When a new training plan is assigned
3. **Encouragement** - Motivational messages from coach
4. **Reminder** - Workout reminders
5. **Achievement** - Milestone celebrations
6. **Message** - New chat message received

### Data Structure

**Firestore Collection: `notifications`**

```dart
{
  'senderId': 'coach_uid',
  'receiverId': 'athlete_uid',
  'type': 'encouragement',        // Type of notification
  'title': 'Keep It Up! 💪',      // Notification title
  'message': 'Great job today!',  // Notification body
  'sentAt': Timestamp,            // When sent
  'readAt': Timestamp | null,     // When read (null = unread)
  'senderName': 'Coach Mike',     // Display name
}
```

### Implementation Files

| File | Purpose |
|------|---------|
| `lib/features/notifications/data/repositories/notification_repository_impl.dart` | CRUD operations for notifications |
| `lib/features/notifications/domain/repositories/notification_repository.dart` | Repository interface |
| `lib/features/notifications/presentation/providers/notification_provider.dart` | State management |
| `lib/features/notifications/presentation/screens/notifications_screen.dart` | UI for viewing notifications |
| `lib/core/services/notification_service.dart` | FCM integration & local notifications |

### Coach Features

- ✅ Send notifications to individual athletes
- ✅ Send bulk notifications to all athletes
- ✅ View sent notification history
- ✅ Quick-send templates (encouragement, reminders)

### Athlete Features

- ✅ View all received notifications
- ✅ Mark notifications as read
- ✅ Unread count badge in app bar
- ✅ Receive push notifications (foreground & background)

### Push Notification Flow

1. **Coach sends notification** → Document created in Firestore
2. **Cloud Function triggers** (optional) → Sends FCM message
3. **FCM delivers to device** → Shows system notification
4. **User taps notification** → Opens app to notifications screen

---

## 💬 Messaging System

### Is Messaging Real-Time?

**YES!** The messaging system uses **Firestore real-time listeners** (`snapshots()`) for instant message delivery.

### How Real-Time Works

```dart
// From conversations_provider.dart
Stream<List<Conversation>> watchConversations(String userId) {
  return _firestore
      .collection('conversations')
      .where('participantIds', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()  // ← Real-time listener!
      .map((snapshot) => snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList());
}

// From conversation_detail_provider.dart
Stream<List<Message>> watchMessages(String conversationId) {
  return _firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('sentAt', ascending: true)
      .snapshots()  // ← Real-time listener!
      .map((snapshot) => snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList());
}
```

### Real-Time Benefits

| Feature | How It Works |
|---------|--------------|
| **Instant message delivery** | Messages appear immediately without refresh |
| **Live typing indicators** | (Future feature) Can be added easily |
| **Read receipts** | Updates propagate in real-time |
| **Unread counts** | Badge updates automatically |
| **Last message preview** | Conversation list updates live |

### Data Structure

**Firestore Collection: `conversations`**

```dart
{
  'participantIds': ['coach_uid', 'athlete_uid'],
  'participantNames': {
    'coach_uid': 'Coach Mike',
    'athlete_uid': 'Alex Thompson'
  },
  'lastMessage': 'Great workout today!',
  'lastMessageAt': Timestamp,
  'unreadCounts': {
    'coach_uid': 0,
    'athlete_uid': 2
  },
  'createdAt': Timestamp
}
```

**Subcollection: `conversations/{id}/messages`**

```dart
{
  'senderId': 'coach_uid',
  'receiverId': 'athlete_uid',
  'content': 'Great workout today!',
  'senderName': 'Coach Mike',
  'sentAt': Timestamp,
  'readAt': Timestamp | null
}
```

### Implementation Files

| File | Purpose |
|------|---------|
| `lib/features/messaging/data/repositories/conversations_repository_impl.dart` | Conversation CRUD |
| `lib/features/messaging/presentation/providers/conversations_provider.dart` | Conversations state |
| `lib/features/messaging/presentation/providers/conversation_detail_provider.dart` | Messages state |
| `lib/features/messaging/presentation/screens/conversations_screen.dart` | Conversation list UI |
| `lib/features/messaging/presentation/screens/conversation_detail_screen.dart` | Chat UI |

### Coach Features

- ✅ View all athlete conversations
- ✅ Send/receive messages in real-time
- ✅ Start new conversations with athletes
- ✅ See unread message counts
- ✅ Message history persists

### Athlete Features

- ✅ Message their assigned coach
- ✅ Receive messages in real-time
- ✅ View conversation history
- ✅ Unread badge on messaging icon

---

## 🔧 FCM Setup (Firebase Cloud Messaging)

### Android Configuration

The app is configured for FCM in:
- `android/app/google-services.json` - Firebase config
- `android/app/src/main/AndroidManifest.xml` - Permissions

### Required Permissions

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Notification Service

The `NotificationService` class (`lib/core/services/notification_service.dart`) handles:

1. **FCM Token Management**
   - Retrieves device FCM token
   - Stores token in user's Firestore document
   - Handles token refresh

2. **Foreground Notifications**
   - Uses `flutter_local_notifications` to show notifications when app is open
   - Custom notification channels for different types

3. **Background Handling**
   - FCM handles notifications when app is in background
   - Tapping notification opens relevant screen

### Initialization

```dart
// In main.dart
await NotificationService.instance.initialize();
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  Notifications  │  │   Messaging     │                   │
│  │  Screen         │  │   Screens       │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
│           │                    │                            │
│  ┌────────▼────────┐  ┌────────▼────────┐                   │
│  │  Notification   │  │  Conversation   │                   │
│  │  Provider       │  │  Providers      │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
└───────────┼─────────────────────┼───────────────────────────┘
            │                     │
┌───────────▼─────────────────────▼───────────────────────────┐
│                      Domain Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  Notification   │  │  Conversation   │                   │
│  │  Repository     │  │  Repository     │                   │
│  │  (Interface)    │  │  (Interface)    │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
└───────────┼─────────────────────┼───────────────────────────┘
            │                     │
┌───────────▼─────────────────────▼───────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  Notification   │  │  Conversations  │                   │
│  │  Repository     │  │  Repository     │                   │
│  │  Impl           │  │  Impl           │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
└───────────┼─────────────────────┼───────────────────────────┘
            │                     │
            ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Services                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Firestore  │  │    FCM      │  │    Auth     │         │
│  │  Database   │  │   Push      │  │   Users     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 Testing the System

### Test Accounts

After seeding the database, you can test with these accounts:

**Coaches:**
- `coach.mike@example.com` / `Test123!`
- `coach.sarah@example.com` / `Test123!`
- (and 4 more coaches)

**Athletes:**
- `alex.t@example.com` / `Test123!`
- `emma.w@example.com` / `Test123!`
- (and 34 more athletes)

### Testing Notifications

1. Log in as a coach
2. Go to an athlete's detail page
3. Use "Send Encouragement" or "Send Reminder" buttons
4. Log in as that athlete on another device/emulator
5. Verify notification appears

### Testing Real-Time Messaging

1. Log in as coach on Device A
2. Log in as athlete on Device B
3. Open messaging on both devices
4. Send message from coach
5. Verify instant delivery on athlete device

---

## 📊 Seeded Test Data

When you run the database seeder, it creates:

| Data Type | Count | Description |
|-----------|-------|-------------|
| Coaches | 6 | Distributed across teams |
| Athletes | 36 | 6 per coach |
| Training Plans | 12 | 2 per coach |
| Activity Logs | 200+ | Realistic workout patterns |
| Notifications | 50+ | Welcome, reminders, encouragements |
| Conversations | 36 | One per coach-athlete pair |
| Messages | 60+ | Sample conversation threads |

### Streak Distribution

- **1-day streak**: 2 athletes (indices 0, 1)
- **3-day streak**: 1 athlete (index 2)
- **5-day streak**: Most athletes (default)
- **6-day streak**: Every 3rd athlete
- **7-day streak**: Every 5th athlete

---

## 🚀 Future Enhancements

1. **Push notification triggers via Cloud Functions**
   - Automatically notify athletes when plan assigned
   - Daily reminder notifications

2. **Rich notifications**
   - Images in notifications
   - Action buttons

3. **Typing indicators**
   - Show when the other person is typing

4. **Message reactions**
   - Quick emoji reactions to messages

5. **Group messaging**
   - Coach messages to all athletes at once

---

## 📝 Summary

| Feature | Technology | Real-Time? |
|---------|------------|------------|
| Notifications | Firestore + FCM | Stored in DB, pushed via FCM |
| Messaging | Firestore Streams | ✅ Yes - instant delivery |
| Push Alerts | FCM | ✅ Yes - device notifications |
| Unread Counts | Firestore Listeners | ✅ Yes - live updates |

The app fully implements a modern, real-time communication system using Firebase's suite of cloud services!
