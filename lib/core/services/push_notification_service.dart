import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'api_service.dart';

const AndroidNotificationChannel _docaChannel = AndroidNotificationChannel(
  'doca_high_importance',
  'Doca Notifications',
  description: 'Alerts for followers, upvotes, comments, shares, and messages.',
  importance: Importance.max,
  playSound: true,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;
  Map<String, dynamic>? _pendingTapData;

  /// Fired when a foreground notification arrives (for unread badge refresh).
  VoidCallback? onNotificationReceived;

  /// Fired when the user taps a notification in the phone's notification tray.
  void Function(Map<String, dynamic> data)? onNotificationTapped;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      // 1. Initialize local notifications WITH tap handler
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleLocalTap,
      );

      // 2. Create high-importance channel + request Android 13+ permission
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_docaChannel);
      await androidPlugin?.requestNotificationsPermission();

      // 3. Request FCM permission
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Foreground notification -> show tray banner WITH JSON payload
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title =
            message.notification?.title ?? message.data['title'] ?? 'Doca';
        final body = message.notification?.body ?? message.data['body'] ?? '';

        if (body.toString().isNotEmpty) {
          _showForegroundBanner(
            id: message.hashCode,
            title: title.toString(),
            body: body.toString(),
            payload: jsonEncode(message.data),
          );
        }
        onNotificationReceived?.call();
      });

      // 5. Background tray tap -> app was minimized
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _dispatchTap(message.data);
      });

      // 6. Cold-start tray tap -> app was completely closed
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        _dispatchTap(initialMessage.data);
      } else {
        final launchDetails =
            await _localNotifications.getNotificationAppLaunchDetails();
        final payload = launchDetails?.notificationResponse?.payload;
        if ((launchDetails?.didNotificationLaunchApp ?? false) &&
            payload != null &&
            payload.isNotEmpty) {
          _decodeAndDispatch(payload);
        }
      }

      // 7. Auto-sync if Firebase rotates the device token
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        try {
          await ApiService.instance.registerFcmToken(newToken);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Push init skipped/failed: $e');
    }
  }

  /// Called by MainNavigationScreen once the user is signed in and ready to navigate.
  void consumePendingTap() {
    final pending = _pendingTapData;
    if (pending != null && onNotificationTapped != null) {
      _pendingTapData = null;
      onNotificationTapped!.call(pending);
    }
  }

  void _handleLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _decodeAndDispatch(payload);
  }

  void _decodeAndDispatch(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        _dispatchTap(decoded);
      }
    } catch (e) {
      debugPrint('Failed to decode notification payload: $e');
    }
  }

  void _dispatchTap(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    if (onNotificationTapped != null) {
      onNotificationTapped!.call(data);
    } else {
      // Save until MainNavigationScreen mounts after auth check
      _pendingTapData = Map<String, dynamic>.from(data);
    }
  }

  Future<void> registerTokenWithBackend() async {
    if (kIsWeb) return;
    try {
      await initialize();
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await ApiService.instance.registerFcmToken(token);
      debugPrint('FCM token synced with backend');
    } catch (e) {
      debugPrint('FCM token registration error: $e');
    }
  }

Future<void> unregisterToken() async {
    _pendingTapData = null;
    if (kIsWeb) return;

    try {
      // Clear any old account banners sitting in the phone's notification tray
      await _localNotifications.cancelAll();

      // Fallback to fetching the device token if it wasn't cached in memory yet
      final token =
          _currentToken ??
          // ignore: deprecated_member_use
          await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        await ApiService.instance
            .removeFcmToken(token)
            .timeout(const Duration(seconds: 4));
      }
      _currentToken = null;
      debugPrint('FCM token unregistered cleanly');
    } catch (e) {
      // Never block logout if the network or server is unreachable
      _currentToken = null;
      debugPrint('FCM token unregister skipped: $e');
    }
  }

  Future<void> _showForegroundBanner({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _docaChannel.id,
      _docaChannel.name,
      channelDescription: _docaChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }
}