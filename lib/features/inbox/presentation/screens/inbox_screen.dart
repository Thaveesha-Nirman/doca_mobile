import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../home/presentation/screens/post_detail_screen.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  int _selectedTab = 0; // 0 = Messages, 1 = Notifications
  List<ChatConversation> _conversations = [];
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isSilentRefreshing = false;
  String? _error;
  Timer? _pollTimer;

  int get _totalUnreadMessages =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  @override
  void initState() {
    super.initState();
    _loadInbox(showLoader: true);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _silentRefresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInbox({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final convosRaw = await ApiService.instance.getConversations();
      final notifRes = await ApiService.instance.getNotifications();
      final notifRaw = (notifRes['notifications'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _conversations = convosRaw
            .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
            .toList();
        _notifications = notifRaw
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _unreadCount = (notifRes['unreadCount'] as num?)?.toInt() ?? 0;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _silentRefresh() async {
    if (_isSilentRefreshing || _isLoading || !mounted) return;
    _isSilentRefreshing = true;
    try {
      final convosRaw = await ApiService.instance.getConversations();
      final notifRes = await ApiService.instance.getNotifications();
      final notifRaw = (notifRes['notifications'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _conversations = convosRaw
            .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
            .toList();
        _notifications = notifRaw
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _unreadCount = (notifRes['unreadCount'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // Silent poll
    } finally {
      _isSilentRefreshing = false;
    }
  }

  bool _isPostNotification(String type) {
    return type == 'post_upvote' ||
        type == 'post_share' ||
        type == 'comment' ||
        type == 'reply' ||
        type == 'comment_upvote';
  }

  Future<void> _openNotification(AppNotification n) async {
    final refId = n.referenceId?.trim() ?? '';

    if ((n.type == 'message' || n.type == 'request_accepted') &&
        refId.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: refId,
            otherAlias: n.actorAlias,
          ),
        ),
      );
      if (mounted) _loadInbox();
      return;
    }

    if (_isPostNotification(n.type) && refId.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: refId),
        ),
      );
      return;
    }

    if ((n.type == 'follow' || n.type == 'message_request') &&
        n.actorUid.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            uid: n.actorUid,
            initialAlias: n.actorAlias,
          ),
        ),
      );
    }
  }

  Future<void> _respondRequest(AppNotification notif, String action) async {
    if (notif.referenceId == null) return;
    try {
      final res = await ApiService.instance.respondToMessageRequest(
        notif.referenceId!,
        action,
      );
      await _loadInbox();
      if (!mounted) return;

      if (action == 'accept' && res['conversationId'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Accepted! You can now chat with ${notif.actorAlias}.',
            ),
          ),
        );
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: res['conversationId'].toString(),
              otherAlias: notif.actorAlias,
            ),
          ),
        );
        if (mounted) _loadInbox();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message request declined.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'post_upvote':
      case 'comment_upvote':
        return Icons.arrow_upward_rounded;
      case 'post_share':
        return Icons.repeat_rounded;
      case 'comment':
      case 'reply':
        return Icons.chat_bubble_outline_rounded;
      case 'message':
      case 'request_accepted':
        return Icons.mark_chat_unread_outlined;
      case 'message_request':
        return Icons.mail_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'follow':
        return Colors.lightBlueAccent;
      case 'post_upvote':
      case 'comment_upvote':
        return AppColors.primary;
      case 'post_share':
        return Colors.greenAccent;
      case 'comment':
      case 'reply':
        return Colors.orangeAccent;
      case 'message':
      case 'request_accepted':
      case 'message_request':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadInbox(showLoader: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: () => _loadInbox(showLoader: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadInbox(showLoader: false),
                        child: _selectedTab == 0
                            ? _buildMessagesList()
                            : _buildNotificationsList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _tabItem('Messages', 0, badgeCount: _totalUnreadMessages),
          _tabItem('Notifications', 1, badgeCount: _unreadCount),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int idx, {int badgeCount = 0}) {
    final active = _selectedTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedTab = idx);
          if (idx == 1 && _unreadCount > 0) {
            ApiService.instance.markNotificationsRead();
            setState(() => _unreadCount = 0);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color:
                      active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            child: Text(
              'No active conversations yet.\nTap a user in the feed and send a Message Request to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, idx) {
        final convo = _conversations[idx];
        final isUnread = convo.hasUnread;

        return ListTile(
          tileColor: isUnread ? AppColors.surfaceElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.65)
                  : AppColors.border,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: isUnread
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.person_outline_rounded,
              color: isUnread ? AppColors.background : AppColors.primary,
            ),
          ),
          title: Text(
            convo.otherAlias,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            convo.lastMessageText.isEmpty
                ? 'Tap to open chat'
                : convo.lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                convo.timeAgo,
                style: TextStyle(
                  color:
                      isUnread ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              if (isUnread) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    convo.unreadCount > 99 ? '99+' : '${convo.unreadCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: convo.id,
                  otherAlias: convo.otherAlias,
                ),
              ),
            );
            if (mounted) _loadInbox(showLoader: false);
          },
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            child: Text(
              'No notifications yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, idx) {
        final n = _notifications[idx];
        final isPendingReq =
            n.type == 'message_request' && n.requestStatus == 'pending';
        final accent = _notifColor(n.type);

        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _openNotification(n),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: n.isRead ? AppColors.border : AppColors.primary,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (n.actorUid.isEmpty) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(
                              uid: n.actorUid,
                              initialAlias: n.actorAlias,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: accent.withValues(alpha: 0.16),
                        child: Icon(
                          _notifIcon(n.type),
                          color: accent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        n.message,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      n.timeAgo,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (!isPendingReq) ...[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
                if (isPendingReq) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _respondRequest(n, 'accept'),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respondRequest(n, 'decline'),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                ] else if (n.type == 'message_request' &&
                    n.requestStatus != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Status: ${n.requestStatus}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ] else if ((n.type == 'request_accepted' ||
                        n.type == 'message') &&
                    n.referenceId != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: () => _openNotification(n),
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Open Chat'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}