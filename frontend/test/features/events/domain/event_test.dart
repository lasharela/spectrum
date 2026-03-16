import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/events/domain/event.dart';

void main() {
  const authorJson = <String, dynamic>{
    'id': 'org1',
    'name': 'Test Organizer',
    'image': 'https://example.com/org.jpg',
    'userType': 'professional',
  };

  final sampleJson = <String, dynamic>{
    'id': 'evt1',
    'title': 'Autism Awareness Workshop',
    'description': 'A workshop about autism awareness.',
    'category': 'Workshop',
    'location': 'Community Center, NYC',
    'startDate': '2026-04-01T09:00:00.000Z',
    'endDate': '2026-04-01T17:00:00.000Z',
    'imageUrl': 'https://example.com/event.jpg',
    'isOnline': true,
    'isFree': false,
    'price': '25.00',
    'status': 'active',
    'organizerId': 'org1',
    'organizer': authorJson,
    'attendeeCount': 42,
    'saved': true,
    'rsvped': true,
    'createdAt': '2026-01-01T00:00:00.000Z',
  };

  group('Event', () {
    group('fromJson', () {
      test('parses valid JSON with all fields', () {
        final event = Event.fromJson(sampleJson);

        expect(event.id, 'evt1');
        expect(event.title, 'Autism Awareness Workshop');
        expect(event.description, 'A workshop about autism awareness.');
        expect(event.category, 'Workshop');
        expect(event.location, 'Community Center, NYC');
        expect(event.startDate, DateTime.parse('2026-04-01T09:00:00.000Z'));
        expect(event.endDate, DateTime.parse('2026-04-01T17:00:00.000Z'));
        expect(event.imageUrl, 'https://example.com/event.jpg');
        expect(event.isOnline, true);
        expect(event.isFree, false);
        expect(event.price, '25.00');
        expect(event.status, 'active');
        expect(event.organizerId, 'org1');
        expect(event.organizer.id, 'org1');
        expect(event.organizer.name, 'Test Organizer');
        expect(event.organizer.image, 'https://example.com/org.jpg');
        expect(event.organizer.userType, 'professional');
        expect(event.attendeeCount, 42);
        expect(event.saved, true);
        expect(event.rsvped, true);
        expect(event.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      });

      test('handles null optional fields (description, location, endDate, imageUrl, price)', () {
        final json = <String, dynamic>{
          'id': 'evt2',
          'title': 'Basic Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.description, isNull);
        expect(event.location, isNull);
        expect(event.endDate, isNull);
        expect(event.imageUrl, isNull);
        expect(event.price, isNull);
      });

      test('defaults category to Workshop when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default Category Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.category, 'Workshop');
      });

      test('defaults isOnline to false when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default isOnline Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.isOnline, false);
      });

      test('defaults isFree to true when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default isFree Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.isFree, true);
      });

      test('defaults status to pending when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default status Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.status, 'pending');
      });

      test('defaults attendeeCount to 0 when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default attendeeCount Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.attendeeCount, 0);
      });

      test('defaults saved to false when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default saved Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.saved, false);
      });

      test('defaults rsvped to false when absent', () {
        final json = <String, dynamic>{
          'id': 'evt3',
          'title': 'Default rsvped Event',
          'startDate': '2026-05-01T10:00:00.000Z',
          'organizerId': 'org1',
          'organizer': authorJson,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

        final event = Event.fromJson(json);

        expect(event.rsvped, false);
      });
    });

    group('copyWith', () {
      late Event baseEvent;

      setUp(() {
        baseEvent = Event.fromJson(sampleJson);
      });

      test('correctly updates saved', () {
        final updated = baseEvent.copyWith(saved: false);
        expect(updated.saved, false);
      });

      test('correctly updates rsvped', () {
        final updated = baseEvent.copyWith(rsvped: false);
        expect(updated.rsvped, false);
      });

      test('correctly updates attendeeCount', () {
        final updated = baseEvent.copyWith(attendeeCount: 100);
        expect(updated.attendeeCount, 100);
      });

      test('correctly updates status', () {
        final updated = baseEvent.copyWith(status: 'cancelled');
        expect(updated.status, 'cancelled');
      });

      test('preserves unchanged fields when updating saved', () {
        final updated = baseEvent.copyWith(saved: false);

        expect(updated.id, baseEvent.id);
        expect(updated.title, baseEvent.title);
        expect(updated.description, baseEvent.description);
        expect(updated.category, baseEvent.category);
        expect(updated.location, baseEvent.location);
        expect(updated.startDate, baseEvent.startDate);
        expect(updated.endDate, baseEvent.endDate);
        expect(updated.imageUrl, baseEvent.imageUrl);
        expect(updated.isOnline, baseEvent.isOnline);
        expect(updated.isFree, baseEvent.isFree);
        expect(updated.price, baseEvent.price);
        expect(updated.status, baseEvent.status);
        expect(updated.organizerId, baseEvent.organizerId);
        expect(updated.organizer, baseEvent.organizer);
        expect(updated.attendeeCount, baseEvent.attendeeCount);
        expect(updated.rsvped, baseEvent.rsvped);
        expect(updated.createdAt, baseEvent.createdAt);
      });

      test('preserves unchanged fields when no arguments provided', () {
        final updated = baseEvent.copyWith();

        expect(updated.id, baseEvent.id);
        expect(updated.title, baseEvent.title);
        expect(updated.category, baseEvent.category);
        expect(updated.status, baseEvent.status);
        expect(updated.attendeeCount, baseEvent.attendeeCount);
        expect(updated.saved, baseEvent.saved);
        expect(updated.rsvped, baseEvent.rsvped);
      });
    });
  });
}
