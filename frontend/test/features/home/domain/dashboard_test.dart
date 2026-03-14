import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/home/domain/dashboard.dart';

void main() {
  group('DashboardPromotion', () {
    test('fromJson parses all fields including new ones', () {
      final json = {
        'id': 'promo-1',
        'title': '20% off therapy sessions',
        'store': 'Calm Center',
        'discount': '20% OFF',
        'brandLogoUrl': 'https://example.com/logo.png',
        'imageUrl': 'https://example.com/bg.jpg',
        'expiresAt': '2026-03-20T18:00:00.000Z',
      };

      final promo = DashboardPromotion.fromJson(json);

      expect(promo.id, 'promo-1');
      expect(promo.title, '20% off therapy sessions');
      expect(promo.store, 'Calm Center');
      expect(promo.discount, '20% OFF');
      expect(promo.brandLogoUrl, 'https://example.com/logo.png');
      expect(promo.imageUrl, 'https://example.com/bg.jpg');
      expect(promo.expiresAt, DateTime.utc(2026, 3, 20, 18));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'promo-2',
        'title': 'Free consultation',
        'store': 'Wellness Hub',
      };

      final promo = DashboardPromotion.fromJson(json);

      expect(promo.discount, isNull);
      expect(promo.brandLogoUrl, isNull);
      expect(promo.imageUrl, isNull);
      expect(promo.expiresAt, isNull);
    });
  });
}
