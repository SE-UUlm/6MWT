import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/metadata_service.dart';

part 'app_info.g.dart';

/// Information about the installed build, shared by exports and future UI.
class AppInfo {
  const AppInfo({this.version, this.buildNumber, this.commitHash});

  final String? version;
  final String? buildNumber;
  final String? commitHash;

  Map<String, dynamic> toJson() => {
    'version': version,
    'buildNumber': buildNumber,
    'commitHash': commitHash,
  };
}

/// Shared by exports and the future About screen.
@Riverpod(keepAlive: true)
Future<AppInfo> appInfo(Ref ref) => AppInfoService().load();
