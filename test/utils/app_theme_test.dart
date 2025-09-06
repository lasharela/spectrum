import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/utils/app_theme.dart';
import 'package:spectrum/utils/app_colors.dart';

void main() {
  group('AppTheme', () {
    group('lightTheme', () {
      late ThemeData theme;

      setUp(() {
        theme = AppTheme.lightTheme;
      });

      test('uses Material 3', () {
        expect(theme.useMaterial3, isTrue);
      });

      test('has light brightness', () {
        expect(theme.brightness, equals(Brightness.light));
      });

      test('color scheme has correct primary color', () {
        expect(theme.colorScheme.primary, equals(AppColors.primary));
      });

      test('color scheme has correct secondary color', () {
        expect(theme.colorScheme.secondary, equals(AppColors.secondary));
      });

      test('color scheme has correct tertiary color', () {
        expect(theme.colorScheme.tertiary, equals(AppColors.tertiary));
      });

      test('color scheme has correct error color', () {
        expect(theme.colorScheme.error, equals(AppColors.error));
      });

      test('color scheme has correct surface color', () {
        expect(theme.colorScheme.surface, equals(AppColors.surface));
      });

      test('scaffold background color is set correctly', () {
        expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
      });

      test('app bar theme is configured correctly', () {
        expect(theme.appBarTheme.backgroundColor, equals(AppColors.surface));
        expect(theme.appBarTheme.elevation, equals(0));
        expect(theme.appBarTheme.centerTitle, isTrue);
        expect(theme.appBarTheme.iconTheme?.color, equals(AppColors.textPrimary));
      });

      test('app bar title text style is configured correctly', () {
        expect(theme.appBarTheme.titleTextStyle?.color, equals(AppColors.textPrimary));
        expect(theme.appBarTheme.titleTextStyle?.fontSize, equals(18));
        expect(theme.appBarTheme.titleTextStyle?.fontWeight, equals(FontWeight.w600));
      });

      test('elevated button theme is configured correctly', () {
        final buttonStyle = theme.elevatedButtonTheme.style;
        
        // Test default style properties
        final backgroundColor = buttonStyle?.backgroundColor?.resolve({});
        final foregroundColor = buttonStyle?.foregroundColor?.resolve({});
        final elevation = buttonStyle?.elevation?.resolve({});
        final padding = buttonStyle?.padding?.resolve({});
        final shape = buttonStyle?.shape?.resolve({});
        
        expect(backgroundColor, equals(AppColors.primary));
        expect(foregroundColor, equals(Colors.white));
        expect(elevation, equals(0));
        expect(padding, equals(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)));
        expect(shape, isA<RoundedRectangleBorder>());
      });

      test('outlined button theme is configured correctly', () {
        final buttonStyle = theme.outlinedButtonTheme.style;
        
        final foregroundColor = buttonStyle?.foregroundColor?.resolve({});
        final side = buttonStyle?.side?.resolve({});
        final padding = buttonStyle?.padding?.resolve({});
        
        expect(foregroundColor, equals(AppColors.primary));
        expect(side?.color, equals(AppColors.primary));
        expect(padding, equals(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)));
      });

      test('text button theme is configured correctly', () {
        final buttonStyle = theme.textButtonTheme.style;
        
        final foregroundColor = buttonStyle?.foregroundColor?.resolve({});
        final padding = buttonStyle?.padding?.resolve({});
        
        expect(foregroundColor, equals(AppColors.primary));
        expect(padding, equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)));
      });

      test('input decoration theme is configured correctly', () {
        final inputTheme = theme.inputDecorationTheme;
        
        expect(inputTheme.filled, isTrue);
        expect(inputTheme.fillColor, equals(AppColors.surface));
        expect(inputTheme.contentPadding, equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)));
      });

      test('input decoration borders are configured correctly', () {
        final inputTheme = theme.inputDecorationTheme;
        
        expect(inputTheme.border, isA<OutlineInputBorder>());
        expect(inputTheme.enabledBorder, isA<OutlineInputBorder>());
        expect(inputTheme.focusedBorder, isA<OutlineInputBorder>());
        expect(inputTheme.errorBorder, isA<OutlineInputBorder>());
        
        // Check border colors
        final enabledBorder = inputTheme.enabledBorder as OutlineInputBorder;
        expect(enabledBorder.borderSide.color, equals(AppColors.divider));
        
        final focusedBorder = inputTheme.focusedBorder as OutlineInputBorder;
        expect(focusedBorder.borderSide.color, equals(AppColors.primary));
        expect(focusedBorder.borderSide.width, equals(2));
        
        final errorBorder = inputTheme.errorBorder as OutlineInputBorder;
        expect(errorBorder.borderSide.color, equals(AppColors.error));
      });

      test('card theme is configured correctly', () {
        expect(theme.cardTheme.color, equals(AppColors.surface));
        expect(theme.cardTheme.elevation, equals(2));
        expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
        
        final shape = theme.cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(12)));
      });

      test('divider theme is configured correctly', () {
        expect(theme.dividerTheme.color, equals(AppColors.divider));
        expect(theme.dividerTheme.thickness, equals(1));
      });
    });
  });
}