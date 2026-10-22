import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

import 'package:cloud_app/core/config/app_config.dart';
import 'package:cloud_app/core/errors/app_exception.dart';
import 'package:cloud_app/core/network/dio_client.dart';
import 'package:cloud_app/core/storage/secure_storage.dart';
import 'package:cloud_app/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handle);
  final FutureOr<ResponseBody> Function(RequestOptions) handle;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      handle(options);

  @override
  void close({bool force = false}) {}
}

class _FailingStore extends MapBase<String, String> {
  final data = <String, String>{};
  bool failRead = false;
  bool failRefreshWrite = false;

  @override
  String? operator [](Object? key) {
    if (failRead) throw StateError('Storage unavailable');
    return data[key];
  }

  @override
  void operator []=(String key, String value) {
    if (failRefreshWrite && key == 'refresh_token') {
      throw StateError('Write failed');
    }
    data[key] = value;
  }

  @override
  void clear() => data.clear();
  @override
  Iterable<String> get keys => data.keys;
  @override
  String? remove(Object? key) => data.remove(key);
}

ResponseBody _json(Object data, [int status = 200]) => ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json']
      },
    );

ResponseBody _rotatedTokens() => _json({
      'message': 'Ok',
      'result': {
        'access_token': 'fresh-access',
        'refresh_token': 'fresh-refresh'
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppConfig.initialize(Environment.dev);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.clearTokens();
    DioClient.resetLogoutFlag();
    await SecureStorage.saveTokens(
        accessToken: 'old-access', refreshToken: 'old-refresh');
  });

  tearDown(() async {
    await SecureStorage.clearTokens();
    DioClient.reset();
  });

  test('overlapping login/logout persists the last token pair', () async {
    await Future.wait([
      SecureStorage.saveTokens(
          accessToken: 'first', refreshToken: 'first-refresh'),
      SecureStorage.clearTokens(),
      SecureStorage.saveTokens(
          accessToken: 'last', refreshToken: 'last-refresh'),
    ]);
    expect(await SecureStorage.getAccessToken(), 'last');
    expect(await SecureStorage.getRefreshToken(), 'last-refresh');
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'access_token'), 'last');
    expect(await storage.read(key: 'refresh_token'), 'last-refresh');
  });

  test('stale logout and refresh cannot replace a new login', () async {
    final revision = SecureStorage.sessionRevision;
    await SecureStorage.saveTokens(
        accessToken: 'new', refreshToken: 'new-refresh');
    expect(
        await SecureStorage.clearTokens(expectedRevision: revision), isFalse);
    expect(
        await SecureStorage.saveRefreshedTokens(
          accessToken: 'late',
          refreshToken: 'late-refresh',
          expectedRevision: revision,
        ),
        isFalse);
    expect(await SecureStorage.getAccessToken(), 'new');
  });

  test('empty tokens are rejected without replacing a valid session', () async {
    await expectLater(
        SecureStorage.saveTokens(accessToken: '', refreshToken: 'r'),
        throwsA(isA<AppException>()));
    expect(await SecureStorage.getAccessToken(), 'old-access');
  });

  test('partial storage write fails visibly and the queue recovers', () async {
    await SecureStorage.clearTokens();
    final store = _FailingStore()..failRefreshWrite = true;
    FlutterSecureStorage.setMockInitialValues(store);
    await expectLater(
        SecureStorage.saveTokens(accessToken: 'partial', refreshToken: 'r'),
        throwsA(isA<AppException>()));
    expect(store.data, isEmpty);
    expect(SecureStorage.hasCachedAccessToken, isFalse);
    store.failRefreshWrite = false;
    await SecureStorage.saveTokens(accessToken: 'recovered', refreshToken: 'r');
    expect(await SecureStorage.getAccessToken(), 'recovered');
  });

  test('storage read failure does not clear saved tokens or send a request',
      () async {
    await SecureStorage.clearTokens();
    final store = _FailingStore()
      ..data.addAll({'access_token': 'stored', 'refresh_token': 'r'});
    store.failRead = true;
    FlutterSecureStorage.setMockInitialValues(store);
    var calls = 0;
    final dio = DioClient.createForTesting(_Adapter((_) {
      calls++;
      return _json({});
    }));
    await expectLater(dio.get('/one/'), throwsA(isA<DioException>()));
    expect(calls, 0);
    expect(store.data['access_token'], 'stored');
    store.failRead = false;
    expect(await SecureStorage.getAccessToken(), 'stored');
  });

  test('late login response cannot restore a session after logout', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final dio = DioClient.createForTesting(_Adapter((_) async {
      started.complete();
      await release.future;
      return _rotatedTokens();
    }));
    final checked = expectLater(
        AuthRepository(dio: dio)
            .login(phoneNumber: '+998901234567', password: 'test-password'),
        throwsA(isA<AppException>()));
    await started.future;
    await SecureStorage.clearTokens();
    release.complete();
    await checked;
    expect(await SecureStorage.getAccessToken(), isNull);
  });

  test('a lost mutation response is not replayed', () async {
    var calls = 0;
    final dio = DioClient.createForTesting(_Adapter((request) {
      calls++;
      throw DioException(
          requestOptions: request, type: DioExceptionType.connectionError);
    }));
    await expectLater(dio.post('/mutation/', data: {'name': 'test'}),
        throwsA(isA<DioException>()));
    expect(calls, 1);
  });

  test('parallel 401s share refresh and replay each request once', () async {
    var refreshes = 0;
    var reads = 0;
    final started = Completer<void>();
    final release = Completer<void>();
    final dio = DioClient.createForTesting(_Adapter((request) async {
      if (request.path.contains('token-refresh')) {
        refreshes++;
        expect(request.data, {'refresh_token': 'old-refresh'});
        started.complete();
        await release.future;
        return _rotatedTokens();
      }
      reads++;
      return request.headers['Authorization'] == 'Bearer fresh-access'
          ? _json({'ok': true})
          : _json({}, 401);
    }));
    final results = Future.wait([dio.get('/one/'), dio.get('/two/')]);
    await started.future;
    release.complete();
    expect((await results).map((r) => r.data['ok']), [true, true]);
    expect(refreshes, 1);
    expect(reads, 4);
    expect(await SecureStorage.getRefreshToken(), 'fresh-refresh');
  });

  test('late 401 reuses a token already refreshed in this session', () async {
    var refreshes = 0;
    final lateStarted = Completer<void>();
    final releaseLate = Completer<void>();
    final dio = DioClient.createForTesting(_Adapter((request) async {
      if (request.path.contains('token-refresh')) {
        refreshes++;
        return _rotatedTokens();
      }
      if (request.headers['Authorization'] == 'Bearer fresh-access') {
        return _json({});
      }
      if (request.path == '/late/') {
        lateStarted.complete();
        await releaseLate.future;
      }
      return _json({}, 401);
    }));
    final late = dio.get('/late/');
    await lateStarted.future;
    await dio.get('/first/');
    releaseLate.complete();
    await late;
    expect(refreshes, 1);
  });

  test('a repeated 401 stops after one refresh and one replay', () async {
    var refreshes = 0;
    var reads = 0;
    final dio = DioClient.createForTesting(_Adapter((request) {
      if (request.path.contains('token-refresh')) {
        refreshes++;
        return _rotatedTokens();
      }
      reads++;
      return _json({}, 401);
    }));
    await expectLater(dio.get('/one/'), throwsA(isA<DioException>()));
    expect(refreshes, 1);
    expect(reads, 2);
    expect(await SecureStorage.getAccessToken(), isNull);
  });

  for (final status in [401, 403, 500]) {
    test('refresh $status only clears a definitively rejected session',
        () async {
      final dio = DioClient.createForTesting(_Adapter((request) =>
          _json({}, request.path.contains('token-refresh') ? status : 401)));
      await expectLater(dio.get('/one/'), throwsA(isA<DioException>()));
      expect(await SecureStorage.getAccessToken(),
          status == 500 ? 'old-access' : isNull);
    });
  }

  test('offline refresh keeps tokens and propagates a transport error',
      () async {
    final dio = DioClient.createForTesting(_Adapter((request) {
      if (request.path.contains('token-refresh')) {
        throw DioException(
            requestOptions: request, type: DioExceptionType.connectionError);
      }
      return _json({}, 401);
    }));
    await expectLater(
        dio.get('/one/'),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.connectionError)
            .having((e) => e.response, 'response', isNull)));
    expect(await SecureStorage.getAccessToken(), 'old-access');
  });

  test('silent refresh rejection does not perform global logout', () async {
    final dio = DioClient.createForTesting(_Adapter((_) => _json({}, 401)));
    await expectLater(
        dio.get('/one/', options: Options(extra: {'silentAuth': true})),
        throwsA(isA<DioException>()));
    expect(await SecureStorage.getAccessToken(), 'old-access');
  });

  test('malformed refresh keeps the previous pair and reports 502', () async {
    final dio = DioClient.createForTesting(
        _Adapter((request) => request.path.contains('token-refresh')
            ? _json({
                'result': {'access_token': 'partial'}
              })
            : _json({}, 401)));
    await expectLater(
        dio.get('/one/'),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 502)));
    expect(await SecureStorage.getRefreshToken(), 'old-refresh');
  });

  for (final status in [200, 401, 403]) {
    test('late refresh $status cannot change a new account', () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final dio = DioClient.createForTesting(_Adapter((request) async {
        if (request.path.contains('token-refresh')) {
          started.complete();
          await release.future;
          return status == 200 ? _rotatedTokens() : _json({}, status);
        }
        return _json({}, 401);
      }));
      final checked =
          expectLater(dio.get('/one/'), throwsA(isA<DioException>()));
      await started.future;
      await SecureStorage.saveTokens(
          accessToken: 'new-account', refreshToken: 'new-refresh');
      release.complete();
      await checked;
      expect(await SecureStorage.getAccessToken(), 'new-account');
      expect(await SecureStorage.getRefreshToken(), 'new-refresh');
    });
  }

  test('late successful read is discarded after changing accounts', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final dio = DioClient.createForTesting(_Adapter((request) async {
      started.complete();
      await release.future;
      return _json({'private': 'previous account'});
    }));
    final checked = expectLater(
        dio.get('/one/'),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.cancel)));
    await started.future;
    await SecureStorage.saveTokens(
        accessToken: 'new', refreshToken: 'new-refresh');
    release.complete();
    await checked;
  });

  test('login 401 does not refresh or clear the current session', () async {
    var calls = 0;
    final dio = DioClient.createForTesting(_Adapter((request) {
      calls++;
      expect(request.headers.containsKey('Authorization'), isFalse);
      return _json({}, 401);
    }));
    await expectLater(
        dio.post('authentication/users/login/'), throwsA(isA<DioException>()));
    expect(calls, 1);
    expect(await SecureStorage.getAccessToken(), 'old-access');
  });

  final otpRequests = <String, Future<String> Function(AuthRepository)>{
    'register/': (repo) => repo.register(
        fullName: 'Test User',
        phoneNumber: '+998901234567',
        password: 'password123'),
    'otp/resend/': (repo) => repo.resendOtp(phoneNumber: '+998901234567'),
    'password/forgot/': (repo) =>
        repo.forgotPassword(phoneNumber: '+998901234567'),
    'password/resend/': (repo) =>
        repo.resendPasswordOtp(phoneNumber: '+998901234567'),
    'password/verify/': (repo) =>
        repo.verifyPasswordOtp(otpKey: 'old-key', otpCode: 123456),
  };
  for (final entry in otpRequests.entries) {
    test(
        '${entry.key} requires a non-empty string OTP key without changing tokens',
        () async {
      Object body = <String, Object>{};
      final dio = DioClient.createForTesting(_Adapter((request) {
        expect(request.method, 'POST');
        expect(request.path, 'authentication/users/${entry.key}');
        return _json(body);
      }));
      final repo = AuthRepository(dio: dio);
      for (final valid in [
        {'otp_key': 'new-key'},
        {
          'message': 'Ok',
          'result': {'otp_key': 'new-key'}
        },
      ]) {
        body = valid;
        expect(await entry.value(repo), 'new-key');
      }
      for (final invalid in [
        {'otp_key': ''},
        {'otp_key': '   '},
        {'otp_key': 123},
        {'result': <String, Object>{}},
        {'result': 'unexpected'},
        <Object>[],
      ]) {
        body = invalid;
        await expectLater(entry.value(repo), throwsA(isA<AppException>()));
      }
      expect(await SecureStorage.getAccessToken(), 'old-access');
      expect(await SecureStorage.getRefreshToken(), 'old-refresh');
    });
  }

  for (final body in [
    {'access': 'accepted', 'refresh': 'accepted-refresh'},
    {
      'result': {'access': 'accepted', 'refresh': 'accepted-refresh'}
    },
    {
      'result': {
        'access_token': 'accepted',
        'refresh_token': 'accepted-refresh'
      }
    },
    {
      'result': <String, Object>{},
      'access_token': 'accepted',
      'refresh_token': 'accepted-refresh'
    },
  ]) {
    test('login preserves supported token envelope: $body', () async {
      var calls = 0;
      final dio = DioClient.createForTesting(_Adapter((request) {
        calls++;
        if (request.path.contains('login')) return _json(body);
        expect(request.headers['Authorization'], 'Bearer accepted');
        // Stop before sync/FCM side effects; verify the token extraction and
        // authenticated /me request without calling any platform services.
        return _json({}, 500);
      }));
      await expectLater(
          AuthRepository(dio: dio)
              .login(phoneNumber: '+998901234567', password: 'test-password'),
          throwsA(isA<AppException>()));
      expect(calls, 2);
      expect(await SecureStorage.getAccessToken(), 'accepted');
      expect(await SecureStorage.getRefreshToken(), 'accepted-refresh');
    });
  }

  for (final otp in [false, true]) {
    test(
        '${otp ? 'OTP' : 'login'} rejects a successful response without tokens',
        () async {
      var calls = 0;
      final dio = DioClient.createForTesting(_Adapter((_) {
        calls++;
        return _json({'message': 'Ok', 'result': {}});
      }));
      final repo = AuthRepository(dio: dio);
      await expectLater(
          otp
              ? repo.verifyOtp(otpKey: 'key', otpCode: 123456)
              : repo.login(
                  phoneNumber: '+998901234567', password: 'test-password'),
          throwsA(isA<AppException>()));
      expect(calls, 1);
      expect(await SecureStorage.getAccessToken(), 'old-access');
    });
  }
}
