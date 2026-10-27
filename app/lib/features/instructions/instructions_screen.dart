import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

const Color _primaryBlue = Color(0xFF347FE5);
const Color _circleBlue = Color(0xFF9BB8F0);
const Color _textGrey = Color(0xFF2B2B2B);
const Color _infoBlue = Color(0xFFB9D0F5);
const Color _titleBlack = Color(0xFF111111);

const Duration _pageTransitionDuration = Duration(milliseconds: 300);

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

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
    _CancelOrRepeatPage(),
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
      context.pop();
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Back - Arrow
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: _titleBlack,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Icon + Titel
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _circleBlue,
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        size: 26,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      l10n.instructions,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: _titleBlack,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 55),

                // Page - Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      for (final page in _pages)
                        SingleChildScrollView(child: page),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                      l10n.continueButton,
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
  const _PageHeader({required this.heading, required this.text});

  final String heading;
  final String text;

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

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.only(left: 15, right: 50),
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, color: _textGrey, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: _infoBoxDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: icon),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                color: _textGrey,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _infoBoxDecoration = BoxDecoration(
  color: _infoBlue,
  borderRadius: BorderRadius.circular(7),
  border: Border.all(color: const Color(0xFF777777), width: 0.7),
);

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

        const SizedBox(height: 35),

        // Test-Steps
        for (final (index, step) in steps.indexed) ...[
          if (index > 0) const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _StepRow(number: '${index + 1}', text: step),
          ),
        ],

        const SizedBox(height: 100),

        _InfoBox(
          icon: const Text('💡', style: TextStyle(fontSize: 20)),
          text: l10n.instructions_2_text,
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFF8DB5F5)),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _titleBlack,
          ),
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

        const SizedBox(height: 30),

        // Image
        Center(
          child: Image.asset(
            'assets/images/personal_data.png',
            width: 280,
            height: 320,
            fit: BoxFit.contain,
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_4_welc,
          text: l10n.instructions_4_text,
        ),

        // Image
        Center(
          child: Image.asset(
            'assets/images/6minute_walk_illustration.png',
            width: 280,
            height: 320,
            fit: BoxFit.contain,
          ),
        ),

        _InfoBox(
          icon: const Icon(
            Icons.error_rounded,
            color: Color(0xFFE53935),
            size: 22,
          ),
          text: l10n.instructions_4_text_2,
        ),
      ],
    );
  }
}

class _CancelOrRepeatPage extends StatelessWidget {
  const _CancelOrRepeatPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          heading: l10n.instructions_5_welc,
          text: l10n.instructions_5_text,
        ),

        const SizedBox(height: 60),

        // Info-Boxes
        Row(
          children: [
            // Left Box: Cancel
            Expanded(
              child: _ReasonsBox(
                icon: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF008B3E),
                  size: 42,
                ),
                reasons: [
                  l10n.instructions_5_c1,
                  l10n.instructions_5_c2,
                  l10n.instructions_5_c3,
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right Box: Repeat
            Expanded(
              child: _ReasonsBox(
                icon: const Icon(
                  Icons.repeat_rounded,
                  color: Color(0xFFE53935),
                  size: 42,
                ),
                reasons: [l10n.instructions_5_f1, l10n.instructions_5_f2],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReasonsBox extends StatelessWidget {
  const _ReasonsBox({required this.icon, required this.reasons});

  final Widget icon;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: _infoBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          for (final reason in reasons) ...[
            const SizedBox(height: 30),
            Text(
              reason,
              style: const TextStyle(
                fontSize: 17,
                color: _textGrey,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
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

        // Image
        Center(
          child: Image.asset(
            'assets/images/performance.png',
            width: 500,
            height: 400,
            fit: BoxFit.contain,
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
