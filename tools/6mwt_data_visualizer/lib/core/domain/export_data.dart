import 'session.dart';

class ExportData {
  const ExportData({
    required this.exportedAt,
    required this.profiles,
    required this.sessions,
  });

  final DateTime exportedAt;
  final List<Profile> profiles;
  final List<Session> sessions;

  Profile? profileForSession(Session session) {
    if (session.profile != null) return session.profile;
    try {
      return profiles.firstWhere((p) => p.id == session.profileId);
    } catch (_) {
      return null;
    }
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('sessions')) {
      return ExportData(
        exportedAt: json['exportedAt'] != null
            ? DateTime.parse(json['exportedAt'] as String)
            : DateTime.now(),
        profiles: (json['profiles'] as List<dynamic>?)
                ?.map((p) => Profile.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        sessions: (json['sessions'] as List<dynamic>)
            .map((s) => Session.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
    } else {
      // Single session file format (e.g. session.json or garmin.json)
      final session = Session.fromJson(json);
      final rawProfile = json['profile'] as Map<String, dynamic>?;
      final profile = rawProfile != null ? Profile.fromJson(rawProfile) : null;
      return ExportData(
        exportedAt: session.startedAt,
        profiles: profile != null ? [profile] : const [],
        sessions: [session],
      );
    }
  }
}
