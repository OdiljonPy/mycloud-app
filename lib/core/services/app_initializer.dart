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
    AutoSyncService().initialize().then((_) {
      // После перезапуска приложения — возобновляем sync автоматически
      AutoSyncService().startAutoSync().catchError((e) {
        debugPrint('[AppInit] startAutoSync error: $e');
      });
    }).catchError((e) {
      debugPrint('[AppInit] AutoSyncService error (non-critical): $e');
    });

    debugPrint('[AppInit] ALL DONE');
  }
}
