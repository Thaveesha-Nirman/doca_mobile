import 'package:material_ui/material_ui.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../inbox/presentation/screens/inbox_screen.dart';
import '../../../scan/presentation/screens/scan_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;

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
    _refreshUnread();
  }

  @override
  void dispose() {
    PushNotificationService.instance.onNotificationReceived = null;
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final res = await ApiService.instance.getNotifications();
      final count = (res['unreadCount'] as num?)?.toInt() ?? 0;
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    } catch (_) {}
  }

  Widget _buildInboxIcon(bool selected) {
    final icon = Icon(
      selected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
      color: selected ? AppColors.primary : null,
    );
    if (_unreadNotifications <= 0) return icon;

    return Badge(
      label: Text(
        _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _refreshUnread();
        },
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
    );
  }
}