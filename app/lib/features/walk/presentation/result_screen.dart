import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';

class ResultScreen extends ConsumerWidget {
  ResultScreen({super.key, required WalkSessionWithProfile session})
    : session = session.session,
      profile = session.profile;

  final WalkSessionRow session;
  final Profile profile;

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  // ===========================================================================
  // FORMAT DURATION
  // ===========================================================================

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')} min';
  }

  // ===========================================================================
  // PERFORMANCE BAR
  // ===========================================================================

  Widget _buildPerformanceBar(double percentage) {
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final position = constraints.maxWidth * progress;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ----------------------------------------------------------------
                  // COLOR GRADIENT
                  // ----------------------------------------------------------------
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE53935),
                            Color(0xFFFFC857),
                            Color(0xFF2196F3),
                            Color(0xFF4CAF50),
                          ],
                          stops: [0.0, 0.30, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ----------------------------------------------------------------
                  // POSITION MARKER
                  // ----------------------------------------------------------------
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

        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: TextStyle(fontSize: 11, color: Colors.black54)),
            Text('25%', style: TextStyle(fontSize: 11, color: Colors.black54)),
            Text('50%', style: TextStyle(fontSize: 11, color: Colors.black54)),
            Text('75%', style: TextStyle(fontSize: 11, color: Colors.black54)),
            Text('100%', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // DETAILS CARD
  // ===========================================================================

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

  // ===========================================================================
  // DETAIL ROW
  // ===========================================================================

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
      final export = (await ref
          .read(walkSessionRepositoryProvider)
          .exportSession(session.id))!;

      final samples = await ref
          .read(sampleRepositoryProvider)
          .exportSession(session.id);

      final profile = await ref
          .read(profileRepositoryProvider)
          .exportProfile(session.profileId);

      export['samples'] = samples;
      export['profile'] = profile;
      export['exportedAt'] = DateTime.now().toUtc().toIso8601String();

      final jsonString = const JsonEncoder().convert(export);

      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/6mwt_export_session_${session.id.substring(0, 8)}_'
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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // -------------------------------------------------------------------------
    // DURATION
    // -------------------------------------------------------------------------

    final durationText = _formatDuration(session.duration);

    // -------------------------------------------------------------------------
    // ASSESSMENT
    // -------------------------------------------------------------------------

    var percentage = 0.0;
    String category = 'No assessment';

    if (session.phase == WalkPhase.finished) {
      final assessment = assessFitness(
        duration: session.duration,
        distance: session.distance,
        ageInYears: profile.age,
        heightInCm: profile.height.toDouble(),
      );

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
              // =================================================================
              // BACK BUTTON
              // =================================================================
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

              // =================================================================
              // HEADER
              // =================================================================
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

                  IconButton(
                    onPressed: () {
                      _exportSession(context, ref);
                    },
                    icon: const Icon(Icons.share),
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

              // =================================================================
              // PERFORMANCE CARD
              // =================================================================
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

                    // -----------------------------------------------------------
                    // PERCENTAGE
                    // -----------------------------------------------------------
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

                    // -----------------------------------------------------------
                    // BAR
                    // -----------------------------------------------------------
                    _buildPerformanceBar(percentage),

                    const SizedBox(height: 20),

                    // -----------------------------------------------------------
                    // CATEGORY
                    // -----------------------------------------------------------
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

              // =================================================================
              // TEST DETAILS
              // =================================================================
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

              // =================================================================
              // PROFILE DETAILS
              // =================================================================
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
                    showDivider: false,
                  ),
                ],
              ),

              // =================================================================
              // INFORMATION
              // =================================================================
              const SizedBox(height: 18),

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

              // =================================================================
              // BACK TO HOME
              // =================================================================
              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
