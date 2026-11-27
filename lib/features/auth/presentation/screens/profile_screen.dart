import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../home/data/models/community_post.dart';
import '../../../home/presentation/screens/comments_screen.dart';
import '../../../home/presentation/screens/create_post_screen.dart';
import '../../../home/presentation/screens/journey_timeline_screen.dart';
import '../../../home/presentation/widgets/community_post_card.dart';
import 'auth_welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'public_profile_screen.dart';
import '../../../home/presentation/widgets/share_post_sheet.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  List<CommunityPost> _myJourneys = [];
  List<CommunityPost> _sharedPosts = [];
  int _activeTab = 0; // 0 = My Journeys, 1 = Shared Posts
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profileRes = await ApiService.instance.getMyProfile();
      final journeysRaw = await ApiService.instance.getMyPosts();
      final sharedRaw = await ApiService.instance.getSharedPosts();

      if (!mounted) return;
      setState(() {
        _profile =
            UserProfile.fromJson(profileRes['user'] as Map<String, dynamic>);
        _myJourneys = journeysRaw
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList();
        _sharedPosts = sharedRaw
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    if (_profile == null) return;
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: _profile!),
      ),
    );
    if (updated != null && mounted) {
      await _loadAll();
    }
  }

  Future<void> _addJourneyUpdate(CommunityPost post) async {
    final created = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(parentPost: post),
      ),
    );
    if (created != null && mounted) {
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journey update added and linked!')),
      );
    }
  }

  Future<void> _openJourney(CommunityPost post, {bool editMode = false}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JourneyTimelineScreen(
          postId: post.id,
          editMode: editMode,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _loadAll();
    }
  }

  Future<void> _vote(CommunityPost post, String type) async {
    try {
      final res = await ApiService.instance.votePost(post.id, type);
      final updated =
          CommunityPost.fromJson(res['post'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _replacePost(_myJourneys, updated);
        _replacePost(_sharedPosts, updated);
      });
    } catch (_) {}
  }

 Future<void> _share(CommunityPost post) async {
  final caption = await showSharePostSheet(
    context: context,
    userAlias: _profile?.alias ?? 'You',
    post: post,
  );
  if (caption == null || !mounted) return;
  try {
    await ApiService.instance.toggleSharePost(post.id, caption: caption);
    await _loadAll();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share failed: $e')),
    );
  }
}

Future<void> _handleEdit(CommunityPost post, bool isShareTab) async {
  if (isShareTab) {
    final shareId = post.shareId ?? 'legacy_${post.id}';
    final newCaption = await showSharePostSheet(
      context: context,
      userAlias: _profile?.alias ?? 'You',
      post: post,
      initialCaption: post.shareCaption,
      isEditing: true,
    );
    if (newCaption == null || !mounted) return;
    try {
      await ApiService.instance.updateShareCaption(shareId, newCaption);
      await _loadAll();
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
    await _loadAll();
  }
}

Future<void> _handleDelete(CommunityPost post, bool isShareTab) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isShareTab ? 'Delete shared post?' : 'Delete post?'),
      content: Text(
        isShareTab
            ? 'Remove this shared post from your profile and feed?'
            : 'Permanently delete this post?',
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
    if (isShareTab) {
      final shareId = post.shareId ?? 'legacy_${post.id}';
      await ApiService.instance.deleteShare(shareId);
    } else {
      await ApiService.instance.deletePost(post.id);
    }
    await _loadAll();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete failed: $e')),
    );
  }
}

  void _replacePost(List<CommunityPost> list, CommunityPost updated) {
  final idx = list.indexWhere((p) => p.id == updated.id);
  if (idx != -1) list[idx] = list[idx].withUpdatedPostData(updated);
}

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _activeTab == 0 ? _myJourneys : _sharedPosts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Settings & Edit Profile',
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: SafeArea(
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
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: _loadAll,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTabs(),
                        const SizedBox(height: AppSpacing.md),
                        if (posts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _activeTab == 0
                                  ? 'You have not published any journeys yet. Tap + on Home to share your first post!'
                                  : 'Posts you share from the feed will show up here.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ...posts.map(
                            (post) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: CommunityPostCard(
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
                                key: ValueKey(post.feedItemId),
sharedByAlias: _activeTab == 1 ? (post.sharedByAlias ?? _profile?.alias) : null,
sharedTimeAgo: _activeTab == 1 ? post.sharedTimeAgo : null,
shareCaption: _activeTab == 1 ? post.shareCaption : '',
canManage: true,
onEdit: () => _handleEdit(post, _activeTab == 1),
onDelete: () => _handleDelete(post, _activeTab == 1),
                                showOwnerJourneyActions: _activeTab == 0,
                                onAuthorTap: post.isOwner
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PublicProfileScreen(
                                              uid: post.authorUid,
                                              initialAlias: post.alias,
                                            ),
                                          ),
                                        );
                                      },
                                onViewJourney: () => _openJourney(post),
                                onAddJourney: () => _addJourneyUpdate(post),
                                onEditJourney: () =>
                                    _openJourney(post, editMode: true),
                                onUpvote: () => _vote(post, 'up'),
                                onDownvote: () => _vote(post, 'down'),
                                onComment: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CommentsScreen(post: post),
                                    ),
                                  );
                                },
                                onShare: () => _share(post),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = _profile!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person_outline_rounded,
              size: 36,
              color: AppColors.background,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.alias,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              user.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${user.gender}${user.age != null ? ' · ${user.age} yrs' : ''}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('Followers', '${user.followersCount}'),
              _stat('Following', '${user.followingCount}'),
              _stat('Journeys', '${_myJourneys.length}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit Profile & Settings'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _tabBtn('My Journeys (${_myJourneys.length})', 0),
        const SizedBox(width: AppSpacing.sm),
        _tabBtn('Shared Posts (${_sharedPosts.length})', 1),
      ],
    );
  }

  Widget _tabBtn(String label, int idx) {
    final active = _activeTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = idx),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.background : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}