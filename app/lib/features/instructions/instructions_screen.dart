import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/presentation/app_title_bar.dart';
import '../../l10n/app_localizations.dart';
import '../walk/domain/fitness_assessment.dart';
import '../walk/presentation/fitness_category_label.dart';
import '../walk/presentation/performance_bar.dart';

const Color _primaryBlue = Color(0xFF347FE5);
const Color _warningRed = Color(0xFFE53935);
const Color _textGrey = Color(0xFF2B2B2B);
const Color _titleBlack = Color(0xFF111111);

const Duration _pageTransitionDuration = Duration(milliseconds: 300);

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key, this.offerTestStart = true});

  /// Whether the last page starts a test. Opened from the quick guide, the
  /// test flow is already running, so the last page returns there instead.
  final bool offerTestStart;

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = <Widget>[
    _WelcomePage(),
    _StepsPage(),
    _PersonalDataPage(),
    _WalkPage(),
    _SafetyPage(),
    _PerformancePage(),
    _SetUpPage(),
  ];

  bool get _isFirstPage => _currentPage == 0;
  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: _pageTransitionDuration,
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_isLastPage) {
      if (widget.offerTestStart) {
        context.go('/profile');
      } else {
        context.pop();
      }
      return;
    }

    _pageController.nextPage(
      duration: _pageTransitionDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // On the first page, back leaves the instructions; otherwise it goes to
    // the previous page.
    return PopScope(
      canPop: _isFirstPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousPage();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTitleBar(title: l10n.instructions),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page - Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  // SliverFillRemaining lets a page fill the available
                  // height, so its content can spread out, but still
                  // scrolls on small screens. The side padding is part of
                  // each page, so pages slide in from the screen edge.
                  children: [
                    for (final page in _pages)
                      CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            sliver: SliverFillRemaining(
                              hasScrollBody: false,
                              child: page,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    if (_isLastPage && widget.offerTestStart) ...[
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryBlue,
                          ),
                          child: Text(l10n.instructions_7_home),
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],

                    // Continue - Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          !_isLastPage
                              ? l10n.continueButton
                              : widget.offerTestStart
                              ? l10n.startTest
                              : l10n.instructions_7_back,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _PageIndicator(
                      pageCount: _pages.length,
                      currentPage: _currentPage,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.pageCount, required this.currentPage});

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < pageCount; i++)
          AnimatedContainer(
            duration: _pageTransitionDuration,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == currentPage ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == currentPage
                  ? _primaryBlue
                  : _primaryBlue.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Heading and intro text shared by most instruction pages.
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.heading, this.text});

  final String heading;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: _titleBlack,
          ),
        ),

        if (text case final text?) ...[
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.only(left: 15, right: 50),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                color: _textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text, this.iconSize = 24});

  final IconData icon;
  final String text;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primaryBlue, size: iconSize),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: _textGrey,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round badge with a number or icon, followed by a text.
class _BadgeRow extends StatelessWidget {
  const _BadgeRow({
    required this.badge,
    required this.text,
    this.bold = false,
    this.color = _primaryBlue,
  });

  final Widget badge;
  final String text;
  final bool bold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: badge,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: bold ? 18 : 16,
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
              color: _titleBlack,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_1_welc,
          text: l10n.instructions_1_text,
        ),

        const SizedBox(height: 30),

        // Image
        Center(
          child: Image.asset(
            'assets/images/6minute_walk_illustration.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _StepsPage extends StatelessWidget {
  const _StepsPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      l10n.bulletPoint_1,
      l10n.bulletPoint_2,
      l10n.bulletPoint_3,
      l10n.bulletPoint_4,
      l10n.bulletPoint_5,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.instructions_2_welc,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: _titleBlack,
          ),
        ),

        const SizedBox(height: 30),

        // Test-Steps
        for (final (index, step) in steps.indexed) ...[
          if (index > 0) const SizedBox(height: 18),
          _BadgeRow(
            badge: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _primaryBlue,
              ),
            ),
            text: step,
            bold: true,
          ),
        ],

        const SizedBox(height: 40),

        _InfoBox(
          icon: Icons.timer_rounded,
          iconSize: 40,
          text: l10n.instructions_2_text,
        ),
      ],
    );
  }
}

class _PersonalDataPage extends StatelessWidget {
  const _PersonalDataPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_3_heading,
          text: l10n.instructions_3_text,
        ),

        const SizedBox(height: 20),

        // Image
        Center(
          child: Image.asset(
            'assets/images/personal_data.png',
            width: 260,
            height: 260,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 20),

        _InfoBox(
          icon: Icons.info_outline_rounded,
          text: l10n.instructions_3_range,
        ),
      ],
    );
  }
}

class _WalkPage extends StatelessWidget {
  const _WalkPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hints = [
      (Icons.forest_rounded, l10n.instructions_4_outdoor),
      (Icons.phone_iphone_rounded, l10n.instructions_4_pocket),
      (Icons.directions_walk_rounded, l10n.instructions_4_walk),
      (Icons.timer_rounded, l10n.instructions_4_timer),
      (Icons.pause_rounded, l10n.instructions_4_pause),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(heading: l10n.instructions_4_welc),

        const SizedBox(height: 16),

        // Image
        Center(
          child: Image.asset(
            'assets/images/6minute_walk_illustration.png',
            height: 150,
            fit: BoxFit.contain,
          ),
        ),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final (icon, hint) in hints)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _BadgeRow(
                    badge: Icon(icon, size: 22, color: _primaryBlue),
                    text: hint,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyPage extends StatelessWidget {
  const _SafetyPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signs = [
      (Icons.favorite_rounded, l10n.instructions_5_chest),
      (Icons.cyclone_rounded, l10n.instructions_5_dizzy),
      (Icons.air_rounded, l10n.instructions_5_breath),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_5_welc,
          text: l10n.instructions_5_text,
        ),

        const SizedBox(height: 30),

        for (final (index, (icon, sign)) in signs.indexed) ...[
          if (index > 0) const SizedBox(height: 18),
          _BadgeRow(
            badge: Icon(icon, size: 22, color: _warningRed),
            text: sign,
            bold: true,
            color: _warningRed,
          ),
        ],

        const SizedBox(height: 40),

        _InfoBox(
          icon: Icons.medical_services_rounded,
          text: l10n.instructions_5_doctor,
        ),
      ],
    );
  }
}

class _PerformancePage extends StatelessWidget {
  const _PerformancePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_6_welc,
          text: l10n.instructions_6_text,
        ),

        const SizedBox(height: 30),

        const PerformanceBar(),

        const SizedBox(height: 24),

        for (final category in FitnessCategory.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: performanceScaleColors[category],
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    fitnessCategoryLabel(l10n, category),
                    style: const TextStyle(fontSize: 16, color: _titleBlack),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SetUpPage extends StatelessWidget {
  const _SetUpPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_7_welc,
          text: l10n.instructions_7_text,
        ),

        const SizedBox(height: 30),

        // Image
        Center(
          child: Image.asset(
            'assets/images/set_up.png',
            width: 500,
            height: 400,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
