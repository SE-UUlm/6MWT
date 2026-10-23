import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/presentation/session_export_service.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';
import '../domain/walk_session_provider.dart';
import 'estimator_comparison_card.dart';

final _log = appLogger('ResultScreen');

class ResultScreen extends ConsumerWidget {
  ResultScreen({super.key, required WalkSessionWithProfile session})
    : session = session.session,
      profile = session.profile;

  final WalkSessionRow session;
  final Profile profile;

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  static const maxValue = 140;
  static const labelCount = 7;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')} min';
  }

  Widget _buildPerformanceBar(double percentage) {
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = percentage.clamp(0, maxValue);
              final position = constraints.maxWidth * progress / maxValue;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFf94144),
                            Color(0xFFf8961e),
                            Color(0xFF90be6d),
                            Color(0xFF43aa8b),
                            Color(0xFF577590),
                          ],
                          stops: [
                            0.0 / maxValue,
                            80 / maxValue,
                            90 / maxValue,
                            110 / maxValue,
                            120 / maxValue,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: position - 2,
                    top: -6,
                    child: Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            for (int i = 0; i < labelCount; i++)
              Expanded(
                child: Text(
                  '${(maxValue / labelCount * (i + 0.5)).toStringAsFixed(0)} %',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade300),

          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 21, color: Colors.black87),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 53, right: 18),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
      ],
    );
  }

  Future<void> _exportSession(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(sessionExportServiceProvider)
          .shareSession(session.id, context: context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final activeSession = ref.read(walkSessionProvider);
    final l10n = AppLocalizations.of(context)!;

    if (activeSession.state.isRunning &&
        activeSession.state.sessionId == session.id) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cannotDeleteActiveSession)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSessionDialogTitle),
        content: Text(l10n.deleteSessionDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(walkSessionRepositoryProvider).deleteSession(session.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionDeleted)));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting session: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonsAsync = ref.watch(
      sessionEstimatorComparisonsProvider(
        session.id,
        heightCm: profile.height,
        gender: profile.gender.name,
      ),
    );

    final l10n = AppLocalizations.of(context)!;
    final genderLabel = switch (profile.gender) {
      Gender.male => l10n.genderMale,
      Gender.female => l10n.genderFemale,
      Gender.other => l10n.genderOther,
    };
    final weightText = NumberFormat.decimalPattern(
      l10n.localeName,
    ).format(profile.weight);

    final durationText = _formatDuration(session.duration);

    var percentage = 0.0;
    String category = 'No assessment';

    if (session.phase == WalkPhase.finished) {
      final assessment = assessFitness(
        duration: session.duration,
        distance: session.distance,
        ageInYears: profile.age,
        heightInCm: profile.height.toDouble(),
      );

      _log.t('Calculated fitness: $assessment');

      percentage = assessment.percentOfExpected;
      category = assessment.category.name;
    }

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBlue,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      size: 50,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(width: 18),

                  const Expanded(
                    child: Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  Builder(
                    builder: (shareContext) => IconButton(
                      onPressed: () {
                        _exportSession(shareContext, ref);
                      },
                      icon: const Icon(Icons.share),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Here are your results from the\n'
                '6-minute walk test.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      '${percentage.round()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const Text(
                      'of expected distance',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),

                    const SizedBox(height: 22),

                    _buildPerformanceBar(percentage),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: circleBlue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            category,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Your performance is based on your '
                            'age, height and walking distance.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _buildDetailsCard(
                title: 'Test Details',
                children: [
                  _buildDetailRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Distance walked',
                    value: '${session.distance.toStringAsFixed(1)} m',
                  ),

                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Test duration',
                    value: durationText,
                  ),

                  _buildDetailRow(
                    icon: Icons.flag_rounded,
                    label: 'Test status',
                    value: session.phase == WalkPhase.aborted
                        ? 'Stopped early'
                        : 'Completed',
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _buildDetailsCard(
                title: 'Your Profile',
                children: [
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: profile.name ?? '-',
                  ),

                  _buildDetailRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: '${profile.age} years',
                  ),

                  _buildDetailRow(
                    icon: Icons.height_rounded,
                    label: 'Height',
                    value: '${profile.height} cm',
                  ),

                  _buildDetailRow(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    value: '$weightText kg',
                  ),

                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Gender',
                    value: genderLabel,
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              comparisonsAsync.when(
                data: (comparisons) {
                  if (comparisons.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: EstimatorComparisonCard(comparisons: comparisons),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Distance comparison',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: primaryBlue,
                              ),
                            ),
                            SizedBox(width: 14),
                            Text(
                              'Calculating distance comparisons...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, st) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.red.shade50.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Distance comparison',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Could not calculate distance comparisons.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Text(
                'The result provides an orientation based on '
                'your recorded walking distance and personal data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  l10n.deleteSession,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
