# PushUp App Testing Guide


**Semua akaun menggunakan password yang sama: Test123!**

**Coach Accounts:**
- coach.mike@example.com
- coach.sarah@example.com
- coach.david@example.com

**Athlete Accounts:**
- alex.t@example.com
- emma.w@example.com
- ryan.d@example.com
- olivia.m@example.com
- liam.a@example.com
- sophia.b@example.com
- noah.t@example.com
- ava.g@example.com
- mason.l@example.com
- isabella.k@example.com
- ethan.p@example.com
- mia.n@example.com

**Password untuk semua: Test123!**

## 📋 Overview

This document outlines all testing scenarios for the PushUp fitness training management application. The app connects Coaches with Athletes for fitness training management, including training plan creation, workout logging, progress tracking, and notifications.

---

## 🔐 Authentication Testing

### Login Flow
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Valid Login | Enter valid email/password → Tap Login | Redirected to appropriate dashboard (Coach or Athlete) |
| Invalid Email | Enter invalid email format → Tap Login | Show email validation error |
| Wrong Password | Enter valid email with wrong password → Login | Show authentication error message |
| Empty Fields | Leave fields empty → Tap Login | Show required field validation errors |
| Forgot Password | Tap "Forgot Password" link | Navigate to password reset screen |

### Registration Flow
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Coach Registration | Select Coach role → Fill form → Register | Create coach account → Navigate to coach dashboard |
| Athlete Registration | Select Athlete role → Fill form → Register | Create athlete account → Navigate to athlete dashboard |
| Email Already Exists | Register with existing email | Show "email already in use" error |
| Password Mismatch | Enter different passwords | Show password mismatch error |
| Weak Password | Enter password < 6 chars | Show password requirements error |

### Session Management
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Stay Logged In | Login → Close app → Reopen | Remain logged in, go to dashboard |
| Logout | Tap logout button | Clear session → Return to welcome screen |

---

## 🏋️ Coach Features Testing

### Training Plans Management
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Create New Plan | Dashboard → Create Plan → Fill details → Add activities | Plan created and appears in plans list |
| Edit Existing Plan | Plans List → Tap plan → Edit → Modify → Save | Changes saved successfully |
| Delete Plan | Plans List → Tap plan → Delete → Confirm | Plan removed from list |
| Add Activities to Plan | Create/Edit Plan → Add Activity → Set details | Activity added to plan |
| Remove Activity from Plan | Edit Plan → Swipe activity → Delete | Activity removed |
| Search Plans | Type in search bar | Filter plans by name |
| Filter by Template | Toggle template filter | Show only template plans |

### Athlete Management
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Athletes List | Dashboard → Athletes tab | Display all assigned athletes |
| Add New Athlete | Athletes → Add Athlete → Fill email | Invitation sent or athlete added 
| View Athlete Detail | Tap on athlete card | Show athlete profile, stats, and progress |
| Remove Athlete | Athlete detail → Remove → Confirm | Athlete unlinked from coach |

### Plan Assignment
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Assign Plan to Athlete | Athlete detail → Assign Plan → Select plan | Plan assigned with start date |
| View Assigned Plans | Athlete detail → Plans tab | Show all plans assigned to athlete |
| Unassign Plan | Assigned plan → Unassign → Confirm | Plan removed from athlete |
| Set Plan Start Date | Assign Plan → Pick date | Assignment starts on selected date |

### Coach Analytics
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Team Overview | Dashboard → Analytics | Show aggregate team statistics |
| Individual Athlete Stats | Analytics → Select athlete | Show detailed athlete performance |
| Progress Charts | Analytics → Charts tab | Display visual progress charts |

---

## 🏃 Athlete Features Testing

### Dashboard
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Today's Workout | Open dashboard | Display scheduled workout for today |
| View Progress Summary | Dashboard → Progress section | Show streak, stats summary |
| Quick Stats Display | Dashboard home tab | Display workout count, streak, total time |

### Training Plans View
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Assigned Plans | Dashboard → Plans tab | List all assigned training plans |
| View Plan Details | Tap on plan | Show full plan with activities by day |
| View Daily Activities | Plan detail → Select day | Display activities for that day |

### Activity Logging
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Log Completed Workout | Activity → Mark Complete → Fill details | Activity logged with timestamp |
| Set Duration | Log Activity → Set duration slider | Duration saved correctly |
| Set Effort Level | Log Activity → Select effort (1-10) | Effort level recorded |
| Add Notes | Log Activity → Type notes → Save | Notes saved with activity |
| Add Distance (if applicable) | Log Activity → Enter distance | Distance recorded |
| Edit Logged Activity | History → Tap activity → Edit | Changes saved to activity log |
| Delete Logged Activity | History → Tap → Delete → Confirm | Activity removed from history |

