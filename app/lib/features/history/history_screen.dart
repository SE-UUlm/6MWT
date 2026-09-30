import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walkSessions = ref.watch(walkSessionsWithProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Row(
          spacing: 8,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF9BB8F0),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                size: 40,
                color: Colors.black87,
              ),
            ),
            const Text('History'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _exportAllSessions(context, ref);
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: walkSessions.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('Keine Einträge vorhanden'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final sessionWithProfile = sessions[index];
              final session = sessionWithProfile.session;
              final profile = sessionWithProfile.profile;

              final finished = session.phase == WalkPhase.finished;

              final assessment = finished
                  ? assessFitness(
                      duration: session.duration,
                      distance: session.distance,
                      ageInYears: profile.age,
                      heightInCm: profile.height.toDouble(),
                    )
                  : null;

              return ListTile(
                leading: Icon(finished ? Icons.check_circle : Icons.cancel),
                title: Text(session.startedAt.toRelativeTimeString(context)),
                key: ValueKey(session.id),
                subtitle: Row(
                  children: [
                    Expanded(child: Text(profile.name.toString())),
                    if (assessment != null)
                      Text(
                        "${assessment.percentOfExpected.toStringAsFixed(0)} % fit",
                      ),
                  ],
                ),
                onTap: () {
                  context.push('/result', extra: sessionWithProfile);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
      ),
    );
  }

  Future<void> _exportAllSessions(BuildContext context, WidgetRef ref) async {
    try {
      final sessions = await ref
          .read(walkSessionRepositoryProvider)
          .exportAllSessions();

      final samplesBySession = await ref
          .read(sampleRepositoryProvider)
          .exportAllSessions();

      final profiles = await ref
          .read(profileRepositoryProvider)
          .exportAllProfiles();

      for (final session in sessions) {
        final sessionId = session['id'] as String;
        session['samples'] = samplesBySession[sessionId] ?? [];
      }

      final export = {
        'exportedAt': DateTime.now().toIso8601String(),
        'profiles': profiles,
        'sessions': sessions,
      };

      final jsonString = const JsonEncoder().convert(export);

      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/6mwt_export_'
        '${DateTime.now().millisecondsSinceEpoch}.json',
      );

      await file.writeAsString(jsonString);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }
}

extension RelativeDateTimeExtension on DateTime {
  String toRelativeTimeString(BuildContext context) {
    final local = toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(local.year, local.month, local.day);

    final locale = Localizations.localeOf(context).toString();
    final timeFormat = DateFormat.jm(
      locale,
    ); // z.B. 14:50 (de) oder 2:50 PM (en)
    final timeString = timeFormat.format(local);

    if (dateToCompare == today) {
      return 'Heute, $timeString';
    } else if (dateToCompare == yesterday) {
      return 'Gestern, $timeString';
    } else if (dateToCompare.year == now.year) {
      // z. B. "12. Mai, 14:50"
      return DateFormat('d. MMM, ', locale).format(local) + timeString;
    } else {
      // z. B. "12.05.2023, 14:50"
      return DateFormat('dd.MM.yyyy, ', locale).format(local) + timeString;
    }
  }
}
