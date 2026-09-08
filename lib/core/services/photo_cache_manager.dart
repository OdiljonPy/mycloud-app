import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PhotoCacheManager extends CacheManager {
  static const key = 'bulutchaPhotoCache';

  static final PhotoCacheManager instance = PhotoCacheManager._();

  PhotoCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 3),
            maxNrOfCacheObjects: 50,
          ),
        );
}
