import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InstructionsScreen1 extends StatelessWidget {
  const InstructionsScreen1({super.key});

  static const Color circleBlue = Color(0xFF9BB8F0);
  static const Color textGrey = Color(0xFF6B6B70);

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

              const SizedBox(height: 12),

              // Icon + Titel
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBlue,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      size: 26,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                'Welcome!',
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
                  'This app guides you step-by-step through the '
                      '6-Minute Walk Test (6MWT). The test helps assess '
                      'your physical performance based on the distance '
                      'walked in six minutes.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF2B2B2B),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Image
              Center(
                child: Image.asset(
                  'assets/images/6minute_walk_illustration.png',
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(),

              // Continue - Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/instructions-2');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF347FE5),
                    foregroundColor: Colors.white,
                    elevation: 0,
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
                    width: 18,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF347FE5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF347FE5).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF347FE5).withValues(alpha: 0.25),
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