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
    try {
      return profiles.firstWhere((p) => p.id == session.profileId);
    } catch (_) {
      return null;
    }
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      profiles: (json['profiles'] as List<dynamic>)
          .map((p) => Profile.fromJson(p as Map<String, dynamic>))
          .toList(),
      sessions: (json['sessions'] as List<dynamic>)
          .map((s) => Session.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
