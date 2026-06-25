import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/home/data/models/file_model.dart';
import '../errors/app_exception.dart';

class FavouritesProvider extends ChangeNotifier {
  static final FavouritesProvider instance = FavouritesProvider._();
  FavouritesProvider._();

  final HomeRepository _repo = HomeRepository();

  final Set<String> _favouriteIds = {};
  List<FileModel> _favouriteFiles = [];
  bool _isLoading = false;
  bool _isBulkLoading = false;
  String? _error;

  Set<String> get favouriteIds => _favouriteIds;
  List<FileModel> get favouriteFiles => _favouriteFiles;
  bool get isLoading => _isLoading;
  bool get isBulkLoading => _isBulkLoading;
  String? get error => _error;

  bool isFavourite(String fileId) => _favouriteIds.contains(fileId);

  Future<void> loadFavourites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final favList = await _repo.getFavouriteFiles();
      final List<FileModel> files = [];
      final Set<String> newIds = {};

      for (final item in favList) {
        if (item is Map<String, dynamic>) {
          final fileData = item['file'];
          if (fileData is Map<String, dynamic>) {
            final fm = FileModel.fromJson(fileData);
            files.add(
              fm.copyWith(
                isFavourite: true,
                favouriteId: item['id']?.toString(), // the record ID
              ),
            );
            newIds.add(fm.id); // the file UUID
          }
        }
      }

      _favouriteFiles = files;
      _favouriteIds.clear();
      _favouriteIds.addAll(newIds);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavourite(FileModel file) async {
    final bool wasFav = _favouriteIds.contains(file.id);

    // Resolve record ID before optimistic removal wipes it from the list
    String? recordId;
    if (wasFav) {
      final loaded = _favouriteFiles.firstWhere(
        (f) => f.id == file.id,
        orElse: () => file,
      );
      recordId = loaded.favouriteId ?? file.favouriteId;
    }

    // Optimistic update
    if (wasFav) {
      _favouriteIds.remove(file.id);
      _favouriteFiles.removeWhere((f) => f.id == file.id);
    } else {
      _favouriteIds.add(file.id);
      _favouriteFiles.add(file.copyWith(isFavourite: true));
    }
    notifyListeners();

    try {
      if (wasFav) {
        await _deleteFromServer(file, recordId);
        await loadFavourites();
      } else {
        await _repo.addToFavourites(file.id);
        await loadFavourites();
      }
    } catch (e) {
      // Revert optimistic update on real failure
      if (wasFav) {
        _favouriteIds.add(file.id);
        _favouriteFiles.add(file.copyWith(isFavourite: true));
      } else {
        _favouriteIds.remove(file.id);
        _favouriteFiles.removeWhere((f) => f.id == file.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Bulk add or remove. Optimistic update instantly, HTTP in batches of 10
  /// concurrently, single [loadFavourites] at the end.
  ///
  /// DELETE /content/favourite-file/{id}/ — {id} is the integer record ID
  /// from FavouriteFileList, not the file UUID. We collect record IDs BEFORE
  /// the optimistic removal so they are not lost from _favouriteFiles.
  Future<void> bulkToggleFavourites(
    List<FileModel> files, {
    required bool remove,
  }) async {
    if (files.isEmpty) return;

    // For remove: collect integer record IDs BEFORE wiping from _favouriteFiles
    Map<String, String?> recordIdByFileId = {};
    if (remove) {
      for (final f in files) {
        final loaded = _favouriteFiles.firstWhere(
          (x) => x.id == f.id,
          orElse: () => f,
        );
        recordIdByFileId[f.id] = loaded.favouriteId ?? f.favouriteId;
      }
    }

    // Instant optimistic update — single notifyListeners
    if (remove) {
      for (final f in files) {
        _favouriteIds.remove(f.id);
        _favouriteFiles.removeWhere((x) => x.id == f.id);
      }
    } else {
      for (final f in files) {
        if (!_favouriteIds.contains(f.id)) {
          _favouriteIds.add(f.id);
          _favouriteFiles.add(f.copyWith(isFavourite: true));
        }
      }
    }
    _isBulkLoading = true;
    notifyListeners();

    const batchSize = 10;
    try {
      for (int i = 0; i < files.length; i += batchSize) {
        final batch = files.skip(i).take(batchSize).toList();
        await Future.wait(
          batch.map((f) async {
            try {
              if (remove) {
                // Use pre-collected record ID — no extra loadFavourites() calls
                await _deleteFromServer(f, recordIdByFileId[f.id]);
              } else {
                // POST /content/favourite-file/ body: {"file": fileUUID}
                final recId = await _repo.addToFavourites(f.id);
                final idx = _favouriteFiles.indexWhere((x) => x.id == f.id);
                if (idx != -1) {
                  _favouriteFiles[idx] = _favouriteFiles[idx]
                      .copyWith(favouriteId: recId.toString());
                }
              }
            } catch (_) {
              // Revert only this one file on error
              if (remove) {
                if (!_favouriteIds.contains(f.id)) {
                  _favouriteIds.add(f.id);
                  _favouriteFiles.add(f.copyWith(isFavourite: true));
                }
              } else {
                _favouriteIds.remove(f.id);
                _favouriteFiles.removeWhere((x) => x.id == f.id);
              }
            }
          }),
        );
      }
    } finally {
      _isBulkLoading = false;
      await loadFavourites();
    }
  }

  bool _is404(Object e) =>
      (e is DioException && e.response?.statusCode == 404) ||
      (e is AppException && e.statusCode == 404);

  /// Удаляет запись с сервера.
  /// Стратегия: сначала integer record ID → при 404 fallback на file UUID.
  /// Сервер принимает оба формата.
  Future<void> _deleteFromServer(FileModel file, String? recordId) async {
    // Если recordId неизвестен — получить свежий из сервера
    if (recordId == null) {
      await loadFavourites();
      recordId = _favouriteFiles
          .firstWhere((f) => f.id == file.id, orElse: () => file)
          .favouriteId;
    }

    // Попытка 1: integer record ID
    if (recordId != null) {
      try {
        await _repo.removeFromFavourites(recordId);
        return;
      } catch (e) {
        if (!_is404(e)) rethrow;
        // 404 по integer ID — пробуем UUID
      }
    }

    // Попытка 2: file UUID (сервер принимает оба формата)
    try {
      await _repo.removeFromFavourites(file.id);
    } catch (e) {
      if (!_is404(e)) rethrow;
      // UUID тоже 404 — файл уже удалён на сервере, всё ок
    }
  }
}
