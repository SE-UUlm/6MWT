// Turns a measured six-minute walk test (6MWT) into a percentage of the
// expected distance and a fitness category.
//
// The reference distances are taken from the public 6MWT calculator at
// https://www.6mwt.org/calculator/ (Stach et al., Clin Res Cardiol 2023,
// doi:10.1007/s00392-023-02373-3). Those reference values depend only on age
// and body height (no sex or weight), which is why this assessment needs
// nothing else.
//
// The percentage compares the walked distance against the expected distance
// (the 50th percentile). The category places the walk into one of the
// percentile bands the calculator visualises.

// The reference distances assume a full six-minute test. A shorter or longer
// test is linearly scaled to a six-minute-equivalent distance before it is
// compared against the reference. This makes short debug runs (e.g. one
// minute) produce a usable result; real tests are always six minutes.
const _referenceTestDuration = Duration(minutes: 6);

// The published reference table only covers these ranges. Inputs outside of
// them are clamped so the result stays within validated territory (the
// calculator's own sliders enforce the same limits).
const _minAgeYears = 40;
const _maxAgeYears = 100;
const _minHeightCm = 150.0;
const _maxHeightCm = 210.0;

// Every reference percentile grows by this many metres per centimetre of body
// height, independent of age. Derived from and verified against the source
// table (e.g. 611.5734 m at 180 cm vs. 555.8634 m at 150 cm, age 40).
const _metresPerCm = 1.857;

// The percentile bands, expressed as a constant offset in metres from the
// expected distance (p50). These offsets are the same for every age and
// height in the source table.
const _p10Offset = -85.191;
const _p25Offset = -43.986;
const _p75Offset = 36.983;
const _p90Offset = 75.631;

enum FitnessCategory {
  reducedPhysicalPerformance,
  lowNormal,
  normalPopulationMean,
  highNormal,
  topPerformance,
}

class FitnessAssessment {
  const FitnessAssessment({
    required this.percentOfExpected,
    required this.category,
  });

  // The walked distance as a percentage of the expected distance. 100 means
  // exactly the population mean for this age and height; higher is better.
  final double percentOfExpected;

  final FitnessCategory category;
}

// Assesses a walk test. [duration] and [distanceInMeters] describe the actual
// walk; [ageInYears] and [heightInCm] describe the subject.
FitnessAssessment assessFitness({
  required Duration duration,
  required double distanceInMeters,
  required int ageInYears,
  required double heightInCm,
}) {
  if (duration <= Duration.zero) {
    throw ArgumentError.value(
      duration,
      'duration',
      'must be greater than zero',
    );
  }

  // Scale the walk to what it would have been over a full six minutes.
  final sixMinuteDistance =
      distanceInMeters *
      (_referenceTestDuration.inMilliseconds / duration.inMilliseconds);

  final expectedDistance = _expectedDistance(
    ageInYears: ageInYears,
    heightInCm: heightInCm,
  );

  return FitnessAssessment(
    percentOfExpected: sixMinuteDistance / expectedDistance * 100,
    category: _categorize(sixMinuteDistance, expectedDistance),
  );
}

// The expected (50th percentile) six-minute walking distance for a healthy
// subject of the given age and height.
double _expectedDistance({
  required int ageInYears,
  required double heightInCm,
}) {
  final age = ageInYears.clamp(_minAgeYears, _maxAgeYears);
  final height = heightInCm.clamp(_minHeightCm, _maxHeightCm);

  final expectedAtMinHeight = _p50AtMinHeight[age - _minAgeYears];

  return expectedAtMinHeight + _metresPerCm * (height - _minHeightCm);
}

FitnessCategory _categorize(double distance, double expectedDistance) {
  if (distance < expectedDistance + _p10Offset) {
    return FitnessCategory.reducedPhysicalPerformance;
  }
  if (distance < expectedDistance + _p25Offset) {
    return FitnessCategory.lowNormal;
  }
  if (distance < expectedDistance + _p75Offset) {
    return FitnessCategory.normalPopulationMean;
  }
  if (distance < expectedDistance + _p90Offset) {
    return FitnessCategory.highNormal;
  }
  return FitnessCategory.topPerformance;
}

// Expected six-minute walking distance (p50, in metres) at the minimum body
// height of 150 cm, indexed by (age - 40) for ages 40 to 100. Copied verbatim
// from the source calculator's reference table.
const _p50AtMinHeight = <double>[
  555.8634, // 40
  555.6604, // 41
  555.4574, // 42
  555.2544, // 43
  555.0514, // 44
  554.8484, // 45
  554.6454, // 46
  554.4424, // 47
  554.2394, // 48
  554.0364, // 49
  553.8334, // 50
  553.6304, // 51
  553.4274, // 52
  553.2244, // 53
  553.0214, // 54
  552.8184, // 55
  552.6154, // 56
  548.5476, // 57
  543.5136, // 58
  538.4796, // 59
  533.4456, // 60
  528.4116, // 61
  523.3776, // 62
  518.3436, // 63
  513.3096, // 64
  508.2756, // 65
  503.2416, // 66
  498.2076, // 67
  493.1736, // 68
  488.1396, // 69
  483.1056, // 70
  478.0716, // 71
  473.0376, // 72
  468.0036, // 73
  462.9696, // 74
  457.9356, // 75
  452.9016, // 76
  447.8676, // 77
  442.8336, // 78
  437.7996, // 79
  432.7656, // 80
  427.7316, // 81
  422.6976, // 82
  417.6636, // 83
  412.6296, // 84
  407.5956, // 85
  402.5616, // 86
  397.5276, // 87
  392.4936, // 88
  387.4596, // 89
  382.4256, // 90
  377.3916, // 91
  372.3576, // 92
  367.3236, // 93
  362.2896, // 94
  357.2556, // 95
  352.2216, // 96
  347.1876, // 97
  342.1536, // 98
  337.1196, // 99
  332.0856, // 100
];
