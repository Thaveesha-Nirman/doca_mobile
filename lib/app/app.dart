import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../features/navigation/presentation/screens/main_navigation_screen.dart';

class DocaApp extends StatelessWidget {
  const DocaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doca',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      theme: AppTheme.dark,
      home: const MainNavigationScreen(),
    );
  }
}
