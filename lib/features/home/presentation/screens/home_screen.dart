import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';
import '../../data/repositories/community_post_repository.dart';
import '../../data/repositories/temporary_local_community_post_repository.dart';
import '../widgets/community_post_card.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.repository = const TemporaryLocalCommunityPostRepository(),
  });

  final CommunityPostRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    setState(() {
      _posts = <CommunityPost>[post, ..._posts];
    });
  }

  void _viewJourney(String journeyId) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('View Journey: $journeyId')));
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
                        : () => _viewJourney(post.journeyId!),
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
