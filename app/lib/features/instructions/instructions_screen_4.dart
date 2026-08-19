import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InstructionsScreen4 extends StatelessWidget {
  const InstructionsScreen4({super.key});

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);
  static const Color textGrey = Color(0xFF2B2B2B);
  static const Color infoBlue = Color(0xFFB9D0F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onTap: () => context.pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Color(0xFF111111),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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

                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 55),

              // Page - Content
              const Text(
                'During the test',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 10),

              const Padding(
                padding: EdgeInsets.only(left: 15, right: 50),
                child: Text(
                  'Walk for six minutes at your normal, brisk pace. '
                      'The app displays the remaining time and the distance already covereda',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF2B2B2B),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 0),

              // Image
              Center(
                child: Image.asset(
                  'assets/images/6minute_walk_illustration.png',
                  width: 280,
                  height: 320,
                  fit: BoxFit.contain,
                ),
              ),


              // Info-Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: infoBlue,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: const Color(0xFF777777),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.error_rounded,
                        color: Color(0xFFE53935),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Stop the test if you experience chest pain, dizziness, or severe shortness of breath.',
                        style: TextStyle(
                          fontSize: 17,
                          color: textGrey,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue - Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/instructions-5');
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
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 18,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.text,
  });

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
          decoration: const BoxDecoration(
            color: Color(0xFF8DB5F5),
          ),
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