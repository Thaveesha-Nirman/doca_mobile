import '../../../inbox/presentation/screens/inbox_screen.dart';

import 'package:material_ui/material_ui.dart';

import '../../../home/presentation/screens/home_screen.dart';
import '../../../scan/presentation/screens/scan_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const List<String> _tabNames = <String>[
    'Home',
    'Scan',
    'Inbox',
    'Profile',
  ];

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });

    debugPrint('Selected Doca tab: ${_tabNames[index]}');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const ScanScreen(),
          const InboxScreen(),
          const Center(child: Text('Profile coming soon')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        height: 76,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _ScanNavigationIcon(),
            selectedIcon: _ScanNavigationIcon(isSelected: true),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ScanNavigationIcon extends StatelessWidget {
  const _ScanNavigationIcon({this.isSelected = false});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: isSelected ? 44 : 40,
      height: isSelected ? 44 : 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.82),
      ),
      child: Icon(
        Icons.center_focus_strong_rounded,
        color: colorScheme.onPrimary,
        size: 22,
      ),
    );
  }
}
