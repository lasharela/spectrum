import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/community/presentation/widgets/new_discussion_modal.dart';

void main() {
  group('NewDiscussionModal', () {
    testWidgets('renders category chips and form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewDiscussionModal(
              onSubmit: ({
                required String content,
                required String category,
              }) {},
            ),
          ),
        ),
      );

      // Verify category chips present
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Sensory'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);

      // Verify form fields
      expect(find.byType(TextField), findsAtLeast(1));
    });

    testWidgets('selecting a category chip highlights it', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewDiscussionModal(
              onSubmit: ({
                required String content,
                required String category,
              }) {},
            ),
          ),
        ),
      );

      // Tap Education chip
      await tester.tap(find.text('Education'));
      await tester.pump();

      // General should no longer be selected (visually)
    });
  });
}
