import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../../data/models/payment_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/error_localizer.dart';
import '../../../../core/errors/app_exception.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerifyCardPage extends StatefulWidget {
  final CardToken card;

  const VerifyCardPage({super.key, required this.card});

  @override
  State<VerifyCardPage> createState() => _VerifyCardPageState();
}

class _VerifyCardPageState extends State<VerifyCardPage> {
  final _smsCtrl = TextEditingController();

  // Server-side error for the SMS code field. Cleared on the next edit.
  String? _smsCodeServerError;

  @override
  void dispose() {
    _smsCtrl.dispose();
    super.dispose();
  }

  /// Extracts a single user-facing string from a DRF-style errors map entry
  /// (either `"field": "msg"` or `"field": ["msg", ...]`).
  static String? _serverFieldError(Map<String, dynamic> errors, String key) {
    final value = errors[key];
    if (value == null) return null;
    if (value is List) {
      if (value.isEmpty) return null;
      final first = value.first?.toString().trim();
      return (first == null || first.isEmpty) ? null : first;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  void _onPaymentError(Object error, AppLocalizations l10n) {
    if (error is AppException) {
      final errors = error.errors;
      switch (error.messageKey) {
        case 'validation_error':
          final smsErr =
              errors == null ? null : _serverFieldError(errors, 'sms_code');
          if (smsErr != null) {
            setState(() => _smsCodeServerError = smsErr);
            return;
          }
          break;
        case 'click_card_verify_error':
          setState(() => _smsCodeServerError = l10n.invalidVerificationCode);
          return;
        case 'card_not_found':
          _showError(l10n.cardVerificationExpired);
          return;
      }
    }
    _showError(ErrorLocalizer.forException(error, l10n));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _verify() {
    final code = _smsCtrl.text.trim();
    if (code.isEmpty) return;
    context.read<PaymentBloc>().add(VerifyCardEvent(
          cardId: widget.card.id,
          smsCode: code,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyCardTitle),
        centerTitle: true,
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is CardVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.cardAddedSuccess),
                backgroundColor: Colors.green,
              ),
            );
            // AddCardPage used pushReplacement — only one pop needed to return to SubscriptionPage
            Navigator.of(context).pop();
          } else if (state is PaymentError) {
            _onPaymentError(state.error, l10n);
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            final isLoading = state is PaymentLoading;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.sms_outlined,
                            size: 48, color: Color(0xFF1A73E8)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.enterSmsCode,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.smsCodeSentFor(widget.card.maskedCardNumber),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOut),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _smsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '······',
                      hintStyle: TextStyle(letterSpacing: 8),
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    onChanged: (_) {
                      if (_smsCodeServerError != null) {
                        setState(() => _smsCodeServerError = null);
                      }
                    },
                  ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, curve: Curves.easeOut),
                  if (_smsCodeServerError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _smsCodeServerError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: errorColor, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _verify,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.confirmButton,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
