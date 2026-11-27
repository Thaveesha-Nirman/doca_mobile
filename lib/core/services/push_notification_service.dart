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

  /// Callback triggered whenever a foreground notification arrives
  /// so the app can refresh unread badges live.
  VoidCallback? onNotificationReceived;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      // 1. Initialize local notifications for foreground Android banners
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

      await _localNotifications.initialize(settings: initSettings);

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

      // 4. Show real phone tray banner when app is open in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title =
            message.notification?.title ?? message.data['title'] ?? 'Doca';
        final body = message.notification?.body ?? message.data['body'] ?? '';

        if (body.toString().isNotEmpty) {
          _showForegroundBanner(
            id: message.hashCode,
            title: title.toString(),
            body: body.toString(),
          );
        }
        onNotificationReceived?.call();
      });

      // 5. Auto-sync if Firebase rotates the device token
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

  Future<void> registerTokenWithBackend() async {
    if (kIsWeb) return;
    try {
      await initialize();
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
    if (kIsWeb || _currentToken == null) return;
    try {
      await ApiService.instance.removeFcmToken(_currentToken!);
    } catch (_) {}
  }

  Future<void> _showForegroundBanner({
    required int id,
    required String title,
    required String body,
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
    );
  }
}