import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class CommunityPostCard extends StatefulWidget {
  const CommunityPostCard({
    required this.alias,
    required this.timeAgo,
    required this.status,
    required this.title,
    required this.body,
    required this.votes,
    required this.comments,
    this.topic = '',
    this.images = const [],
    this.isSensitive = false,
    this.matchedTerms = const [],
    this.userVote,
    this.sharesCount = 0,
    this.isSharedByMe = false,
    this.stepNumber = 1,
    this.journeyCount = 1,
    this.showOwnerJourneyActions = false,
    this.sharedByAlias,
    this.shareCaption = '',
    this.sharedTimeAgo,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
    this.onSharerTap,
    this.onAuthorTap,
    this.onViewJourney,
    this.onAddJourney,
    this.onEditJourney,
    this.onUpvote,
    this.onDownvote,
    this.onComment,
    this.onShare,
    super.key,
  });

  final String alias;
  final String timeAgo;
  final String topic;
  final String status;
  final String title;
  final String body;
  final int votes;
  final String? userVote;
  final int comments;
  final int sharesCount;
  final bool isSharedByMe;
  final int stepNumber;
  final int journeyCount;
  final List<String> images;
  final bool isSensitive;
  final List<String> matchedTerms;
  final bool showOwnerJourneyActions;

  // Facebook-style shared post props
  final String? sharedByAlias;
  final String shareCaption;
  final String? sharedTimeAgo;
  final VoidCallback? onSharerTap;

  // Owner-only 3-dot menu props
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final VoidCallback? onAuthorTap;
  final VoidCallback? onViewJourney;
  final VoidCallback? onAddJourney;
  final VoidCallback? onEditJourney;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  bool _revealSensitive = false;

  bool get _isSharedCard =>
      widget.sharedByAlias != null && widget.sharedByAlias!.trim().isNotEmpty;

  Uint8List? _decodeImage(String raw) {
    try {
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  String _statusLabel(String raw) {
    switch (raw) {
      case 'Healed':
        return 'Healed';
      case 'Ongoing':
        return 'Ongoing Treatment';
      default:
        return 'Just Asking';
    }
  }

  Color _statusColor(String raw) {
    switch (raw) {
      case 'Healed':
        return Colors.greenAccent;
      case 'Ongoing':
        return Colors.orangeAccent;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildThreeDotMenu({required bool forShare}) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      color: AppColors.surfaceElevated,
      onSelected: (value) {
        if (value == 'edit') {
          widget.onEdit?.call();
        } else if (value == 'delete') {
          widget.onDelete?.call();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                forShare ? 'Edit caption' : 'Edit post',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Text(
                forShare ? 'Delete share' : 'Delete post',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final decodedPhotos = widget.images
        .map(_decodeImage)
        .whereType<Uint8List>()
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facebook-style Sharer Header + Caption
          if (_isSharedCard) ...[
            _buildSharerHeader(),
            if (widget.shareCaption.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.shareCaption.trim(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],

          // Original Post Body (embedded when shared)
          if (_isSharedCard)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: _buildOriginalPostContent(decodedPhotos),
            )
          else
            _buildOriginalPostContent(decodedPhotos),

          // Owner Journey Actions (Profile -> My Journeys)
          if (widget.showOwnerJourneyActions) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.onAddJourney != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onAddJourney,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text(
                        'Add Journey',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (widget.onAddJourney != null && widget.onEditJourney != null)
                  const SizedBox(width: AppSpacing.sm),
                if (widget.onEditJourney != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onEditJourney,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text(
                        'Edit Journey',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Bottom Action Bar
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildSharerHeader() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: widget.onSharerTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.repeat_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: widget.sharedByAlias,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: ' shared this post'),
                          ],
                        ),
                      ),
                      if (widget.sharedTimeAgo != null &&
                          widget.sharedTimeAgo!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.sharedTimeAgo!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.canManage) _buildThreeDotMenu(forShare: true),
      ],
    );
  }

  Widget _buildOriginalPostContent(List<Uint8List> decodedPhotos) {
    final statusColor = _statusColor(widget.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Author Header (+ 3-dot menu ONLY on non-shared own posts)
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: widget.onAuthorTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.alias,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.timeAgo}${widget.journeyCount > 1 ? ' · Update #${widget.stepNumber}' : ''}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_isSharedCard && widget.canManage)
              _buildThreeDotMenu(forShare: false),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Status Badge + View Journey Button
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                _statusLabel(widget.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.onViewJourney != null)
              InkWell(
                onTap: widget.onViewJourney,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timeline_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.journeyCount > 1
                            ? 'View Journey (${widget.journeyCount})'
                            : 'View Journey',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Matched symptom indicator (shown during smart search/filtering)
        if (widget.matchedTerms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Colors.tealAccent,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Matched: ${widget.matchedTerms.join(' · ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // 3. Title & Body
        Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.body,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),

        // 4. Uploaded Photos
        if (decodedPhotos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildPhotosSection(decodedPhotos),
        ],
      ],
    );
  }

  Widget _buildActionBar() {
    final isUp = widget.userVote == 'up';
    final isDown = widget.userVote == 'down';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: widget.onUpvote,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: isUp ? AppColors.primary : AppColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${widget.votes}',
                  style: TextStyle(
                    color: isUp
                        ? AppColors.primary
                        : isDown
                            ? Colors.redAccent
                            : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onDownvote,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: isDown ? Colors.redAccent : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        InkWell(
          onTap: widget.onComment,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.comments}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: widget.onShare,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(
                  widget.isSharedByMe
                      ? Icons.repeat_on_rounded
                      : Icons.share_outlined,
                  color: widget.isSharedByMe
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 19,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.isSharedByMe
                      ? 'Shared (${widget.sharesCount})'
                      : widget.sharesCount > 0
                          ? '${widget.sharesCount}'
                          : 'Share',
                  style: TextStyle(
                    color: widget.isSharedByMe
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(List<Uint8List> photos) {
    if (widget.isSensitive && !_revealSensitive) {
      return InkWell(
        onTap: () => setState(() => _revealSensitive = true),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sensitive photo (${photos.length}) · Tap to reveal',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.memory(
          photos.first,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(
              photos[index],
              width: 220,
              height: 180,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}