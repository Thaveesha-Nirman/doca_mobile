import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';
import '../../data/repositories/community_post_repository.dart';
import '../../data/repositories/temporary_local_community_post_repository.dart';
import '../widgets/community_post_card.dart';
import 'create_post_screen.dart';
import '../../../journey/data/repositories/local_journey_repository.dart';
import '../../../journey/presentation/screens/journey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.journeyRepository,
    this.repository = const TemporaryLocalCommunityPostRepository(),
  });

  final CommunityPostRepository repository;
  final LocalJourneyRepository? journeyRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocalJourneyRepository get _journeys =>
      widget.journeyRepository ?? LocalJourneyRepository.instance;
  final Set<String> _startingJourneys = {};
  int _postSequence = 0;

  final TextEditingController _searchController = TextEditingController();

  List<CommunityPost> _posts = <CommunityPost>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  List<CommunityPost> get _visiblePosts {
    final String query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _posts;
    }

    return _posts.where((post) {
      return post.title.toLowerCase().contains(query) ||
          post.body.toLowerCase().contains(query) ||
          post.topic.toLowerCase().contains(query) ||
          post.alias.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<CommunityPost> loadedPosts = await widget.repository
          .fetchPosts();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = loadedPosts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load community posts.';
      });

      debugPrint('Failed to load community posts: $error');
    }
  }

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
    setState(() => _posts = [ownedPost, ..._posts]);
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
    if (id.isEmpty || !_journeys.ownsPost(id) || !_startingJourneys.add(id)) {
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
    final List<CommunityPost> visiblePosts = _visiblePosts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _openCreatePost,
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _buildErrorState()
            else if (visiblePosts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('No posts found')),
              )
            else
              ...visiblePosts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CommunityPostCard(
                    key: ValueKey(post.id),
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
                    journeyId: post.journeyId,
                    onViewJourney: post.journeyId == null
                        ? null
                        : () => _openJourney(post),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: _loadPosts, child: const Text('Retry')),
        ],
      ),
    );
  }
}
