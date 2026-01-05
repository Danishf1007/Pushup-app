# Features Guide - Streak & Workout Tracking

## 🔥 Streak Feature

### How It Works
The streak feature automatically tracks consecutive days when athletes complete workouts.

**Streak Calculation:**
- **Increments** when an athlete logs a workout on a new day (consecutive to the previous day)
- **Maintains** if the athlete logs multiple workouts on the same day
- **Resets to 1** if more than 1 day passes without a workout
- **Updates** automatically every time a workout is logged

### Where to See Streak

**Athlete Dashboard:**
- Quick Stats section shows "Current Streak" in days
- Progress Overview displays streak with fire icon 🔥

**Athlete Profile (Progress Tab):**
- Overall Statistics shows both "Current Streak" and "Best Streak"
- Streak card displays detailed information

**Coach View (Athlete Detail):**
- Stats row shows athlete's current streak with fire emoji 🔥
- Helps coach monitor athlete consistency

### How to Build a Streak

1. **Log Your First Workout:**
   - Dashboard → Click "Start Workout" on today's activity
   - Fill in duration, effort level, and notes
   - Click "Save"
   - Streak starts at 1 day

2. **Maintain Your Streak:**
   - Log at least one workout every day
   - Can log multiple workouts in a day (streak counts once per day)
   - Missing even one day will reset your streak

3. **Track Your Best:**
   - Your longest streak is saved as "Best Streak"
   - Try to beat your personal record!

### Technical Details
- Stored in Firestore collection: `athlete_stats`
- Fields: `currentStreak`, `longestStreak`, `lastActivityDate`
- Updated automatically via `updateStatsAfterActivity()` method
- Calculation happens when `logActivity()` is called

---

## 💪 Workout Count Feature

### How It Works
The workout count tracks total completed workouts across all time.

**Counting Logic:**
- **Increments** every time an athlete logs a new activity
- **Never decreases** (permanent record)
- **Tracks** both weekly and total workouts
- **Updates** in real-time across all screens

### Where to See Workout Count

**Athlete Dashboard:**
- Progress Overview shows "This Week" workouts
- Quick Stats displays total workouts

**Athlete Profile (Progress Tab):**
- "Total Workouts" stat card shows all-time count
- Weekly and monthly breakdowns available

**Coach View (Athlete Detail):**
- Stats row shows total workouts completed by athlete
- Recent Activity section lists individual workouts

### How to Log a Workout

**Method 1: From Dashboard**
1. Navigate to Athlete Dashboard
2. Click "Start Workout" on Today's Workout card
3. Fill in the form:
   - **Duration** (required) - in minutes
   - **Distance** (optional) - for cardio activities
   - **Effort Level** (1-10) - how hard it felt
   - **Notes** (optional) - personal observations
4. Click "Save"

**Method 2: From Workouts Tab**
1. Click Workouts icon in bottom navigation
2. Select an activity from your assigned plan
3. Click "Log Workout"
4. Fill in the form and save

**Method 3: From Activity Tab**
1. Go to Activity tab
2. Click + button to log
3. Select activity and fill details

### What Counts as a Workout?

✅ **Counts:**
- Any logged activity with duration
- Strength training sessions
- Cardio workouts
- Flexibility exercises
- Recovery activities

❌ **Doesn't Count:**
- Scheduled but not logged activities
- Planned workouts that weren't completed
- Deleted activity logs

### Technical Details
- Stored in Firestore collection: `athlete_stats`
- Fields: `totalWorkouts`, `weeklyWorkouts`, `monthlyWorkouts`
- Also tracks: `totalDuration`, `weeklyDuration`, `monthlyDuration`
- Activity logs stored in: `activityLogs` collection
- Real-time updates via StreamProvider

---

## 📊 Statistics Overview

### Available Metrics

**Individual Stats:**
- Total Workouts
- Current Streak
- Longest Streak
- Total Duration
- Weekly Workouts
- Monthly Workouts
- Last Activity Date

**Progress Tracking:**
- Weekly activity chart (workouts per day)
- Monthly progress chart (4-week view)
- Workout type distribution (pie chart)
- Recent activity history

### Data Persistence
- All stats persist in Firestore database
- Survives app restarts and device changes
- Syncs across multiple devices
- Historical data never deleted (unless manually removed)

---

## 🎯 Tips for Athletes

1. **Build Habits:**
   - Log workouts immediately after completing them
   - Set a daily reminder to maintain streak
   - Aim for consistency over intensity

2. **Track Progress:**
   - Check Progress tab weekly to see trends
   - Compare monthly workouts to identify patterns
   - Celebrate milestone achievements

3. **Stay Motivated:**
   - Try to beat your longest streak
   - Set a goal for total workouts per month
   - Share progress with your coach

4. **Be Honest:**
   - Log actual duration and effort
   - Add notes about how you felt
   - Skip logging if you didn't complete the workout

---

## 🏆 Achievements

The app also tracks achievements based on:
- Workout streaks (3, 7, 14, 30 days)
- Total workouts (10, 25, 50, 100)
- Plan completion
- Consistency milestones

Check the Achievements section to see your progress!
