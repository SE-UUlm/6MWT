import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/sample_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final database = AppDatabase();

  ref.onDispose(database.close);

  return database;
}

@Riverpod(keepAlive: true)
SampleRepository sampleRepository(Ref ref) =>
    SampleRepository(ref.watch(databaseProvider));
