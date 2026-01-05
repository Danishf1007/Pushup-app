import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:pushup_app/features/notifications/presentation/widgets/notification_badge.dart';

void main() {
  group('NotificationBadge', () {
    testWidgets('should display notification icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider(
              'test-user',
            ).overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBadge(userId: 'test-user', onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('should display badge with count when unread > 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider(
              'test-user',
            ).overrideWith((ref) => Stream.value(5)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBadge(userId: 'test-user', onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should display 99+ when count exceeds 99', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider(
              'test-user',
            ).overrideWith((ref) => Stream.value(150)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBadge(userId: 'test-user', onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('should not display badge when count is 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider(
              'test-user',
            ).overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBadge(userId: 'test-user', onTap: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that no badge number is displayed
      expect(find.text('0'), findsNothing);
    });

    testWidgets('should call onTap when pressed', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider(
              'test-user',
            ).overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBadge(
                userId: 'test-user',
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should use custom icon color when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider(
              'test-user',
            ).overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotificationBadge(
                userId: 'test-user',
                onTap: () {},
                iconColor: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.notifications_outlined),
      );
      expect(icon.color, Colors.blue);
    });
  });
}
