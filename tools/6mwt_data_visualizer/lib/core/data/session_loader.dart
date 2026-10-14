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
  /// Scans for subdirectories containing `session.json` or `session_*.json`, attaching
  /// `reference.json`, `reference_*.json` and `references/*.json`.
  /// Also handles direct session folders or legacy export files.
  static Future<ExportData> loadFromDataDirectory(String dataDirPath) async {
    final dir = Directory(dataDirPath);
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', dataDirPath);
    }

    final sessions = <Session>[];
    final profiles = <Profile>[];

    final ownSessions = await _loadSessionFolder(dir);
    if (ownSessions.isNotEmpty) {
      sessions.add(_groupFolder(dir, ownSessions));
    } else {
      final entries = await dir.list().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final entry in entries) {
        if (entry is Directory) {
          final recordings = await _loadSessionFolder(entry);
          if (recordings.isNotEmpty) {
            sessions.add(_groupFolder(entry, recordings));
          }
        } else if (entry is File && entry.path.endsWith('.json')) {
          final name = entry.uri.pathSegments.last;
          if (name == 'reference.json' || name.startsWith('reference_')) {
            continue;
          }
          try {
            final data = await _loadLegacyExportFile(entry);
            sessions.addAll(data.sessions);
            profiles.addAll(data.profiles);
          } catch (_) {
            // Ignore unrelated JSON files.
          }
        }
      }
    }
    profiles.addAll(sessions.map((s) => s.profile).whereType<Profile>());

    // Sort sessions by start time descending
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return ExportData(
      exportedAt: DateTime.now(),
      profiles: profiles,
      sessions: sessions,
    );
  }

  static Session _groupFolder(Directory folder, List<Session> recordings) {
    if (recordings.length == 1) return recordings.single;
    return recordings.first.copyWith(
      id: 'folder:${folder.absolute.path}',
      notes: folder.uri.pathSegments.where((s) => s.isNotEmpty).last,
      subsessions: recordings,
    );
  }

  /// Loads each device recording independently, sharing the folder references.
  static Future<List<Session>> _loadSessionFolder(Directory folder) async {
    final files = await folder
        .list()
        .where((entry) {
          final name = entry.uri.pathSegments.last;
          return entry is File &&
              (name == 'session.json' ||
                  (name.startsWith('session_') && name.endsWith('.json')));
        })
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    if (files.isEmpty) return [];
    final references = await _loadReferences(folder, includeLegacy: true);
    final sessions = <Session>[];
    for (final file in files) {
      try {
        final data = ExportData.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        for (final session in data.sessions) {
          sessions.add(
            session.copyWith(
              profile: data.profileForSession(session),
              sourcePath: file.absolute.path,
              referenceDirectory: '${folder.path}/references',
              references: references,
              notes: session.notes.isEmpty
                  ? folder.uri.pathSegments.where((s) => s.isNotEmpty).last
                  : session.notes,
            ),
          );
        }
      } catch (error) {
        debugPrint('Error loading session from ${file.path}: $error');
      }
    }
    return sessions;
  }

  static Future<ExportData> loadFiles(List<String> paths) async {
    final datasets = <ExportData>[];
    for (final path in paths.toSet()) {
      datasets.add(await load(path));
    }
    return ExportData(
      exportedAt: DateTime.now(),
      profiles: datasets.expand((d) => d.profiles).toList(),
      sessions: datasets.expand((d) => d.sessions).toList(),
    );
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

  /// Opens a system file-picker dialog and returns the chosen file paths.
  /// Returns null if the user cancels.
  static Future<List<String>?> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select 6MWT JSON export files',
      allowMultiple: true,
    );
    return result?.files.map((f) => f.path).whereType<String>().toList();
  }

  /// Loads and parses an [ExportData] from the given [filePathOrDirPath].
  static Future<ExportData> load(String filePathOrDirPath) async {
    final type = await FileSystemEntity.type(filePathOrDirPath);
    if (type == FileSystemEntityType.directory) {
      return loadFromDataDirectory(filePathOrDirPath);
    }

    final file = File(filePathOrDirPath);
    final fileName = file.uri.pathSegments.last;

    if (fileName == 'session.json' ||
        fileName.startsWith('session_') ||
        fileName == 'reference.json') {
      final sessions = await _loadSessionFolder(file.parent);
      final selected = fileName == 'reference.json' && sessions.isNotEmpty
          ? [_groupFolder(file.parent, sessions)]
          : sessions.where((s) => s.sourcePath == file.absolute.path).toList();
      if (selected.isNotEmpty) {
        return ExportData(
          exportedAt: selected.first.startedAt,
          profiles: selected
              .map((s) => s.profile)
              .whereType<Profile>()
              .toList(),
          sessions: selected,
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
          sourcePath: file.absolute.path,
          profile: data.profileForSession(session),
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
