import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';
import 'create_post_screen.dart';
import '../widgets/community_post_card.dart';
import '../../../journey/data/repositories/local_journey_repository.dart';
import '../../../journey/presentation/screens/journey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.journeyRepository, super.key});

  final LocalJourneyRepository? journeyRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocalJourneyRepository get _journeys =>
      widget.journeyRepository ?? LocalJourneyRepository.instance;
  final Set<String> _startingJourneys = {};
  int _postSequence = 0;
  static const List<String> _filters = [
    'For You',
    'Recent',
    'Most Helpful',
    'Healed Stories',
    'Nearby Alerts',
  ];
  final List<CommunityPost> _posts = <CommunityPost>[
    CommunityPost(
      alias: 'CalmOtter47',
      timeAgo: '12 min ago',
      topic: 'Skin irritation',
      status: 'Asking',
      title: 'Has anyone experienced something similar?',
      body:
          'I noticed some mild redness after changing my skincare '
          'routine. I stopped using the new product for now. Has '
          'anyone had a similar experience?',
      votes: 24,
      comments: 8,
    ),
    CommunityPost(
      alias: 'QuietMoon22',
      id: 'shared_root_update',
      journeyId: 'shared_journey',
      rootPostId: 'shared_root',
      parentPostId: 'shared_root',
      timeAgo: '1 hr ago',
      topic: 'Recovery journey',
      status: 'Ongoing',
      title: 'Week two of tracking my skin changes',
      body:
          'I have been recording my symptoms and keeping my routine '
          'simple. The irritation looks calmer today, but I am still '
          'monitoring it carefully.',
      votes: 67,
      comments: 19,
      isSensitive: true,
    ),
    CommunityPost(
      alias: 'BlueLotus81',
      timeAgo: '3 hr ago',
      topic: 'Healed story',
      status: 'Healed',
      title: 'Patience and a simple routine helped me',
      body:
          'After speaking with a qualified professional and following '
          'the recommended routine, my skin has improved. Sharing this '
          'to encourage anyone who is still recovering.',
      votes: 142,
      comments: 31,
    ),
  ];
  String _selectedFilter = 'For You';
  Future<void> _openCreatePost() async {
    final CommunityPost? post = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute<CommunityPost>(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    if (!mounted || post == null) {
      return;
    }

    final ownedPost = post.copyWith(
      id: 'home_post_${DateTime.now().microsecondsSinceEpoch}_${++_postSequence}',
      alias: LocalJourneyRepository.currentAlias,
      createdAt: DateTime.now().toUtc(),
    );
    _journeys.registerOwnedPost(ownedPost);
    setState(() => _posts.insert(0, ownedPost));

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Post published locally')));
  }

  Future<void> _openJourney(CommunityPost post) async {
    final id = post.journeyId;
    if (id == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => JourneyScreen(
          journeyId: id,
          repository: _journeys,
          isCurrentUserOwner: _journeys.ownsJourney(id),
        ),
      ),
    );
  }

  Future<void> _startJourney(CommunityPost post) async {
    final id = post.id;
    if (id == null || !_journeys.ownsPost(id) || !_startingJourneys.add(id)) {
      return;
    }
    setState(() {});
    try {
      final privacy = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Journey privacy'),
          children: ['Private', 'Shared Anonymously']
              .map(
                (value) => SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop(value),
                  child: Text(value),
                ),
              )
              .toList(),
        ),
      );
      if (privacy == null) return;
      final journey = await _journeys.createJourney(
        rootPostId: id,
        privacy: privacy,
      );
      if (!mounted) return;
      final index = _posts.indexWhere((item) => item.id == id);
      if (index < 0) return;
      final linkedPost = journey.rootPost!;
      setState(() => _posts[index] = linkedPost);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Journey created')));
      await _openJourney(linkedPost);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create journey: $error')),
        );
      }
    } finally {
      _startingJourneys.remove(id);
      if (mounted) setState(() {});
    }
  }

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
            const _PrivacyNotice(),
            const SizedBox(height: AppSpacing.xl),
            _buildFeedHeading(),
            const SizedBox(height: AppSpacing.md),
            _buildFilters(),
            const SizedBox(height: AppSpacing.lg),
            _CreatePostPrompt(onTap: _openCreatePost),
            const SizedBox(height: AppSpacing.lg),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final CommunityPost post = _posts[index];

                return CommunityPostCard(
                  key: ValueKey(post.id ?? index),
                  journeyId: post.journeyId,
                  onViewJourney: () => _openJourney(post),
                  onStartJourney:
                      _journeys.ownsPost(post.id) &&
                          !_startingJourneys.contains(post.id)
                      ? () => _startJourney(post)
                      : null,
                  alias: post.alias,
                  timeAgo: post.timeAgo,
                  topic: post.topic,
                  status: post.status,
                  title: post.title,
                  body: post.body,
                  votes: post.votes,
                  comments: post.comments,
                  isSensitive: post.isSensitive,
                );
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doca',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'A safer space for your health journey',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: 'Notifications',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      readOnly: true,
      onTap: () {},
      style: const TextStyle(color: AppColors.textPrimary),
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
        suffixIcon: const Icon(
          Icons.tune_rounded,
          color: AppColors.textSecondary,
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

  Widget _buildFeedHeading() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Community',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          'Anonymous feed',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'You’re in control of what you share. Your real name and exact '
              'location are never shown publicly.',
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

class _CreatePostPrompt extends StatelessWidget {
  const _CreatePostPrompt({required this.onTap});

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
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceElevated,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Share a question or recovery update…',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Icon(Icons.edit_outlined, color: AppColors.primary, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}
