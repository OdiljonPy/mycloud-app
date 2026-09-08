import 'package:cloud_app/features/sync/sync_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'home_page.dart';
import 'files_page.dart';
import 'shared_page.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_page.dart';
import '../../profile/presentation/profile_page.dart';

/// Real rendered height of MainPage's bottom nav bar, measured after layout.
/// Default is a fallback estimate used before the first measurement lands.
final bottomNavBarHeightProvider = StateProvider<double>((ref) => 66.0);

/// Whether the Files tab (index 1) is the currently selected MainPage tab —
/// only that tab has the upload FAB at the bottom-right corner.
final isFilesTabActiveProvider = StateProvider<bool>((ref) => false);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  final _homeKey = GlobalKey<HomePageState>();
  final _filesKey = GlobalKey<FilesPageState>();
  final _bottomNavKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBottomNavHeight());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBottomNavHeight());
  }

  @override
  void didChangeTextScaleFactor() {
    super.didChangeTextScaleFactor();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBottomNavHeight());
  }

  void _measureBottomNavHeight() {
    if (!mounted) return;
    final renderBox =
        _bottomNavKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    ProviderScope.containerOf(context, listen: false)
        .read(bottomNavBarHeightProvider.notifier)
        .state = renderBox.size.height;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentIndex != 0) {
            if (_currentIndex == 1) {
              if (_filesKey.currentState?.handleBackNavigation() ?? false) {
                return; // FilesPage handled the back press (e.g., navigated up a directory)
              }
            }
            setState(() => _currentIndex = 0);
            ProviderScope.containerOf(context, listen: false)
                .read(isFilesTabActiveProvider.notifier)
                .state = false;
            return;
          }
          // Home tab → double-press to exit
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
            _lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.logoutConfirmMessage),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          SystemNavigator.pop();
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                key: _homeKey,
                onNavigateToFiles: () {
                  setState(() => _currentIndex = 1);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = true;
                },
                onNavigateToShared: () {
                  setState(() => _currentIndex = 2);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = false;
                },
                onNavigateToProfile: () {
                  setState(() => _currentIndex = 3);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = false;
                },
                onToggleFavourites: () {
                  setState(() => _currentIndex = 1);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = true;
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _filesKey.currentState?.toggleFavourites();
                  });
                },
              ),
              FilesPage(key: _filesKey),
              const SharedPage(),
              ProfilePage(onLogout: _logout),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // Отписываем push-устройство, пока access token ещё валиден — сам
    // запрос требует аутентификации.
    await AuthRepository.unregisterCurrentDevice();
    await SecureStorage.clearTokens();
    await syncOnLogoutCallback();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  Widget _buildBottomNav() {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    
    return Container(
      key: _bottomNavKey,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: t.home,
                index: 0,
                current: _currentIndex,
                onTap: (i) {
                  setState(() => _currentIndex = i);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = (i == 1);
                },
              ),
              _NavItem(
                icon: Icons.folder_rounded,
                label: t.files,
                index: 1,
                current: _currentIndex,
                onTap: (i) {
                  if (i == 1) {
                    _filesKey.currentState?.resetToRoot();
                  }
                  setState(() => _currentIndex = i);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = (i == 1);
                },
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: t.shared,
                index: 2,
                current: _currentIndex,
                onTap: (i) {
                  setState(() => _currentIndex = i);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = (i == 1);
                },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: t.profile,
                index: 3,
                current: _currentIndex,
                onTap: (i) {
                  setState(() => _currentIndex = i);
                  ProviderScope.containerOf(context, listen: false)
                      .read(isFilesTabActiveProvider.notifier)
                      .state = (i == 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav widgets ───────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8B949E)
        : Colors.grey[400];
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1A73E8).withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: active ? const Color(0xFF1A73E8) : inactiveColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? const Color(0xFF1A73E8) : inactiveColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

