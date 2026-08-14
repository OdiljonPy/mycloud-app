import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'language_notifier.dart';
import 'push_notification_service.dart';
import '../../main.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/notification_type_mapper.dart';
import '../../features/sync/auto_sync_service.dart';

class AppInitializer {
  static Future<void> init() async {
    debugPrint('[AppInit] START');

    debugPrint('[AppInit] Theme + Language...');
    await Future.wait([
      ThemeNotifier.instance.init(),
      LanguageNotifier.instance.init(),
    ]);
    debugPrint('[AppInit] Theme + Language DONE');

    if (Platform.isAndroid) {
      debugPrint('[AppInit] AndroidAlarmManager...');
      await AndroidAlarmManager.initialize();
      debugPrint('[AppInit] AndroidAlarmManager DONE');
    }

    debugPrint('[AppInit] PushNotificationService...');
    try {
      await PushNotificationService.initialize();
      PushNotificationService.onTokenRefreshed =
          (_) => unawaited(AuthRepository.registerCurrentDevice());

      // Тап по уведомлению, показанному вручную в foreground.
      PushNotificationService.onLocalNotificationTapped =
          (payload) => NotificationTypeMapper.handleTap(payload);

      // Тап по системному уведомлению, когда приложение было в
      // background (onMessageOpenedApp) или полностью закрыто
      // (getInitialMessage — разбирается один раз при старте).
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        NotificationTypeMapper.handleTap(message.data['type'] as String?);
      });
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        NotificationTypeMapper.handleTap(initialMessage.data['type'] as String?);
      }
    } catch (e) {
      debugPrint('[AppInit] PushNotificationService error (non-critical): $e');
    }

    debugPrint('[AppInit] AutoSyncService (background)...');
    () async {
      try {
        final service = AutoSyncService();
        await service.initialize();
        final autoEnabled = await service.isAutoSyncEnabled();
        if (autoEnabled) {
          unawaited(service.startAutoSync());
        }
      } catch (e) {
        debugPrint('[AppInit] AutoSyncService error (non-critical): $e');
      }
    }();

    debugPrint('[AppInit] ALL DONE');
  }
}
