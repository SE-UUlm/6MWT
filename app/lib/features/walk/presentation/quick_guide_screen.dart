import 'package:six_minute_walk_test/app/app_colors.dart';
import 'package:six_minute_walk_test/core/presentation/app_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/log.dart';
import '../../../app/notification_providers.dart';

final _log = appLogger('QuickGuideScreen');

class QuickGuideScreen extends ConsumerStatefulWidget {
  const QuickGuideScreen({super.key});

  @override
  ConsumerState<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends ConsumerState<QuickGuideScreen> {
  bool _preparing = false;

  /// Prepares notifications and passes their availability to the walk screen.
  /// Permission denial or notification errors do not prevent continuing.
  Future<void> _continue() async {
    if (_preparing) return;

    setState(() {
      _preparing = true;
    });

    try {
      var notificationReady = false;

      try {
        final service = ref.read(localNotificationServiceProvider);

        notificationReady = await service.requestNotificationPermission();
      } catch (error, stackTrace) {
        notificationReady = false;

        _log.w(
          'Could not prepare notifications',
          error: error,
          stackTrace: stackTrace,
        );
      }

      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;

      await context.push<void>('/walk', extra: notificationReady);
    } finally {
      if (mounted) {
        setState(() {
          _preparing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTitleBar(title: l10n.quickGuide_title),
      // The bottom inset is part of the scroll padding instead of a SafeArea,
      // so content scrolls behind the system navigation. The top inset is
      // already handled by the app bar.
      // SliverFillRemaining stretches the content to the screen height so the
      // steps can spread out, but still scrolls on small screens.
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                28,
                16,
                28,
                30 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _Step(
                          icon: Icons.forest_rounded,
                          text: l10n.quickGuide_step_outdoor,
                        ),
                        _Step(
                          icon: Icons.phone_iphone_rounded,
                          text: l10n.quickGuide_step_pocket,
                        ),
                        _Step(
                          icon: Icons.directions_walk_rounded,
                          text: l10n.quickGuide_step_walk,
                        ),
                        _Step(
                          icon: Icons.notifications_active_rounded,
                          text: l10n.quickGuide_step_end,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          context.push('/instructions?from=quick-guide'),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: Text(l10n.quickGuide_more_info),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.health_and_safety_outlined,
                          size: 22,
                          color: Colors.black87,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            l10n.quickGuide_disclaimer,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _preparing ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.continueButton,
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
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                height: 1.3,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
