import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({
    required this.post,
    this.onAuthorTap,
    super.key,
  });

  final CommunityPost post;
  final void Function(String uid)? onAuthorTap;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _inputController = TextEditingController();
  List<PostComment> _comments = [];
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isSending = false;
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
    _totalCount = widget.post.comments;
    _loadComments();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.instance.getComments(
        widget.post.id,
        sort: _sortBy,
      );
      final raw = (data['comments'] as List<dynamic>?) ?? [];
      final parsed = raw
          .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _comments = parsed;
        _totalCount = (data['totalCount'] as num?)?.toInt() ?? parsed.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load comments: $e')),
      );
    }
  }

  Future<void> _sendComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ApiService.instance.addComment(
        postId: widget.post.id,
        body: text,
        parentCommentId: _replyingTo?.id,
      );
      _inputController.clear();
      setState(() => _replyingTo = null);
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

  Future<void> _deleteComment(PostComment comment, {required bool isReply}) async {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_totalCount);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text('Comments ($_totalCount)'),
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
        body: Column(
          children: [
            // Post title summary strip + active sort badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${widget.post.alias} · ${widget.post.timeAgo}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
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
            ),

            // Comments list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet. Start the conversation!',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadComments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _comments.length,
                            itemBuilder: (_, idx) =>
                                _buildCommentThread(_comments[idx]),
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

            // Input bar
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: AppColors.textPrimary),
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
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                        painter: _ReplyLinePainter(
                          isLast: isLast,
                          color: AppColors.textSecondary.withValues(alpha: 0.35),
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
                onTap: () => widget.onAuthorTap?.call(c.authorUid),
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
                onPressed: () => setState(() => _replyingTo = c),
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

class _ReplyLinePainter extends CustomPainter {
  const _ReplyLinePainter({
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

    // L-shaped branch from top into the reply card
    final branchPath = Path()
      ..moveTo(lineX, 0)
      ..lineTo(lineX, curveY - radius)
      ..quadraticBezierTo(lineX, curveY, lineX + radius, curveY)
      ..lineTo(size.width, curveY);

    canvas.drawPath(branchPath, paint);

    // Continue the vertical line down if there is another reply below
    if (!isLast) {
      canvas.drawLine(
        const Offset(lineX, curveY - radius),
        Offset(lineX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReplyLinePainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.color != color;
  }
}