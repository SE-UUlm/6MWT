import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color panelBlue = Color(0xFFDCE6FB);

  static const double textHorizontalPadding = 50;
  static const double panelHorizontalPadding = 120;

  static const double illustrationHeight = 300;
  static const double illustrationWidth = 500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          // Image
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 7, 0),
            child: SizedBox(
              width: double.infinity,
              height: illustrationHeight,
              child: Image.asset(
                'assets/images/walk_illustration.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF9BB8F0),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      size: 300,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 2),

                          // Titel + Icon + Info Box
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: textHorizontalPadding,
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    const Text(
                                      '6-Minute Walk Test',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w200,
                                        color: Color(0xFF111111),
                                        height: 1.5,
                                      ),
                                    ),

                                    Positioned(
                                      right: -25,
                                      top: -25,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => context.push('/instructions-1'),
                                        child: const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.info_outline,
                                            size: 25,
                                            color: Color(0xFF6B6B70),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                const Text(
                                  'Standardized assessment of functional\n'
                                      'exercise capacity',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w200,
                                    color: Color(0xFF2A2A2A),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: panelHorizontalPadding,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: panelBlue,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  _FeatureRow(
                                    icon: Icons.person_outline,
                                    iconColor: Color(0xFF6B6B70),
                                    text: 'Patient profile setup',
                                  ),
                                  SizedBox(height: 20),
                                  _FeatureRow(
                                    icon: Icons.favorite_border,
                                    iconColor: Color(0xFFE05C5C),
                                    text: '6-minute countdown',
                                  ),
                                  SizedBox(height: 20),
                                  _FeatureRow(
                                    icon: Icons.bar_chart_rounded,
                                    iconColor: Color(0xFFE0A45C),
                                    text: 'Results and values',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Continue - Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.push('/walk'),
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
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

  Future<void> _exportData(
      BuildContext context,
      WidgetRef ref,
      ) async {
    try {
      final sessions = await ref
          .read(walkSessionRepositoryProvider)
          .exportAllSessions();

      final samplesBySession = await ref
          .read(sampleRepositoryProvider)
          .exportAllSessions();

      final profiles = await ref
          .read(profileRepositoryProvider)
          .exportAllProfiles();

      for (final session in sessions) {
        final sessionId = session['id'] as String;
        session['samples'] = samplesBySession[sessionId] ?? [];
      }

      final export = {
        'exportedAt': DateTime.now().toIso8601String(),
        'profiles': profiles,
        'sessions': sessions,
      };

      final jsonString = const JsonEncoder().convert(export);

      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/6mwt_export_'
            '${DateTime.now().millisecondsSinceEpoch}.json',
      );

      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
          ),
        );
      }
    }
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}
