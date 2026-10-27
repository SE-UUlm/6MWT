import 'package:six_minute_walk_test/app/metadata_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/domain/app_info.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static final repositoryUri = Uri.parse('https://github.com/SE-UUlm/6MWT');

  Future<void> _openRepository(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        repositoryUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Keep the screen usable when the platform cannot open a browser.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.aboutLinkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final info = ref.watch(appInfoProvider);
    String available(String? value) =>
        value == null || value.trim().isEmpty ? l10n.aboutUnavailable : value;

    Widget metadata(AppInfo value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TwoColumns(
          children: [
            _InfoField(
              label: l10n.aboutVersion,
              value: available(value.version),
            ),
            _InfoField(
              label: l10n.aboutBuild,
              value: available(value.buildNumber),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoField(
          label: l10n.aboutCommit,
          value: available(
            value.commitHash?.substring(
              0,
              value.commitHash!.length.clamp(0, 8),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF15356D),
        scrolledUnderElevation: 0,
      ),
      // The bottom inset is part of the scroll padding instead of a SafeArea,
      // so content scrolls behind the system navigation. The top inset is
      // already handled by the app bar.
      body: Center(
        child: SizedBox(
          width: 640,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 160,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 160,
                  child: Icon(
                    Icons.directions_walk_rounded,
                    size: 100,
                    color: Color(0xFF347FE5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF0C2B68),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aboutProject,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF586A85),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              _AboutPanel(
                child: info.when(
                  data: metadata,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => metadata(const AppInfo()),
                ),
              ),
              const SizedBox(height: 16),
              _AboutPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutAuthors,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF586A85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TwoColumns(
                      fitLastColumn: true,
                      children: [
                        for (final name in [
                          'Moritz Beck',
                          'Lea-Marie Kindermann',
                          'Serhat Kan',
                          'Luca-Marie Jamrosy',
                        ])
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: const Color(0xFF15356D),
                                  height: 1.5,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AboutPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AboutAction(
                      onPressed: () => _openRepository(context),
                      icon: Icons.open_in_new,
                      label: l10n.aboutRepository,
                      subtitle: repositoryUri.toString(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFE7EDF6)),
                    ),
                    _InfoField(
                      label: l10n.aboutProjectLicense,
                      value: 'GPL-3.0-or-later',
                    ),
                    const SizedBox(height: 8),
                    _AboutAction(
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: l10n.appTitle,
                        applicationVersion: info.asData?.value.version,
                        applicationLegalese: 'GPL-3.0-or-later',
                      ),
                      icon: Icons.description_outlined,
                      label: l10n.aboutLicenses,
                    ),
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

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFEDF0F5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B15356D),
          blurRadius: 24,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: const Color(0xFF586A85)),
      ),
      const SizedBox(height: 6),
      SelectableText(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFF15356D),
          height: 1.5,
        ),
      ),
    ],
  );
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.children, this.fitLastColumn = false});

  final List<Widget> children;
  final bool fitLastColumn;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns =
          constraints.maxWidth >= 220 &&
          MediaQuery.textScalerOf(context).scale(16) <= 24;
      if (twoColumns && fitLastColumn) {
        return Table(
          columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            for (var i = 0; i < children.length; i += 2)
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 20, top: i == 0 ? 0 : 12),
                    child: children[i],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                    child: i + 1 < children.length
                        ? children[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        );
      }
      return Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          for (final child in children)
            SizedBox(
              width: twoColumns
                  ? (constraints.maxWidth - 20) / 2
                  : constraints.maxWidth,
              child: child,
            ),
        ],
      );
    },
  );
}

class _AboutAction extends StatelessWidget {
  const _AboutAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.subtitle,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 10),
      foregroundColor: const Color(0xFF347FE5),
      minimumSize: const Size(double.infinity, 48),
      alignment: Alignment.centerLeft,
    ),
    onPressed: onPressed,
    child: Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF586A85),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 20),
      ],
    ),
  );
}
