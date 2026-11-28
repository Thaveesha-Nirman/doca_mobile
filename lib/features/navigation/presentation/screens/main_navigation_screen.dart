import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../auth/presentation/screens/public_profile_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/post_detail_screen.dart';
import '../../../inbox/presentation/screens/chat_screen.dart';
import '../../../inbox/presentation/screens/inbox_screen.dart';
import '../../../scan/presentation/screens/scan_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<int> _tabHistory = [];
  DateTime? _lastBackPressed;
  int _unreadBadgeCount = 0;
  Timer? _syncTimer;

  static const _screens = [
    HomeScreen(),
    InboxScreen(),
    ScanScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.registerTokenWithBackend();
    PushNotificationService.instance.onNotificationReceived = _refreshUnread;
    PushNotificationService.instance.onNotificationTapped =
        _handleNotificationTap;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.consumePendingTap();
    });

    _refreshUnread();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshUnread(),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    PushNotificationService.instance.onNotificationReceived = null;
    PushNotificationService.instance.onNotificationTapped = null;
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      _refreshUnread();
      return;
    }
    setState(() {
      _tabHistory.remove(index);
      _tabHistory.add(_selectedIndex);
      _selectedIndex = index;
    });
    _refreshUnread();
  }

  void _handleBackPress() {
    // 1. Go back to the previous tab the user visited
    if (_tabHistory.isNotEmpty) {
      setState(() {
        _selectedIndex = _tabHistory.removeLast();
      });
      _refreshUnread();
      return;
    }

    // 2. If not on Home, jump to Home before exiting
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      _refreshUnread();
      return;
    }

    // 3. On Home: double-back within 2 seconds to exit cleanly
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit Doca'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  Future<void> _refreshUnread() async {
    try {
      final res = await ApiService.instance.getNotifications();
      final unreadNotifs = (res['unreadCount'] as num?)?.toInt() ?? 0;
      final unreadMsgs = (res['unreadMessagesCount'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() => _unreadBadgeCount = unreadNotifs + unreadMsgs);
      }
    } catch (_) {}
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (!mounted) return;

    final type = (data['type'] ?? '').toString().trim();
    final refId = (data['referenceId'] ?? '').toString().trim();
    final actorUid = (data['actorUid'] ?? '').toString().trim();
    final actorAlias = (data['actorAlias'] ?? 'Anonymous').toString().trim();

    final isPostType = type == 'post_upvote' ||
        type == 'post_share' ||
        type == 'comment' ||
        type == 'reply' ||
        type == 'comment_upvote';

    if ((type == 'message' || type == 'request_accepted') && refId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: refId,
            otherAlias: actorAlias.isEmpty ? 'Chat' : actorAlias,
          ),
        ),
      );
      return;
    }

    if (isPostType && refId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: refId),
        ),
      );
      return;
    }

    if (type == 'message_request') {
      _selectTab(1);
      return;
    }

    if (type == 'follow' && actorUid.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            uid: actorUid,
            initialAlias: actorAlias.isEmpty ? 'Profile' : actorAlias,
          ),
        ),
      );
      return;
    }

    _selectTab(1);
  }

  Widget _buildInboxIcon(bool selected) {
    final icon = Icon(
      selected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
      color: selected ? AppColors.primary : null,
    );
    if (_unreadBadgeCount <= 0) return icon;

    return Badge(
      label: Text(
        _unreadBadgeCount > 99 ? '99+' : '$_unreadBadgeCount',
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _buildInboxIcon(false),
              selectedIcon: _buildInboxIcon(true),
              label: 'Inbox',
            ),
            const NavigationDestination(
              icon: Icon(Icons.center_focus_weak_rounded),
              selectedIcon: Icon(
                Icons.center_focus_strong_rounded,
                color: AppColors.primary,
              ),
              label: 'Scanner',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}