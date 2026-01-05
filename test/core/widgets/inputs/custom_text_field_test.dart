import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_app/core/widgets/inputs/custom_text_field.dart';

void main() {
  group('CustomTextField', () {
    testWidgets('should display label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomTextField(label: 'Email')),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('should display hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(label: 'Email', hintText: 'Enter your email'),
          ),
        ),
      );

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('should display error text when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(label: 'Email', errorText: 'Invalid email'),
          ),
        ),
      );

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('should update value through controller', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(label: 'Email', controller: controller),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(controller.text, 'test@example.com');

      controller.dispose();
    });

    testWidgets('should call onChanged when text changes', (
      WidgetTester tester,
    ) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Email',
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(changedValue, 'test@example.com');
    });

    testWidgets('should obscure text when obscureText is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(label: 'Password', obscureText: true),
          ),
        ),
      );

      // Find TextField which is wrapped inside TextFormField
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('should display prefix icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(label: 'Email', prefixIcon: Icons.email),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('should display suffix icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Password',
              suffixIcon: Icons.visibility,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should call onSuffixIconPressed when suffix icon is tapped', (
      WidgetTester tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Password',
              suffixIcon: Icons.visibility,
              onSuffixIconPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('should be disabled when enabled is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CustomTextField(label: 'Email', enabled: false)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('should display helper text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Password',
              helperText: 'Minimum 8 characters',
            ),
          ),
        ),
      );

      expect(find.text('Minimum 8 characters'), findsOneWidget);
    });
  });
}
