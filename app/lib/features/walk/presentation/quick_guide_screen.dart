import 'package:six_minute_walk_test/core/presentation/app_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

class QuickGuideScreen extends StatelessWidget {
  const QuickGuideScreen({super.key});

  static const Color primaryBlue = Color(0xFF347FE5);

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
                      onPressed: () => context.push('/instructions'),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: Text(l10n.quickGuide_more_info),
                      style: TextButton.styleFrom(foregroundColor: primaryBlue),
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
                      onPressed: () {
                        context.push('/walk');
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
              color: QuickGuideScreen.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: QuickGuideScreen.primaryBlue),
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
