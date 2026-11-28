import 'dart:math';
import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'demographics_setup_screen.dart';

class AliasSetupScreen extends StatefulWidget {
  const AliasSetupScreen({super.key});

  @override
  State<AliasSetupScreen> createState() => _AliasSetupScreenState();
}

class _AliasSetupScreenState extends State<AliasSetupScreen> {
  final TextEditingController _aliasController = TextEditingController();

  static const _adjectives = [
    'Calm',
    'Quiet',
    'Gentle',
    'Bright',
    'Kind',
    'Steady',
  ];
  static const _nouns = [
    'Otter',
    'Moon',
    'River',
    'Cloud',
    'Fox',
    'Leaf',
  ];

  @override
  void initState() {
    super.initState();
    _generateRandomAlias();
  }

  void _generateRandomAlias() {
    final rng = Random();
    final adj = _adjectives[rng.nextInt(_adjectives.length)];
    final noun = _nouns[rng.nextInt(_nouns.length)];
    final num = rng.nextInt(90) + 10;
    _aliasController.text = '$adj$noun$num';
  }

  void _continue() {
    final alias = _aliasController.text.trim();
    if (alias.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alias must be at least 3 characters long.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DemographicsSetupScreen(alias: alias),
      ),
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Choose Your Alias',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pick your public name',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Step 2 of 3 — This anonymous alias is all the community will ever see.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _aliasController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Anonymous Alias',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Generate random alias',
                    icon: const Icon(Icons.casino_outlined,
                        color: AppColors.primary),
                    onPressed: _generateRandomAlias,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}