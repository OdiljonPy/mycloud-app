import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../l10n/app_localizations.dart';
import 'reset_password_page.dart';

class ResetPasswordOtpPage extends StatefulWidget {
  final AuthRepository? authRepository;
  final String phoneNumber;
  final String otpKey;

  const ResetPasswordOtpPage({
    super.key,
    this.authRepository,
    required this.phoneNumber,
    required this.otpKey,
  });

  @override
  State<ResetPasswordOtpPage> createState() => _ResetPasswordOtpPageState();
}

class _ResetPasswordOtpPageState extends State<ResetPasswordOtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late final _authRepo = widget.authRepository ?? AuthRepository();
  late String _otpKey;

  bool _isLoading = false;
  bool _isResending = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _otpKey = widget.otpKey;
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(String val, int index) {
    if (_isLoading || _isResending) return;
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 1) {
      // Вставка из буфера / автозаполнение — раскладываем по всем полям с начала.
      final chars = digits.split('');
      for (int j = 0; j < 6; j++) {
        _controllers[j].text = j < chars.length ? chars[j] : '';
      }
      final nextEmpty = chars.length.clamp(0, 6);
      if (nextEmpty < 6) {
        _focusNodes[nextEmpty].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      _controllers[index].text = digits;
      if (digits.isNotEmpty && index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
      if (digits.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    setState(() {});
    if (_otpCode.length == 6) _verify();
  }

  void _onBackspace(int index) {
    if (_isLoading || _isResending) return;
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  Future<void> _verify() async {
    if (_isLoading ||
        _isResending ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    final code = _otpCode;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = const AppException(
            message: 'Incomplete verification code',
            messageKey: 'local_incomplete_otp',
          ));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Password-reset flow: password/verify/ returns a new otp_key
      // required by password/reset/ (no tokens saved, sync untouched)
      final newOtpKey = await _authRepo.verifyPasswordOtp(
        otpKey: _otpKey,
        otpCode: int.parse(code),
      );
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              otpKey: newOtpKey,
              authRepository: _authRepo,
              otpCode: int.parse(code),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_isLoading ||
        _isResending ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      final newKey =
          await _authRepo.resendPasswordOtp(phoneNumber: widget.phoneNumber);
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      setState(() => _otpKey = newKey);
      for (final c in _controllers) {
        c.clear();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.otpCodeResentMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS HIG ranglar
    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor =
        isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);
    final inputFillColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F7FA);
    final accentColor =
        isDark ? const Color(0xFF0A84FF) : const Color(0xFF1A73E8);
    final errorColor =
        isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
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
                child:
                    Icon(Icons.message_rounded, color: accentColor, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.verifyOtpCodeTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                  children: [
                    TextSpan(
                        text: AppLocalizations.of(context)!.otpSentToPrefix),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => SizedBox(
                    width: 46,
                    height: 56,
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace) {
                          _onBackspace(i);
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        readOnly: _isLoading || _isResending,
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: accentColor, width: 2),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) => _onDigitChanged(val, i),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: errorColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: errorColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ErrorLocalizer.forException(
                              _error!, AppLocalizations.of(context)!),
                          style: TextStyle(color: errorColor, fontSize: 13),
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
                  onPressed: _isLoading || _isResending ? null : _verify,
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
                          AppLocalizations.of(context)!.verifyButton,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isLoading || _isResending ? null : _resend,
                  child: _isResending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.resendCodeButton,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
