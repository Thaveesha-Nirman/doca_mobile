import '../../../explore/presentation/screens/explore_screen.dart';

import 'package:material_ui/material_ui.dart';

import '../../../home/presentation/screens/home_screen.dart';

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
    _PlaceholderScreen(
      icon: Icons.center_focus_strong_rounded,
      title: 'Private skin scan',
      description: 'Scan privately and review possible matches.',
    ),
    _PlaceholderScreen(
      icon: Icons.timeline_rounded,
      title: 'Journey',
      description: 'Track your private skin-health journey.',
    ),
    _PlaceholderScreen(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Inbox',
      description: 'View your consent-based conversations.',
    ),
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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 48, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
