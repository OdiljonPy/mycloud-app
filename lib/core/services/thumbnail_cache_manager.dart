import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ThumbnailCacheManager extends CacheManager {
  static const key = 'bulutchaThumbnailCache';

  static final ThumbnailCacheManager instance = ThumbnailCacheManager._();

  ThumbnailCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        );
}
