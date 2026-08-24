import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Должен быть top-level (вне класса) и с этой аннотацией — иначе Android
// не найдёт entry point для background isolate, и пуши в background/killed
// состоянии не будут запускать этот handler.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[PushNotification] Background message: ${message.messageId}, data: ${message.data}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Основные уведомления',
    description: 'Уведомления об оплате, синхронизации и общем доступе',
    importance: Importance.high,
  );

  static String? _currentToken;
  static String? get currentToken => _currentToken;

  /// Токен из памяти, если уже получен; иначе — свежий запрос к Firebase.
  static Future<String?> ensureToken() async {
    if (_currentToken != null) return _currentToken;
    try {
      await _waitForApnsTokenIfNeeded();
      _currentToken = await _messaging.getToken();
    } catch (e) {
      debugPrint('[PushNotification] ensureToken failed: $e');
    }
    return _currentToken;
  }

  /// Вызывается при получении/обновлении FCM-токена. Устанавливается
  /// вызывающей стороной (регистрация на бэкенде — Этап 6), чтобы этот
  /// сервис не знал про NotificationsRepository напрямую.
  static void Function(String token)? onTokenRefreshed;

  /// Тап по локальному уведомлению, показанному в foreground (payload —
  /// строка "type" из data пейлоада FCM). Роутинг вешает Этап 7.
  static void Function(String? payload)? onLocalNotificationTapped;

  /// FCM data содержит notification_id — сигнал вызывающей стороне
  /// подтянуть канонический объект через REST и освежить бейдж непрочитанных.
  /// Колбэк, а не прямой импорт репозитория — этот сервис не должен знать
  /// про NotificationsRepository напрямую (тот же принцип, что у onTokenRefreshed).
  static void Function(String notificationId)? onNotificationIdReceived;

  static Future<void> initialize() async {
    await _initLocalNotifications();
    await _requestPermission();

    try {
      await _waitForApnsTokenIfNeeded();
      _currentToken = await _messaging.getToken();
    } catch (e) {
      debugPrint('[PushNotification] getToken failed: $e');
    }

    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      onTokenRefreshed?.call(token);
    });

    // FCM не показывает системное уведомление сам, когда приложение в
    // foreground — делаем это вручную через flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  /// Ждёт APNs-токен на iOS перед запросом FCM-токена — без этого getToken()
  /// на холодном старте может вернуть null/упасть, т.к. APNs-токен от ОС
  /// ещё не пришёл. Верхняя граница ожидания жёсткая (5с), после неё
  /// продолжаем без него — тот же паттерн "одна попытка, лог, дальше",
  /// что и у остальных Firebase-вызовов в этом файле.
  static Future<void> _waitForApnsTokenIfNeeded() async {
    if (!Platform.isIOS) return;
    const maxAttempts = 10;
    const pollInterval = Duration(milliseconds: 500);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) return;
      } catch (e) {
        debugPrint('[PushNotification] getAPNSToken check failed: $e');
      }
      await Future.delayed(pollInterval);
    }
    debugPrint(
      '[PushNotification] APNs token not available after '
      '${maxAttempts * pollInterval.inMilliseconds}ms, proceeding anyway',
    );
  }

  static Future<void> _requestPermission() async {
    try {
      // firebase_messaging сам запрашивает POST_NOTIFICATIONS на Android 13+
      // с этой версии пакета — отдельный permission_handler не нужен.
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[PushNotification] requestPermission failed: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onLocalNotificationTapped?.call(response.payload);
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationId = message.data['notification_id'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        onNotificationIdReceived?.call(notificationId);
      } catch (e) {
        debugPrint('[PushNotification] onNotificationIdReceived failed: $e');
      }
    }

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['type'] as String?,
      );
    } catch (e) {
      debugPrint('[PushNotification] show foreground notification failed: $e');
    }
  }

  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? info.name;
      }
    } catch (e) {
      debugPrint('[PushNotification] getDeviceId failed: $e');
    }
    return 'unknown_device';
  }
}
