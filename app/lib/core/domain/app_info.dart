/// Information about the installed build, shared by exports and the About screen.
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
