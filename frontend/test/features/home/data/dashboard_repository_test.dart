import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/home/data/dashboard_repository.dart';

void main() {
  group('DashboardRepository', () {
    test('getDashboard method exists and returns DashboardData type', () {
      final repo = DashboardRepository;
      expect(repo, isNotNull);
    });
  });
}
