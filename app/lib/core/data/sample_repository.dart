import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

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
        sourceId: sample.sourceId,
        type: sample.type.wireName,
        values: jsonEncode(sample.values),
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

  Future<List<SensorSampleRow>> _loadSession(String sessionId) {
    final query = _db.select(_db.sensorSamples)
      ..where((row) => row.sessionId.equals(sessionId))
      ..orderBy([(row) => OrderingTerm.asc(row.timestamp)]);

    return query.get();
  }

  Future<String> exportSessionAsJson(String sessionId) async {
    final rows = await _loadSession(sessionId);

    return const JsonEncoder().convert([
      for (final row in rows)
        {
          'timestamp': row.timestamp.millisecondsSinceEpoch,
          'sourceId': row.sourceId,
          'type': row.type,
          'values': jsonDecode(row.values),
        },
    ]);
  }
}
