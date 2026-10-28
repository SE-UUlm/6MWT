import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color darkBlue = Color(0xFF0C2B68);
  static const Color textBlue = Color(0xFF15356D);
  static const Color panelBlue = Color(0xFFF1F6FF);
  static const Color iconBackground = Color(0xFFE0EEFF);
  static const Color secondaryText = Color(0xFF5E6B85);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,

      // The system insets are part of the scroll padding instead of a SafeArea,
      // so content scrolls behind the status bar and system navigation.
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding:
            MediaQuery.paddingOf(context) + const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: SizedBox(
                    width: double.infinity,
                    height: 225,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.directions_walk_rounded,
                            size: 150,
                            color: primaryBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 8,
                  child: IconButton(
                    tooltip: l10n.aboutTitle,
                    icon: const Icon(Icons.info_outline_rounded),
                    color: primaryBlue,
                    onPressed: () => context.push('/about'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                      height: 1.2,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    l10n.appSubTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5E6B85),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: panelBlue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.directions_walk_rounded,
                        title: l10n.home_walk,
                        description: l10n.home_walksb,
                      ),
                    ),

                    _VerticalDivider(),

                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.favorite_rounded,
                        title: l10n.home_performance,
                        description: l10n.home_performancesb,
                      ),
                    ),

                    _VerticalDivider(),

                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.bar_chart_rounded,
                        title: l10n.home_progress,
                        description: l10n.home_progresssb,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 30),

                      const SizedBox(width: 10),

                      Text(
                        l10n.startTest,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _HomeActionCard(
                icon: Icons.bar_chart_rounded,
                title: l10n.home_result,
                subtitle: l10n.home_resultsb,
                onTap: () => context.push('/history'),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _HomeActionCard(
                icon: Icons.info_outline_rounded,
                title: l10n.home_instruction,
                subtitle: l10n.home_instructionsb,
                onTap: () => context.push('/instructions'),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 49,
          height: 49,
          decoration: const BoxDecoration(
            color: HomeScreen.iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: HomeScreen.primaryBlue),
        ),

        const SizedBox(height: 9),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: HomeScreen.textBlue,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: HomeScreen.secondaryText,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 105, color: const Color(0xFFE0EAF8));
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE7EDF6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: HomeScreen.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: HomeScreen.primaryBlue, size: 25),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HomeScreen.textBlue,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: HomeScreen.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8796AD),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
