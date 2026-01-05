import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Send push notification when any in-app notification is created
 * This is the main trigger for all push notifications
 */
export const onNotificationCreated = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    const { receiverId, title, message, type, senderName, data } = notification;

    try {
      // Get receiver's FCM token
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${receiverId}`);
        return null;
      }

      // Build notification icon based on type
      let icon = "📬";
      switch (type) {
        case "planAssigned":
          icon = "🎯";
          break;
        case "encouragement":
          icon = "💪";
          break;
        case "reminder":
          icon = "⏰";
          break;
        case "achievement":
          icon = "🏆";
          break;
        case "coachMessage":
          icon = "💬";
          break;
        case "workoutCompleted":
          icon = "✅";
          break;
      }

      // Send push notification
      const fcmMessage: admin.messaging.Message = {
        notification: {
          title: `${icon} ${title}`,
          body: message,
        },
        data: {
          type: type || "general",
          notificationId: snapshot.id,
          ...(data || {}),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "pushup_channel",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: `${icon} ${title}`,
                body: message,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
        token: fcmToken,
      };

      await admin.messaging().send(fcmMessage);
      console.log(`Push notification sent to user ${receiverId}: ${title}`);
      return null;
    } catch (error) {
      console.error("Error sending push notification:", error);
      return null;
    }
  });

/**
 * Send push notification when a plan is assigned to an athlete
 */
export const onPlanAssigned = functions.firestore
  .document("planAssignments/{assignmentId}")
  .onCreate(async (snapshot, context) => {
    const assignment = snapshot.data();
    const { athleteId, planId, assignedBy } = assignment;

    try {
      // Get athlete's FCM token
      const athleteDoc = await admin.firestore()
        .collection("users")
        .doc(athleteId)
        .get();

      const fcmToken = athleteDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for athlete ${athleteId}`);
        return null;
      }

      // Get plan details
      const planDoc = await admin.firestore()
        .collection("trainingPlans")
        .doc(planId)
        .get();

      const planName = planDoc.data()?.name || "Training Plan";

      // Get coach name
      const coachDoc = await admin.firestore()
        .collection("users")
        .doc(assignedBy)
        .get();

      const coachName = coachDoc.data()?.name || "Your coach";

      // Send notification
      const message: admin.messaging.Message = {
        notification: {
          title: "🎯 New Training Plan Assigned!",
          body: `${coachName} assigned you "${planName}". Let's get started!`,
        },
        data: {
          type: "plan_assigned",
          planId: planId,
          assignmentId: snapshot.id,
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`Notification sent to athlete ${athleteId} for plan assignment`);

      return null;
    } catch (error) {
      console.error("Error sending plan assignment notification:", error);
      return null;
    }
  });

/**
 * Send push notification when an athlete completes a workout
 */
export const onWorkoutCompleted = functions.firestore
  .document("activityLogs/{activityId}")
  .onCreate(async (snapshot, context) => {
    const activity = snapshot.data();
    const { athleteId, activityName, reps, duration } = activity;

    try {
      // Get athlete info
      const athleteDoc = await admin.firestore()
        .collection("users")
        .doc(athleteId)
        .get();

      const athleteData = athleteDoc.data();
      const coachId = athleteData?.coachId;

      if (!coachId) {
        console.log(`No coach assigned to athlete ${athleteId}`);
        return null;
      }

      // Get coach's FCM token
      const coachDoc = await admin.firestore()
        .collection("users")
        .doc(coachId)
        .get();

      const fcmToken = coachDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for coach ${coachId}`);
        return null;
      }

      const athleteName = athleteData?.name || "An athlete";

      // Build activity details
      let details = activityName;
      if (reps) details += ` - ${reps} reps`;
      if (duration) details += ` - ${duration} mins`;

      // Send notification
      const message: admin.messaging.Message = {
        notification: {
          title: "💪 Workout Completed!",
          body: `${athleteName} just finished: ${details}`,
        },
        data: {
          type: "workout_completed",
          athleteId: athleteId,
          activityId: snapshot.id,
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`Notification sent to coach ${coachId} for workout completion`);

      return null;
    } catch (error) {
      console.error("Error sending workout completion notification:", error);
      return null;
    }
  });

/**
 * Send push notification for achievement unlocks
 */
export const onAchievementUnlocked = functions.firestore
  .document("userAchievements/{achievementId}")
  .onCreate(async (snapshot, context) => {
    const userAchievement = snapshot.data();
    const { userId, achievementId } = userAchievement;

    try {
      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return null;
      }

      // Get achievement details
      const achievementDoc = await admin.firestore()
        .collection("achievements")
        .doc(achievementId)
        .get();

      const achievementData = achievementDoc.data();
      const achievementName = achievementData?.name || "Achievement";
      const achievementIcon = achievementData?.icon || "🏆";

      // Send notification
      const message: admin.messaging.Message = {
        notification: {
          title: `${achievementIcon} Achievement Unlocked!`,
          body: `Congratulations! You've earned "${achievementName}"`,
        },
        data: {
          type: "achievement_unlocked",
          achievementId: achievementId,
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`Achievement notification sent to user ${userId}`);

      return null;
    } catch (error) {
      console.error("Error sending achievement notification:", error);
      return null;
    }
  });

