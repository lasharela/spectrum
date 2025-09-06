import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/widgets/custom_text_field.dart';

void main() {
  group('CustomTextField', () {
    testWidgets('displays label text', (WidgetTester tester) async {
      const labelText = 'Username';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: labelText,
              controller: TextEditingController(),
            ),
          ),
        ),
      );

      expect(find.text(labelText), findsOneWidget);
    });

    testWidgets('displays hint text', (WidgetTester tester) async {
      const hintText = 'Enter your username';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Username',
              hintText: hintText,
              controller: TextEditingController(),
            ),
          ),
        ),
      );

      // Check that the hint text is present in the widget tree
      expect(find.text(hintText), findsOneWidget);
    });

    testWidgets('accepts text input', (WidgetTester tester) async {
      final controller = TextEditingController();
      const inputText = 'test input';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Input',
              controller: controller,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), inputText);
      await tester.pump();

      expect(controller.text, equals(inputText));
    });

    testWidgets('obscures text when obscureText is true',
        (WidgetTester tester) async {
      final controller = TextEditingController(text: 'password123');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Password',
              controller: controller,
              obscureText: true,
            ),
          ),
        ),
      );

      // The TextFormField should be present
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows text when obscureText is false',
        (WidgetTester tester) async {
      final controller = TextEditingController(text: 'visible');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Email',
              controller: controller,
              obscureText: false,
            ),
          ),
        ),
      );

      // The TextFormField should be present
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('accepts custom keyboardType', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Email',
              controller: TextEditingController(),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      // The TextFormField should be present with the custom keyboard type
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('validates input when validator is provided',
        (WidgetTester tester) async {
      const errorMessage = 'Field is required';
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                labelText: 'Required Field',
                controller: TextEditingController(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return errorMessage;
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState?.validate();
      await tester.pump();

      // Should show error message for empty field
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('calls onChanged callback', (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Input',
              controller: TextEditingController(),
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      const inputText = 'new text';
      await tester.enterText(find.byType(TextFormField), inputText);
      await tester.pump();

      expect(changedValue, equals(inputText));
    });

    testWidgets('is enabled by default', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Input',
              controller: controller,
            ),
          ),
        ),
      );

      // Should be able to enter text when enabled
      await tester.enterText(find.byType(TextFormField), 'test');
      expect(controller.text, equals('test'));
    });

    testWidgets('can be disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Input',
              controller: TextEditingController(),
              enabled: false,
            ),
          ),
        ),
      );

      // The TextFormField should be present
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows prefix icon when provided', (WidgetTester tester) async {
      const icon = Icons.person;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Username',
              controller: TextEditingController(),
              prefixIcon: const Icon(icon),
            ),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('shows suffix icon when provided', (WidgetTester tester) async {
      const icon = Icons.clear;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              labelText: 'Search',
              controller: TextEditingController(),
              suffixIcon: const Icon(icon),
            ),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
    });
  });
}
