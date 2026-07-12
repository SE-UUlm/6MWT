import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'profile_repository.dart';
import 'sample_repository.dart';
import 'test_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();

  ref.onDispose(database.close);

  return database;
});

final testRepositoryProvider = Provider<TestRepository>(
  (ref) => TestRepository(ref.watch(databaseProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final sampleRepositoryProvider = Provider<SampleRepository>(
  (ref) => SampleRepository(ref.watch(databaseProvider)),
);
