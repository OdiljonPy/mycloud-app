import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'core/config/app_config.dart';
import 'core/services/language_notifier.dart';
import 'core/services/main_page_visibility_observer.dart';
import 'core/services/navigation_service.dart';
import 'core/services/payment_deep_link_service.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/sync/presentation/widgets/sync_status_bubble.dart';
import 'l10n/app_localizations.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier._();
  static final ThemeNotifier instance = ThemeNotifier._();

  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    _mode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggle() => setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode m) {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
    SharedPreferences.getInstance().then((p) {
      p.setString(_key, m == ThemeMode.dark ? 'dark' : 'light');
    });
  }
}

// ── Themes ──────────────────────────────────────────────────────────────────

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8), brightness: Brightness.light),
  scaffoldBackgroundColor: const Color(0xFFF5F7FA),
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE2E8F0),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, surfaceTintColor: Colors.transparent),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.white),
);

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF1A73E8), onPrimary: Colors.white,
    secondary: Color(0xFF1A73E8), onSecondary: Colors.white,
    error: Color(0xFFEF4444), onError: Colors.white,
    surface: Color(0xFF161B22), onSurface: Color(0xFFE6EDF3),
    surfaceContainerHighest: Color(0xFF21262D),
  ),
  scaffoldBackgroundColor: const Color(0xFF0D1117),
  cardColor: const Color(0xFF161B22),
  dividerColor: const Color(0xFF30363D),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF161B22), foregroundColor: Color(0xFFE6EDF3), elevation: 0, surfaceTintColor: Colors.transparent),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF161B22)),
  dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF161B22)),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF161B22)),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFF21262D), filled: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    hintStyle: const TextStyle(color: Color(0xFF8B949E)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFE6EDF3)), bodyMedium: TextStyle(color: Color(0xFFE6EDF3)),
    bodySmall: TextStyle(color: Color(0xFF8B949E)), titleLarge: TextStyle(color: Color(0xFFE6EDF3)),
    titleMedium: TextStyle(color: Color(0xFFE6EDF3)), titleSmall: TextStyle(color: Color(0xFF8B949E)),
    labelLarge: TextStyle(color: Color(0xFFE6EDF3)), labelMedium: TextStyle(color: Color(0xFF8B949E)),
    labelSmall: TextStyle(color: Color(0xFF8B949E)),
  ),
);

// ── Entry Point ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize(Environment.dev);
  await initializeDateFormatting();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Main] Firebase init failed (non-critical): $e');
  }

  unawaited(PaymentDeepLinkService.initialize());

  runApp(const ProviderScope(child: CloudApp()));

  // Плавающая таблетка синка живёт в root Overlay (а не внутри MainPage),
  // чтобы оставаться видимой поверх ЛЮБОГО экрана — включая UploadPage,
  // который пушится поверх MainPage через обычный Navigator.push.
  WidgetsBinding.instance.addPostFrameCallback((_) => _insertSyncStatusOverlay());

  // image_picker copies every picked file into the cache dir and never deletes
  // it: Android — into random-UUID subfolders, iOS — as flat files at the cache
  // root. Safety net for cases where the process was killed before
  // UploadQueueNotifier could clean up a picked file itself (Android: removes
  // UUID folders, iOS: removes stale image_picker files by age).
  // Fire-and-forget so it never delays first frame.
  unawaited(_cleanupOrphanedImagePickerCache());
}

final mainPageVisibilityObserver = MainPageVisibilityObserver();

bool _syncOverlayInserted = false;

void _insertSyncStatusOverlay() {
  if (_syncOverlayInserted) return;
  final overlay = NavigationService.navigatorKey.currentState?.overlay;
  if (overlay == null) {
    // Navigator ещё не успел создать свой Overlay к этому кадру — пробуем
    // ещё раз на следующем.
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertSyncStatusOverlay());
    return;
  }
  try {
    overlay.insert(OverlayEntry(
      builder: (_) => const SyncStatusBubble(),
    ));
    _syncOverlayInserted = true;
  } catch (e) {
    debugPrint('[Main] Failed to insert sync status overlay: $e');
  }
}

final RegExp _uuidDirName = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// image_picker (iOS) writes every picked/captured file flat into
/// NSTemporaryDirectory() as `image_picker_<GUID><suffix>` and never deletes
/// it (FLTImagePickerPhotoAssetUtil.temporaryFilePath:). Only files with this
/// prefix are candidates for the age-based sweep.
const String _iosImagePickerFilePrefix = 'image_picker_';

/// Top-level temp-dir entries owned by other caches. They are directories and
/// the age-based sweep only looks at files, but guard by name as well.
const Set<String> _protectedTempEntries = {
  'bulutchaThumbnailCache', // ThumbnailCacheManager.key
  'bulutchaPhotoCache', // PhotoCacheManager.key
  'libCachedImageData', // flutter_cache_manager default
  'tus_uploads', // UploadRepository
  'tus_sync_uploads', // TusSyncUploader
};

/// UploadQueueNotifier state lives in memory only, so nothing picked before
/// the current process started can ever be restored via restoreFile — every
/// leftover image_picker file is already orphaned at startup. 48h is a purely
/// defensive margin (clock drift, mtime quirks, a future persisted queue) so
/// the sweep can never touch a file a user could still want to restore.
const Duration _orphanedPickerFileMaxAge = Duration(hours: 48);

Future<void> _cleanupOrphanedImagePickerCache() async {
  try {
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) return;
    await for (final entry in tempDir.list()) {
      if (entry is! Directory) continue;
      final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!_uuidDirName.hasMatch(name)) continue;
      try {
        await entry.delete(recursive: true);
      } catch (e) {
        debugPrint('[Main] Failed to delete orphaned picker cache dir $name: $e');
      }
    }

    // iOS: flat layout — image_picker_<GUID><suffix> directly in the temp dir.
    // Only files (never directories), only with the image_picker prefix, only
    // when older than the threshold.
    final cutoff = DateTime.now().subtract(_orphanedPickerFileMaxAge);
    await for (final entry in tempDir.list()) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (_protectedTempEntries.contains(name)) continue;
      if (!name.startsWith(_iosImagePickerFilePrefix)) continue;
      try {
        final modified = await entry.lastModified();
        if (modified.isAfter(cutoff)) continue;
        await entry.delete();
      } catch (e) {
        debugPrint('[Main] Failed to delete stale picker file $name: $e');
      }
    }
  } catch (e) {
    debugPrint('[Main] image_picker cache cleanup failed (non-critical): $e');
  }
}

class CloudApp extends StatelessWidget {
  const CloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeNotifier.instance, LanguageNotifier.instance]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService.navigatorKey,
          scaffoldMessengerKey: NavigationService.scaffoldMessengerKey,
          navigatorObservers: [mainPageVisibilityObserver],
          title: 'Bulutcha',
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: ThemeNotifier.instance.mode,
          locale: LanguageNotifier.instance.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ru'), Locale('uz')],
          home: const SplashPage(),
        );
      },
    );
  }
}
