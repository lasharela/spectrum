import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/features/community/presentation/widgets/new_discussion_modal.dart';
import '../../../../helpers/test_utils.dart';

void main() {
  group('NewDiscussionModal', () {
    testWidgets('renders category select and form field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          NewDiscussionModal(
            onSubmit: ({String? title, required String content, String? imageUrl, required String category}) {},
          ),
        ),
      );

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Choose a category'), findsOneWidget);
      expect(find.text('Discussion'), findsOneWidget);
      expect(find.byType(FTextField), findsNWidgets(3));
    });

    testWidgets('shows post button disabled until content exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          NewDiscussionModal(
            onSubmit: ({String? title, required String content, String? imageUrl, required String category}) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final postButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Post'),
      );
      expect(postButton.onPress, isNull);
    });
  });
}
