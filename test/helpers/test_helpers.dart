import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_app/core/constants/app_constants.dart';
import 'package:pushup_app/features/auth/domain/entities/user_entity.dart';

/// Test helpers and utilities for unit and widget tests.

/// Creates a test user entity.
UserEntity createTestUser({
  String id = 'test-user-id',
  String email = 'test@example.com',
  String displayName = 'Test User',
  UserRole role = UserRole.athlete,
  String? coachId,
  String? profilePicture,
  DateTime? createdAt,
  DateTime? lastActive,
  String? fcmToken,
}) {
  return UserEntity(
    id: id,
    email: email,
    displayName: displayName,
    role: role,
    coachId: coachId,
    profilePicture: profilePicture,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    lastActive: lastActive,
    fcmToken: fcmToken,
  );
}

/// Creates a coach user entity.
UserEntity createTestCoach({
  String id = 'test-coach-id',
  String email = 'coach@example.com',
  String displayName = 'Coach Smith',
  DateTime? createdAt,
}) {
  return createTestUser(
    id: id,
    email: email,
    displayName: displayName,
    role: UserRole.coach,
    createdAt: createdAt,
  );
}

/// Creates an athlete user entity.
UserEntity createTestAthlete({
  String id = 'test-athlete-id',
  String email = 'athlete@example.com',
  String displayName = 'John Doe',
  String coachId = 'test-coach-id',
  DateTime? createdAt,
}) {
  return createTestUser(
    id: id,
    email: email,
    displayName: displayName,
    role: UserRole.athlete,
    coachId: coachId,
    createdAt: createdAt,
  );
}

/// Wraps a widget with MaterialApp and ProviderScope for testing.
Widget wrapWithMaterialApp(
  Widget widget, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: widget)),
  );
}

/// Wraps a widget with MaterialApp, ProviderScope, and custom theme.
Widget wrapWithTestApp(
  Widget widget, {
  List<Override> overrides = const [],
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: theme ?? ThemeData.light(), home: widget),
  );
}

/// Pumps a widget and waits for animations to settle.
Future<void> pumpWidgetAndSettle(
  WidgetTester tester,
  Widget widget, {
  Duration? duration,
}) async {
  await tester.pumpWidget(widget);
  if (duration != null) {
    await tester.pump(duration);
  }
  await tester.pumpAndSettle();
}

/// Extension on WidgetTester for common operations.
extension WidgetTesterExtensions on WidgetTester {
  /// Pumps the widget and settles all animations.
  Future<void> pumpAndSettleWidget(Widget widget) async {
    await pumpWidget(widget);
    await pumpAndSettle();
  }

  /// Taps a widget and settles.
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enters text and settles.
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }
}

/// Matcher for verifying icon presence.
Matcher hasIcon(IconData icon) => findsWidgets;

/// Creates a mock date for consistent testing.
DateTime testDate([int daysAgo = 0]) {
  return DateTime(2024, 6, 15).subtract(Duration(days: daysAgo));
}
