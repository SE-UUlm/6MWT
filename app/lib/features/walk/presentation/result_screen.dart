import 'package:six_minute_walk_test/core/presentation/app_title_bar.dart';
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
import '../domain/estimators/distance_confidence.dart';
import '../domain/walk_session_provider.dart';
import 'distance_confidence_format.dart';
import 'number_format.dart';
import 'performance_bar.dart';
import 'estimator_comparison_card.dart';
import 'fitness_category_label.dart';

final _log = appLogger('ResultScreen');

class ResultScreen extends ConsumerWidget {
  ResultScreen({super.key, required WalkSessionWithProfile session})
    : session = session.session,
      profile = session.profile;

  final WalkSessionRow session;
  final Profile profile;

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')} min';
  }

  // The localized percentage with a smaller percent sign.
  TextSpan _percentSpan(AppLocalizations l10n, int value) {
    final number = NumberFormat.decimalPattern(l10n.localeName).format(value);
    final formatted = l10n.percentValue(value);
    final numberStart = formatted.indexOf(number);

    TextSpan sign(String text) => TextSpan(
      text: text,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
    );

    return TextSpan(
      children: [
        sign(formatted.substring(0, numberStart)),
        TextSpan(text: number),
        sign(formatted.substring(numberStart + number.length)),
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
    Color valueColor = Colors.black,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.resultExportFailed(e.toString()),
            ),
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.resultDeleteFailed(e.toString()),
          ),
        ),
      );
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

    // Null for sessions recorded before confidence was stored.
    final storedConfidence = session.distanceConfidence;
    final confidence = storedConfidence == null
        ? null
        : DistanceConfidence(storedConfidence);

    final expectedDistance = expectedSixMinuteDistance(
      ageInYears: profile.age,
      heightInCm: profile.height.toDouble(),
    );
    double? percentage;
    String category = l10n.resultNoAssessment;
    // A session still marked as running after the app restarted was
    // interrupted as well, e.g. by a crash.
    var explanation = l10n.resultEarlyStopExplanation;

    if (session.phase == WalkPhase.finished) {
      final assessment = assessFitness(
        duration: session.duration,
        distance: session.distance,
        ageInYears: profile.age,
        heightInCm: profile.height.toDouble(),
      );

      _log.t('Calculated fitness: $assessment');

      percentage = assessment.percentOfExpected;
      category = fitnessCategoryLabel(l10n, assessment.category);
      explanation = l10n.resultPerformanceExplanation;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTitleBar(
        title: l10n.resultTitle,
        actions: [
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

      // The bottom inset is part of the scroll padding instead of a SafeArea,
      // so content scrolls behind the system navigation. The top inset is
      // already handled by the app bar.
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          28,
          24,
          28,
          30 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.resultIntro,
              style: const TextStyle(
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
                  Text(
                    l10n.resultPerformance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // The percent sign is smaller than the number, so it does
                  // not compete with the value itself.
                  Text.rich(
                    percentage == null
                        ? const TextSpan(text: '—')
                        : _percentSpan(l10n, percentage.round()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  Text(
                    l10n.resultExpectedDistance,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),

                  const SizedBox(height: 22),

                  PerformanceBar(
                    expectedDistance: expectedDistance,
                    percentage: percentage,
                  ),

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

                        Text(
                          explanation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Without an assessment there is nothing the warning could
                  // qualify.
                  if (percentage != null &&
                      confidence?.level == ConfidenceLevel.low) ...[
                    const SizedBox(height: 12),

                    Container(
                      key: const ValueKey('low-confidence-warning'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 30,
                            color: Colors.red.shade700,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              l10n.resultLowConfidenceWarning,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              l10n.resultDisclaimer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 20),

            _buildDetailsCard(
              title: l10n.resultTestDetails,
              children: [
                _buildDetailRow(
                  icon: Icons.swap_horiz_rounded,
                  label: l10n.resultDistanceWalked,
                  value: '${formatDecimal(l10n, session.distance, 1)} m',
                ),

                _buildDetailRow(
                  icon: Icons.verified_outlined,
                  label: l10n.resultDistanceConfidence,
                  value: formatConfidence(l10n, confidence),
                  valueColor: confidenceColor(confidence),
                ),

                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: l10n.resultTestDuration,
                  value: durationText,
                ),

                _buildDetailRow(
                  icon: Icons.flag_rounded,
                  label: l10n.resultTestStatus,
                  value: session.phase == WalkPhase.aborted
                      ? l10n.resultStoppedEarly
                      : l10n.resultCompleted,
                  showDivider: false,
                ),
              ],
            ),

            const SizedBox(height: 14),
            _buildDetailsCard(
              title: l10n.resultYourProfile,
              children: [
                _buildDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: l10n.resultName,
                  value: profile.name ?? '—',
                ),

                _buildDetailRow(
                  icon: Icons.cake_outlined,
                  label: l10n.resultAge,
                  value: l10n.resultAgeYears(profile.age),
                ),

                _buildDetailRow(
                  icon: Icons.height_rounded,
                  label: l10n.resultHeight,
                  value: l10n.resultHeightCm(profile.height),
                ),

                _buildDetailRow(
                  icon: Icons.monitor_weight_outlined,
                  label: l10n.resultWeight,
                  value: l10n.resultWeightKg(weightText),
                ),

                _buildDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: l10n.resultGender,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.resultDistanceComparison,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            l10n.resultCalculatingDistanceComparisons,
                            style: const TextStyle(
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
                          Text(
                            l10n.resultDistanceComparison,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.resultDistanceComparisonFailed,
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

            const SizedBox(height: 10),

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
    );
  }
}