### Progress Tracking
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Streak Card | Progress tab | Display current and best streak |
| View Weekly Stats | Progress tab → Weekly section | Show workouts completed this week |
| View Monthly Stats | Progress tab → Monthly section | Show monthly workout summary |
| View Activity History | Progress tab → History list | Show chronological activity list |
| View Weekly Chart | Progress → Charts | Display weekly activity bar chart |
| View Monthly Chart | Progress → Monthly chart | Display monthly progress line chart |

### Profile
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Profile | Dashboard → Profile tab | Display user information |
| Edit Profile | Profile → Edit → Modify → Save | Profile updated successfully |
| Change Profile Picture | Profile → Tap avatar → Select image | Image uploaded and displayed |

---

## 🏆 Achievements Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Achievements List | Navigate to Achievements | Display all available achievements |
| View Unlocked Achievements | Achievements → Unlocked tab | Show earned achievements with dates |
| View Locked Achievements | Achievements → Locked tab | Show locked achievements with progress |
| Achievement Unlock | Complete achievement criteria | Show celebration dialog, update list |
| First Workout Badge | Log first workout ever | Unlock "First Step" achievement |
| 7-Day Streak Badge | Complete 7 consecutive days | Unlock "Week Warrior" achievement |
| 30-Day Streak Badge | Complete 30 consecutive days | Unlock "Consistency Champion" |

---

## 🔔 Notifications Testing

### Notification Center
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Notifications | Tap notification bell | Show notification center with list |
| View Unread Count | Check bell icon badge | Display correct unread count |
| Mark as Read | Tap notification | Notification marked as read |
| Mark All as Read | Tap "Mark all read" | All notifications marked as read |
| Delete Notification | Swipe notification → Delete | Notification removed from list |
| Notification Grouping | View list with multiple types | Notifications grouped by date |

### Notification Types (Coach → Athlete)
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Send Welcome Notification | Assign athlete | Athlete receives welcome notification |
| Send Plan Assigned | Assign plan to athlete | Athlete receives plan notification |
| Send Encouragement | Coach → Send → Encouragement | Athlete receives motivational message |
| Send Custom Message | Coach → Send → Custom → Type message | Athlete receives custom notification |

---

## 💬 Messaging Testing

### Conversations
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| View Conversations List | Navigate to Messages | Display all conversations |
| Start New Conversation | Messages → New → Select recipient | Open chat with selected user |
| View Unread Badge | Check message icon | Show correct unread message count |

### Chat
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Send Text Message | Type message → Send | Message sent and displayed |
| Receive Message | Wait for incoming | Message appears in real-time |
| View Message Timestamps | Check message bubbles | Display correct time/date |
| Scroll Message History | Scroll up in chat | Load older messages |

---

## 📊 Charts & Analytics Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Weekly Activity Chart | Progress → Weekly | Bar chart with 7-day data |
| Monthly Progress Chart | Progress → Monthly | Line chart with monthly trends |
| Workout Type Distribution | Analytics → Types | Pie chart showing activity types |
| Coach Team Performance | Coach Analytics | Aggregate team statistics |

---

## 🛠️ Database Seeder Testing

The database seeder populates Firestore with sample test data. Access it through the Developer Tools screen in the app.

### How to Access the Seeder

1. **Via Welcome Screen**: Long-press the version number (v1.0.0) at the bottom of the welcome screen to access Developer Tools
2. **Via Deep Link**: Navigate to `/dev/seed` route in the app
3. **Via Code**: Use `context.push(RoutePaths.devSeed)` from any screen

### Running the Seeder in the App

Add this temporary code to any screen (e.g., welcome screen) for quick access:

```dart
// Temporary dev button
ElevatedButton(
  onPressed: () => context.push('/dev/seed'),
  child: const Text('Dev Tools'),
),
```

Or modify [lib/core/router/app_router.dart](lib/core/router/app_router.dart) to make the dev route accessible.

### Quick Access (Already Implemented)

The app already has a hidden developer tools access:
- Go to the **Welcome Screen**
- **Long-press** on the version number "v1.0.0" at the bottom
- This opens the Developer Tools / Database Seeder screen

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Seed Full Database | Dev Tools → Seed Database | Creates 3 coaches, 12 athletes, plans, logs |
| Clear All Data | Dev Tools → Clear → Confirm | All data deleted from Firestore |
| Verify Seeded Coaches | Login as coach | Coach account accessible with athletes |
| Verify Seeded Athletes | Login as athlete | Athlete has assigned plans and history |
| Verify Training Plans | View plans after seed | Plans exist with activities |
| Verify Activity Logs | Check athlete progress | Historical activity logs present |
| Verify Notifications | Check notification center | Sample notifications exist |

