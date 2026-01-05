# How to Clear & Re-seed Database

## Quick Access to Seeder

### Method 1: From Welcome Screen (Easiest)
1. Run the app
2. On the **Welcome Screen**, **long-press** the app logo/title at the top
3. This opens the Dev Seed Screen

### Method 2: Manual Navigation
1. From anywhere in the app, navigate to: `/dev/seed`
2. Or use the route path in your browser/deep link

## Using the Dev Seed Screen

Once you're in the Dev Seed Screen, you'll see two buttons:

### 🧹 Clear All Data
- **What it does**: Deletes all test data from Firestore AND Firebase Auth
- **Warning**: This is irreversible! 
- Use this first if you want fresh data

### 🌱 Seed Database
- **What it does**: Creates realistic test data:
  - ✅ 3 coaches
  - ✅ 12 athletes (4 per coach)
  - ✅ 5 training plans
  - ✅ Plan assignments with realistic completion rates
  - ✅ Activity logs linked to plans
  - ✅ Athlete statistics
  - ✅ Notifications

## Recommended Workflow

```
1. Click "Clear All Data" → Wait for success message
2. Click "Seed Database" → Wait for completion
3. Sign in with any test account (see below)
4. Enjoy realistic demo data! 🎉
```

## Test Accounts

All accounts use password: **Test123!**

### Coach Accounts
- coach.mike@example.com
- coach.sarah@example.com
- coach.david@example.com

### Athlete Accounts
- noah.t@example.com (Coach Sarah's athlete)
- sophia.b@example.com (Coach Sarah's athlete)
- liam.a@example.com (Coach Sarah's athlete)
- alex.t@example.com (Coach Mike's athlete)
- emma.w@example.com (Coach Mike's athlete)
- ryan.d@example.com (Coach Mike's athlete)
- olivia.m@example.com (Coach Mike's athlete)
- ava.g@example.com (Coach David's athlete)
- mason.l@example.com (Coach David's athlete)
- isabella.k@example.com (Coach David's athlete)
- ethan.p@example.com (Coach David's athlete)
- mia.n@example.com (Coach David's athlete)

## What's Fixed?

✅ **Consistent Data**: All athletes under the same coach now have completion rates based on actual logged activities, not random numbers

✅ **Realistic Progress**: Completion rates range from 30-80%, showing varied but realistic progress

✅ **Automatic Updates**: When you log new activities, completion rates update automatically

✅ **Proper Linking**: Activity logs are properly linked to assignments and plan activities

## Data Breakdown

After seeding, each athlete will have:
- **1 active plan assignment** with realistic completion (30-80%)
- **Activity logs** matching activities from their assigned plan
- **Updated statistics** (streaks, workout counts, etc.)
- **Notifications** from their coach

The completion percentage you see reflects **actual completed activities** from their plan!
