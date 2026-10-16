import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/config_fixtures.dart';

void main() {
  final paywall = loadBundledConfig().paywall;

  test('the yearly saving is rounded down, never overstated', () {
    // 349 a year is 29.08 a month against 59: a 50.7% saving.
    expect(paywall.savePercentOf(paywall.planById('yearly')), 50);
  });

  test('the priciest monthly rate saves nothing', () {
    expect(paywall.savePercentOf(paywall.planById('monthly')), 0);
  });
}
