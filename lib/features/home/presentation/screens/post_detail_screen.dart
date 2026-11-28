import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../data/models/community_post.dart';
import '../widgets/community_post_card.dart';
import '../widgets/share_post_sheet.dart';
import 'create_post_screen.dart';
import 'journey_timeline_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    required this.postId,
    this.initialPost,
    super.key,
  });

  final String postId;
  final CommunityPost? initialPost;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  CommunityPost? _post;
  List<PostComment> _comments = [];
  int _totalComments = 0;
  bool _isLoadingPost = true;
  bool _isLoadingComments = true;
  bool _isSending = false;
  bool _hasChanges = false;
  String? _error;
  String _myAlias = 'You';
  PostComment? _replyingTo;
  String _sortBy = 'newest'; // newest | oldest | mostUpvoted | leastUpvoted

  String get _sortLabel {
    switch (_sortBy) {
      case 'mostUpvoted':
        return 'Most Upvoted';
      case 'leastUpvoted':
        return 'Least Upvoted';
      case 'oldest':
        return 'Oldest';
      case 'newest':
      default:
        return 'Newest';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _totalComments = widget.initialPost!.comments;
      _isLoadingPost = false;
    }
    _loadAll();
    _loadMyAlias();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
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

  Future<void> _loadAll() async {
    await Future.wait([
      _loadPost(),
      _loadComments(),
    ]);
  }

  Future<void> _loadPost() async {
    if (_post == null) {
      setState(() {
        _isLoadingPost = true;
        _error = null;
      });
    }

    try {
      final res = await ApiService.instance.getPostById(widget.postId);
      final raw = res['post'] as Map<String, dynamic>?;
      if (raw == null) throw Exception('Post not found');
      final fresh = CommunityPost.fromJson(raw);

      if (!mounted) return;
      setState(() {
        _post = fresh;
        _totalComments = fresh.comments;
        _isLoadingPost = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPost = false;
        if (_post == null) {
          _error = 'Could not load original post: $e';
        }
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final data = await ApiService.instance.getComments(
        widget.postId,
        sort: _sortBy,
      );
      final raw = (data['comments'] as List<dynamic>?) ?? [];
      final parsed = raw
          .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      final newTotal = (data['totalCount'] as num?)?.toInt() ?? parsed.length;
      setState(() {
        _comments = parsed;
        _totalComments = newTotal;
        if (_post != null) {
          _post = _post!.copyWith(comments: newTotal);
        }
        _isLoadingComments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingComments = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load comments: $e')),
      );
    }
  }

  Future<void> _handleVotePost(String type) async {
    final post = _post;
    if (post == null) return;
    try {
      final res = await ApiService.instance.votePost(post.id, type);
      final fresh = CommunityPost.fromJson(res['post'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _post = fresh;
        _hasChanges = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e')),
      );
    }
  }

  Future<void> _handleSharePost() async {
    final post = _post;
    if (post == null) return;

    if (post.isSharedByMe) {
      final confirm = await showRemoveShareDialog(context);
      if (!confirm || !mounted) return;
      try {
        await ApiService.instance.unsharePost(post.id);
        _hasChanges = true;
        await _loadPost();
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
      _hasChanges = true;
      await _loadPost();
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

  Future<void> _handleEditPost() async {
    final post = _post;
    if (post == null) return;

    final updated = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => CreatePostScreen(editingPost: post)),
    );
    if (updated != null && mounted) {
      _hasChanges = true;
      await _loadPost();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated!')),
      );
    }
  }

  Future<void> _handleDeletePost() async {
    final post = _post;
    if (post == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This will permanently delete your post.'),
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
      await ApiService.instance.deletePost(post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openJourney() async {
    final post = _post;
    if (post == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JourneyTimelineScreen(postId: post.id),
      ),
    );
    if (changed == true && mounted) {
      _hasChanges = true;
      await _loadPost();
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

  Future<void> _sendComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ApiService.instance.addComment(
        postId: widget.postId,
        body: text,
        parentCommentId: _replyingTo?.id,
      );
      _inputController.clear();
      setState(() {
        _replyingTo = null;
        _hasChanges = true;
      });
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to comment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _voteComment(PostComment comment, String type) async {
    try {
      await ApiService.instance.voteComment(comment.id, type);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote error: $e')),
      );
    }
  }

  Future<void> _deleteComment(
    PostComment comment, {
    required bool isReply,
  }) async {
    final hasReplies = !isReply && comment.replies.isNotEmpty;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReply ? 'Delete reply?' : 'Delete comment?'),
        content: Text(
          hasReplies
              ? 'This will permanently delete your comment and all its replies.'
              : 'Are you sure you want to permanently delete this ${isReply ? 'reply' : 'comment'}?',
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
      await ApiService.instance.deleteComment(comment.id);
      _hasChanges = true;
      await _loadComments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isReply ? 'Reply deleted' : 'Comment deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $e')),
      );
    }
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: const Text(
            'Original Post',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Sort comments ($_sortLabel)',
              color: AppColors.surfaceElevated,
              onSelected: (value) {
                setState(() => _sortBy = value);
                _loadComments();
              },
              itemBuilder: (_) => [
                _buildSortMenuItem(
                  'mostUpvoted',
                  'Most Upvoted',
                  Icons.arrow_upward_rounded,
                ),
                _buildSortMenuItem(
                  'leastUpvoted',
                  'Least Upvoted',
                  Icons.arrow_downward_rounded,
                ),
                _buildSortMenuItem(
                  'newest',
                  'Newest First',
                  Icons.schedule_rounded,
                ),
                _buildSortMenuItem(
                  'oldest',
                  'Oldest First',
                  Icons.history_rounded,
                ),
              ],
            ),
          ],
        ),
        body: _isLoadingPost
            ? const Center(child: CircularProgressIndicator())
            : _error != null || post == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error ?? 'Post not found',
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
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadAll,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.xl,
                            ),
                            children: [
                              // Clean Original Post Card (no share wrapper)
                              CommunityPostCard(
                                key: ValueKey('original_${post.id}'),
                                alias: post.alias,
                                timeAgo: post.timeAgo,
                                status: post.status,
                                title: post.title,
                                body: post.body,
                                votes: post.votes,
                                userVote: post.userVote,
                                comments: _totalComments,
                                sharesCount: post.sharesCount,
                                isSharedByMe: post.isSharedByMe,
                                stepNumber: post.stepNumber,
                                journeyCount: post.journeyCount,
                                images: post.images,
                                isSensitive: post.isSensitive,
                                canManage: post.isOwner,
                                onEdit: _handleEditPost,
                                onDelete: _handleDeletePost,
                                onAuthorTap: () => _openUserByUid(
                                  post.authorUid,
                                  post.alias,
                                  isMe: post.isOwner,
                                ),
                                onViewJourney: _openJourney,
                                onUpvote: () => _handleVotePost('up'),
                                onDownvote: () => _handleVotePost('down'),
                                onComment: () =>
                                    _commentFocusNode.requestFocus(),
                                onShare: _handleSharePost,
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Comments section header
                              Row(
                                children: [
                                  Text(
                                    'Comments ($_totalComments)',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.14),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      _sortLabel,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),

                              if (_isLoadingComments)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 28),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_comments.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 28),
                                  child: Center(
                                    child: Text(
                                      'No comments yet. Start the conversation!',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ..._comments.map(_buildCommentThread),
                            ],
                          ),
                        ),
                      ),

                      // Replying indicator
                      if (_replyingTo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 8,
                          ),
                          color: AppColors.surfaceElevated,
                          child: Row(
                            children: [
                              Text(
                                'Replying to ${_replyingTo!.alias}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _replyingTo = null),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Comment input bar
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              top: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  focusNode: _commentFocusNode,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _replyingTo != null
                                        ? 'Write a reply...'
                                        : 'Add a supportive comment...',
                                    hintStyle: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceElevated,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.pill),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendComment(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              IconButton(
                                onPressed: _isSending ? null : _sendComment,
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: AppColors.primary,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCommentThread(PostComment comment) {
    final hasReplies = comment.replies.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSingleComment(comment, isReply: false),
          if (hasReplies)
            ...List.generate(comment.replies.length, (index) {
              final reply = comment.replies[index];
              final isLast = index == comment.replies.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 28,
                      child: CustomPaint(
                        painter: _PostDetailReplyLinePainter(
                          isLast: isLast,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: _buildSingleComment(reply, isReply: true),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSingleComment(PostComment c, {required bool isReply}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isReply ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openUserByUid(
                  c.authorUid,
                  c.alias,
                  isMe: c.isOwner,
                ),
                child: Text(
                  c.alias,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                c.timeAgo,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (c.isOwner)
                InkWell(
                  onTap: () => _deleteComment(c, isReply: isReply),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 17,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c.body,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _votePill(c),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() => _replyingTo = c);
                  _commentFocusNode.requestFocus();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text(
                  'Reply',
                  style: TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _votePill(PostComment c) {
    final isUp = c.userVote == 'up';
    final isDown = c.userVote == 'down';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _voteComment(c, 'up'),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: isUp ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              '${c.votes}',
              style: TextStyle(
                color: isUp
                    ? AppColors.primary
                    : isDown
                        ? Colors.redAccent
                        : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () => _voteComment(c, 'down'),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 16,
                color: isDown ? Colors.redAccent : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailReplyLinePainter extends CustomPainter {
  const _PostDetailReplyLinePainter({
    required this.isLast,
    required this.color,
  });

  final bool isLast;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double lineX = 12;
    const double curveY = 30;
    const double radius = 10;

    final branchPath = Path()
      ..moveTo(lineX, 0)
      ..lineTo(lineX, curveY - radius)
      ..quadraticBezierTo(lineX, curveY, lineX + radius, curveY)
      ..lineTo(size.width, curveY);

    canvas.drawPath(branchPath, paint);

    if (!isLast) {
      canvas.drawLine(
        const Offset(lineX, curveY - radius),
        Offset(lineX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PostDetailReplyLinePainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.color != color;
  }
}