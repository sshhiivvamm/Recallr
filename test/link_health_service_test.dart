import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recallr/core/services/link_health_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LinkHealthService.getCachedStatus', () {
    test('returns null when no entry is cached for the given id', () async {
      final status = await LinkHealthService.instance.getCachedStatus(1);
      expect(status, isNull);
    });

    test('returns true when link was cached as alive', () async {
      SharedPreferences.setMockInitialValues({'health_42': true});
      final status = await LinkHealthService.instance.getCachedStatus(42);
      expect(status, true);
    });

    test('returns false when link was cached as broken', () async {
      SharedPreferences.setMockInitialValues({'health_7': false});
      final status = await LinkHealthService.instance.getCachedStatus(7);
      expect(status, false);
    });

    test('different ids have independent cached values', () async {
      SharedPreferences.setMockInitialValues({
        'health_1': true,
        'health_2': false,
      });

      expect(await LinkHealthService.instance.getCachedStatus(1), true);
      expect(await LinkHealthService.instance.getCachedStatus(2), false);
      expect(await LinkHealthService.instance.getCachedStatus(3), isNull);
    });
  });
}
