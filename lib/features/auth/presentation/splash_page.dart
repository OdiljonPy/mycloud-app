import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/app_initializer.dart';
import '../../../core/services/language_notifier.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../../home/presentation/main_page.dart';

// ─── Splash ──────────────────────────────────────────────────────────────────

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await Future.wait([
      AppInitializer.init(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    await _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final langChosen = prefs.getBool('lang_chosen') ?? false;
    final onboardDone = prefs.getBool('onboard_done') ?? false;

    String? token;
    try { token = await SecureStorage.getAccessToken(); } catch (_) {}

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      _go(const MainPage());
    } else if (!langChosen) {
      _go(const LanguageSelectionPage());
    } else if (!onboardDone) {
      _go(const OnboardingPage());
    } else {
      _go(const LoginPage());
    }
  }

  void _go(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/mycloud.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.cloud_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bulutcha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your files, everywhere.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white.withValues(alpha: 0.7),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Language Selection ───────────────────────────────────────────────────────

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});
  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String _selected = 'uz';

  final _langs = const [
    {'code': 'uz', 'label': "O'zbekcha", 'flag': '🇺🇿'},
    {'code': 'ru', 'label': 'Русский', 'flag': '🇷🇺'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
  ];

  Future<void> _confirm() async {
    LanguageNotifier.instance.setLanguage(_selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lang_chosen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/mycloud.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.cloud_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tilni tanlang',
                  style: TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Выберите язык · Choose language',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                const Spacer(),
                ..._langs.map((lang) {
                  final isSelected = _selected == lang['code'];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = lang['code']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang['flag']!, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 16),
                          Text(
                            lang['label']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF1A73E8)
                                  : Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF1A73E8), size: 22),
                        ],
                      ),
                    ),
                  );
                }),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A73E8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Davom etish →',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Onboarding ───────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;

  static final _slides = [
    _Slide(
      icon: Icons.cloud_upload_rounded,
      titles: {
        'uz': 'Barcha fayllar bir joyda',
        'ru': 'Все файлы в одном месте',
        'en': 'All files in one place',
      },
      subtitles: {
        'uz': 'Rasmlar, videolar, hujjatlar — hammasi xavfsiz saqlangan',
        'ru': 'Фото, видео, документы — всё надёжно хранится',
        'en': 'Photos, videos, documents — all securely stored',
      },
      gradient: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    ),
    _Slide(
      icon: Icons.sync_rounded,
      titles: {
        'uz': 'Avtomatik sinxronizatsiya',
        'ru': 'Автоматическая синхронизация',
        'en': 'Auto sync',
      },
      subtitles: {
        'uz': 'Galereya fonida yuklanadi — Google Photos kabi',
        'ru': 'Галерея загружается фоном — как Google Photos',
        'en': 'Gallery uploads in background — like Google Photos',
      },
      gradient: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    ),
    _Slide(
      icon: Icons.lock_rounded,
      titles: {
        'uz': 'Xavfsiz va tez',
        'ru': 'Безопасно и быстро',
        'en': 'Safe and fast',
      },
      subtitles: {
        'uz': 'Sizning malumotlaringiz faqat sizniki',
        'ru': 'Ваши данные принадлежат только вам',
        'en': 'Your data belongs only to you',
      },
      gradient: [Color(0xFF1565C0), Color(0xFF1A237E)],
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboard_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageNotifier.instance.locale.languageCode;
    final skipLabel = lang == 'uz' ? "O'tkazib yuborish" : lang == 'ru' ? 'Пропустить' : 'Skip';
    final startLabel = lang == 'uz' ? 'Boshlash' : lang == 'ru' ? 'Начать' : 'Get Started';
    final slide = _slides[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    lang == 'uz' ? 'O\'tkazib yuborish' : lang == 'ru' ? 'Пропустить' : 'Skip',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
                ),
              ),

              // Dots + Next button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Row(
                  children: [
                    // Dots
                    Row(
                      children: List.generate(_slides.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Next / Get Started
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _page == _slides.length - 1 ? 160 : 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: _page == _slides.length - 1
                              ? const Text(
                                  'Boshlash',
                                  style: TextStyle(
                                    color: Color(0xFF1A73E8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF1A73E8),
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Map<String, String> titles;    // {'uz': ..., 'ru': ..., 'en': ...}
  final Map<String, String> subtitles;
  final List<Color> gradient;
  const _Slide({
    required this.icon,
    required this.titles,
    required this.subtitles,
    required this.gradient,
  });
  String title(String lang) => titles[lang] ?? titles['en'] ?? '';
  String subtitle(String lang) => subtitles[lang] ?? subtitles['en'] ?? '';
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageNotifier.instance.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Icon(slide.icon, color: Colors.white, size: 68),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.subtitle(lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
