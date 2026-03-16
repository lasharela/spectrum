import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';
import 'package:spectrum_app/shared/domain/author.dart';

void main() {
  const authorJson = {
    'id': 'u1',
    'name': 'Alice',
    'image': null,
    'userType': 'parent',
  };

  const baseAuthor = Author(
    id: 'u1',
    name: 'Alice',
    userType: 'parent',
  );

  group('Promotion', () {
    test('fromJson creates a valid Promotion from JSON map', () {
      final json = {
        'id': 'p1',
        'title': '20% Off Sensory Toys',
        'description': 'Great deal on sensory toys',
        'category': 'Toys',
        'discount': '20%',
        'store': 'SensoryWorld',
        'brandLogoUrl': 'https://example.com/logo.png',
        'imageUrl': 'https://example.com/promo.jpg',
        'expiresAt': '2027-06-01T00:00:00.000Z',
        'validFrom': '2026-01-01T00:00:00.000Z',
        'organizationId': 'org1',
        'createdById': 'u1',
        'createdBy': authorJson,
        'likesCount': 10,
        'liked': true,
        'saved': true,
        'claimed': false,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final promo = Promotion.fromJson(json);

      expect(promo.id, 'p1');
      expect(promo.title, '20% Off Sensory Toys');
      expect(promo.description, 'Great deal on sensory toys');
      expect(promo.category, 'Toys');
      expect(promo.discount, '20%');
      expect(promo.store, 'SensoryWorld');
      expect(promo.brandLogoUrl, 'https://example.com/logo.png');
      expect(promo.imageUrl, 'https://example.com/promo.jpg');
      expect(promo.expiresAt, DateTime.parse('2027-06-01T00:00:00.000Z'));
      expect(promo.validFrom, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(promo.organizationId, 'org1');
      expect(promo.createdById, 'u1');
      expect(promo.createdBy.id, 'u1');
      expect(promo.likesCount, 10);
      expect(promo.liked, true);
      expect(promo.saved, true);
      expect(promo.claimed, false);
    });

    test('fromJson handles null optional fields (discount, expiresAt, description)', () {
      final json = {
        'id': 'p2',
        'title': 'Free Resource',
        'category': 'General',
        'store': 'CommunityStore',
        'validFrom': '2026-01-01T00:00:00.000Z',
        'createdById': 'u1',
        'createdBy': authorJson,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final promo = Promotion.fromJson(json);

      expect(promo.description, isNull);
      expect(promo.discount, isNull);
      expect(promo.expiresAt, isNull);
      expect(promo.brandLogoUrl, isNull);
      expect(promo.imageUrl, isNull);
      expect(promo.organizationId, isNull);
      expect(promo.likesCount, 0);
      expect(promo.liked, false);
      expect(promo.saved, false);
      expect(promo.claimed, false);
    });

    test('fromJson defaults category to General when absent', () {
      final json = {
        'id': 'p3',
        'title': 'No Category Promo',
        'store': 'AnyStore',
        'validFrom': '2026-01-01T00:00:00.000Z',
        'createdById': 'u1',
        'createdBy': authorJson,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final promo = Promotion.fromJson(json);

      expect(promo.category, 'General');
    });

    test('copyWith correctly updates liked', () {
      final promo = Promotion(
        id: 'p1',
        title: 'Test Promo',
        category: 'General',
        store: 'TestStore',
        validFrom: DateTime(2026),
        createdById: 'u1',
        createdBy: baseAuthor,
        createdAt: DateTime(2026),
      );

      final updated = promo.copyWith(liked: true);

      expect(updated.liked, true);
      expect(promo.liked, false);
    });

    test('copyWith correctly updates likesCount', () {
      final promo = Promotion(
        id: 'p1',
        title: 'Test Promo',
        category: 'General',
        store: 'TestStore',
        validFrom: DateTime(2026),
        createdById: 'u1',
        createdBy: baseAuthor,
        createdAt: DateTime(2026),
        likesCount: 5,
      );

      final updated = promo.copyWith(likesCount: 10);

      expect(updated.likesCount, 10);
      expect(promo.likesCount, 5);
    });

    test('copyWith correctly updates saved', () {
      final promo = Promotion(
        id: 'p1',
        title: 'Test Promo',
        category: 'General',
        store: 'TestStore',
        validFrom: DateTime(2026),
        createdById: 'u1',
        createdBy: baseAuthor,
        createdAt: DateTime(2026),
      );

      final updated = promo.copyWith(saved: true);

      expect(updated.saved, true);
      expect(promo.saved, false);
    });

    test('copyWith correctly updates claimed', () {
      final promo = Promotion(
        id: 'p1',
        title: 'Test Promo',
        category: 'General',
        store: 'TestStore',
        validFrom: DateTime(2026),
        createdById: 'u1',
        createdBy: baseAuthor,
        createdAt: DateTime(2026),
      );

      final updated = promo.copyWith(claimed: true);

      expect(updated.claimed, true);
      expect(promo.claimed, false);
    });

    test('copyWith preserves unchanged fields', () {
      final promo = Promotion(
        id: 'p1',
        title: 'Test Promo',
        category: 'General',
        store: 'TestStore',
        validFrom: DateTime(2026),
        createdById: 'u1',
        createdBy: baseAuthor,
        createdAt: DateTime(2026),
        likesCount: 7,
        liked: false,
        saved: false,
        claimed: false,
      );

      final updated = promo.copyWith(liked: true);

      expect(updated.id, 'p1');
      expect(updated.title, 'Test Promo');
      expect(updated.store, 'TestStore');
      expect(updated.likesCount, 7);
      expect(updated.saved, false);
      expect(updated.claimed, false);
    });

    group('isPermanent', () {
      test('returns true when expiresAt is null', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Permanent Promo',
          category: 'General',
          store: 'TestStore',
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.isPermanent, true);
      });

      test('returns false when expiresAt is set', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Expiring Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: DateTime(2027),
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.isPermanent, false);
      });
    });

    group('isExpired', () {
      test('returns true when expiresAt is in the past', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Expired Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: DateTime(2020, 1, 1),
          validFrom: DateTime(2019),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2019),
        );

        expect(promo.isExpired, true);
      });

      test('returns false when expiresAt is in the future', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Active Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: DateTime(2099, 1, 1),
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.isExpired, false);
      });

      test('returns false when expiresAt is null', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Permanent Promo',
          category: 'General',
          store: 'TestStore',
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.isExpired, false);
      });
    });

    group('timeRemaining', () {
      test('returns empty string when expiresAt is null', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Permanent Promo',
          category: 'General',
          store: 'TestStore',
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.timeRemaining, '');
      });

      test('returns "Expired" when expiresAt is in the past', () {
        final promo = Promotion(
          id: 'p1',
          title: 'Expired Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: DateTime(2020, 1, 1),
          validFrom: DateTime(2019),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2019),
        );

        expect(promo.timeRemaining, 'Expired');
      });

      test('returns "2d left" when expiry is 2 days away', () {
        final future = DateTime.now().add(const Duration(days: 2, hours: 1));
        final promo = Promotion(
          id: 'p1',
          title: 'Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: future,
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.timeRemaining, '2d left');
      });

      test('returns "5h left" when expiry is 5 hours away', () {
        final future = DateTime.now().add(const Duration(hours: 5, minutes: 30));
        final promo = Promotion(
          id: 'p1',
          title: 'Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: future,
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.timeRemaining, '5h left');
      });

      test('returns "30m left" when expiry is 30 minutes away', () {
        final future = DateTime.now().add(const Duration(minutes: 30, seconds: 30));
        final promo = Promotion(
          id: 'p1',
          title: 'Promo',
          category: 'General',
          store: 'TestStore',
          expiresAt: future,
          validFrom: DateTime(2026),
          createdById: 'u1',
          createdBy: baseAuthor,
          createdAt: DateTime(2026),
        );

        expect(promo.timeRemaining, '30m left');
      });
    });
  });
}
