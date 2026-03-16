import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/events/domain/event.dart';
import 'package:spectrum_app/features/events/presentation/widgets/event_card.dart';
import 'package:spectrum_app/shared/domain/author.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  final defaultOrganizer = Author(
    id: 'org-1',
    name: 'Test Organizer',
    userType: 'professional',
  );

  Event makeEvent({
    String title = 'Sensory-Friendly Movie Night',
    String category = 'Social',
    String? location,
    DateTime? startDate,
    bool isOnline = false,
    bool isFree = true,
    String? price,
  }) {
    return Event(
      id: 'event-1',
      title: title,
      category: category,
      location: location,
      startDate: startDate ?? DateTime(2025, 6, 15, 14, 30),
      isOnline: isOnline,
      isFree: isFree,
      price: price,
      organizerId: 'user-1',
      organizer: defaultOrganizer,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  group('EventCard', () {
    testWidgets('renders event title', (tester) async {
      final event = makeEvent(title: 'Autism Awareness Workshop');

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Autism Awareness Workshop'), findsOneWidget);
    });

    testWidgets('renders category badge', (tester) async {
      final event = makeEvent(category: 'Workshop');

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workshop'), findsOneWidget);
    });

    testWidgets('renders formatted date/time string', (tester) async {
      final date = DateTime(2025, 6, 15, 14, 30);
      final event = makeEvent(startDate: date);

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      final dateStr = DateFormat('MMM d, yyyy').format(date);
      final timeStr = DateFormat('h:mm a').format(date);
      final expected = '$dateStr at $timeStr';

      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('renders location when not null', (tester) async {
      final event = makeEvent(location: 'Community Center, Room 5');

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Community Center, Room 5'), findsOneWidget);
    });

    testWidgets('does not render location row when location is null',
        (tester) async {
      final event = makeEvent(location: null);

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      // Only the date/time detail row should exist, not a location row
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      expect(find.byIcon(Icons.computer_outlined), findsNothing);
    });

    testWidgets('renders FREE text when isFree is true', (tester) async {
      final event = makeEvent(isFree: true);

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('FREE'), findsOneWidget);
    });

    testWidgets('renders price when not free and price is set', (tester) async {
      final event = makeEvent(isFree: false, price: '\$25.00');

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$25.00'), findsOneWidget);
      expect(find.text('FREE'), findsNothing);
    });

    testWidgets('does not render FREE or price when not free and price is null',
        (tester) async {
      final event = makeEvent(isFree: false, price: null);

      await tester.pumpWidget(
        buildTestWidget(EventCard(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('FREE'), findsNothing);
    });
  });
}
