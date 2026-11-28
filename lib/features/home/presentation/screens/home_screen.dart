import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../data/models/community_post.dart';
import '../widgets/community_post_card.dart';
import '../widgets/share_post_sheet.dart';
import '../widgets/symptom_filter_sheet.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';
import 'journey_timeline_screen.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTab = 'forYou'; // "forYou" | "following"
  FeedFilterState _filters = const FeedFilterState();
  String _myAlias = 'You';

  bool get _isSearchingOrFiltering =>
      _searchController.text.trim().isNotEmpty || _filters.hasAny;

  String get _activeSortLabel {
    final effective = _filters.sortBy.isNotEmpty
        ? _filters.sortBy
        : (_searchController.text.trim().isNotEmpty ||
                _filters.symptoms.isNotEmpty ||
                _filters.bodyArea != null)
            ? 'relevance'
            : 'newest';

    switch (effective) {
      case 'relevance':
        return 'Best Match';
      case 'top':
        return 'Most Helpful';
      case 'journeys':
        return 'Most Updates';
      case 'newest':
      default:
        return 'Newest';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadMyAlias();
  }

  Future<void> _loadMyAlias() async {
    try {
      final res = await ApiService.instance.getMyProfile();
      final alias =
          (res['user'] as Map<String, dynamic>?)?['alias']?.toString();
      if (alias != null && alias.isNotEmpty && mounted) {
        setState(() => _myAlias = alias);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadFeed();
    });
  }

  Future<void> _openFilterSheet() async {
    final updated = await showSymptomFilterSheet(
      context: context,
      initial: _filters,
    );
    if (updated != null && mounted) {
      setState(() => _filters = updated);
      await _loadFeed();
    }
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _filters = const FeedFilterState());
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawList = await ApiService.instance.getPosts(
        tab: _selectedTab,
        query: _searchController.text.trim(),
        status: _filters.status,
        symptoms: _filters.symptoms,
        bodyArea: _filters.bodyArea,
        hasPhotosOnly: _filters.hasPhotosOnly,
        journeysOnly: _filters.journeysOnly,
        sortBy: _filters.sortBy,
      );
      final fetched = rawList
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _posts = fetched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load posts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    if (!mounted || created == null) return;
    await _loadFeed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post published to the community feed!')),
    );
  }

  Future<void> _handleVote(CommunityPost post, String type) async {
    try {
      final res = await ApiService.instance.votePost(post.id, type);
      final fresh = CommunityPost.fromJson(res['post'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _posts = _posts
            .map((p) => p.id == post.id ? p.withUpdatedPostData(fresh) : p)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e')),
      );
    }
  }

  Future<void> _handleShare(CommunityPost post) async {
    if (post.isSharedByMe) {
      final confirm = await showRemoveShareDialog(context);
      if (!confirm || !mounted) return;
      try {
        await ApiService.instance.unsharePost(post.id);
        await _loadFeed();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared post removed')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove failed: $e')),
        );
      }
      return;
    }

    final caption = await showSharePostSheet(
      context: context,
      userAlias: _myAlias,
      post: post,
    );
    if (caption == null || !mounted) return;

    try {
      await ApiService.instance.toggleSharePost(post.id, caption: caption);
      await _loadFeed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared to the feed & your profile!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  Future<void> _handleEdit(CommunityPost post) async {
    if (post.isSharedPost) {
      if (post.shareId == null) return;
      final newCaption = await showSharePostSheet(
        context: context,
        userAlias: _myAlias,
        post: post,
        initialCaption: post.shareCaption,
        isEditing: true,
      );
      if (newCaption == null || !mounted) return;

      try {
        await ApiService.instance.updateShareCaption(post.shareId!, newCaption);
        await _loadFeed();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caption updated!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
      return;
    }

    final updated = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(editingPost: post),
      ),
    );
    if (updated != null && mounted) {
      await _loadFeed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated!')),
      );
    }
  }

  Future<void> _handleDelete(CommunityPost post) async {
    final isShare = post.isSharedPost;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isShare ? 'Delete shared post?' : 'Delete post?'),
        content: Text(
          isShare
              ? 'This removes your shared post from the feed. The original post stays intact.'
              : 'This will permanently delete your post.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      if (isShare) {
        if (post.shareId == null) return;
        await ApiService.instance.deleteShare(post.shareId!);
      } else {
        await ApiService.instance.deletePost(post.id);
      }
      await _loadFeed();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isShare ? 'Shared post deleted' : 'Post deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openOriginalPost(CommunityPost post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: post.id,
          initialPost: post,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadFeed();
    }
  }

  Future<void> _openComments(CommunityPost post) async {
    final updatedCount = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          post: post,
          onAuthorTap: (uid) => _openUserByUid(uid, 'Profile'),
        ),
      ),
    );
    if (updatedCount != null && mounted) {
      setState(() {
        _posts = _posts
            .map(
              (p) => p.id == post.id ? p.copyWith(comments: updatedCount) : p,
            )
            .toList();
      });
    }
  }

  Future<void> _openJourney(CommunityPost post) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JourneyTimelineScreen(postId: post.id),
      ),
    );
    if (changed == true && mounted) {
      await _loadFeed();
    }
  }

  void _openUserByUid(String uid, String alias, {bool isMe = false}) {
    if (isMe) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    if (uid.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          uid: uid,
          initialAlias: alias,
        ),
      ),
    );
  }

  void _openAuthor(CommunityPost post) {
    _openUserByUid(post.authorUid, post.alias, isMe: post.isOwner);
  }

  void _openSharer(CommunityPost post) {
    if (post.sharedByUid == null) return;
    _openUserByUid(
      post.sharedByUid!,
      post.sharedByAlias ?? 'Profile',
      isMe: post.isSharerMe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildSidebarDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildFeedTabs(),
            QuickSymptomFilterBar(
              filters: _filters,
              onFiltersChanged: (next) {
                setState(() => _filters = next);
                _loadFeed();
              },
              onOpenAllFilters: _openFilterSheet,
            ),
            if (_isSearchingOrFiltering && !_isLoading && _error == null)
              _buildSearchSummaryStrip(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFeed,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    style:
                                        const TextStyle(color: Colors.redAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  ElevatedButton(
                                    onPressed: _loadFeed,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _posts.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.sm,
                                  AppSpacing.md,
                                  AppSpacing.xxl,
                                ),
                                itemCount: _posts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (_, index) {
                                  final post = _posts[index];
                                  return CommunityPostCard(
                                    key: ValueKey(post.feedItemId),
                                    alias: post.alias,
                                    timeAgo: post.timeAgo,
                                    status: post.status,
                                    title: post.title,
                                    body: post.body,
                                    votes: post.votes,
                                    userVote: post.userVote,
                                    comments: post.comments,
                                    sharesCount: post.sharesCount,
                                    isSharedByMe: post.isSharedByMe,
                                    stepNumber: post.stepNumber,
                                    journeyCount: post.journeyCount,
                                    images: post.images,
                                    isSensitive: post.isSensitive,
                                    matchedTerms: post.matchedTerms,
                                    sharedByAlias: post.sharedByAlias,
                                    shareCaption: post.shareCaption,
                                    canManage: post.isSharedPost
                                        ? post.isSharerMe
                                        : post.isOwner,
                                    onEdit: () => _handleEdit(post),
                                    onDelete: () => _handleDelete(post),
                                    sharedTimeAgo: post.sharedTimeAgo,
                                    onSharerTap: () => _openSharer(post),
                                    onOpenOriginalPost: () =>
                                        _openOriginalPost(post),
                                    onAuthorTap: () => _openAuthor(post),
                                    onViewJourney: () => _openJourney(post),
                                    onUpvote: () => _handleVote(post, 'up'),
                                    onDownvote: () => _handleVote(post, 'down'),
                                    onComment: () => _openComments(post),
                                    onShare: () => _handleShare(post),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSummaryStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_posts.length} matching ${_posts.length == 1 ? 'post' : 'posts'} · $_activeSortLabel',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: const Text(
              'Reset all',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 56,
            horizontal: AppSpacing.xl,
          ),
          child: Column(
            children: [
              Icon(
                _isSearchingOrFiltering
                    ? Icons.search_off_rounded
                    : Icons.forum_outlined,
                size: 42,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _isSearchingOrFiltering
                    ? 'No posts matched those exact symptoms or filters.\nTry removing a filter or using simpler keywords.'
                    : _selectedTab == 'following'
                        ? 'No posts or shares from people you follow yet.\nTap a username in "For You" and hit Follow!'
                        : 'No posts yet. Tap + to share your journey!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_isSearchingOrFiltering) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Clear Search & Filters'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _searchDebounce?.cancel();
                  _loadFeed();
                },
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search symptoms (e.g. itchy red bumps)...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setState(() {});
                            _loadFeed();
                          },
                        ),
                      IconButton(
                        tooltip: 'Filter by Symptoms',
                        padding: const EdgeInsets.only(right: 6),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: _openFilterSheet,
                        icon: _filters.hasAny
                            ? Badge(
                                label: Text('${_filters.activeCount}'),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Create Post',
            onPressed: _openCreatePost,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.background,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _buildTabItem('For You', 'forYou'),
          _buildTabItem('Following', 'following'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String tabKey) {
    final selected = _selectedTab == tabKey;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectedTab == tabKey) return;
          setState(() => _selectedTab = tabKey);
          _loadFeed();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Doca',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Anonymous health community',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Divider(color: AppColors.border, height: 28),
            const Text(
              'FILTER BY STATUS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public, color: AppColors.textPrimary),
              title: const Text(
                'All Posts',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _filters = _filters.copyWith(clearStatus: true));
                Navigator.of(context).pop();
                _loadFeed();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text(
                'Just Asking',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _filters = _filters.copyWith(status: 'Asking'));
                Navigator.of(context).pop();
                _loadFeed();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.healing_outlined,
                color: Colors.orangeAccent,
              ),
              title: const Text(
                'Ongoing Treatment',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _filters = _filters.copyWith(status: 'Ongoing'));
                Navigator.of(context).pop();
                _loadFeed();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: Colors.greenAccent,
              ),
              title: const Text(
                'Healed Stories',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _filters = _filters.copyWith(status: 'Healed'));
                Navigator.of(context).pop();
                _loadFeed();
              },
            ),
          ],
        ),
      ),
    );
  }
}