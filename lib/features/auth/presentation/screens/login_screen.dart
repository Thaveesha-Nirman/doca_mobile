import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.onGetStarted, this.onExistingAccount});

  final VoidCallback? onGetStarted;
  final VoidCallback? onExistingAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Welcome to Doca',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'A private and anonymous space for your health journey.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  debugPrint('Get Started button pressed');
                  onGetStarted?.call();
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  debugPrint('I Already Have an Account button pressed');
                  onExistingAccount?.call();
                },
                child: const Text('I Already Have an Account'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Your real name and location are never shown publicly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
