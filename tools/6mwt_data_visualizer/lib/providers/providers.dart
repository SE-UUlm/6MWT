import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/data/session_loader.dart';
import '../core/domain/export_data.dart';
import '../core/domain/session.dart';

part 'providers.g.dart';

// ---------------------------------------------------------------------------
// Export data (the loaded JSON file)
// ---------------------------------------------------------------------------

@riverpod
class ExportDataNotifier extends _$ExportDataNotifier {
  @override
  AsyncValue<ExportData?> build() => const AsyncValue.data(null);

  Future<void> loadFromPath(String path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => SessionLoader.load(path));
  }

  Future<void> pickDirectoryAndLoad() async {
    final path = await SessionLoader.pickDirectory();
    if (path != null) {
      await loadFromPath(path);
    }
  }

  Future<void> pickAndLoad() async {
    final path = await SessionLoader.pickFile();
    if (path != null) {
      await loadFromPath(path);
    }
  }
}

// ---------------------------------------------------------------------------
// Auto-detected default directory / files
// ---------------------------------------------------------------------------

@riverpod
Future<List<String>> defaultJsonFiles(Ref ref) async {
  final dir = await SessionLoader.findDefaultDataDirectory();
  if (dir == null) return [];
  return [dir];
}

// ---------------------------------------------------------------------------
// Selected session
// ---------------------------------------------------------------------------

@riverpod
class SelectedSession extends _$SelectedSession {
  @override
  Session? build() => null;

  void select(Session session) => state = session;
  void clear() => state = null;
}
