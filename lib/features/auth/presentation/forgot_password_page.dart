import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/utils/uzbek_phone_formatter.dart';
import '../../../l10n/app_localizations.dart';
import 'reset_password_otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController(text: '+998 ');
  final _authRepo = AuthRepository();
  final _phoneFocus = FocusNode();

  bool _isLoading = false;
  bool _phoneTouched = false;
  String? _error;

  String _rawPhone() => _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
  bool get _isPhoneValid => _rawPhone().length == 12;

  Future<void> _sendOtp() async {
    setState(() => _phoneTouched = true);
    if (!_isPhoneValid) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final phone = '+${_rawPhone()}';
      final otpKey = await _authRepo.forgotPassword(phoneNumber: phone);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordOtpPage(
              phoneNumber: phone,
              otpKey: otpKey,
            ),
          ),
        );
      }
    } on AppException catch (e) {
      final localized = mounted
          ? ErrorLocalizer.localize(e.message, AppLocalizations.of(context)!)
          : e.message;
      setState(() => _error = localized);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus && !_phoneTouched) {
        setState(() => _phoneTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS HIG ranglar
    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);
    final hintColor = isDark ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
    final accentColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF1A73E8);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.lock_reset_rounded, color: accentColor, size: 28),
              ),

              const SizedBox(height: 24),

              Text(
                AppLocalizations.of(context)!.forgotPasswordTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.forgotPasswordSubtitle,
                style: TextStyle(fontSize: 14, color: subtitleColor),
              ),

              const SizedBox(height: 40),

              Text(
                AppLocalizations.of(context)!.phoneNumberLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                inputFormatters: [UzbekPhoneFormatter()],
                style: TextStyle(fontSize: 15, color: textColor),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '+998 XX XXX XX XX',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F7FA),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.phone_rounded, color: accentColor, size: 18),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: accentColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              if (_phoneTouched && !_isPhoneValid) ...[
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.invalidPhoneNumber,
                  style: TextStyle(color: errorColor, fontSize: 12),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: errorColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: errorColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.sendOtpCodeButton,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}