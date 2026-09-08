import 'dart:async';

import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tus_client/tus_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/errors/app_exception.dart';

class _TusDiskStore extends TusStore {
  final Directory _dir;
  _TusDiskStore(this._dir);

  String _keyFile(String fingerprint) => p.join(
    _dir.path,
    '${fingerprint.replaceAll(RegExp(r'[^\w]'), '_')}.tusurl',
  );

  @override
  Future<Uri?> get(String fingerprint) async {
    try {
      final f = File(_keyFile(fingerprint));
      if (!await f.exists()) return null;
      final url = await f.readAsString();
      return Uri.tryParse(url);
    } catch (e) {
      if (kDebugMode) debugPrint('[UploadRepo] disk store get failed: $e');
      return null;
    }
  }

  @override
  Future<void> set(String fingerprint, Uri url) async {
    try {
      await File(_keyFile(fingerprint)).writeAsString(url.toString());
    } catch (e) {
      if (kDebugMode) debugPrint('[UploadRepo] disk store set failed: $e');
    }
  }

  @override
  Future<void> remove(String fingerprint) async {
    try {
      final f = File(_keyFile(fingerprint));
      if (await f.exists()) await f.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[UploadRepo] disk store remove failed: $e');
    }
  }
}

class UploadRepository {
  static int resumeDelaySeconds = 3;

  static const _knownMediaExtensions = {'cr2', 'nef', 'arw', 'ts', 'mts'};

  // Максимум ПОДРЯД идущих неудачных сетевых повторов на один файл —
  // страховка от бесконечного while в [uploadFile]. Счётчик сбрасывается,
  // если после предыдущего повтора был реальный прогресс (см. там же).
  static const _maxNetworkRetries = 5;

  // Загрузка в UploadPage тоже строго последовательная (см. _startUploadAll
  // там — await на каждом файле), поэтому активный клиент — ровно один.
  TusClient? _activeClient;
  bool _abortIsCancel = false;

  /// Прерывает текущую активную заливку, если она есть — иначе no-op.
  /// [isCancel]=false — пауза (resumable state в сторе остаётся, следующая
  /// заливка этого файла продолжится с того же байтового оффсета).
  /// [isCancel]=true — отмена (resumable state будет вычищен внутри
  /// [uploadFile] после того как заливка фактически остановится).
  void requestAbort({required bool isCancel}) {
    final client = _activeClient;
    if (client == null) return;
    _abortIsCancel = isCancel;
    client.pause();
  }

  static bool isAllowed(String fileName) {
    final mime = lookupMimeType(fileName) ?? '';
    if (mime.isEmpty) {
      final ext = fileName.split('.').last.toLowerCase();
      return _knownMediaExtensions.contains(ext);
    }
    return mime.startsWith('image/') || mime.startsWith('video/');
  }

