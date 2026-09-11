import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  static const Color primaryBlue = Color(0xFF347FE5);
  static const Color circleBlue = Color(0xFF9BB8F0);

  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (name.isEmpty ||
        age == null ||
        height == null ||
        weight == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final profileRepository = ref.read(profileRepositoryProvider);

    final profileId = await profileRepository.ensureProfile(
      name: name,
      age: age,
      height: height,
    );

    if (!mounted) return;

    context.push('/video', extra: profileId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zurück-Button
              Transform.translate(
                offset: const Offset(-15, -1),
                child: IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Icon + Titel
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBlue,
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      size: 50,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Text(
                    'Pre-Calibration',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              const Text(
                'To obtain the most accurate test results possible, '
                'please enter all information correctly.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.15,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Patient Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              _InputField(controller: _nameController, hintText: 'Name'),

              const SizedBox(height: 8),

              _InputField(
                controller: _ageController,
                hintText: 'Age in years',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _GenderButton(
                      icon: Icons.male,
                      label: 'Male',
                      selected: _selectedGender == 'male',
                      onTap: () {
                        setState(() {
                          _selectedGender = 'male';
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _GenderButton(
                      icon: Icons.female,
                      label: 'Female',
                      selected: _selectedGender == 'female',
                      onTap: () {
                        setState(() {
                          _selectedGender = 'female';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Anthropometrics',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              _InputField(
                controller: _heightController,
                hintText: 'Height',
                suffixText: 'cm',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 8),

              _InputField(
                controller: _weightController,
                hintText: 'Weight',
                suffixText: 'kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'Your privacy is important to us. This information will\n'
                  'not be used for any other purposes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 65),

              // Continue - Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _continue,
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
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    this.suffixText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final String? suffixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB5B5B5), fontSize: 15),
          suffixText: suffixText,
          suffixStyle: const TextStyle(color: Color(0xFFB5B5B5), fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFF888888)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFF888888)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: const BorderSide(color: Color(0xFF367FEA), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF1198F5)
              : Colors.grey.shade300,
          foregroundColor: selected ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
