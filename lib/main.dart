import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

/// Entry point of the PushUp application.
///
/// This file should only contain the main function and app initialization.
/// All app configuration is handled in [PushUpApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize push notification service
  await PushNotificationService.instance.initialize();

  runApp(const ProviderScope(child: PushUpApp()));
}