  Future<void> uploadFile({
    required XFile file,
    String? parentId,
    required String userId,
    void Function(double progress)? onProgress,
    void Function()? onComplete,
    void Function(String status)? onStatusChange,
  }) async {
    final token = await SecureStorage.getAccessToken();
    if (token == null) throw const AppException(message: 'No auth token');

    final fileName = file.name;
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

    if (!isAllowed(fileName)) {
      throw const AppException(message: 'Разрешены только фото и видео файлы');
    }

    final metadata = {
      'filename': fileName,
      'filetype': mimeType,
      'owner': userId,
      if (parentId != null) 'folder_id': parentId,
    };

    final tempDir = await getTemporaryDirectory();
    final tusDir = Directory(p.join(tempDir.path, 'tus_uploads'));
    if (!tusDir.existsSync()) tusDir.createSync(recursive: true);
    final store = _TusDiskStore(tusDir);

    final client = TusClient(
      Uri.parse(AppConfig.instance.tusUrl),
      file,
      store: store,
      headers: {'Authorization': 'Bearer $token'},
      metadata: metadata,
      maxChunkSize: 512 * 1024,
    );
    _activeClient = client;

    bool isCompleted = false;
    StreamSubscription? connectivitySub;
    int networkRetries = 0;
    bool madeProgressSinceRetry = false;
    double lastProgress = 0.0;

    // Слушаем сеть только для UI статуса
    connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (isCompleted) return;
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        onStatusChange?.call('paused');
      } else {
        onStatusChange?.call('resumed');
      }
    });

    onStatusChange?.call('uploading');

    // Retry loop: при ошибке сети — ждём и пробуем снова
    // TusStore сохраняет offset → продолжаем с того места
    while (!isCompleted) {
      try {
        // Таймаут-страховка от "тихо зависшего" сокета (соединение живо,
        // но сервер никогда не отвечает) — без него await здесь мог бы не
        // завершиться никогда, и UploadSyncCoordinator остался бы на паузе
        // навсегда (см. upload_sync_coordinator.dart). TimeoutException
        // уходит в тот же catch ниже, что и обычный обрыв сети — retry
        // продолжится с сохранённого TUS-offset, как и раньше.
        await client
            .upload(
              onProgress: (double progress) {
                if (progress > lastProgress) {
                  lastProgress = progress;
                  madeProgressSinceRetry = true;
                }
                onProgress?.call((progress / 100.0).clamp(0.0, 1.0));
              },
              onComplete: () {
                isCompleted = true;
                connectivitySub?.cancel();
                onComplete?.call();
              },
            )
            .timeout(
              const Duration(minutes: 30),
              onTimeout: () {
                // Future.timeout() не отменяет client.upload() — если
                // "зависший" запрос проснётся уже после того, как retry
                // ниже стартовал новый upload() на том же TusClient (те же
                // resumable-поля, тот же TUS URL), возможна гонка из двух
                // параллельных запросов на один upload endpoint. pause()
                // — best-effort сигнал остановиться до следующего чанка.
                try {
                  client.pause();
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('[UploadRepo] pause on timeout failed: $e');
                  }
                }
                throw TimeoutException('TUS upload timed out after 30 minutes');
              },
            );

        // upload() вернулся без исключения и без onComplete — единственная
        // причина: requestAbort() вызвал client.pause() извне (пауза или
        // отмена юзером конкретного файла). Сетевая ошибка сюда не попадает
        // — она уходит в catch ниже.
        if (!isCompleted) {
          final isCancel = _abortIsCancel;
          _abortIsCancel = false;
          connectivitySub.cancel();
          if (isCancel) {
            // Чистим resumable-URL — следующая заливка этого файла должна
            // начаться с нуля, а не резюмиться на отменённый upload.
            await store.remove(client.fingerprint);
            onStatusChange?.call('cancelled');
          } else {
            onStatusChange?.call('pausedByUser');
          }
        }
        break;
      } catch (e) {
        if (!_isRetryableNetworkError(e)) {
          // Протокольная/серверная/локальная ошибка (HTTP 4xx/5xx, битые
          // заголовки, файл недоступен, Error) — повтор бессмыслен, ждать
          // сеть тем более. Выходим из цикла исключением: UploadPage ловит
          // его и делает failItem → батч гарантированно дойдёт до
          // allSettled, остальные файлы очереди не блокируются.
          if (kDebugMode) {
            debugPrint('[UploadRepo] non-retryable error for $fileName: $e');
          }
          _activeClient = null;
          connectivitySub.cancel();
          throw AppException(
            message: 'Upload failed: $e',
            statusCode: _httpStatusFromError(e),
          );
        }

        // Сетевая ошибка. Ограничиваем число ПОДРЯД идущих неудачных
        // повторов: если после прошлого повтора чанки реально уходили —
        // обнуляем (длинный файл по плохой сети — норма, не ошибка).
        if (madeProgressSinceRetry) {
          networkRetries = 0;
          madeProgressSinceRetry = false;
        }
        networkRetries++;
        if (networkRetries > _maxNetworkRetries) {
          if (kDebugMode) {
            debugPrint(
              '[UploadRepo] giving up on $fileName after '
              '$_maxNetworkRetries network retries: $e',
            );
          }
          _activeClient = null;
          connectivitySub.cancel();
          throw AppException(
            message:
                'Upload failed after $_maxNetworkRetries network retries: $e',
          );
        }

        // Сеть пропала — ждём connectivity и повторяем
        onStatusChange?.call('paused');

        await _waitForNetwork();

        onStatusChange?.call('resumed');
        await Future.delayed(Duration(seconds: resumeDelaySeconds));
        onStatusChange?.call('uploading');
        // Продолжаем while — upload() сам возьмёт offset из store
      }
    }

    _activeClient = null;
    connectivitySub.cancel();
  }

  /// true — ошибка транспорта: есть смысл дождаться сети и повторить с
  /// сохранённого TUS-offset. false — повтор не поможет, файл надо failить.
  static bool _isRetryableNetworkError(Object e) {
    // tus_client: любой не-2xx HTTP-статус или невалидные заголовки ответа.
    if (e is ProtocolException) return false;
    // Наши собственные ошибки (auth и т.п.).
    if (e is AppException) return false;
    // Локальная FS-ошибка (файл удалён/недоступен) — сеть ни при чём.
    if (e is FileSystemException) return false;
    // StateError/ArgumentError/RangeError... — баг, а не сеть.
    if (e is Error) return false;
    // Сюда попадают: SocketException (в т.ч. обёртка из package:http),
    // HttpException "Connection closed…", TlsException, TimeoutException
    // (в т.ч. наша 30-минутная страховка), http.ClientException (package:http
    // не в прямых зависимостях — по типу не проверить). Всё это транспорт;
    // бесконечный цикл исключён счётчиком _maxNetworkRetries.
    return true;
  }

  /// Вытаскивает HTTP-статус из текста ProtocolException tus_client
  /// ("unexpected status code (403) while …"), иначе null.
  static int? _httpStatusFromError(Object e) {
    final m = RegExp(r'status code \((\d{3})\)').firstMatch(e.toString());
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  Future<void> _waitForNetwork() async {
    final completer = Completer<void>();
    StreamSubscription? sub;
    sub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork && !completer.isCompleted) {
        sub?.cancel();
        completer.complete();
      }
    });
    // Таймаут 5 минут на случай если событие не придёт
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        sub?.cancel();
      },
    );
  }
}
