import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

import '../features/auth/presentation/screens/login_screen.dart';

class DocaApp extends StatelessWidget {
  const DocaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doca',
      debugShowCheckedModeBanner: false,

      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      theme: AppTheme.dark,
      home: const LoginScreen(),
    );
  }
}
