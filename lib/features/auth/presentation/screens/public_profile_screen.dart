import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../home/data/models/community_post.dart';
import '../../../home/presentation/screens/comments_screen.dart';
import '../../../home/presentation/screens/journey_timeline_screen.dart';
import '../../../home/presentation/widgets/community_post_card.dart';
import '../../../home/presentation/widgets/share_post_sheet.dart';
import '../../../home/presentation/screens/post_detail_screen.dart';
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    required this.uid,
    this.initialAlias = 'Profile',
    super.key,
  });

  final String uid;
  final String initialAlias;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserProfile? _profile;
  List<CommunityPost> _journeys = [];
  List<CommunityPost> _sharedPosts = [];
  String _chatStatus = 'none'; // none | pending_sent | pending_received | accepted | self
  String? _requestId;
  int _activeTab = 0; // 0 = Journeys, 1 = Shared Posts
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
Future<void> _openOriginalPost(CommunityPost post) async {
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PostDetailScreen(postId: post.id, initialPost: post),
    ),
  );
  if (changed == true && mounted) {
    await _loadData();
  }
}
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileRes = await ApiService.instance.getPublicProfile(widget.uid);
      final statusRes =
          await ApiService.instance.getMessageRequestStatus(widget.uid);

      final user =
          UserProfile.fromJson(profileRes['user'] as Map<String, dynamic>);
      final rawJourneys = (profileRes['journeys'] as List<dynamic>?) ?? [];
      final rawShared = (profileRes['sharedPosts'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _profile = user;
        _journeys = rawJourneys
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList();
        _sharedPosts = rawShared
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList();
        _chatStatus = (statusRes['status'] ?? 'none').toString();
        _requestId = statusRes['requestId']?.toString();
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

  Future<void> _toggleFollow() async {
    if (_profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final res = await ApiService.instance.toggleFollow(widget.uid);
      if (!mounted) return;
      setState(() {
        _profile = _profile!.copyWith(
          isFollowing: res['isFollowing'] == true,
          followersCount:
              (res['followersCount'] as num?)?.toInt() ?? _profile!.followersCount,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Follow error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleMessageAction() async {
    if (_isBusy) return;

    if (_chatStatus == 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat is active! Open the Inbox tab to message.'),
        ),
      );
      return;
    }

    if (_chatStatus == 'pending_sent') return;

    setState(() => _isBusy = true);
    try {
      if (_chatStatus == 'pending_received' && _requestId != null) {
        await ApiService.instance.respondToMessageRequest(_requestId!, 'accept');
        if (!mounted) return;
        setState(() => _chatStatus = 'accepted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted! You can now chat in Inbox.'),
          ),
        );
      } else {
        final res = await ApiService.instance.sendMessageRequest(widget.uid);
        if (!mounted) return;
        setState(() {
          _chatStatus = (res['status'] ?? 'pending_sent').toString();
          _requestId = res['requestId']?.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message request sent!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _vote(CommunityPost post, String type) async {
    try {
      final res = await ApiService.instance.votePost(post.id, type);
      final updated =
          CommunityPost.fromJson(res['post'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _replacePost(_journeys, updated);
        _replacePost(_sharedPosts, updated);
      });
    } catch (_) {}
  }

Future<void> _share(CommunityPost post) async {
    if (post.isSharedByMe) {
      final confirm = await showRemoveShareDialog(context);
      if (!confirm || !mounted) return;
      try {
        await ApiService.instance.unsharePost(post.id);
        await _loadData();
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

    String myAlias = 'You';
    try {
      final meRes = await ApiService.instance.getMyProfile();
      myAlias =
          (meRes['user'] as Map<String, dynamic>?)?['alias']?.toString() ??
              'You';
    } catch (_) {}

    if (!mounted) return;
    final caption = await showSharePostSheet(
      context: context,
      userAlias: myAlias,
      post: post,
    );
    if (caption == null || !mounted) return;

    try {
      await ApiService.instance.toggleSharePost(post.id, caption: caption);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared to the feed & your profile!')),
      );
    } catch (_) {}
  }
 void _replacePost(List<CommunityPost> list, CommunityPost updated) {
  final idx = list.indexWhere((p) => p.id == updated.id);
  if (idx != -1) list[idx] = list[idx].withUpdatedPostData(updated);
}
  String _messageButtonLabel() {
    switch (_chatStatus) {
      case 'accepted':
        return 'Message (Inbox)';
      case 'pending_sent':
        return 'Request Sent';
      case 'pending_received':
        return 'Accept Request';
      default:
        return 'Message Request';
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _activeTab == 0 ? _journeys : _sharedPosts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          _profile?.alias ?? widget.initialAlias,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSectionTabs(),
                      const SizedBox(height: AppSpacing.md),
                      if (posts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            _activeTab == 0
                                ? 'No journeys published yet.'
                                : 'No shared posts yet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...posts.map(
                          (post) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
sharedTimeAgo: _activeTab == 1 ? post.sharedTimeAgo : null,onOpenOriginalPost: () => _openOriginalPost(post),
shareCaption: _activeTab == 1 ? post.shareCaption : '',
                              onViewJourney: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JourneyTimelineScreen(postId: post.id),
                                  ),
                                );
                              },
                              onUpvote: () => _vote(post, 'up'),
                              onDownvote: () => _vote(post, 'down'),
                              onComment: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CommentsScreen(post: post),
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
    );
  }

  Widget _buildHeaderCard() {
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
              fontSize: 21,
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
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('Followers', '${user.followersCount}'),
              _stat('Following', '${user.followingCount}'),
              _stat('Journeys', '${_journeys.length}'),
            ],
          ),
          if (!user.isMe) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _toggleFollow,
                    icon: Icon(
                      user.isFollowing
                          ? Icons.check_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 18,
                    ),
                    label: Text(user.isFollowing ? 'Following' : 'Follow'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (_isBusy || _chatStatus == 'pending_sent')
                            ? null
                            : _handleMessageAction,
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(
                      _messageButtonLabel(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  Widget _buildSectionTabs() {
    return Row(
      children: [
        _tabBtn('Journeys (${_journeys.length})', 0),
        const SizedBox(width: AppSpacing.sm),
        _tabBtn('Shared (${_sharedPosts.length})', 1),
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