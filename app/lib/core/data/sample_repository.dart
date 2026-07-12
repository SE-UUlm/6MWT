import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/sample_sink.dart';
import '../domain/sensor_sample.dart';
import 'database.dart';

// Summary of one recorded test run, for the debug screen.
class RecordingSummary {
  const RecordingSummary({
    required this.sessionId,
    required this.firstSampleAt,
    required this.sampleCount,
  });

  final String sessionId;
  final DateTime firstSampleAt;
  final int sampleCount;
}

class SampleRepository implements SampleSink {
  SampleRepository(this._db);

  // High-frequency sources (accelerometer at ~50 Hz) would overwhelm
  // row-by-row inserts, so samples are buffered and written in batches.
  static const _batchSize = 100;

  final AppDatabase _db;

  final List<SensorSamplesCompanion> _buffer = [];

  @override
  void addSample(String sessionId, SensorSample sample) {
    _buffer.add(
      SensorSamplesCompanion.insert(
        sessionId: sessionId,
        timestamp: sample.timestamp,
        sensorId: sample.sensorId,
        sampleType: sample.type,
        valuesJson: jsonEncode(sample.values),
      ),
    );

    if (_buffer.length >= _batchSize) {
      // Fire-and-forget: recording must never block the running test.
      unawaited(flush());
    }
  }

  @override
  Future<void> flush() async {
    if (_buffer.isEmpty) {
      return;
    }

    final rows = List.of(_buffer);
    _buffer.clear();

    await _db.batch((batch) => batch.insertAll(_db.sensorSamples, rows));
  }

  Stream<List<RecordingSummary>> watchRecordings() {
    final count = _db.sensorSamples.id.count();
    final firstTimestamp = _db.sensorSamples.timestamp.min();

    final query = _db.selectOnly(_db.sensorSamples)
      ..addColumns([_db.sensorSamples.sessionId, count, firstTimestamp])
      ..groupBy([_db.sensorSamples.sessionId])
      ..orderBy([OrderingTerm.desc(firstTimestamp)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          RecordingSummary(
            sessionId: row.read(_db.sensorSamples.sessionId)!,
            firstSampleAt: row.read(firstTimestamp)!,
            sampleCount: row.read(count)!,
          ),
      ],
    );
  }

  Future<List<SensorSampleRow>> _loadSession(String sessionId) {
    final query = _db.select(_db.sensorSamples)
      ..where((row) => row.sessionId.equals(sessionId))
      ..orderBy([(row) => OrderingTerm.asc(row.timestamp)]);

    return query.get();
  }

  Future<String> exportSessionAsJson(String sessionId) async {
    final rows = await _loadSession(sessionId);

    return const JsonEncoder.withIndent('  ').convert([
      for (final row in rows)
        {
          'timestamp': row.timestamp.toIso8601String(),
          'sensorId': row.sensorId,
          'type': row.sampleType,
          'values': jsonDecode(row.valuesJson),
        },
    ]);
  }

  // One column per value key (union over the whole session); samples that do
  // not have a key leave the cell empty.
  Future<String> exportSessionAsCsv(String sessionId) async {
    final rows = await _loadSession(sessionId);

    final decoded = [
      for (final row in rows)
        (row: row, values: (jsonDecode(row.valuesJson) as Map<String, dynamic>)),
    ];

    final valueKeys = <String>{
      for (final entry in decoded) ...entry.values.keys,
    }.toList()..sort();

    final buffer = StringBuffer()
      ..writeln(['timestamp', 'sensor_id', 'sample_type', ...valueKeys].join(','));

    for (final entry in decoded) {
      buffer.writeln(
        [
          entry.row.timestamp.toIso8601String(),
          entry.row.sensorId,
          entry.row.sampleType,
          for (final key in valueKeys) entry.values[key]?.toString() ?? '',
        ].join(','),
      );
    }

    return buffer.toString();
  }
}
