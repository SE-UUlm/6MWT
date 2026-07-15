import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/sample_repository.dart';

// TODO: Use riverpod annotation to get rid of flutter_riverpod dependency in data layer

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  ref.onDispose(database.close);

  return database;
});

final sampleRepositoryProvider = Provider<SampleRepository>(
  (ref) => SampleRepository(ref.watch(databaseProvider)),
);
