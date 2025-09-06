import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/utils/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary color is correct orange', () {
      expect(AppColors.primary, equals(const Color(0xFFFF7900)));
    });

    test('secondary color is correct yellow', () {
      expect(AppColors.secondary, equals(const Color(0xFFFFE642)));
    });

    test('tertiary color is correct light orange', () {
      expect(AppColors.tertiary, equals(const Color(0xFFF2CF7E)));
    });

    test('quaternary color is correct amber', () {
      expect(AppColors.quaternary, equals(const Color(0xFFFFBF00)));
    });

    test('background color is correct light gray', () {
      expect(AppColors.background, equals(const Color(0xFFF8F9FA)));
    });

    test('surface color is white', () {
      expect(AppColors.surface, equals(Colors.white));
    });

    test('error color is correct red', () {
      expect(AppColors.error, equals(const Color(0xFFE74C3C)));
    });

    test('success color is correct green', () {
      expect(AppColors.success, equals(const Color(0xFF27AE60)));
    });

    test('warning color is correct amber', () {
      expect(AppColors.warning, equals(const Color(0xFFFFBF00)));
    });

    test('info color is correct blue', () {
      expect(AppColors.info, equals(const Color(0xFF3498DB)));
    });

    test('textPrimary color is correct dark gray', () {
      expect(AppColors.textPrimary, equals(const Color(0xFF2D3436)));
    });

    test('textSecondary color is correct medium gray', () {
      expect(AppColors.textSecondary, equals(const Color(0xFF636E72)));
    });

    test('textDisabled color is correct light gray', () {
      expect(AppColors.textDisabled, equals(const Color(0xFFB2BEC3)));
    });

    test('divider color is correct light gray', () {
      expect(AppColors.divider, equals(const Color(0xFFE9ECEF)));
    });

    test('all colors are valid Color objects', () {
      expect(AppColors.primary, isA<Color>());
      expect(AppColors.secondary, isA<Color>());
      expect(AppColors.tertiary, isA<Color>());
      expect(AppColors.quaternary, isA<Color>());
      expect(AppColors.accent1, isA<Color>());
      expect(AppColors.accent2, isA<Color>());
      expect(AppColors.accent3, isA<Color>());
      expect(AppColors.accent4, isA<Color>());
      expect(AppColors.background, isA<Color>());
      expect(AppColors.surface, isA<Color>());
      expect(AppColors.error, isA<Color>());
      expect(AppColors.success, isA<Color>());
      expect(AppColors.warning, isA<Color>());
      expect(AppColors.info, isA<Color>());
      expect(AppColors.textPrimary, isA<Color>());
      expect(AppColors.textSecondary, isA<Color>());
      expect(AppColors.textDisabled, isA<Color>());
      expect(AppColors.divider, isA<Color>());
      expect(AppColors.disabled, isA<Color>());
      expect(AppColors.overlay, isA<Color>());
    });

    test('colors have expected opacity', () {
      // Most colors should be fully opaque
      expect(AppColors.primary.opacity, equals(1.0));
      expect(AppColors.secondary.opacity, equals(1.0));
      expect(AppColors.tertiary.opacity, equals(1.0));
      expect(AppColors.quaternary.opacity, equals(1.0));
      expect(AppColors.background.opacity, equals(1.0));
      expect(AppColors.surface.opacity, equals(1.0));
      expect(AppColors.error.opacity, equals(1.0));
      expect(AppColors.success.opacity, equals(1.0));
      expect(AppColors.warning.opacity, equals(1.0));
      expect(AppColors.info.opacity, equals(1.0));
      expect(AppColors.textPrimary.opacity, equals(1.0));
      expect(AppColors.textSecondary.opacity, equals(1.0));
      expect(AppColors.textDisabled.opacity, equals(1.0));
      expect(AppColors.divider.opacity, equals(1.0));
      expect(AppColors.disabled.opacity, equals(1.0));
      // Overlay has partial opacity
      expect(AppColors.overlay.opacity, lessThan(1.0));
    });
  });
}
