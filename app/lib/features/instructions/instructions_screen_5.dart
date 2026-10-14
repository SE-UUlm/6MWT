import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class InstructionsScreen5 extends StatelessWidget {
  const InstructionsScreen5({super.key});

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);
  static const Color textGrey = Color(0xFF2B2B2B);
  static const Color infoBlue = Color(0xFFB9D0F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Icon + Titel
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBlue,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      size: 30,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(width: 18),

                  Text(
                    AppLocalizations.of(context)!.instructions,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 55),

              // Page - Content
              Text(
                AppLocalizations.of(context)!.instructions_5_welc,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.only(left: 15, right: 50),
                child: Text(
                  AppLocalizations.of(context)!.instructions_5_text,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF2B2B2B),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Info-Boxes
              Row(
                children: [
                  // Left Box: Cancel
                  Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height / 2.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: infoBlue,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF777777),
                          width: 0.7,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF008B3E),
                            size: 42,
                          ),

                          const SizedBox(height: 30),

                          Text(
                            AppLocalizations.of(context)!.instructions_5_c1,
                            style: TextStyle(
                              fontSize: 17,
                              color: textGrey,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 30),

                          Text(
                            AppLocalizations.of(context)!.instructions_5_c2,
                            style: TextStyle(
                              fontSize: 17,
                              color: textGrey,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 30),

                          Text(
                            AppLocalizations.of(context)!.instructions_5_c3,
                            style: TextStyle(
                              fontSize: 17,
                              color: textGrey,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right Box: Repeat
                  Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height / 2.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: infoBlue,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFF777777),
                          width: 0.7,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            color: Color(0xFFE53935),
                            size: 42,
                          ),

                          const SizedBox(height: 30),

                          Text(
                            AppLocalizations.of(context)!.instructions_5_f1,
                            style: TextStyle(
                              fontSize: 17,
                              color: textGrey,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 30),

                          Text(
                            AppLocalizations.of(context)!.instructions_5_f2,
                            style: TextStyle(
                              fontSize: 17,
                              color: textGrey,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Continue - Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/instructions-6');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF347FE5),
                    foregroundColor: Colors.white,
                    elevation: 0,
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
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}
