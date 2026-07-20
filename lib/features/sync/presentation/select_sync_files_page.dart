import 'dart:typed_data';

import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Список альбомов (папок) устройства на чистом photo_manager — без
/// сторонних asset-picker пакетов (конфликт версий с tus_client). Юзер
/// выбирает один или несколько альбомов целиком (Camera, Screenshots и
/// т.д.) — не отдельные файлы. Возвращает список выбранных
/// AssetPathEntity.id через Navigator.pop, либо null если пользователь
/// ушёл назад/свайпом не подтвердив выбор.
class SelectSyncFilesPage extends StatefulWidget {
  final Set<String> initiallySelected;

  const SelectSyncFilesPage({super.key, required this.initiallySelected});

  @override
  State<SelectSyncFilesPage> createState() => _SelectSyncFilesPageState();
}

class _SelectSyncFilesPageState extends State<SelectSyncFilesPage> {
  final List<AssetPathEntity> _albums = [];
  late final Set<String> _selected;

  bool _loading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _loading = false;
        });
      }
      return;
    }

    // "All" — виртуальный агрегирующий альбом, не реальная папка на
    // устройстве — сканер (media_scanner.dart) его сознательно пропускает,
    // поэтому и в выборе он не участвует.
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );
    albums.removeWhere((a) => a.isAll);

    if (mounted) {
      setState(() {
        _albums.addAll(albums);
        _loading = false;
      });
    }
  }

  void _toggle(AssetPathEntity album) {
    setState(() {
      if (!_selected.remove(album.id)) {
        _selected.add(album.id);
      }
    });
  }

  void _done() => Navigator.of(context).pop(_selected.toList());

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.selectSyncFilesTitle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _done,
            child: Text(
              '${t.selectSyncFilesDone} (${_selected.length})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.selectSyncFilesPermissionDenied,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_albums.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _albums.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final album = _albums[index];
        final isSelected = _selected.contains(album.id);
        return ListTile(
          onTap: () => _toggle(album),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: _AlbumThumbnail(album: album),
            ),
          ),
          title: Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snapshot) {
              final count = snapshot.data;
              return Text(count != null ? '$count' : '');
            },
          ),
          trailing: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
        );
      },
    );
  }
}

class _AlbumThumbnail extends StatelessWidget {
  final AssetPathEntity album;

  const _AlbumThumbnail({required this.album});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetEntity>>(
      future: album.getAssetListRange(start: 0, end: 1),
      builder: (context, snapshot) {
        final assets = snapshot.data;
        if (assets == null || assets.isEmpty) {
          return Container(color: Colors.grey.withValues(alpha: 0.15));
        }
        return FutureBuilder<Uint8List?>(
          future: assets.first.thumbnailDataWithSize(const ThumbnailSize(120, 120)),
          builder: (context, thumbSnapshot) {
            if (thumbSnapshot.connectionState != ConnectionState.done ||
                thumbSnapshot.data == null) {
              return Container(color: Colors.grey.withValues(alpha: 0.15));
            }
            return Image.memory(thumbSnapshot.data!, fit: BoxFit.cover);
          },
        );
      },
    );
  }
}
