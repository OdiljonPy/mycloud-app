import 'package:cloud_app/features/sync/sync_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'home_page.dart';
import 'files_page.dart';
import 'shared_page.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_page.dart';
import '../../profile/presentation/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  final _homeKey = GlobalKey<HomePageState>();
  final _filesKey = GlobalKey<FilesPageState>();

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
                onNavigateToFiles: () => setState(() => _currentIndex = 1),
                onNavigateToShared: () => setState(() => _currentIndex = 2),
                onNavigateToProfile: () => setState(() => _currentIndex = 3),
                onToggleFavourites: () {
                  setState(() => _currentIndex = 1);
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
                onTap: (i) => setState(() => _currentIndex = i),
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
                },
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: t.shared,
                index: 2,
                current: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: t.profile,
                index: 3,
                current: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
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

