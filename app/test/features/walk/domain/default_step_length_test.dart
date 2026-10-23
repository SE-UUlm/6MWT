import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/estimators/default_step_length.dart';

void main() {
  for (final (gender, expected) in <(String?, double)>[
    ('male', 0.747),
    ('female', 0.7434),
    ('other', 0.7452),
    (null, 0.7452),
    ('unknown', 0.7452),
  ]) {
    test('estimates metres per step at 180 cm with gender=$gender', () {
      expect(
        estimateDefaultStepLength(heightCm: 180, gender: gender),
        closeTo(expected, 1e-9),
      );
    });
  }

  test('scales the neutral estimate with height', () {
    expect(estimateDefaultStepLength(heightCm: 160), closeTo(0.6624, 1e-9));
    expect(estimateDefaultStepLength(heightCm: 200), closeTo(0.828, 1e-9));
  });

  test('accepts positive heights outside the profile form range', () {
    expect(estimateDefaultStepLength(heightCm: 49), closeTo(0.20286, 1e-9));
    expect(estimateDefaultStepLength(heightCm: 251), closeTo(1.03914, 1e-9));
  });

  for (final height in <num?>[null, double.nan, double.infinity, -10, 0]) {
    test('falls back to 0.7 m for missing or invalid height=$height', () {
      expect(estimateDefaultStepLength(heightCm: height, gender: 'male'), 0.7);
    });
  }
}
