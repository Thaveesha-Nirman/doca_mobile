import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class CommunityPostCard extends StatefulWidget {
  const CommunityPostCard({
    required this.alias,
    required this.timeAgo,
    required this.topic,
    required this.status,
    required this.title,
    required this.body,
    required this.votes,
    required this.comments,
    this.isSensitive = false,
    this.journeyId,
    this.onViewJourney,
    this.onStartJourney,
    super.key,
  });

  final String alias;
  final String timeAgo;
  final String topic;
  final String status;
  final String title;
  final String body;
  final int votes;
  final int comments;
  final bool isSensitive;
  final String? journeyId;
  final VoidCallback? onViewJourney;
  final VoidCallback? onStartJourney;

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  int _vote = 0;
  bool _isSaved = false;
  bool _isRevealed = false;

  int get _displayVotes => widget.votes + _vote;

  Color get _statusColor {
    return switch (widget.status) {
      'Healed' => AppColors.secondary,
      'Ongoing' => AppColors.warning,
      _ => AppColors.primary,
    };
  }

  void _setVote(int vote) {
    setState(() {
      _vote = _vote == vote ? 0 : vote;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: _buildHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildPostContent(),
          ),
          if (widget.isSensitive) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSensitivePreview(),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildActions(),
          ),
          if (widget.journeyId != null && widget.onViewJourney != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: OutlinedButton(
                onPressed: widget.onViewJourney,
                child: const Text('View Journey'),
              ),
            ),
          if (widget.journeyId == null && widget.onStartJourney != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: OutlinedButton(
                onPressed: widget.onStartJourney,
                child: const Text('Start Journey'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.alias,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.timeAgo} · Anonymous',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Post options',
          color: AppColors.surfaceElevated,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: AppColors.textSecondary,
          ),
          onSelected: (value) {
            debugPrint('Post action: $value');
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'hide', child: Text('Hide post')),
            PopupMenuItem(value: 'block', child: Text('Block user')),
            PopupMenuItem(value: 'report', child: Text('Report post')),
          ],
        ),
      ],
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _PostBadge(label: widget.topic, color: AppColors.secondary),
            _PostBadge(label: widget.status, color: _statusColor),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.body,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSensitivePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: double.infinity,
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: _isRevealed ? 0 : 18,
                sigmaY: _isRevealed ? 0 : 18,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.65),
                      AppColors.secondary.withValues(alpha: 0.55),
                      AppColors.surfaceElevated,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textPrimary,
                  size: 52,
                ),
              ),
            ),
            if (!_isRevealed)
              ColoredBox(
                color: AppColors.background.withValues(alpha: 0.58),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Reveal sensitive medical image',
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isRevealed = true;
                        });
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View sensitive image'),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.textSecondary,
                      size: 15,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Sensitive content',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildActions() {
    return Row(
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Upvote',
                visualDensity: VisualDensity.compact,
                onPressed: () => _setVote(1),
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: _vote == 1
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                '$_displayVotes',
                style: TextStyle(
                  color: _vote == 0
                      ? AppColors.textPrimary
                      : _vote == 1
                      ? AppColors.secondary
                      : AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: 'Downvote',
                visualDensity: VisualDensity.compact,
                onPressed: () => _setVote(-1),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _vote == -1
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${widget.comments}',
          tooltip: 'Comments',
          onPressed: () {
            debugPrint('Comments opened: ${widget.title}');
          },
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Share post',
          onPressed: () {
            debugPrint('Post shared: ${widget.title}');
          },
          icon: const Icon(
            Icons.ios_share_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        IconButton(
          tooltip: _isSaved ? 'Remove saved post' : 'Save post',
          onPressed: () {
            setState(() {
              _isSaved = !_isSaved;
            });
          },
          icon: Icon(
            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isSaved ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PostBadge extends StatelessWidget {
  const _PostBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 19),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
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
    );
  }
}
