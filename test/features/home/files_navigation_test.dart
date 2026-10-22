import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_app/core/config/app_config.dart';
import 'package:cloud_app/core/errors/app_exception.dart';
import 'package:cloud_app/core/network/dio_client.dart';
import 'package:cloud_app/features/home/data/home_repository.dart';
import 'package:cloud_app/features/home/data/models/file_model.dart';
import 'package:cloud_app/features/home/data/models/folder_model.dart';
import 'package:cloud_app/features/home/presentation/files_page.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString('[]', 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
  @override
  void close({bool force = false}) {}
}

class _Request {
  _Request(this.folder, this.page);
  final String? folder;
  final int page;
  final result = Completer<Map<String, dynamic>>();
}

class _Repository extends HomeRepository {
  final requests = <_Request>[];
  @override
  Future<Map<String, dynamic>> getContent({String? parentId, int page = 1}) {
    final request = _Request(parentId, page);
    requests.add(request);
    return request.result.future;
  }

  @override
  Future<List<Map<String, dynamic>>> getPinnedFolders() async => [];
}

Map<String, dynamic> _content(List<FolderModel> folders,
        {bool hasNext = false}) =>
    {
      'folders': folders,
      'files': <FileModel>[],
      'hasNext': hasNext,
      'totalCount': folders.length
    };
const _a = FolderModel(id: 'a', name: 'Folder A');
const _b = FolderModel(id: 'b', name: 'Folder B');

Future<void> _mount(
    WidgetTester tester, _Repository repository, GlobalKey<FilesPageState> key,
    {bool parentBack = false}) async {
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PopScope(
      canPop: !parentBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && parentBack) key.currentState!.handleBackNavigation();
      },
      child: FilesPage(
          key: key, repository: repository, handleSystemBack: !parentBack),
    ),
  )));
  await tester.pump();
}

void main() {
  setUpAll(() {
    AppConfig.initialize(Environment.dev);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    DioClient.instance.httpClientAdapter = _Adapter();
    DioClient.instance.interceptors.clear();
  });

  testWidgets('Returning during a load ignores the late folder response',
      (tester) async {
    final repo = _Repository();
    final key = GlobalKey<FilesPageState>();
    await _mount(tester, repo, key);
    repo.requests.first.result.complete(_content([_a]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folder A').first);
    await tester.pump();
    expect(repo.requests.last.folder, 'a');
    final pendingFolder = repo.requests.last;
    expect(key.currentState!.handleBackNavigation(), isTrue);
    await tester.pump();
    expect(repo.requests.last.folder, isNull);
    repo.requests.last.result.complete(_content([_a]));
    await tester.pumpAndSettle();
    pendingFolder.result.complete(_content([_b]));
    await tester.pumpAndSettle();
    expect(find.text('Folder A'), findsWidgets);
    expect(find.text('Folder B'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Parent back handler moves up exactly one folder',
      (tester) async {
    final repo = _Repository();
    final key = GlobalKey<FilesPageState>();
    await _mount(tester, repo, key, parentBack: true);
    repo.requests.last.result.complete(_content([_a]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folder A').first);
    await tester.pump();
    repo.requests.last.result.complete(_content([_b]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folder B').first);
    await tester.pump();
    repo.requests.last.result.complete(_content([]));
    await tester.pumpAndSettle();
    final before = repo.requests.length;
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(repo.requests.length, before + 1);
    expect(repo.requests.last.folder, 'a');
    repo.requests.last.result.complete(_content([_b]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pagination appends folders and ignores duplicate identifiers',
      (tester) async {
    final repo = _Repository();
    final key = GlobalKey<FilesPageState>();
    await _mount(tester, repo, key);
    final folders = List.generate(
        3, (i) => FolderModel(id: 'folder-$i', name: 'Directory $i'));
    repo.requests.last.result.complete(_content(folders, hasNext: true));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find
        .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable))
        .first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    expect(repo.requests.last.page, 2);
    repo.requests.last.result.complete(_content([folders.last, _b]));
    await tester.pumpAndSettle();
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Folder B'), findsOneWidget);
    expect(find.text('Directory 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favourites during loading returns to the pending folder',
      (tester) async {
    final repo = _Repository();
    final key = GlobalKey<FilesPageState>();
    await _mount(tester, repo, key);
    repo.requests.last.result.complete(_content([_a]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folder A').first);
    await tester.pump();
    final pending = repo.requests.last;
    key.currentState!.toggleFavourites();
    await tester.pumpAndSettle();
    pending.result.complete(_content([_b]));
    await tester.pumpAndSettle();
    expect(find.text('Folder B'), findsNothing);
    expect(key.currentState!.handleBackNavigation(), isTrue);
    await tester.pump();
    expect(repo.requests.last.folder, 'a');
    expect(repo.requests.last, isNot(same(pending)));
    repo.requests.last.result.complete(_content([_b]));
    await tester.pumpAndSettle();
    expect(find.text('Folder B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed pagination waits for explicit retry and keeps its page',
      (tester) async {
    final repo = _Repository();
    final key = GlobalKey<FilesPageState>();
    await _mount(tester, repo, key);
    repo.requests.last.result.complete(_content([_a], hasNext: true));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find
        .descendant(of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable))
        .first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    expect(repo.requests.last.page, 2);
    repo.requests.last.result.completeError(
        const AppException(message: 'offline', type: AppExceptionType.network));
    await tester.pumpAndSettle();
    final failedCount = repo.requests.length;
    await tester.pump(const Duration(seconds: 2));
    expect(repo.requests.length, failedCount);
    expect(find.text('Folder A'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repo.requests.length, failedCount + 1);
    expect(repo.requests.last.page, 2);
    repo.requests.last.result.complete(_content([_b]));
    await tester.pumpAndSettle();
    expect(find.text('Folder B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
