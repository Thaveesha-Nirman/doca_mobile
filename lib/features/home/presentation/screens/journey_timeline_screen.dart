import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/community_post.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';

class JourneyTimelineScreen extends StatefulWidget {
  const JourneyTimelineScreen({
    required this.postId,
    this.editMode = false,
    super.key,
  });

  final String postId;
  final bool editMode;

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  List<CommunityPost> _steps = [];
  bool _isLoading = true;
  String? _error;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.getJourneyTimeline(widget.postId);
      final rawPosts = (data['posts'] as List<dynamic>?) ?? [];
      final steps = rawPosts
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _steps = steps;
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

  Future<void> _addUpdate() async {
    if (_steps.isEmpty) return;
    final created = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(parentPost: _steps.first),
      ),
    );
    if (created != null && mounted) {
      _hasChanged = true;
      await _loadTimeline();
    }
  }

  Future<void> _editStep(CommunityPost step) async {
    final updated = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(editingPost: step),
      ),
    );
    if (updated != null && mounted) {
      _hasChanged = true;
      await _loadTimeline();
    }
  }

  Future<void> _deleteStep(CommunityPost step) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This step will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ApiService.instance.deletePost(step.id);
      _hasChanged = true;
      if (!mounted) return;
      if (_steps.length <= 1) {
        Navigator.of(context).pop(true);
      } else {
        await _loadTimeline();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Uint8List? _decode(String raw) {
    try {
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _steps.isNotEmpty && _steps.first.isOwner;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_hasChanged);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            widget.editMode ? 'Edit Journey' : 'Recovery Journey',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (isOwner)
              TextButton.icon(
                onPressed: _addUpdate,
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                label: const Text(
                  'Add Update',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
          ],
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
                          onPressed: _loadTimeline,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTimeline,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        if (_steps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: Text(
                              '${_steps.first.alias} · ${_steps.length} linked ${_steps.length == 1 ? 'post' : 'posts'} (oldest to newest)',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ...List.generate(_steps.length, (index) {
                          final step = _steps[index];
                          final isLast = index == _steps.length - 1;
                          return _buildTimelineStep(step, index + 1, isLast, isOwner);
                        }),
                        if (isOwner) ...[
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: _addUpdate,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add Next Update to This Journey'),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTimelineStep(
    CommunityPost step,
    int displayStep,
    bool isLast,
    bool isOwner,
  ) {
    final photos = step.images.map(_decode).whereType<Uint8List>().toList();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline vertical line + circle dot
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$displayStep',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          step.status,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        step.timeAgo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (isOwner) ...[
                        IconButton(
                          tooltip: 'Edit step',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          onPressed: () => _editStep(step),
                        ),
                        IconButton(
                          tooltip: 'Delete step',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteStep(step),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.body,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, idx) => ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.memory(
                            photos[idx],
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CommentsScreen(post: step),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 15),
                    label: Text('${step.comments} comments'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}