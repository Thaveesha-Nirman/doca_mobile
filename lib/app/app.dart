import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../core/services/api_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/screens/auth_welcome_screen.dart';
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
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      theme: AppTheme.dark.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          },
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _resolveStartScreen();
  }

  Future<void> _resolveStartScreen() async {
    // 1. Wait for Firebase to finish restoring any saved session from disk
    User? user;
    try {
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      user = FirebaseAuth.instance.currentUser;
    }

    if (!mounted) return;

    if (user == null) {
      _goTo(const AuthWelcomeScreen());
      return;
    }

    // 2. Make sure the saved Firebase account wasn't revoked/deleted
    try {
      await user.getIdToken();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'invalid-user-token') {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _goTo(const AuthWelcomeScreen());
        return;
      }
    } catch (_) {
      // Network hiccup — keep the user signed in
    }

    // 3. Check if their Doca profile exists (only redirect to welcome if truly missing)
    try {
      final res = await ApiService.instance
          .getMyProfile()
          .timeout(const Duration(seconds: 5));
      if (res['user'] == null) {
        if (!mounted) return;
        _goTo(const AuthWelcomeScreen());
        return;
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('404') || msg.contains('profile not found')) {
        if (!mounted) return;
        _goTo(const AuthWelcomeScreen());
        return;
      }
      // If the server is temporarily unreachable, still open the app so they aren't logged out
    }

    if (!mounted) return;
    _goTo(const MainNavigationScreen());
  }

  void _goTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Doca',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}