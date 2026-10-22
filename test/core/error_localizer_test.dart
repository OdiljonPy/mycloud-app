import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_app/core/config/app_config.dart';
import 'package:cloud_app/core/errors/app_exception.dart';
import 'package:cloud_app/core/network/dio_client.dart';
import 'package:cloud_app/core/storage/secure_storage.dart';
import 'package:cloud_app/core/utils/error_localizer.dart';
import 'package:cloud_app/features/auth/data/auth_repository.dart';
import 'package:cloud_app/features/home/data/home_repository.dart';
import 'package:cloud_app/features/notifications/data/notifications_repository.dart';
import 'package:cloud_app/features/payment/data/repository/payment_repository.dart';
import 'package:cloud_app/features/profile/data/profile_repository.dart';
import 'package:cloud_app/features/share/data/remote/share_remote_data_source_impl.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _ErrorAdapter implements HttpClientAdapter {
  _ErrorAdapter(this.handle);
  final FutureOr<ResponseBody> Function(RequestOptions) handle;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      handle(options);
  @override
  void close({bool force = false}) {}
}

DioException _dioError(
    {DioExceptionType type = DioExceptionType.badResponse,
    int? status,
    Object? data,
    String path = '/content/folder/'}) {
  final request = RequestOptions(path: path);
  return DioException(
      requestOptions: request,
      type: type,
      response: status == null
          ? null
          : Response(requestOptions: request, statusCode: status, data: data));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final locale in ['en', 'ru', 'uz']) {
    test('error categories use $locale translations', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      String message(Object e) => ErrorLocalizer.forException(e, l10n);
      expect(message(const SocketException('private host')),
          l10n.errorNetworkUnavailable);
      expect(message(TimeoutException('technical timeout')),
          l10n.errorRequestTimeout);
      expect(message(_dioError(type: DioExceptionType.connectionError)),
          l10n.errorNetworkUnavailable);
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout
      ]) {
        expect(message(_dioError(type: type)), l10n.errorRequestTimeout);
      }
      expect(message(_dioError(type: DioExceptionType.cancel)),
          l10n.errorRequestCancelled);
      expect(
          message(_dioError(status: 403, data: {'message': 'user not found'})),
          l10n.errorAccessDenied);
      expect(message(_dioError(status: 404)), l10n.errorResourceNotFound);
      expect(message(_dioError(status: 409)), l10n.errorItemAlreadyExists);
      expect(message(_dioError(status: 429)), l10n.errorTooManyRequests);
      expect(
          message(
              _dioError(status: 429, path: '/api/v1/content/shared-by-me/')),
          l10n.errorShareLimitReached);
      expect(
          message(_dioError(status: 401, path: '/authentication/users/login/')),
          l10n.errorInvalidCredentials);
      expect(message(_dioError(status: 401)), l10n.errorSessionExpiredRelogin);
      for (final status in [500, 502, 503, 504]) {
        expect(
            message(
                _dioError(status: status, data: {'message': 'invalid code'})),
            l10n.errorServerUnavailable);
      }
      for (final status in [400, 422]) {
        expect(
            message(_dioError(status: status, data: {
              'name': ['invalid_field_value']
            })),
            l10n.errorValidation);
      }
    });

    test('known legacy messages remain specific in $locale', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      final messages = {
        'Upload failed: SocketException: private host':
            l10n.errorNetworkUnavailable,
        'Upload failed: TimeoutException: private path':
            l10n.errorRequestTimeout,
        'invalid phone_number or password': l10n.errorInvalidCredentials,
        'OTP code is still valid': l10n.errorOtpStillValid,
        'invalid code': l10n.errorInvalidCode,
        'wrong code': l10n.errorInvalidCode,
        'OTP expired': l10n.errorOtpExpired,
        'user already exists': l10n.errorUserAlreadyExists,
        'user not found': l10n.errorUserNotFound,
        'session expired': l10n.errorSessionExpired,
        'folder already exists': l10n.errorItemAlreadyExists,
        'file not found': l10n.errorResourceNotFound,
        'Cannot modify sync folder': l10n.syncFolderReadOnly,
      };
      for (final entry in messages.entries) {
        expect(ErrorLocalizer.localize(entry.key, l10n), entry.value);
      }
      for (final unknown in [
        'already',
        'exists',
        'not found',
        'OTP request malformed',
        'Invalid authentication response',
        '<html>private server traceback</html>',
        'Exception: SELECT password FROM users',
        'Status code 401',
      ]) {
        expect(
            ErrorLocalizer.localize(unknown, l10n), l10n.genericErrorFallback);
      }
      expect(ErrorLocalizer.forException(StateError('private path'), l10n),
          l10n.genericErrorFallback);
    });

    test('structured validation and local keys are translated in $locale',
        () async {
      final l10n = await AppLocalizations.delegate.load(Locale(locale));
      expect(
          ErrorLocalizer.forException(
              _dioError(status: 400, data: {
                'errors': {
                  'phone_number': ['A user with this phone already exists.']
                },
              }),
              l10n),
          l10n.errorUserAlreadyExists);
      expect(
          ErrorLocalizer.forException(
              _dioError(status: 400, data: {
                'name': ['folder already exists'],
              }),
              l10n),
          l10n.errorValidation);
      expect(
          ErrorLocalizer.forException(
              const AppException(
                message: 'Incomplete verification code',
                messageKey: 'local_incomplete_otp',
              ),
              l10n),
          l10n.enterCompleteOtpCode);
      expect(
          ErrorLocalizer.forException(
              _dioError(status: 400, data: {
                'message_key': 'you_can_pin_maximum_5_folders',
              }),
              l10n),
          l10n.maxPinnedFolders);
    });
  }

  test('Dio conversion preserves field errors without mutating the response',
      () {
    final errors = {
      'phone_number': ['already exists'],
      'code': 'nested_code'
    };
    final body = {
      'message': 'Failed',
      'message_key': 'validation_error',
      'errors': errors
    };
    final error = AppException.fromDio(_dioError(status: 400, data: body),
        fallbackMessage: 'Fallback');
    expect(error.statusCode, 400);
    expect(error.messageKey, 'validation_error');
    expect(error.errors?['phone_number'], ['already exists']);
    expect(errors['code'], 'nested_code');
    expect(error.errors?['code'], 'nested_code');
    expect(error.message, 'Failed');
  });

  test('Dio conversion safely handles HTML, null and list responses', () {
    for (final body in [
      null,
      '<html>unavailable</html>',
      ['invalid']
    ]) {
      final error = AppException.fromDio(_dioError(status: 502, data: body),
          fallbackMessage: 'Fallback');
      expect(error.statusCode, 502);
      expect(error.message, 'Fallback');
    }
  });

  group('repository error conversion', () {
    setUp(() async {
      AppConfig.initialize(Environment.dev);
      FlutterSecureStorage.setMockInitialValues({});
      await SecureStorage.clearTokens();
      DioClient.reset();
    });
    tearDown(() => DioClient.reset());

    final reads = <String, Future<dynamic> Function(Dio)>{
      'profile': (_) => ProfileRepository().getMe(),
      'content': (_) => HomeRepository().getContent(),
      'notifications': (_) => NotificationsRepository().getNotifications(),
      'sharing': (dio) => ShareRemoteDataSourceImpl(dio).getSharedWithMe(),
      'authentication': (dio) =>
          AuthRepository(dio: dio).forgotPassword(phoneNumber: '+998901234567'),
    };
    for (final entry in reads.entries) {
      test('${entry.key} keeps transport and HTTP failures', () async {
        final dio = DioClient.instance;
        dio.interceptors
            .removeWhere((i) => i.runtimeType.toString() == 'PrettyDioLogger');
        dio.httpClientAdapter = _ErrorAdapter((request) {
          throw DioException(
              requestOptions: request, type: DioExceptionType.receiveTimeout);
        });
        await expectLater(
            entry.value(dio),
            throwsA(isA<AppException>()
                .having((e) => e.type, 'type', AppExceptionType.timeout)));
        dio.httpClientAdapter = _ErrorAdapter((_) => ResponseBody.fromString(
              '<html>temporary failure</html>',
              503,
              headers: {
                'content-type': ['text/html']
              },
            ));
        await expectLater(
            entry.value(dio),
            throwsA(isA<AppException>()
                .having((e) => e.statusCode, 'status', 503)));
      });
    }

    test('existing payment validation fields and request stay compatible',
        () async {
      final dio = DioClient.instance;
      dio.interceptors
          .removeWhere((i) => i.runtimeType.toString() == 'PrettyDioLogger');
      dio.httpClientAdapter = _ErrorAdapter((request) {
        expect(request.method, 'POST');
        expect(request.path, '/payment/cards/');
        expect(request.data,
            {'card_number': '8600000000000000', 'expire_date': '12/30'});
        return ResponseBody.fromString(
            jsonEncode({
              'message_key': 'validation_error',
              'errors': {
                'card_number': ['Card number is invalid']
              },
            }),
            400,
            headers: {
              'content-type': ['application/json']
            });
      });
      await expectLater(
          PaymentRepository().addCard(
            cardNumber: '8600000000000000',
            expireDate: '12/30',
          ),
          throwsA(isA<AppException>()
              .having((e) => e.messageKey, 'key', 'validation_error')
              .having((e) => e.errors?['card_number'], 'field error',
                  ['Card number is invalid'])));
    });
  });
}
