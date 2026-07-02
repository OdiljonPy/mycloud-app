import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/language_notifier.dart';
import '../../auth/presentation/login_page.dart';
import '../data/profile_repository.dart';
import '../../../main.dart';
import '../../share/presentation/share_requests_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../payment/data/repository/payment_repository.dart';
import '../../payment/data/models/payment_models.dart';
import '../../payment/presentation/bloc/payment_bloc.dart';
import '../../payment/presentation/pages/plans_page.dart';
import 'package:cloud_app/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfilePage({super.key, this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repo = ProfileRepository();
  final _paymentRepo = PaymentRepository();

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _storageData;
  Map<String, dynamic>? _usageData;
  CurrentSubscription? _subscription;
  List<Plan> _plans = [];
  bool _isLoading = true;

  static const _accent = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<CurrentSubscription?> _loadSubscriptionSilently() async {
    try {
      return await _paymentRepo.getCurrentSubscription();
    } catch (_) {
      return null;
    }
  }

  Future<List<Plan>> _loadPlansSilently() async {
    try {
      return await _paymentRepo.getPlans();
    } catch (_) {
      return [];
    }
  }

  Plan? _findNextPlan() {
    final sub = _subscription;
    if (sub == null || sub.planId == null || _plans.isEmpty) return null;
    final pool = _plans.where((p) => p.billingPeriod == sub.billingPeriod).toList();
    final sorted = (pool.isNotEmpty ? pool : [..._plans])
      ..sort((a, b) => a.storage.compareTo(b.storage));
    final idx = sorted.indexWhere((p) => p.id == sub.planId);
    if (idx == -1 || idx >= sorted.length - 1) return null;
    return sorted[idx + 1];
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getMe(),
        _repo.getStorageUsed(),
        _repo.getStorageUsage(),
        _loadSubscriptionSilently(),
        _loadPlansSilently(),
      ]);
      if (!mounted) return;
      setState(() {
        _userData = results[0] as Map<String, dynamic>;
        _storageData = results[1] as Map<String, dynamic>;
        _usageData = results[2] as Map<String, dynamic>;
        _subscription = results[3] as CurrentSubscription?;
        _plans = results[4] as List<Plan>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String get _fullName =>
      _userData?['full_name'] as String? ??
          _userData?['name'] as String? ??
          'User';

  String get _phone =>
      _userData?['phone_number'] as String? ??
          _userData?['phone'] as String? ??
          '';

  String? get _avatarUrl => _userData?['image'] as String?;

  String _formatBytes(dynamic bytes) {
    if (bytes == null) return '0 KB';
    final b = (bytes is num)
        ? bytes.toDouble()
        : double.tryParse(bytes.toString()) ?? 0;
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(2)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    return '${(b / 1024).toStringAsFixed(0)} KB';
  }

  Future<void> _deleteAccount() async {
    try {
      await _repo.disableAccount();
      await SecureStorage.clearTokens();
      DioClient.reset();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (widget.onLogout != null) {
      widget.onLogout!();
      return;
    }
    await SecureStorage.clearTokens();
    DioClient.reset();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      await _repo.uploadAvatar(file);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.avatarUpdated)),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditNameSheet() {
    final controller = TextEditingController(text: _fullName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.changeName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.newName,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await _repo.updateProfile(fullName: name);
                      await SecureStorage.saveFullName(name);
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.nameUpdated)),
                        );
                      }
                    } on AppException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(e.message),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPhoneSheet() {
    final controller = TextEditingController(text: _phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.changePhone,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.newPhone,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final phone = controller.text.trim();
                    if (phone.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await _repo.updateProfile(phone: phone);
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!.phoneUpdated)),
                        );
                      }
                    } on AppException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(e.message),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.changePassword,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: currentCtrl,
                  hint: AppLocalizations.of(context)!.oldPassword,
                  obscure: obscureCurrent,
                  onToggle: () => setSheetState(
                          () => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: newCtrl,
                  hint: AppLocalizations.of(context)!.newPassword,
                  obscure: obscureNew,
                  onToggle: () =>
                      setSheetState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: confirmCtrl,
                  hint: AppLocalizations.of(context)!.confirmPassword,
                  obscure: obscureConfirm,
                  onToggle: () => setSheetState(
                          () => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppLocalizations.of(context)!.passwordTooShort),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await _repo.changePassword(
                          current: currentCtrl.text,
                          newPass: newCtrl.text,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(context)!.passwordChanged)),
                          );
                        }
                      } on AppException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor:
        Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: Colors.grey[400],
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.chooseLanguage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildLangOption('🇷🇺', 'Русский', 'ru', ctx),
              _buildLangOption('🇺🇿', "O'zbekcha", 'uz', ctx),
              _buildLangOption('🇬🇧', 'English', 'en', ctx),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(
      String flag, String label, String code, BuildContext ctx) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: currentLocale == code
          ? const Icon(Icons.check_circle_rounded,
          color: Color(0xFF2563EB))
          : const Icon(Icons.radio_button_unchecked,
          color: Colors.grey),
      onTap: () {
        LanguageNotifier.instance.setLanguage(code);
        Navigator.pop(ctx);
      },
    );
  }

  String get _langLabel {
    final currentLocale = Localizations.localeOf(context).languageCode;
    switch (currentLocale) {
      case 'uz':
        return "O'zbekcha";
      case 'en':
        return 'English';
      default:
        return 'Русский';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 60),
                _buildNamePhone(),
                const SizedBox(height: 24),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildStorageSection(),
                      const SizedBox(height: 16),
                      _buildEditSection(),
                      const SizedBox(height: 16),
                      _buildLanguage(),
                      const SizedBox(height: 16),
                      _buildShareRequests(),
                      const SizedBox(height: 16),
                      _buildTheme(),
                      const SizedBox(height: 24),
                      _buildLogout(),
                      const SizedBox(height: 12),
                      _buildDeleteAccount(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader() {
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _avatarUrl != null
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? const Icon(Icons.person,
                          size: 48, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Name & phone
  Widget _buildNamePhone() {
    return Column(
      children: [
        Text(
          _fullName,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _phone,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Edit section
  Widget _buildEditSection() {
    final t = AppLocalizations.of(context)!;
    return _buildSectionCard(
      title: t.personalData,
      child: Column(
        children: [
          _buildSettingsTile(
            Icons.person_outline_rounded,
            t.changeName,
            _fullName,
            _showEditNameSheet,
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            Icons.phone_outlined,
            t.changePhone,
            _phone.isNotEmpty ? _phone : t.newPhone,
            _showEditPhoneSheet,
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            Icons.lock_outline_rounded,
            t.changePassword,
            '••••••••',
            _showChangePasswordSheet,
          ),
        ],
      ),
    );
  }

  // Language
  Widget _buildLanguage() {
    final t = AppLocalizations.of(context)!;
    return _buildSectionCard(
      child: _buildSettingsTile(
        Icons.language_rounded,
        t.language,
        _langLabel,
        _showLanguageSheet,
      ),
    );
  }

  // Storage + Subscription combined block
  Widget _buildStorageSection() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final innerBg = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF5F5F7);
    final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary = isDark ? Colors.white54 : Colors.black45;

    final used = _storageData?['used_storage'];
    final limit = _storageData?['storage_limit'];
    final percent = (_storageData?['percent_used'] as num?)?.toDouble() ?? 0;
    final images = _usageData?['images'];
    final videos = _usageData?['videos'];

    final sub = _subscription;
    final hasActive = sub != null && sub.planId != null;
    final nextPlan = _findNextPlan();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.storage,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.storageSubtitle,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storage_rounded,
                            color: Color(0xFF1A73E8), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_formatBytes(used)} использовано из ${_formatBytes(limit)}',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 8, color: borderColor),
                        FractionallySizedBox(
                          widthFactor: (percent / 100).clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFFF97316)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUsageTile(
                          Icons.image_outlined,
                          t.images,
                          _formatBytes(images),
                          const Color(0xFF10B981),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildUsageTile(
                          Icons.videocam_outlined,
                          t.videos,
                          _formatBytes(videos),
                          const Color(0xFFF59E0B),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider(
                    create: (_) => PaymentBloc(PaymentRepository()),
                    child: PlansPage(currentPlanId: sub?.planId),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(
                  nextPlan != null
                      ? t.upgradeToPlan(nextPlan.name)
                      : hasActive
                          ? t.changePlan
                          : t.choosePlan,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTile(
      IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45)),
                Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Share Requests
  Widget _buildShareRequests() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ShareRequestsPage(),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded,
                    color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.shareRequests,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      t.shareRequestsSubtitle,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Theme
  Widget _buildTheme() {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildSectionCard(
      title: t.theme,
      child: Row(
        children: [
          _buildThemeTile(
              t.light, Icons.wb_sunny_rounded, false, isDark),
          const SizedBox(width: 8),
          _buildThemeTile(
              t.dark, Icons.nightlight_round, true, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeTile(String label, IconData icon, bool isDarkOption,
      bool currentIsDark) {
    final isActive = isDarkOption == currentIsDark;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ThemeNotifier.instance.setMode(
            isDarkOption ? ThemeMode.dark : ThemeMode.light,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? _accent.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? _accent
                  : Colors.grey.withValues(alpha: 0.2),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isActive ? _accent : Colors.grey[400],
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isActive ? _accent : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logout
  Widget _buildLogout() {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(t.logout,
            style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(t.logoutConfirm),
              content: Text(t.logoutConfirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
                  child: Text(t.logout,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeleteAccount() {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        label: Text(
          t.deleteAccount,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(t.deleteAccountConfirm),
              content: Text(t.deleteAccountConfirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteAccount();
                  },
                  child: Text(
                    t.deleteAccount,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helpers
  Widget _buildSectionCard({required Widget child, String? title}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