/**
 * Send reminder notification for today's workout
 * Scheduled to run daily at 9 AM
 */
export const sendDailyWorkoutReminders = functions.pubsub
  .schedule("0 9 * * *")
  .timeZone("America/New_York")
  .onRun(async (context) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    try {
      // Get all active plan assignments for today
      const assignmentsSnapshot = await admin.firestore()
        .collection("planAssignments")
        .where("status", "==", "active")
        .get();

      const notifications: Promise<string>[] = [];

      for (const doc of assignmentsSnapshot.docs) {
        const assignment = doc.data();
        const { athleteId, planId } = assignment;

        // Get athlete's FCM token
        const athleteDoc = await admin.firestore()
          .collection("users")
          .doc(athleteId)
          .get();

        const fcmToken = athleteDoc.data()?.fcmToken;
        if (!fcmToken) continue;

        // Get plan name
        const planDoc = await admin.firestore()
          .collection("trainingPlans")
          .doc(planId)
          .get();

        const planName = planDoc.data()?.name || "your workout";

        // Send reminder
        const message: admin.messaging.Message = {
          notification: {
            title: "⏰ Time to Workout!",
            body: `Don't forget to complete ${planName} today. Let's keep that streak going!`,
          },
          data: {
            type: "daily_reminder",
            planId: planId,
          },
          token: fcmToken,
        };

        notifications.push(admin.messaging().send(message));
      }

      await Promise.all(notifications);
      console.log(`Sent ${notifications.length} daily workout reminders`);

      return null;
    } catch (error) {
      console.error("Error sending daily reminders:", error);
      return null;
    }
  });

/**
 * Send encouragement when an athlete hasn't worked out in 3 days
 * Runs daily to check for inactive athletes
 */
export const sendInactivityReminders = functions.pubsub
  .schedule("0 18 * * *") // 6 PM daily
  .timeZone("America/New_York")
  .onRun(async (context) => {
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    try {
      // Get all athletes
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "athlete")
        .get();

      const notifications: Promise<string>[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) continue;

        // Check last activity
        const lastActivitySnapshot = await admin.firestore()
          .collection("activityLogs")
          .where("athleteId", "==", userId)
          .orderBy("completedAt", "desc")
          .limit(1)
          .get();

        if (lastActivitySnapshot.empty) {
          // No activities ever - send welcome reminder
          const message: admin.messaging.Message = {
            notification: {
              title: "👋 Ready to get started?",
              body: "Let's begin your fitness journey! Check out your training plan.",
            },
            data: {
              type: "inactivity_reminder",
            },
            token: fcmToken,
          };

          notifications.push(admin.messaging().send(message));
        } else {
          const lastActivity = lastActivitySnapshot.docs[0].data();
          const lastActivityDate = lastActivity.completedAt.toDate();

          if (lastActivityDate < threeDaysAgo) {
            // Send re-engagement message
            const message: admin.messaging.Message = {
              notification: {
                title: "💪 We miss you!",
                body: "It's been a few days. Ready to get back on track?",
              },
              data: {
                type: "inactivity_reminder",
              },
              token: fcmToken,
            };

            notifications.push(admin.messaging().send(message));
          }
        }
      }

      await Promise.all(notifications);
      console.log(`Sent ${notifications.length} inactivity reminders`);

      return null;
    } catch (error) {
      console.error("Error sending inactivity reminders:", error);
      return null;
    }
  });
