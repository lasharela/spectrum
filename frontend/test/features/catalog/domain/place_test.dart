import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/catalog/domain/place.dart';

void main() {
  final sampleOwnerJson = <String, dynamic>{
    'id': 'owner1',
    'name': 'Jane Doe',
    'image': 'https://example.com/avatar.jpg',
    'userType': 'parent',
  };

  final sampleJson = <String, dynamic>{
    'id': 'place1',
    'name': 'Sensory Park',
    'description': 'A quiet park with sensory activities.',
    'category': 'Park',
    'address': '123 Main St, Springfield',
    'imageUrl': 'https://example.com/park.jpg',
    'averageRating': 4.5,
    'ratingCount': 12,
    'tags': <dynamic>['outdoor', 'sensory'],
    'ageGroups': <dynamic>['3-6', '7-12'],
    'specialNeeds': <dynamic>['autism', 'adhd'],
    'latitude': 37.7749,
    'longitude': -122.4194,
    'ownerId': 'owner1',
    'owner': sampleOwnerJson,
    'saved': true,
    'userRating': 5,
    'createdAt': '2026-01-15T10:00:00.000Z',
  };

  group('Place', () {
    group('fromJson', () {
      test('parses valid JSON with all fields', () {
        final place = Place.fromJson(sampleJson);

        expect(place.id, 'place1');
        expect(place.name, 'Sensory Park');
        expect(place.description, 'A quiet park with sensory activities.');
        expect(place.category, 'Park');
        expect(place.address, '123 Main St, Springfield');
        expect(place.imageUrl, 'https://example.com/park.jpg');
        expect(place.averageRating, 4.5);
        expect(place.ratingCount, 12);
        expect(place.tags, ['outdoor', 'sensory']);
        expect(place.ageGroups, ['3-6', '7-12']);
        expect(place.specialNeeds, ['autism', 'adhd']);
        expect(place.latitude, 37.7749);
        expect(place.longitude, -122.4194);
        expect(place.ownerId, 'owner1');
        expect(place.owner.id, 'owner1');
        expect(place.owner.name, 'Jane Doe');
        expect(place.saved, true);
        expect(place.userRating, 5);
        expect(place.createdAt, DateTime.parse('2026-01-15T10:00:00.000Z'));
      });

      test('handles null optional fields', () {
        final json = <String, dynamic>{
          'id': 'place2',
          'name': 'Basic Place',
          'description': null,
          'category': 'General',
          'address': null,
          'imageUrl': null,
          'averageRating': 0,
          'ratingCount': 0,
          'tags': <dynamic>[],
          'ageGroups': <dynamic>[],
          'specialNeeds': <dynamic>[],
          'latitude': null,
          'longitude': null,
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'saved': false,
          'userRating': null,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.description, isNull);
        expect(place.address, isNull);
        expect(place.imageUrl, isNull);
        expect(place.latitude, isNull);
        expect(place.longitude, isNull);
        expect(place.userRating, isNull);
      });

      test('defaults category to General when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'No Category Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.category, 'General');
      });

      test('defaults averageRating to 0 when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'No Rating Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.averageRating, 0.0);
      });

      test('defaults ratingCount to 0 when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'No Rating Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.ratingCount, 0);
      });

      test('defaults tags to empty list when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'No Tags Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.tags, isEmpty);
      });

      test('defaults ageGroups to empty list when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'No AgeGroups Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.ageGroups, isEmpty);
      });

      test('defaults specialNeeds to empty list when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'No SpecialNeeds Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.specialNeeds, isEmpty);
      });

      test('defaults saved to false when absent', () {
        final json = <String, dynamic>{
          'id': 'place3',
          'name': 'Unsaved Place',
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.saved, false);
      });

      test('correctly parses tags list field', () {
        final json = <String, dynamic>{
          'id': 'place4',
          'name': 'Tagged Place',
          'tags': <dynamic>['quiet', 'outdoor', 'family-friendly'],
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.tags, ['quiet', 'outdoor', 'family-friendly']);
      });

      test('correctly parses ageGroups list field', () {
        final json = <String, dynamic>{
          'id': 'place4',
          'name': 'Age Group Place',
          'ageGroups': <dynamic>['0-2', '3-6', '7-12', '13+'],
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.ageGroups, ['0-2', '3-6', '7-12', '13+']);
      });

      test('correctly parses specialNeeds list field', () {
        final json = <String, dynamic>{
          'id': 'place4',
          'name': 'Special Needs Place',
          'specialNeeds': <dynamic>['autism', 'adhd', 'sensory'],
          'ownerId': 'owner1',
          'owner': sampleOwnerJson,
          'createdAt': '2026-02-01T00:00:00.000Z',
        };

        final place = Place.fromJson(json);

        expect(place.specialNeeds, ['autism', 'adhd', 'sensory']);
      });
    });

    group('copyWith', () {
      late Place basePlace;

      setUp(() {
        basePlace = Place.fromJson(sampleJson);
      });

      test('correctly updates saved', () {
        final updated = basePlace.copyWith(saved: false);

        expect(updated.saved, false);
        expect(basePlace.saved, true);
      });

      test('correctly updates userRating', () {
        final updated = basePlace.copyWith(userRating: 3);

        expect(updated.userRating, 3);
        expect(basePlace.userRating, 5);
      });

      test('correctly updates averageRating', () {
        final updated = basePlace.copyWith(averageRating: 3.2);

        expect(updated.averageRating, 3.2);
        expect(basePlace.averageRating, 4.5);
      });

      test('correctly updates ratingCount', () {
        final updated = basePlace.copyWith(ratingCount: 20);

        expect(updated.ratingCount, 20);
        expect(basePlace.ratingCount, 12);
      });

      test('preserves unchanged fields', () {
        final updated = basePlace.copyWith(saved: false);

        expect(updated.id, basePlace.id);
        expect(updated.name, basePlace.name);
        expect(updated.description, basePlace.description);
        expect(updated.category, basePlace.category);
        expect(updated.address, basePlace.address);
        expect(updated.imageUrl, basePlace.imageUrl);
        expect(updated.averageRating, basePlace.averageRating);
        expect(updated.ratingCount, basePlace.ratingCount);
        expect(updated.tags, basePlace.tags);
        expect(updated.ageGroups, basePlace.ageGroups);
        expect(updated.specialNeeds, basePlace.specialNeeds);
        expect(updated.latitude, basePlace.latitude);
        expect(updated.longitude, basePlace.longitude);
        expect(updated.ownerId, basePlace.ownerId);
        expect(updated.owner.id, basePlace.owner.id);
        expect(updated.userRating, basePlace.userRating);
        expect(updated.createdAt, basePlace.createdAt);
      });
    });
  });
}
