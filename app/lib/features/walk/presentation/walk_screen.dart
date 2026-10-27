import 'dart:async';

import 'package:six_minute_walk_test/app/log.dart';
import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/core/domain/sensor_sample.dart';
import 'package:six_minute_walk_test/features/walk/domain/fitness_assessment.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

import '../domain/walk_session.dart';
import '../domain/walk_session_provider.dart';
import 'estimator_comparison_card.dart';
import 'fitness_category_label.dart';

final _log = appLogger('WalkScreen');

class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key, required this.profileId});

  final int profileId;

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  Profile? _profile;
  late final WalkSession _session;

  double _stopSliderValue = 0.0;

  bool _resultNavigationTriggered = false;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _session = ref.read(walkSessionProvider);
    _loadProfile();
    _session.warmUp();
  }

  @override
  void dispose() {
    _pageController.dispose();
    unawaited(_stopWarmUp());
    super.dispose();
  }

  Future<void> _stopWarmUp() async {
    try {
      await _session.stopWarmUp();
    } catch (error, stackTrace) {
      _log.w(
        'Could not stop sensor warm-up',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadProfile() async {
    final repository = ref.read(profileRepositoryProvider);

    final profile = await repository.loadProfile(widget.profileId);

    if (!mounted) return;

    final session = ref.read(walkSessionProvider);
    if (profile != null) {
      session.setProfile(
        id: profile.id,
        heightCm: profile.height,
        gender: profile.gender.name,
      );
    }

    setState(() {
      _profile = profile;
    });
  }

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  String _statusMessage(WalkSessionState state, AppLocalizations l10n) {
    final errorMessage = state.errorMessage;

    if (errorMessage != null) {
      return switch (state.errorIssue) {
        WalkErrorIssue.locationUnavailable => l10n.walkErrorLocation,
        WalkErrorIssue.activityRecognitionDenied =>
          l10n.walkErrorActivityRecognition,
        WalkErrorIssue.sensorError => l10n.walkErrorSensor(
          errorMessage.replaceFirst('Sensor error: ', ''),
        ),
        null => errorMessage,
      };
    }

    switch (state.phase) {
      case WalkPhase.idle:
        return l10n.walkNotStarted;

      case WalkPhase.running:
        return state.lastSamples[SampleType.position] == null
            ? l10n.walkWaitingForGps
            : l10n.walkWalking;

      case WalkPhase.finished:
        return l10n.walkFinished;

      case WalkPhase.aborted:
        return l10n.walkStopped;
    }
  }

  String _assessmentPercentage(
    WalkSessionState state,
    WalkSession session,
    AppLocalizations l10n,
  ) {
    final duration = session.walkDuration - state.remainingTime;

    if (duration <= Duration.zero) {
      return l10n.walkNotStartedYet;
    }

    if (_profile == null) {
      return l10n.walkLoading;
    }

    final assessment = assessFitness(
      duration: duration,
      distance: state.distance,
      ageInYears: _profile!.age,
      heightInCm: _profile!.height.toDouble(),
    );

    return '${assessment.percentOfExpected.round()} %';
  }

  String _assessmentCategory(
    WalkSessionState state,
    WalkSession session,
    AppLocalizations l10n,
  ) {
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

    return fitnessCategoryLabel(l10n, assessment.category);
  }

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
            onHorizontalDragEnd: (_) async {
              if (_stopSliderValue >= 0.9) {
                if (!mounted || !context.mounted) return;

                await _session.abort();

                _endSession();
              } else {
                setState(() {
                  _stopSliderValue = 0.0;
                });
                return;
              }
            },
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.walkSlideToStop,
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

    ref.listen<AsyncValue<WalkSessionState>>(walkSessionStateProvider, (
      previous,
      next,
    ) {
      final state = next.value;

      if (state == null) return;

      // Reset -> Navigation für einen neuen Test wieder erlauben
      if (state.phase == WalkPhase.idle) {
        _resultNavigationTriggered = false;
        return;
      }

      if (state.phase == WalkPhase.finished && !_resultNavigationTriggered) {
        _resultNavigationTriggered = true;
        _endSession();
      }
    });

    final state = ref.watch(walkSessionStateProvider).value ?? session.state;

    return PageView(
      scrollDirection: Axis.horizontal,
      controller: _pageController,
      children: [
        _buildSimpleView(state, session),
        _buildDetailedView(state, session),
      ],
    );
  }

  Future<void> _endSession() async {
    final sessionRow = createWalkSessionRow(_session, _session.state);
    final profile = _profile;

    if (sessionRow == null || profile == null) {
      setState(() {
        _stopSliderValue = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.walkResultCouldNotBeLoaded,
          ),
        ),
      );
      return;
    }

    final sessionWithProfile = WalkSessionWithProfile(
      session: sessionRow,
      profile: profile,
    );
    await _session.reset();

    if (!mounted) return;

    context.pushReplacement('/result', extra: sessionWithProfile);
  }

  Widget _buildDetailedView(WalkSessionState state, WalkSession session) {
    final l10n = AppLocalizations.of(context)!;

    final lastPosition = state.lastSamples[SampleType.position];

    final latitude = lastPosition?.values[PositionKeys.latitude];

    final longitude = lastPosition?.values[PositionKeys.longitude];

    final accuracy = lastPosition?.values[PositionKeys.accuracy];

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

              Text(
                l10n.walkPleaseGoFar,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.swap_horiz_rounded,
                      title: l10n.walk_idstance,
                      value: '${state.distance.toStringAsFixed(1)} m',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _InfoCard(
                      icon: Icons.directions_walk_rounded,
                      title: l10n.walk_status,
                      value: _statusMessage(state, l10n),
                      showStatusDot: state.isRunning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _LargeInfoCard(
                icon: Icons.bar_chart_rounded,
                title: l10n.walk_assessment,
                value: _assessmentPercentage(state, session, l10n),
                subtitle: _assessmentCategory(state, session, l10n).isEmpty
                    ? l10n.walkNotStartedYet
                    : l10n.walkOfExpectedDistance,
                trailing: _assessmentCategory(state, session, l10n).isEmpty
                    ? null
                    : _assessmentCategory(state, session, l10n),
              ),

              const SizedBox(height: 12),

              _LargeInfoCard(
                icon: Icons.location_on_rounded,
                title: l10n.walk_position,
                value: lastPosition == null
                    ? l10n.walkNoPositionYet
                    : '${latitude?.toStringAsFixed(6) ?? '-'}, '
                          '${longitude?.toStringAsFixed(6) ?? '-'}',
                subtitle: lastPosition == null
                    ? l10n.walkWaitingForGps
                    : l10n.walkAccuracy(accuracy?.toStringAsFixed(1) ?? '-'),
                showArrow: true,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.access_time_rounded,
                      title: l10n.walk_duration,
                      value: durationText,
                      subtitle: l10n.walkOfSixMinutes,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _InfoCard(
                      icon: Icons.person_outline_rounded,
                      title: l10n.walk_profile,
                      value: _profile == null
                          ? l10n.walkLoading
                          : l10n.walkYears(_profile!.age),
                      subtitle: _profile == null
                          ? ''
                          : l10n.walkHeightCm(_profile!.height),
                    ),
                  ),
                ],
              ),

              if (state.comparisons.isNotEmpty) ...[
                const SizedBox(height: 12),
                EstimatorComparisonCard(comparisons: state.comparisons),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleView(WalkSessionState state, WalkSession session) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: const Offset(0, 40),
              child: Image.asset(
                'assets/images/walking_image.png',
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.white.withValues(alpha: 0.25)),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        state.formattedRemainingTime,
                        style: const TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                  if (state.isRunning)
                    _buildStopSlider()
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _profile == null
                            ? null
                            : () async {
                                await session.start();
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
                        child: Text(
                          l10n.walkStartTestButton,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

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

          if (trailing != null) ...[
            const SizedBox(width: 10),
            // Long labels wrap instead of squeezing the text column.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.4,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF7EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trailing!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1BA765),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

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
