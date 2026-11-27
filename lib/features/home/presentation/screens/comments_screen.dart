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
      final data = await ApiService.instance.getComments(widget.post.id);
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

  Future<void> _toggleReaction(PostComment comment, String type) async {
    try {
      await ApiService.instance.toggleCommentReaction(comment.id, type);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reaction error: $e')),
      );
    }
  }

  Future<void> _deleteComment(PostComment comment) async {
    try {
      await ApiService.instance.deleteComment(comment.id);
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete error: $e')),
      );
    }
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
        ),
        body: Column(
          children: [
            // Post title summary strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSingleComment(comment, isReply: false),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              children: comment.replies
                  .map((r) => _buildSingleComment(r, isReply: true))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleComment(PostComment c, {required bool isReply}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                GestureDetector(
                  onTap: () => _deleteComment(c),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.redAccent,
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
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _reactionChip(
                label: '👍 ${c.helpfulCount}',
                active: c.myReactions.contains('helpful'),
                onTap: () => _toggleReaction(c, 'helpful'),
              ),
              _reactionChip(
                label: '❤️ ${c.heartCount}',
                active: c.myReactions.contains('heart'),
                onTap: () => _toggleReaction(c, 'heart'),
              ),
              _reactionChip(
                label: '🤗 ${c.careCount}',
                active: c.myReactions.contains('care'),
                onTap: () => _toggleReaction(c, 'care'),
              ),
              TextButton(
                onPressed: () => setState(() => _replyingTo = c),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _reactionChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}