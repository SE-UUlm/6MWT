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
  /// Scans for subdirectories containing `session.json`, attaching
  /// `reference.json`, `reference_*.json` and `references/*.json`.
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

  /// Loads a session and all reference recordings from a session directory.
  static Future<Session?> _loadSessionFolder(Directory folder) async {
    final sessionFile = File('${folder.path}/session.json');
    if (!await sessionFile.exists()) {
      return null;
    }

    try {
      final sessionContent = await sessionFile.readAsString();
      final sessionJson = jsonDecode(sessionContent) as Map<String, dynamic>;
      var session = Session.fromJson(sessionJson);

      session = session.copyWith(
        referenceDirectory: '${folder.path}/references',
        references: await _loadReferences(folder, includeLegacy: true),
        notes: session.notes.isEmpty
            ? folder.uri.pathSegments.where((s) => s.isNotEmpty).last
            : session.notes,
      );

      return session;
    } catch (e) {
      debugPrint('Error loading session from ${folder.path}: $e');
      return null;
    }
  }

  static Future<ExportData> _loadLegacyExportFile(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return _attachFileReferences(ExportData.fromJson(json), file);
  }

  /// Opens a system directory-picker dialog and returns the chosen directory path.
  static Future<String?> pickDirectory() async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select data directory',
    );
  }

  /// Opens a system file-picker dialog and returns the chosen file path.
  /// Returns null if the user cancels.
  static Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select 6MWT JSON export file',
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
    return _attachFileReferences(ExportData.fromJson(json), file);
  }

  static Future<List<Session>> _loadReferences(
    Directory directory, {
    bool includeLegacy = false,
  }) async {
    final files = <File>[];
    if (await directory.exists()) {
      await for (final entry in directory.list()) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (includeLegacy
            ? name == 'reference.json' ||
                  (name.startsWith('reference_') && name.endsWith('.json'))
            : name.endsWith('.json')) {
          files.add(entry);
        }
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    final references = <Session>[];
    for (final file in files) {
      try {
        var reference = Session.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        final name = file.uri.pathSegments.last;
        if (reference.referenceName == null && name != 'reference.json') {
          reference = reference.copyWith(
            referenceName: name.substring(0, name.length - 5),
          );
        }
        references.add(reference);
      } catch (error) {
        debugPrint('Error loading reference ${file.path}: $error');
      }
    }
    if (includeLegacy) {
      references.addAll(
        await _loadReferences(Directory('${directory.path}/references')),
      );
    }
    return references;
  }

  static Future<ExportData> _attachFileReferences(
    ExportData data,
    File file,
  ) async {
    final sessions = <Session>[];
    for (final session in data.sessions) {
      final key = base64Url.encode(utf8.encode(session.id));
      final directory = Directory('${file.path}.references/$key');
      sessions.add(
        session.copyWith(
          referenceDirectory: directory.path,
          references: await _loadReferences(directory),
        ),
      );
    }
    return ExportData(
      exportedAt: data.exportedAt,
      profiles: data.profiles,
      sessions: sessions,
    );
  }

  /// Writes only a new sidecar file; existing recordings are never rewritten.
  static Future<Session> saveReference(
    Session session,
    Session reference,
  ) async {
    final path = session.referenceDirectory;
    if (path == null) {
      throw StateError('Load a session from disk before saving.');
    }
    final directory = await Directory(path).create(recursive: true);
    final staging = await directory.createTemp('.draft-');
    try {
      final file = File('${staging.path}/reference.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(reference.toReferenceJson()),
        flush: true,
      );
      final suffix = staging.uri.pathSegments.where((s) => s.isNotEmpty).last;
      await file.rename(
        '$path/reference_${DateTime.now().microsecondsSinceEpoch}_$suffix.json',
      );
    } finally {
      await staging.delete(recursive: true);
    }
    return session.copyWith(references: [...session.references, reference]);
  }

  static Map<String, dynamic> _parseJson(String content) {
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
