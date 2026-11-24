import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../journey/presentation/screens/journey_screen.dart';
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
    'Explore',
    'Scan',
    'Journey',
    'Inbox',
  ];

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    ScanScreen(),
    JourneyScreen(),
    InboxScreen(),
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
      body: IndexedStack(index: _currentIndex, children: _pages),
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
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: _ScanNavigationIcon(),
            selectedIcon: _ScanNavigationIcon(isSelected: true),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline_rounded),
            label: 'Journey',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Inbox',
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
