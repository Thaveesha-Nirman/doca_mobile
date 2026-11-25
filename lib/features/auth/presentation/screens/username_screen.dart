import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'gender_screen.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();

  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _continue() {
    final username = _usernameController.text.trim();

    if (username.length < 3) {
      setState(() {
        _errorText = 'Username must contain at least 3 characters.';
      });
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const GenderScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Create your username'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Choose an anonymous username',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This name will be shown instead of your real name.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _usernameController,
                maxLength: 30,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Example: CalmOtter47',
                  errorText: _errorText,
                ),
              ),
              const Spacer(),
              FilledButton(onPressed: _continue, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
