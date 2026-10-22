import 'dart:async';

import 'package:cloud_app/core/errors/app_exception.dart';
import 'package:cloud_app/features/auth/data/auth_repository.dart';
import 'package:cloud_app/features/auth/presentation/forgot_password_page.dart';
import 'package:cloud_app/features/auth/presentation/login_page.dart';
import 'package:cloud_app/features/auth/presentation/otp_page.dart';
import 'package:cloud_app/features/auth/presentation/register_page.dart';
import 'package:cloud_app/features/auth/presentation/reset_password_otp_page.dart';
import 'package:cloud_app/features/auth/presentation/reset_password_page.dart';
import 'package:cloud_app/features/auth/presentation/splash_page.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthRepository extends AuthRepository {
  _AuthRepository() : super(dio: Dio());

  final loginResult = Completer<void>();
  final registerResult = Completer<String>();
  final forgotResult = Completer<String>();
  final verifyResult = Completer<void>();
  final verifyPasswordResult = Completer<String>();
  Completer<String> resendResult = Completer<String>();
  final resetResult = Completer<void>();
  int loginCalls = 0;
  int registerCalls = 0;
  int forgotCalls = 0;
  int verifyCalls = 0;
  int resendCalls = 0;
  int resetCalls = 0;
  String? verifiedKey;
  int? verifiedCode;
  String? resetKey;

  @override
  Future<void> login({required String phoneNumber, required String password}) {
    loginCalls++;
    return loginResult.future;
  }

  @override
  Future<String> register(
      {required String fullName,
      required String phoneNumber,
      required String password}) {
    registerCalls++;
    return registerResult.future;
  }

  @override
  Future<String> forgotPassword({required String phoneNumber}) {
    forgotCalls++;
    return forgotResult.future;
  }

  @override
  Future<void> verifyOtp({required String otpKey, required int otpCode}) {
    verifyCalls++;
    verifiedKey = otpKey;
    verifiedCode = otpCode;
    return verifyResult.future;
  }

  @override
  Future<String> verifyPasswordOtp(
      {required String otpKey, required int otpCode}) {
    verifyCalls++;
    verifiedKey = otpKey;
    verifiedCode = otpCode;
    return verifyPasswordResult.future;
  }

  @override
  Future<String> resendOtp({required String phoneNumber}) {
    resendCalls++;
    return resendResult.future;
  }

  @override
  Future<String> resendPasswordOtp({required String phoneNumber}) {
    resendCalls++;
    return resendResult.future;
  }

  @override
  Future<void> resetPassword(
      {required String otpKey,
      required int otpCode,
      required String password,
      required String confirmPassword}) {
    resetCalls++;
    resetKey = otpKey;
    return resetResult.future;
  }
}

const _failure = AppException(message: 'invalid code');

Future<void> _mount(WidgetTester tester, Widget page,
    {Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = const Size(450, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: page,
  ));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, List<String> values) async {
  for (var i = 0; i < values.length; i++) {
    await tester.enterText(find.byType(TextField).at(i), values[i]);
  }
  await tester.pump();
}

