import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';

void main() {
  // Expected six-minute distance (p50) for a 40 year old, 150 cm subject,
  // taken from the reference calculator.
  const expectedAt40And150 = 555.8634;

  test('walking exactly the expected distance yields 100%', () {
    final result = assessFitness(
      duration: const Duration(minutes: 6),
      distanceInMeters: expectedAt40And150,
      ageInYears: 40,
      heightInCm: 150,
    );

    expect(result.percentOfExpected, closeTo(100, 0.01));
    expect(result.category, FitnessCategory.normalPopulationMean);
  });

  test('percentage scales linearly below the expected distance', () {
    final result = assessFitness(
      duration: const Duration(minutes: 6),
      distanceInMeters: expectedAt40And150 / 2,
      ageInYears: 40,
      heightInCm: 150,
    );

    expect(result.percentOfExpected, closeTo(50, 0.01));
  });

  test('body height increases the expected distance by 1.857 m/cm', () {
    // 30 cm taller -> expected distance grows by 30 * 1.857 = 55.71 m.
    final result = assessFitness(
      duration: const Duration(minutes: 6),
      distanceInMeters: expectedAt40And150 + 55.71,
      ageInYears: 40,
      heightInCm: 180,
    );

    expect(result.percentOfExpected, closeTo(100, 0.01));
  });

  test('a shorter test is scaled up to a six-minute-equivalent', () {
    // Walking a sixth of the expected distance in one minute matches the
    // expected six-minute distance.
    final result = assessFitness(
      duration: const Duration(minutes: 1),
      distanceInMeters: expectedAt40And150 / 6,
      ageInYears: 40,
      heightInCm: 150,
    );

    expect(result.percentOfExpected, closeTo(100, 0.01));
    expect(result.category, FitnessCategory.normalPopulationMean);
  });

  group('categories', () {
    FitnessCategory categoryFor(double distance) => assessFitness(
      duration: const Duration(minutes: 6),
      distanceInMeters: distance,
      ageInYears: 40,
      heightInCm: 150,
    ).category;

    test('below p10 is reduced physical performance', () {
      // p10 = 555.8634 - 85.191 = 470.6724
      expect(categoryFor(470), FitnessCategory.reducedPhysicalPerformance);
      expect(categoryFor(471), FitnessCategory.lowNormal);
    });

    test('between p25 and p75 is the normal population mean', () {
      // p25 = 511.8774, p75 = 592.8464
      expect(categoryFor(512), FitnessCategory.normalPopulationMean);
      expect(categoryFor(592), FitnessCategory.normalPopulationMean);
    });

    test('at or above p90 is top performance', () {
      // p90 = 555.8634 + 75.631 = 631.4944
      expect(categoryFor(632), FitnessCategory.topPerformance);
      expect(categoryFor(631), FitnessCategory.highNormal);
    });
  });

  group('input ranges', () {
    test('age below 40 is treated as 40', () {
      final young = assessFitness(
        duration: const Duration(minutes: 6),
        distanceInMeters: expectedAt40And150,
        ageInYears: 25,
        heightInCm: 150,
      );

      expect(young.percentOfExpected, closeTo(100, 0.01));
    });

    test('height above 210 is treated as 210', () {
      final tall = assessFitness(
        duration: const Duration(minutes: 6),
        distanceInMeters: 100,
        ageInYears: 40,
        heightInCm: 230,
      );
      final clamped = assessFitness(
        duration: const Duration(minutes: 6),
        distanceInMeters: 100,
        ageInYears: 40,
        heightInCm: 210,
      );

      expect(tall.percentOfExpected, clamped.percentOfExpected);
    });
  });

  test('non-positive duration throws', () {
    expect(
      () => assessFitness(
        duration: Duration.zero,
        distanceInMeters: 500,
        ageInYears: 40,
        heightInCm: 150,
      ),
      throwsArgumentError,
    );
  });

  group('Some more examples from the website', () {
    const cases = [
      (
        age: 46,
        height: 153,
        distance: 450,
        percentage: 80,
        category: FitnessCategory.reducedPhysicalPerformance,
      ),
      (
        age: 67,
        height: 153,
        distance: 450,
        percentage: 89,
        category: FitnessCategory.lowNormal,
      ),
      (
        age: 67,
        height: 153,
        distance: 530,
        percentage: 105,
        category: FitnessCategory.normalPopulationMean,
      ),
      (
        age: 67,
        height: 172,
        distance: 530,
        percentage: 98,
        category: FitnessCategory.normalPopulationMean,
      ),
      (
        age: 67,
        height: 198,
        distance: 530,
        percentage: 90,
        category: FitnessCategory.lowNormal,
      ),
      (
        age: 67,
        height: 210,
        distance: 530,
        percentage: 87,
        category: FitnessCategory.lowNormal,
      ),
      (
        age: 78,
        height: 210,
        distance: 530,
        percentage: 96,
        category: FitnessCategory.normalPopulationMean,
      ),
      (
        age: 93,
        height: 203,
        distance: 530,
        percentage: 114,
        category: FitnessCategory.highNormal,
      ),
      (
        age: 72,
        height: 175,
        distance: 230,
        percentage: 44,
        category: FitnessCategory.reducedPhysicalPerformance,
      ),
      (
        age: 91,
        height: 160,
        distance: 450,
        percentage: 114,
        category: FitnessCategory.highNormal,
      ),
      (
        age: 72,
        height: 171,
        distance: 600,
        percentage: 117,
        category: FitnessCategory.topPerformance,
      ),
    ];
    for (final c in cases) {
      test('Test for combination $c', () {
        final assessment = assessFitness(
          duration: Duration(minutes: 6),
          distanceInMeters: c.distance.toDouble(),
          ageInYears: c.age,
          heightInCm: c.height.toDouble(),
        );

        expect(assessment.category, c.category);
        expect(
          assessment.percentOfExpected,
          closeTo(c.percentage, 0.51),
        ); // Values from website GUI are rounded to whole percent
      });
    }
  });
}
