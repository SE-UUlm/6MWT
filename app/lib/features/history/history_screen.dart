import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/presentation/session_export_service.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.historyTitle),
          ],
        ),
        actions: [
          Builder(
            builder: (shareContext) => IconButton(
              onPressed: () {
                _exportAllSessions(shareContext, ref);
              },
              icon: const Icon(Icons.share),
            ),
          ),
        ],
      ),
      body: walkSessions.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(child: Text(l10n.historyNoEntries));
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
                        "${assessment.percentOfExpected.toStringAsFixed(0)} % ${l10n.historyFit}",
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
        error: (err, stack) =>
            Center(child: Text(l10n.historyLoadFailed(err.toString()))),
      ),
    );
  }

  Future<void> _exportAllSessions(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(sessionExportServiceProvider)
          .shareAllSessions(context: context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.historyExportFailed(e.toString()),
            ),
          ),
        );
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

    final l10n = AppLocalizations.of(context)!;

    if (dateToCompare == today) {
      return '${l10n.historyToday}, $timeString';
    } else if (dateToCompare == yesterday) {
      return '${l10n.historyYesterday}, $timeString';
    } else if (dateToCompare.year == now.year) {
      // z. B. "12. Mai, 14:50"
      return '${DateFormat.MMMd(locale).format(local)}, $timeString';
    } else {
      // z. B. "12.05.2023, 14:50"
      return '${DateFormat.yMd(locale).format(local)}, $timeString';
    }
  }
}
