import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'verify_card_page.dart';
import '../widgets/card_preview_widget.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardCtrl = TextEditingController();
  final _expireCtrl = TextEditingController();

  @override
  void dispose() {
    _cardCtrl.dispose();
    _expireCtrl.dispose();
    super.dispose();
  }

  String get _rawCardNumber => _cardCtrl.text.replaceAll(' ', '');
  String get _rawExpireDate => _expireCtrl.text.replaceAll('/', '');

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PaymentBloc>().add(AddCardEvent(
          cardNumber: _rawCardNumber,
          expireDate: _rawExpireDate,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addCard),
        centerTitle: true,
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is CardAdded) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PaymentBloc>(),
                  child: VerifyCardPage(card: state.card),
                ),
              ),
            );
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            final isLoading = state is PaymentLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    CardPreviewWidget(
                      numberText: _cardCtrl.text.isEmpty
                          ? '•••• •••• •••• ••••'
                          : _cardCtrl.text.padRight(19, '•').substring(0, 19),
                      expiryText: _expireCtrl.text.isEmpty
                          ? 'MM/YY'
                          : _expireCtrl.text,
                      detectionDigits: _rawCardNumber,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.06, curve: Curves.easeOut),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _cardCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardNumberFormatter(),
                      ],
                      maxLength: 19, // 16 digits + 3 spaces
                      decoration: InputDecoration(
                        labelText: l10n.cardNumberLabel,
                        hintText: '0000 0000 0000 0000',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterCardNumber;
                        if (_rawCardNumber.length != 16) return l10n.cardNumber16Digits;
                        return null;
                      },
                    ).animate(delay: 150.ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, curve: Curves.easeOut),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expireCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpireDateFormatter(),
                      ],
                      maxLength: 5, // MM/YY
                      decoration: InputDecoration(
                        labelText: l10n.expiryDate,
                        hintText: 'MM/YY',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.enterExpiryDate;
                        if (_rawExpireDate.length != 4) return l10n.expiryDateFormat;
                        final month = int.tryParse(_rawExpireDate.substring(0, 2));
                        if (month == null || month < 1 || month > 12) {
                          return l10n.invalidMonth;
                        }
                        return null;
                      },
                    ).animate(delay: 250.ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, curve: Curves.easeOut),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
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
                              l10n.addCard,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ).animate(delay: 350.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, curve: Curves.easeOut),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// XXXX XXXX XXXX XXXX formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 16) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// MM/YY formatter
class _ExpireDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;

    String formatted = digits;
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else if (digits.length == 2 && oldValue.text.length < 2) {
      formatted = '$digits/';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
