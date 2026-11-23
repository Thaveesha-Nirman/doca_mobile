import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xxl),
            _buildScanCard(context),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle(
              title: 'Quick actions',
              subtitle: 'Everything you need in one place',
            ),
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Skin Scan',
                    actionName: 'skin scan',
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.explore_rounded,
                    label: 'Explore',
                    actionName: 'explore',
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.timeline_rounded,
                    label: 'Journey',
                    actionName: 'journey',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle(
              title: 'Your journey',
              subtitle: 'Track your latest skin-care progress',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildJourneyCard(context),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle(
              title: 'Explore today',
              subtitle: 'Helpful content selected for you',
            ),
            const SizedBox(height: AppSpacing.md),
            const _ExploreTile(
              icon: Icons.water_drop_rounded,
              title: 'Daily skin hydration',
              subtitle: 'Simple habits for healthier-looking skin',
            ),
            const SizedBox(height: AppSpacing.md),
            const _ExploreTile(
              icon: Icons.wb_sunny_rounded,
              title: 'Sun protection guide',
              subtitle: 'Learn how to protect your skin every day',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good evening',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Welcome to Doca',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => debugPrint('Home: profile tapped'),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.face_retouching_natural_rounded,
            size: 36,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Understand your skin better',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start a guided scan and receive a simple overview of your skin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => debugPrint('Home: start scan tapped'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Start skin scan'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly progress',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complete your next check-in',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => debugPrint('Home: journey tapped'),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '65% completed',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.actionName,
  });

  final IconData icon;
  final String label;
  final String actionName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => debugPrint('Home: $actionName tapped'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.secondary, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => debugPrint('Home: $title tapped'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.secondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
