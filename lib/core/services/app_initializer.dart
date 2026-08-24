import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'language_notifier.dart';
import 'navigation_service.dart';
import 'push_notification_service.dart';
import '../../main.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/notification_type_mapper.dart';
import '../../features/notifications/notifications_providers.dart';
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

      // Пришёл notification_id из FCM (foreground или тап) — REST
      // верифицирует уведомление и освежает бейдж непрочитанных.
      // Container достаётся через navigatorKey.currentContext, т.к. этот
      // static-метод не имеет своего ref (тот же приём, что и в
      // main_page_visibility_observer.dart).
      PushNotificationService.onNotificationIdReceived = (notificationId) async {
        final context = NavigationService.navigatorKey.currentContext;
        if (context == null) return;
        try {
          final container = ProviderScope.containerOf(context, listen: false);
          await container
              .read(notificationsRepositoryProvider)
              .getNotificationDetail(notificationId);
          container.invalidate(unreadCountProvider);
        } catch (e) {
          debugPrint('[AppInitializer] notification detail fetch failed: $e');
        }
      };

      // Тап по системному уведомлению, когда приложение было в
      // background (onMessageOpenedApp) или полностью закрыто
      // (getInitialMessage — разбирается один раз при старте).
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        NotificationTypeMapper.handleTap(message.data['type'] as String?);
        final notificationId = message.data['notification_id'] as String?;
        if (notificationId != null && notificationId.isNotEmpty) {
          PushNotificationService.onNotificationIdReceived?.call(notificationId);
        }
      });
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        NotificationTypeMapper.handleTap(initialMessage.data['type'] as String?);
        final notificationId = initialMessage.data['notification_id'] as String?;
        if (notificationId != null && notificationId.isNotEmpty) {
          PushNotificationService.onNotificationIdReceived?.call(notificationId);
        }
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
