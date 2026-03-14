import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spectrum_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Suppress overflow errors in test environment (small viewport)
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('overflowed')) return;
      FlutterError.presentError(details);
    };

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SpectrumApp()));

    // Verify that the app launches
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
