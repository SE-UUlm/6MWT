import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';

import '../domain/walk_session.dart';
import '../domain/walk_session_provider.dart';

bool _debugInitialized = false;

class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key, required this.profileId});

  final int profileId;

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  Profile? _profile;

  double _stopSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final repository = ref.read(profileRepositoryProvider);

    final profile = await repository.loadProfile(widget.profileId);

    if (!mounted) return;

    final session = ref.read(walkSessionProvider);
    session.profileId = widget.profileId;

    setState(() {
      _profile = profile;
    });
  }

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  // ---------------------------------------------------------------------------
  // STATUS
  // ---------------------------------------------------------------------------

  String _statusMessage(WalkSessionState state) {
    final errorMessage = state.errorMessage;

    if (errorMessage != null) {
      return errorMessage;
    }

    switch (state.phase) {
      case WalkPhase.idle:
        return 'Not started';

      case WalkPhase.running:
        return state.lastSamples[SampleType.position] == null
            ? 'Waiting for GPS...'
            : 'Walking';

      case WalkPhase.finished:
        return 'Finished';

      case WalkPhase.aborted:
        return 'Stopped';
    }
  }

  // ---------------------------------------------------------------------------
  // ASSESSMENT
  // ---------------------------------------------------------------------------

  String _assessmentPercentage(WalkSessionState state, WalkSession session) {
    final duration = session.walkDuration - state.remainingTime;

    if (duration <= Duration.zero) {
      return 'Not started yet';
    }

    if (_profile == null) {
      return 'Loading...';
    }

    final assessment = assessFitness(
      duration: duration,
      distance: state.distance,
      ageInYears: _profile!.age,
      heightInCm: _profile!.height.toDouble(),
    );

    return '${assessment.percentOfExpected.round()} %';
  }

  String _assessmentCategory(WalkSessionState state, WalkSession session) {
    final duration = session.walkDuration - state.remainingTime;

    if (duration <= Duration.zero) {
      return '';
    }

    if (_profile == null) {
      return '';
    }

    final assessment = assessFitness(
      duration: duration,
      distance: state.distance,
      ageInYears: _profile!.age,
      heightInCm: _profile!.height.toDouble(),
    );

    return assessment.category.name;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  Widget _buildStopSlider() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double knobSize = 46;
          final double maxOffset = constraints.maxWidth - knobSize;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _stopSliderValue += details.delta.dx / maxOffset;
                _stopSliderValue = _stopSliderValue.clamp(0.0, 1.0);
              });
            },
            onHorizontalDragEnd: (_) {
              if (_stopSliderValue >= 0.9) {
                final session = ref.read(walkSessionProvider);

                session.abort();

                context.push('/result', extra: widget.profileId);
              } else {
                setState(() {
                  _stopSliderValue = 0.0;
                });
              }
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Text(
                    'Slide to stop',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),

                Positioned(
                  left: _stopSliderValue * maxOffset,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(walkSessionProvider);

    final state = ref.watch(walkSessionStateProvider).value ?? session.state;

    // -------------------------------------------------------------------------
    // DEBUG PROFILE
    // -------------------------------------------------------------------------

    final profile = ref.watch(profileRepositoryProvider);

    if (!_debugInitialized) {
      _debugInitialized = true;

      Future.microtask(() async {
        final profileId = await profile.ensureProfile(
          height: 189,
          age: 27,
          name: 'Frank',
        );

        session.profileId = profileId;
      });
    }

    final lastPosition = state.lastSamples[SampleType.position];

    // -------------------------------------------------------------------------
    // CURRENT POSITION
    // -------------------------------------------------------------------------

    final latitude = lastPosition?.values[PositionKeys.latitude];

    final longitude = lastPosition?.values[PositionKeys.longitude];

    final accuracy = lastPosition?.values[PositionKeys.accuracy];

    // -------------------------------------------------------------------------
    // DURATION
    // -------------------------------------------------------------------------

    final elapsedDuration = session.walkDuration - state.remainingTime;

    final durationText = elapsedDuration <= Duration.zero
        ? '0:00'
        : _formatDuration(elapsedDuration);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================================
              // WALK ICON
              // =================================================================
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleBlue,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    size: 52,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =================================================================
              // TIMER
              // =================================================================
              Text(
                state.formattedRemainingTime,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Please go as far as possible in 6 minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 24),

              // =================================================================
              // DISTANCE + STATUS
              // =================================================================
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Distance',
                      value: '${state.distance.toStringAsFixed(1)} m',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _InfoCard(
                      icon: Icons.directions_walk_rounded,
                      title: 'Status',
                      value: _statusMessage(state),
                      showStatusDot: state.isRunning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =================================================================
              // ASSESSMENT
              // =================================================================
              _LargeInfoCard(
                icon: Icons.bar_chart_rounded,
                title: 'Assessment',
                value: _assessmentPercentage(state, session),
                subtitle: _assessmentCategory(state, session).isEmpty
                    ? 'Not started yet'
                    : 'of expected distance',
                trailing: _assessmentCategory(state, session).isEmpty
                    ? null
                    : _assessmentCategory(state, session),
              ),

              const SizedBox(height: 12),

              // =================================================================
              // CURRENT POSITION
              // =================================================================
              _LargeInfoCard(
                icon: Icons.location_on_rounded,
                title: 'Current Position',
                value: lastPosition == null
                    ? 'No position yet'
                    : '${latitude?.toStringAsFixed(6) ?? '-'}, '
                          '${longitude?.toStringAsFixed(6) ?? '-'}',
                subtitle: lastPosition == null
                    ? 'Waiting for GPS...'
                    : 'Accuracy: ${accuracy?.toStringAsFixed(1) ?? '-'} m',
                showArrow: true,
              ),

              const SizedBox(height: 12),

              // =================================================================
              // DURATION + PROFILE
              // =================================================================
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.access_time_rounded,
                      title: 'Duration',
                      value: durationText,
                      subtitle: 'of 6:00 min',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _InfoCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      value: _profile == null
                          ? 'Loading...'
                          : '${_profile!.age} years',
                      subtitle: _profile == null
                          ? ''
                          : '${_profile!.height} cm',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =================================================================
              // START / SLIDE TO STOP
              // =================================================================
              if (state.isRunning)
                _buildStopSlider()
              else
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: session.start,
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
                      'Start Test',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // =================================================================
              // RESET
              // =================================================================
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: session.reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: const BorderSide(color: primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Reset',
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

  // ---------------------------------------------------------------------------
  // DURATION FORMAT
  // ---------------------------------------------------------------------------

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// SMALL INFO CARD
// =============================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.showStatusDot = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final bool showStatusDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: const Color(0xFF347FE5)),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    if (showStatusDot)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22B573),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LARGE INFO CARD
// =============================================================================

class _LargeInfoCard extends StatelessWidget {
  const _LargeInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.trailing,
    this.showArrow = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String? trailing;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF347FE5)),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF7EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: Color(0xFF1BA765),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (showArrow)
            const Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color: Colors.black45,
            ),
        ],
      ),
    );
  }
}
