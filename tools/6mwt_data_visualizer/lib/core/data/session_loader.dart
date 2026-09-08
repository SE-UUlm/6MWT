import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/export_data.dart';

class SessionLoader {
  /// Tries to auto-detect the data directory relative to the executable.
  /// Looks for `data/` starting from the current working directory up to 4
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

  /// Scans a directory for `*.json` files and returns their paths.
  static Future<List<String>> findJsonFilesInDirectory(
      String directoryPath) async {
    final dir = Directory(directoryPath);
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .map((e) => e.path)
        .toList();
    return files;
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

  /// Loads and parses an [ExportData] from the given [filePath].
  static Future<ExportData> load(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final json = await compute(_parseJson, content);
    return ExportData.fromJson(json);
  }

  static Map<String, dynamic> _parseJson(String content) {
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
