import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildSearchField(),
            const SizedBox(height: AppSpacing.md),
            const _SafetyNotice(),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeading(
              title: 'Browse topics',
              subtitle: 'Find communities that match your concerns',
            ),
            const SizedBox(height: AppSpacing.md),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TopicChip(label: 'Skin irritation'),
                _TopicChip(label: 'Acne support'),
                _TopicChip(label: 'Dryness'),
                _TopicChip(label: 'Sensitive skin'),
                _TopicChip(label: 'Recovery stories'),
                _TopicChip(label: 'Daily routines'),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionHeading(
              title: 'Healed journeys',
              subtitle: 'Anonymous experiences shared by the community',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExploreItem(
              icon: Icons.auto_awesome_rounded,
              badge: 'Healed',
              title: 'Small changes that helped my recovery',
              subtitle: 'A four-week anonymous recovery journey',
              onTap: () {
                debugPrint('Explore: healed journey selected');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ExploreItem(
              icon: Icons.timeline_rounded,
              badge: '6 updates',
              title: 'Tracking progress with a simple routine',
              subtitle: 'Community member · Shared anonymously',
              onTap: () {
                debugPrint('Explore: recovery timeline selected');
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionHeading(
              title: 'Helpful discussions',
              subtitle: 'Community posts people found useful',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExploreItem(
              icon: Icons.forum_outlined,
              badge: '42 helpful',
              title: 'How do you track changes without overthinking?',
              subtitle: '18 replies · Most Helpful',
              onTap: () {
                debugPrint('Explore: helpful discussion selected');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ExploreItem(
              icon: Icons.shield_outlined,
              badge: 'Privacy',
              title: 'Sharing progress photos more safely',
              subtitle: '11 replies · Image privacy discussion',
              onTap: () {
                debugPrint('Explore: privacy discussion selected');
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionHeading(
              title: 'Regional updates',
              subtitle: 'Broad privacy-protected community patterns',
            ),
            const SizedBox(height: AppSpacing.md),
            _ExploreItem(
              icon: Icons.location_on_outlined,
              badge: 'General region',
              title: 'View community health updates',
              subtitle: 'Exact user locations are never displayed',
              onTap: () {
                debugPrint('Explore: regional updates selected');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Discover topics, stories, and helpful discussions',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            debugPrint('Explore: filters opened');
          },
          tooltip: 'Open filters',
          icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      style: const TextStyle(color: AppColors.textPrimary),
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        debugPrint('Explore search submitted: $value');
      },
      decoration: InputDecoration(
        hintText: 'Search symptoms, topics, or stories',
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            debugPrint('Explore: search filters opened');
          },
          tooltip: 'Search filters',
          icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Community experiences can offer support, but they are not a '
              'medical diagnosis or professional advice.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        debugPrint('Explore topic selected: $label');
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ExploreItem extends StatelessWidget {
  const _ExploreItem({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary, size: 23),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
