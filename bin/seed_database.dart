// ignore_for_file: avoid_print
/// Command-line script to run the database seeder.
///
/// Run this script with:
/// ```
/// dart run bin/seed_database.dart
/// ```
///
/// Note: This requires Firebase to be initialized. For local development,
/// you may need to configure Firebase CLI or use the Firebase Emulator Suite.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pushup_app/core/utils/database_seeder.dart';
import 'package:pushup_app/firebase_options.dart';

Future<void> main() async {
  print('🌱 PushUp Database Seeder');
  print('========================\n');

  try {
    // Initialize Firebase
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');

    // Create seeder instance
    final seeder = DatabaseSeeder(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );

    // Ask user for action
    print('Choose an action:');
    print('1. Seed database with test data');
    print('2. Clear all data');
    print('3. Seed and then clear (test mode)');
    print('\nEnter 1, 2, or 3:');

    // For non-interactive mode, default to seeding
    print('\n🌱 Starting database seeding...\n');

    final result = await seeder.seedAll();

    if (result.success) {
      print('✅ ${result.message}');
      print('\nSeeded data summary:');
      print('  • Coaches: ${result.coachCount}');
      print('  • Athletes: ${result.athleteCount}');
      print('  • Training Plans: ${result.planCount}');
      print('\nTest accounts created:');
      print('  Coaches:');
      print('    - coach.mike@example.com');
      print('    - coach.sarah@example.com');
      print('    - coach.david@example.com');
      print('  \nAthletes are linked to coaches automatically.');
    } else {
      print('❌ Seeding failed: ${result.message}');
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('\nStack trace:\n$stackTrace');
  }

  print('\n========================');
  print('Seeding complete!');
}