### Seeded Test Accounts

After running the seeder, the following accounts are created with password: **`Test123!`**

**Coaches:**
- **coach.mike@example.com** / Test123! - Coach Mike Johnson
- **coach.sarah@example.com** / Test123! - Coach Sarah Williams
- **coach.david@example.com** / Test123! - Coach David Chen

**Athletes (assigned to coaches):**
- **alex.t@example.com** / Test123! - Alex Thompson (Coach Mike)
- **emma.w@example.com** / Test123! - Emma Wilson (Coach Mike)
- **ryan.d@example.com** / Test123! - Ryan Davis (Coach Mike)
- **olivia.m@example.com** / Test123! - Olivia Martinez (Coach Mike)
- **liam.a@example.com** / Test123! - Liam Anderson (Coach Sarah)
- **sophia.b@example.com** / Test123! - Sophia Brown (Coach Sarah)
- **noah.t@example.com** / Test123! - Noah Taylor (Coach Sarah)
- **ava.g@example.com** / Test123! - Ava Garcia (Coach David)
- **mason.l@example.com** / Test123! - Mason Lee (Coach David)
- **isabella.k@example.com** / Test123! - Isabella Kim (Coach David)
- **ethan.p@example.com** / Test123! - Ethan Park (Coach David)
- **mia.n@example.com** / Test123! - Mia Nguyen (Coach David)

---

## 🔄 State Management Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Provider Initialization | App start | All providers initialize correctly |
| State Persistence | Make changes → Restart | State restored correctly |
| Real-time Updates | Change data in Firestore | UI updates in real-time |
| Error State Handling | Simulate network error | Error state displayed gracefully |
| Loading States | Perform async operation | Loading indicators shown |

---

## 📱 UI/UX Testing

### Responsive Design
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Portrait Mode | Use app in portrait | Layout displays correctly |
| Landscape Mode | Rotate device | Layout adjusts appropriately |
| Different Screen Sizes | Test on various devices | Responsive scaling works |

### Theme & Colors
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Light Theme | Use app | Consistent light theme applied |
| Color Contrast | Check text/background | WCAG compliant contrast |
| Brand Colors | Verify primary/secondary | Correct brand colors (#FF6B35) |

### Navigation
| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Bottom Navigation | Tap nav items | Navigate to correct tab |
| Back Navigation | Tap back button | Return to previous screen |
| Deep Linking | Use deep link URL | Navigate to correct screen |

---

## ⚠️ Error Handling Testing

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Network Disconnection | Turn off network | Show offline message |
| Firebase Errors | Simulate Firebase failure | Display user-friendly error |
| Invalid Input | Enter invalid data | Show validation errors |
| Session Expiry | Let session expire | Redirect to login |
| Empty States | View empty lists | Display empty state UI |

---

## 🧪 Running Tests

### Unit Tests
```bash
flutter test test/features/
```

### Widget Tests
```bash
flutter test test/core/widgets/
```

### Integration Tests
```bash
flutter test test/integration/
```

### All Tests
```bash
flutter test
```

### Test with Coverage
```bash
flutter test --coverage
```

---

## 📝 Test Files Structure

```
test/
├── core/
│   └── widgets/           # Widget unit tests
├── features/
│   ├── achievements/
│   │   └── domain/        # Achievement entity tests
│   ├── auth/
│   │   └── domain/        # User entity tests
│   └── notifications/
│       ├── domain/        # Notification entity tests
│       └── presentation/  # Notification widget tests
├── helpers/               # Test utilities and mocks
├── integration/           # App flow integration tests
└── widget_test.dart       # Basic widget test example
```

---

## ✅ Pre-Release Checklist

- [ ] All unit tests passing
- [ ] All widget tests passing
- [ ] All integration tests passing
- [ ] Manual testing of all user flows
- [ ] Test on Android device/emulator
- [ ] Test on iOS device/simulator
- [ ] Test with seeded data
- [ ] Test with clean/empty data
- [ ] Verify Firebase connectivity
- [ ] Check crash reporting
- [ ] Performance profiling
- [ ] Accessibility testing

---

## 📌 Notes

1. **Firebase Requirement**: Most tests require Firebase to be initialized. Use `FakeFirebaseFirestore` for unit tests.
2. **Test Data**: Use the database seeder for manual testing scenarios.
3. **Real-time Features**: Test notifications and messaging with two devices/emulators.
4. **Streaks**: Streak calculation depends on server time - ensure correct timezone handling.
