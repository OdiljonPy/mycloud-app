import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String otpKey;
  final int otpCode;

  const ResetPasswordPage({
    super.key,
    required this.otpKey,
    required this.otpCode,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepo = AuthRepository();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _success;

  bool _passwordTouched = false;
  bool _confirmTouched = false;

  bool get _isPasswordValid => _passwordController.text.length >= 8;
  bool get _isConfirmValid =>
      _confirmPasswordController.text == _passwordController.text &&
      _confirmPasswordController.text.isNotEmpty;
  bool get _isFormValid => _isPasswordValid && _isConfirmValid;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus && !_passwordTouched) {
        setState(() => _passwordTouched = true);
      }
    });
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus && !_confirmTouched) {
        setState(() => _confirmTouched = true);
      }
    });
  }

  Future<void> _resetPassword() async {
    setState(() {
      _passwordTouched = true;
      _confirmTouched = true;
    });
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      await _authRepo.resetPassword(
        otpKey: widget.otpKey,
        otpCode: widget.otpCode,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      setState(() => _success = 'Password reset successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS HIG ranglar
    final bgColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93);
    final inputFillColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F7FA);
    final hintColor = isDark ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
    final accentColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF1A73E8);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
    final successColor = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);

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
                child: Icon(Icons.lock_rounded, color: accentColor, size: 28),
              ),

              const SizedBox(height: 24),

              Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a strong password with at least 8 characters.',
                style: TextStyle(fontSize: 14, color: subtitleColor),
              ),

              const SizedBox(height: 40),

              // Password
              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                style: TextStyle(fontSize: 15, color: textColor),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: inputFillColor,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock_rounded, color: accentColor, size: 18),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: hintColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
              if (_passwordTouched && !_isPasswordValid) ...[
                const SizedBox(height: 6),
                Text(
                  'Минимум 8 символов',
                  style: TextStyle(color: errorColor, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),

              // Confirm Password
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmFocus,
                obscureText: _obscureConfirm,
                style: TextStyle(fontSize: 15, color: textColor),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _resetPassword(),
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: inputFillColor,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        color: accentColor, size: 18),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: hintColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
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
              if (_confirmTouched && !_isConfirmValid) ...[
                const SizedBox(height: 6),
                Text(
                  'Пароли не совпадают',
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
                          style: TextStyle(color: errorColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_success != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: successColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: successColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _success!,
                          style: TextStyle(color: successColor, fontSize: 13),
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
                  onPressed: _isLoading || !_isFormValid
                      ? null
                      : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
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
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
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