VoidCallback _submit(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!;

void main() {
  for (final language in ['en', 'ru', 'uz']) {
    testWidgets('registration texts use $language localization',
        (tester) async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      await _mount(tester, RegisterPage(authRepository: _AuthRepository()),
          locale: Locale(language));
      expect(find.text(l10n.createAccountTitle), findsOneWidget);
      expect(find.text(l10n.createAccountSubtitle), findsOneWidget);
      expect(find.text(l10n.fullNameLabel), findsOneWidget);
      expect(find.text(l10n.sendOtpCodeButton), findsOneWidget);
    });
  }

  testWidgets(
      'changing locale translates an existing error without resubmitting or resetting inputs',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(tester, LoginPage(authRepository: repo));
    await _enter(tester, ['+998901234567', 'password123']);
    _submit(tester)();
    repo.loginResult.completeError(
        const AppException(message: 'invalid phone_number or password'));
    await tester.pumpAndSettle();
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(en.errorInvalidCredentials), findsOneWidget);
    await _mount(tester, LoginPage(authRepository: repo),
        locale: const Locale('ru'));
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(find.text(ru.errorInvalidCredentials), findsOneWidget);
    expect(find.text(en.errorInvalidCredentials), findsNothing);
    expect(repo.loginCalls, 1);
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'password123');
  });

  testWidgets('incomplete OTP warning also follows a locale change',
      (tester) async {
    final repo = _AuthRepository();
    Widget page() => OtpPage(
        phoneNumber: '+998901234567', otpKey: 'key', authRepository: repo);
    await _mount(tester, page());
    _submit(tester)();
    await tester.pump();
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(en.enterCompleteOtpCode), findsOneWidget);
    await _mount(tester, page(), locale: const Locale('uz'));
    final uz = await AppLocalizations.delegate.load(const Locale('uz'));
    expect(find.text(uz.enterCompleteOtpCode), findsOneWidget);
    expect(repo.verifyCalls, 0);
  });

  testWidgets('language selection previews its button in the selected language',
      (tester) async {
    await _mount(tester, const LanguageSelectionPage());
    final uz = await AppLocalizations.delegate.load(const Locale('uz'));
    expect(find.text(uz.languageContinue), findsOneWidget);
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(find.text(ru.languageContinue), findsOneWidget);
  });

  testWidgets('onboarding follows the inherited locale on all slides',
      (tester) async {
    await _mount(tester, const OnboardingPage(), locale: const Locale('ru'));
    final ru = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(find.text(ru.onboardingFilesTitle), findsOneWidget);
    expect(find.text(ru.skipButton), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-450, 0));
    await tester.pumpAndSettle();
    expect(find.text(ru.onboardingSyncTitle), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-450, 0));
    await tester.pumpAndSettle();
    expect(find.text(ru.onboardingPrivacyTitle), findsOneWidget);
    expect(find.text(ru.getStartedButton), findsOneWidget);
  });

  testWidgets(
      'login keyboard submission is single-flight and recovers after failure',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(tester, LoginPage(authRepository: repo));
    await _enter(tester, ['+998901234567', 'password123']);
    final keyboardSubmit =
        tester.widget<TextField>(find.byType(TextField).last).onSubmitted!;
    keyboardSubmit('password123');
    keyboardSubmit('password123');
    expect(repo.loginCalls, 1);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).first).readOnly,
        isTrue);
    repo.loginResult.completeError(StateError('unexpected failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull);
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'password123');
  });

  for (final succeeds in [false, true]) {
    testWidgets('login completion after dispose is ignored: success=$succeeds',
        (tester) async {
      final repo = _AuthRepository();
      await _mount(tester, LoginPage(authRepository: repo));
      await _enter(tester, ['+998901234567', 'password123']);
      _submit(tester)();
      await tester.pumpWidget(const SizedBox());
      if (succeeds) {
        repo.loginResult.complete();
      } else {
        repo.loginResult.completeError(_failure);
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('covered login does not replace the covering route on success',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(tester, LoginPage(authRepository: repo));
    await _enter(tester, ['+998901234567', 'password123']);
    _submit(tester)();
    final context = tester.element(find.byType(LoginPage));
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('cover')),
    )));
    await tester.pump(const Duration(milliseconds: 400));
    repo.loginResult.complete();
    await tester.pumpAndSettle();
    expect(find.text('cover'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'registration guards same-frame double submission and keeps one OTP route',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(tester, RegisterPage(authRepository: repo));
    await _enter(
        tester, ['Test User', '+998901234567', 'password123', 'password123']);
    final submit = _submit(tester);
    submit();
    submit();
    expect(repo.registerCalls, 1);
    repo.registerResult.complete('registration-key');
    await tester.pumpAndSettle();
    expect(find.byType(OtpPage), findsOneWidget);
    // The captured callback must also remain guarded while its OTP child owns the route.
    submit();
    expect(repo.registerCalls, 1);
    Navigator.of(tester.element(find.byType(OtpPage))).pop();
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot-password ignores a response after leaving the form',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(tester, ForgotPasswordPage(authRepository: repo));
    await _enter(tester, ['+998901234567']);
    final submit = _submit(tester);
    submit();
    submit();
    expect(repo.forgotCalls, 1);
    await tester.pumpWidget(const SizedBox());
    repo.forgotResult.completeError(_failure);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final recovery in [false, true]) {
    Widget otpPage(_AuthRepository repo) => recovery
        ? ResetPasswordOtpPage(
            phoneNumber: '+998901234567',
            otpKey: 'old-key',
            authRepository: repo)
        : OtpPage(
            phoneNumber: '+998901234567',
            otpKey: 'old-key',
            authRepository: repo);

    testWidgets(
        'OTP verify locks resend and preserves numeric API format: recovery=$recovery',
        (tester) async {
      final repo = _AuthRepository();
      await _mount(tester, otpPage(repo));
      final resend =
          tester.widget<TextButton>(find.byType(TextButton)).onPressed!;
      final verify = _submit(tester);
      await tester.enterText(find.byType(TextField).first, '001234');
      verify();
      resend();
      expect(repo.verifyCalls, 1);
      expect(repo.verifiedCode, 1234);
      expect(repo.verifiedKey, 'old-key');
      expect(repo.resendCalls, 0);
      await tester.pump();
      expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
      if (recovery) {
        repo.verifyPasswordResult.completeError(_failure);
      } else {
        repo.verifyResult.completeError(_failure);
      }
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'OTP resend locks verify and uses the new key: recovery=$recovery',
        (tester) async {
      final repo = _AuthRepository();
      await _mount(tester, otpPage(repo));
      await tester.enterText(find.byType(TextField).first, '123');
      final resend =
          tester.widget<TextButton>(find.byType(TextButton)).onPressed!;
      final verify = _submit(tester);
      resend();
      resend();
      verify();
      expect(repo.resendCalls, 1);
      expect(repo.verifyCalls, 0);
      repo.resendResult.complete('new-key');
      await tester.pumpAndSettle();
      for (final field
          in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(field.controller!.text, isEmpty);
      }
      await tester.enterText(find.byType(TextField).first, '654321');
      expect(repo.verifiedKey, 'new-key');
      if (recovery) {
        repo.verifyPasswordResult.completeError(_failure);
      } else {
        repo.verifyResult.completeError(_failure);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('failed resend retains entered digits: recovery=$recovery',
        (tester) async {
      final repo = _AuthRepository();
      await _mount(tester, otpPage(repo));
      await tester.enterText(find.byType(TextField).first, '123');
      tester.widget<TextButton>(find.byType(TextButton)).onPressed!();
      repo.resendResult.completeError(_failure);
      await tester.pumpAndSettle();
      final digits = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller!.text)
          .join();
      expect(digits, '123');
      expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNotNull);
    });

    testWidgets(
        'OTP resend completion after dispose is ignored: recovery=$recovery',
        (tester) async {
      final repo = _AuthRepository();
      await _mount(tester, otpPage(repo));
      tester.widget<TextButton>(find.byType(TextButton)).onPressed!();
      await tester.pumpWidget(const SizedBox());
      repo.resendResult.complete('new-key');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'password recovery passes verified key to reset and guards keyboard resubmission',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(
        tester,
        ResetPasswordOtpPage(
            phoneNumber: '+998901234567',
            otpKey: 'initial-key',
            authRepository: repo));
    await tester.enterText(find.byType(TextField).first, '123456');
    repo.verifyPasswordResult.complete('verified-key');
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordPage), findsOneWidget);
    expect(
        tester.widget<ResetPasswordPage>(find.byType(ResetPasswordPage)).otpKey,
        'verified-key');
    await _enter(tester, ['password123', 'password123']);
    final keyboardSubmit =
        tester.widget<TextField>(find.byType(TextField).last).onSubmitted!;
    keyboardSubmit('password123');
    keyboardSubmit('password123');
    expect(repo.resetCalls, 1);
    expect(repo.resetKey, 'verified-key');
    await tester.pumpWidget(const SizedBox());
    repo.resetResult.completeError(_failure);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing reset page during success delay does not navigate later',
      (tester) async {
    final repo = _AuthRepository();
    await _mount(
        tester,
        ResetPasswordPage(
            otpKey: 'key', otpCode: 123456, authRepository: repo));
    await _enter(tester, ['password123', 'password123']);
    _submit(tester)();
    repo.resetResult.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(LoginPage), findsNothing);
  });
}
