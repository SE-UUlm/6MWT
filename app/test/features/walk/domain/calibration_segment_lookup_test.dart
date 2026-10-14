import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/domain/calibrated_step_distance_estimator.dart';

void main() {
  test('indexed history queries match full scans at boundaries and gaps', () {
    final random = Random(76);
    final segments = <CalibrationSegment>[];
    var cursor = 1700000000.0;
    for (var i = 0; i < 1000; i++) {
      final start = cursor + (i % 4 == 0 ? random.nextDouble() * 2 : 0);
      cursor = start + .1 + random.nextDouble() * 5;
      segments.add(CalibrationSegment(start, cursor, random.nextDouble() * 10));
    }
    final boundaries = [
      segments.first.start - 10,
      for (final s in segments) ...[s.start, s.end],
      segments.last.end + 10,
    ];
    for (final start in boundaries) {
      final end = start + .1 + random.nextDouble() * 20;
      final expectedSum = segments.fold(
        0.0,
        (sum, segment) => sum + segment.between(start, end),
      );
      var coveredUntil = start;
      var expectedCoverage = false;
      for (final segment in segments) {
        if (segment.end <= coveredUntil) continue;
        if (segment.start > coveredUntil + 1e-6) break;
        coveredUntil = segment.end;
        if (coveredUntil >= end - 1e-6) {
          expectedCoverage = true;
          break;
        }
      }
      expect(StepCalibrationHistory.sum(segments, start, end), expectedSum);
      expect(
        StepCalibrationHistory.covers(segments, start, end),
        expectedCoverage,
      );
    }
    expect(StepCalibrationHistory.sum([], 0, 10), 0);
    expect(StepCalibrationHistory.covers([], 0, 10), isFalse);
  });
}
