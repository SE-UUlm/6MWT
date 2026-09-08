import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/export_data.dart';
import '../domain/session.dart';

class SessionLoader {
  /// Tries to auto-detect the data directory relative to the executable.
  /// Looks for `data/` starting from the current working directory up to 6
  /// levels up.
  static Future<String?> findDefaultDataDirectory() async {
    Directory dir = Directory.current;
    for (int i = 0; i < 6; i++) {
      final candidate = Directory('${dir.path}/data');
      if (await candidate.exists()) {
        return candidate.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  /// Loads all sessions from the given [dataDirPath].
  ///
  /// Scans for subdirectories containing `session.json`. If a `reference.json`
  /// is also found in the same subfolder, it is attached as [Session.referenceSession].
  /// Also handles direct session folders or legacy export files.
  static Future<ExportData> loadFromDataDirectory(String dataDirPath) async {
    final dir = Directory(dataDirPath);
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', dataDirPath);
    }

    final sessions = <Session>[];
    final profiles = <Profile>[];

    // Check if the directory itself is a single session folder
    final selfSessionFile = File('${dir.path}/session.json');
    if (await selfSessionFile.exists()) {
      final session = await _loadSessionFolder(dir);
      if (session != null) {
        if (session.profile != null) profiles.add(session.profile!);
        return ExportData(
          exportedAt: session.startedAt,
          profiles: profiles,
          sessions: [session],
        );
      }
    }

    // Scan subdirectories
    final entries = await dir.list().toList();
    for (final entry in entries) {
      if (entry is Directory) {
        final session = await _loadSessionFolder(entry);
        if (session != null) {
          sessions.add(session);
          if (session.profile != null) {
            profiles.add(session.profile!);
          }
        }
      } else if (entry is File && entry.path.endsWith('.json')) {
        // Also support any top-level legacy export JSON file
        final fileName = entry.uri.pathSegments.last;
        if (fileName != 'session.json' && fileName != 'reference.json') {
          try {
            final legacyData = await _loadLegacyExportFile(entry);
            sessions.addAll(legacyData.sessions);
            profiles.addAll(legacyData.profiles);
          } catch (_) {
            // Ignore non-export json files
          }
        }
      }
    }

    // Sort sessions by start time descending
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return ExportData(
      exportedAt: DateTime.now(),
      profiles: profiles,
      sessions: sessions,
    );
  }

  /// Loads a session and optional reference.json from a session directory.
  static Future<Session?> _loadSessionFolder(Directory folder) async {
    final sessionFile = File('${folder.path}/session.json');
    if (!await sessionFile.exists()) {
      return null;
    }

    try {
      final sessionContent = await sessionFile.readAsString();
      final sessionJson = jsonDecode(sessionContent) as Map<String, dynamic>;
      var session = Session.fromJson(sessionJson);

      // Check for reference.json in the same folder
      final refFile = File('${folder.path}/reference.json');
      if (await refFile.exists()) {
        try {
          final refContent = await refFile.readAsString();
          final refJson = jsonDecode(refContent) as Map<String, dynamic>;
          final refSession = Session.fromJson(refJson);
          session = session.copyWith(referenceSession: refSession);
        } catch (e) {
          debugPrint('Error parsing reference.json in ${folder.path}: $e');
        }
      }

      // If notes is empty, fallback to folder name
      if (session.notes.isEmpty) {
        final folderName = folder.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .lastOrNull ??
            'Session';
        session = Session(
          id: session.id,
          notes: folderName,
          startedAt: session.startedAt,
          duration: session.duration,
          distance: session.distance,
          phase: session.phase,
          profileId: session.profileId,
          samples: session.samples,
          profile: session.profile,
          referenceSession: session.referenceSession,
        );
      }

      return session;
    } catch (e) {
      debugPrint('Error loading session from ${folder.path}: $e');
      return null;
    }
  }

  static Future<ExportData> _loadLegacyExportFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return ExportData.fromJson(json);
  }

  /// Opens a system directory-picker dialog and returns the chosen directory path.
  static Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Datenordner auswählen',
    );
  }

  /// Opens a system file-picker dialog and returns the chosen file path.
  /// Returns null if the user cancels.
  static Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '6MWT Export-Datei auswählen',
    );
    return result?.files.single.path;
  }

  /// Loads and parses an [ExportData] from the given [filePathOrDirPath].
  static Future<ExportData> load(String filePathOrDirPath) async {
    final type = await FileSystemEntity.type(filePathOrDirPath);
    if (type == FileSystemEntityType.directory) {
      return loadFromDataDirectory(filePathOrDirPath);
    }

    final file = File(filePathOrDirPath);
    final fileName = file.uri.pathSegments.last;

    if (fileName == 'session.json') {
      final session = await _loadSessionFolder(file.parent);
      if (session != null) {
        return ExportData(
          exportedAt: session.startedAt,
          profiles: session.profile != null ? [session.profile!] : const [],
          sessions: [session],
        );
      }
    }

    if (fileName == 'reference.json') {
      // If reference.json was picked, check if session.json exists in the same folder
      final session = await _loadSessionFolder(file.parent);
      if (session != null) {
        return ExportData(
          exportedAt: session.startedAt,
          profiles: session.profile != null ? [session.profile!] : const [],
          sessions: [session],
        );
      }
    }

    // Default file parse
    final content = await file.readAsString();
    final json = await compute(_parseJson, content);
    return ExportData.fromJson(json);
  }

  static Map<String, dynamic> _parseJson(String content) {
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
