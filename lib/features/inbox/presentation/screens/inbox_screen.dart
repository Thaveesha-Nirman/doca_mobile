import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: res['conversationId'].toString(),
              otherAlias: notif.actorAlias,
            ),
          ),
        );
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
            onPressed: _loadInbox,
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
                              onPressed: _loadInbox,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInbox,
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
          _tabItem('Messages (${_conversations.length})', 0),
          _tabItem(
            _unreadCount > 0
                ? 'Notifications ($_unreadCount)'
                : 'Notifications',
            1,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int idx) {
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
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
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
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border),
          ),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.background,
            ),
          ),
          title: Text(
            convo.otherAlias,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            convo.lastMessageText.isEmpty
                ? 'Tap to open chat'
                : convo.lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Text(
            convo.timeAgo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
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
            _loadInbox();
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

        return Container(
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(
                            uid: n.actorUid,
                            initialAlias: n.actorAlias,
                          ),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceElevated,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
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
                  Text(
                    n.timeAgo,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
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
              ] else if (n.type == 'request_accepted' &&
                  n.referenceId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: n.referenceId!,
                          otherAlias: n.actorAlias,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Open Chat'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}