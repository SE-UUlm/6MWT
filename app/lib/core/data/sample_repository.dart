import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/domain/sample_sink.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';

final _log = appLogger('SampleRepository');

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
    // Waits only for the batch taken from the buffer by this call, not for
    // batches already being written by earlier fire-and-forget flush calls.
    if (_buffer.isEmpty) {
      return;
    }

    final rows = List.of(_buffer);
    _buffer.clear();

    try {
      await _db.batch((batch) => batch.insertAll(_db.sensorSamples, rows));
    } catch (error, stackTrace) {
      // The rows were already taken from the buffer, so this batch is lost.
      _log.e(
        'Cannot write ${rows.length} samples',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<SensorSampleRow>> _loadSession(String sessionId) {
    final query = _db.select(_db.sensorSamples)
      ..where((row) => row.sessionId.equals(sessionId))
      ..orderBy([(row) => OrderingTerm.asc(row.timestamp)]);

    return query.get();
  }

  Future<List<SensorSample>> loadSessionSamples(String sessionId) async {
    await flush();
    final rows = await _loadSession(sessionId);
    return rows.map((row) {
      final decoded = jsonDecode(row.values) as Map<String, dynamic>;
      final values = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      return SensorSample(
        timestamp: row.timestamp.toUtc(),
        type: SampleType.fromWireName(row.type),
        sourceId: row.sourceId,
        values: values,
      );
    }).toList();
  }

  static Map<String, dynamic> _rowToMap(SensorSampleRow row) => {
    'id': row.id,
    // Older recordings may still contain local timestamps with an offset.
    'timestamp': row.timestamp.toUtc().toIso8601String(),
    'sourceId': row.sourceId,
    'type': row.type,
    'values': jsonDecode(row.values),
  };

  Future<List<Map<String, dynamic>>> exportSession(String sessionId) async {
    final rows = await _loadSession(sessionId);
    return [for (final row in rows) _rowToMap(row)];
  }

  /// Returns all samples grouped by sessionId.
  Future<Map<String, List<Map<String, dynamic>>>> exportAllSessions() async {
    final query = _db.select(_db.sensorSamples)
      ..orderBy([
        (row) => OrderingTerm.asc(row.sessionId),
        (row) => OrderingTerm.asc(row.timestamp),
      ]);
    final rows = await query.get();
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final row in rows) {
      grouped.putIfAbsent(row.sessionId, () => []).add(_rowToMap(row));
    }

    return grouped;
  }
}
