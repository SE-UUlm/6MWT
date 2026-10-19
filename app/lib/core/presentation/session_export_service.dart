import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/export_metadata.dart';
import '../data/profile_repository.dart';
import '../data/providers.dart';
import '../data/sample_repository.dart';
import '../data/walk_session_repository.dart';

part 'session_export_service.g.dart';

@Riverpod(keepAlive: true)
SessionExportService sessionExportService(Ref ref) => SessionExportService(
  sessions: ref.watch(walkSessionRepositoryProvider),
  profiles: ref.watch(profileRepositoryProvider),
  samples: ref.watch(sampleRepositoryProvider),
  metadata: ref.watch(exportMetadataServiceProvider),
);

class SessionExportService {
  SessionExportService({
    required this.sessions,
    required this.profiles,
    required this.samples,
    required this.metadata,
  });

  final WalkSessionRepository sessions;
  final ProfileRepository profiles;
  final SampleRepository samples;
  final ExportMetadataService metadata;

  Future<Map<String, dynamic>> buildSessionExport(String sessionId) async {
    final session = await sessions.exportSession(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId not found');
    }
    return _withMetadata({
      ...session,
      'samples': await samples.exportSession(sessionId),
      'profile': await profiles.exportProfile(session['profileId'] as int),
    });
  }

  Future<Map<String, dynamic>> buildAllSessionsExport() async {
    final allSessions = await sessions.exportAllSessions();
    final samplesBySession = await samples.exportAllSessions();
    return _withMetadata({
      'profiles': await profiles.exportAllProfiles(),
      'sessions': [
        for (final session in allSessions)
          {...session, 'samples': samplesBySession[session['id']] ?? []},
      ],
    });
  }

  Future<Map<String, dynamic>> _withMetadata(
    Map<String, dynamic> export,
  ) async => {
    ...export,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    ...await metadata.getMetadata(),
  };

  Future<void> shareSession(String sessionId) async {
    final export = await buildSessionExport(sessionId);
    final shortId = sessionId.length > 8
        ? sessionId.substring(0, 8)
        : sessionId;
    await _share(export, prefix: '6mwt_export_session_$shortId');
  }

  Future<void> shareAllSessions() async {
    final export = await buildAllSessionsExport();
    await _share(export, prefix: '6mwt_export');
  }

  Future<void> _share(
    Map<String, dynamic> export, {
    required String prefix,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonEncode(export));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}
