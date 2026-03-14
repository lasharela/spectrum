import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/features/auth/data/auth_repository.dart';
import 'package:spectrum_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/community/presentation/widgets/feed_filter_sheet.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import 'package:spectrum_app/shared/providers/api_provider.dart';

import '../../../../helpers/mocks.dart';

/// Builds the FeedFilterSheet inside a Navigator so that Navigator.pop works.
Widget _buildSheetInApp({
  String? selectedCategory,
  String? selectedState,
  String? selectedCity,
  String? defaultState,
  String? defaultCity,
  required void Function({String? category, String? state, String? city})
      onApply,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: FeedFilterSheet(
                selectedCategory: selectedCategory,
                selectedState: selectedState,
                selectedCity: selectedCity,
                defaultState: defaultState,
                defaultCity: defaultCity,
                onApply: onApply,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Creates an ApiClient backed by a Dio that returns canned city data.
ApiClient _buildMockApiClient() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.clear();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // Return empty cities for any request
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'cities': <String>[]},
      ));
    },
  ));
  return ApiClient(
    baseUrl: 'http://localhost',
    dio: dio,
    storage: MockSecureStorage(),
  );
}

void main() {
  late List<Override> overrides;

  setUp(() {
    final mockApiClient = _buildMockApiClient();
    overrides = [
      apiClientProvider.overrideWithValue(mockApiClient),
      authRepositoryProvider.overrideWithValue(
        AuthRepository(mockApiClient),
      ),
    ];
  });

  group('FeedFilterSheet', () {
    testWidgets('renders Filters title, Clear and Apply buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSheetInApp(
          onApply: ({String? category, String? state, String? city}) {},
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('renders Category and State labels', (tester) async {
      await tester.pumpWidget(
        _buildSheetInApp(
          onApply: ({String? category, String? state, String? city}) {},
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
    });

    testWidgets('renders city text field', (tester) async {
      await tester.pumpWidget(
        _buildSheetInApp(
          onApply: ({String? category, String? state, String? city}) {},
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      // There should be at least one FTextField for city input
      expect(find.byType(FTextField), findsAtLeastNWidgets(1));
    });

    testWidgets('Clear button calls onApply with all nulls', (tester) async {
      String? receivedCategory = 'not-called';
      String? receivedState = 'not-called';
      String? receivedCity = 'not-called';

      await tester.pumpWidget(
        _buildSheetInApp(
          selectedCategory: 'Education',
          selectedState: 'Texas',
          selectedCity: 'Houston',
          onApply: ({String? category, String? state, String? city}) {
            receivedCategory = category;
            receivedState = state;
            receivedCity = city;
          },
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(receivedCategory, isNull);
      expect(receivedState, isNull);
      expect(receivedCity, isNull);
    });

    testWidgets('Apply button calls onApply with current values', (
      tester,
    ) async {
      String? receivedCategory;
      String? receivedState;
      String? receivedCity;
      bool applyCalled = false;

      await tester.pumpWidget(
        _buildSheetInApp(
          selectedCategory: 'Support',
          selectedState: 'Florida',
          selectedCity: 'Miami',
          onApply: ({String? category, String? state, String? city}) {
            applyCalled = true;
            receivedCategory = category;
            receivedState = state;
            receivedCity = city;
          },
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(applyCalled, true);
      expect(receivedCategory, 'Support');
      expect(receivedState, 'Florida');
      expect(receivedCity, 'Miami');
    });

    testWidgets('shows placeholder hint for city when no state selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSheetInApp(
          onApply: ({String? category, String? state, String? city}) {},
          overrides: overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select a state first'), findsOneWidget);
    });
  });
}
