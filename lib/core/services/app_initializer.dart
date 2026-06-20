import 'dart:async';
import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'language_notifier.dart';
import '../../main.dart';
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
