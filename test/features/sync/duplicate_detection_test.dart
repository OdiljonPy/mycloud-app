import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:cloud_app/features/sync/data/sync_queue_db.dart';
import 'package:cloud_app/features/sync/data/sync_task.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Dublikat Tekshirish Testi', () {
    late SyncQueueDb db;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('test_sync_db');
      db = SyncQueueDb();
      await db.init();
    });

    tearDown(() async {
      await db.reset();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Test 1: Bir xil hash + size + mime → Dublikat aniqlanishi kerak', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final task1 = SyncTask(
        localId: 'test_image_1',
        filePath: '/path/to/image1.jpg',
        fileName: 'image1.jpg',
        fileSize: 1024000,
        mimeType: 'image/jpeg',
        sha256: 'abc123hash',
        status: SyncStatus.done,
        createdAt: now,
        updatedAt: now,
      );

      print('✅ Test 1: Birinchi faylni qo\'shamiz (done holatida)');
      await db.insertOrIgnore(task1);

      print('🔍 Test 1: Bir xil hash + size + mime bilan tekshirish...');
      final isDuplicate = await db.isDoneByFingerprint(
        sha256: 'abc123hash',
        fileSize: 1024000,
        mimeType: 'image/jpeg',
      );

      print('📊 Test 1: Natija: ${isDuplicate ? "DUBLIKAT" : "YANGI"}');
      expect(isDuplicate, true, reason: 'Bir xil fingerprint → dublikat bo\'lishi kerak');
    });

    test('Test 2: Bir xil hash, lekin boshqa size → Dublikat EMAS', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final task1 = SyncTask(
        localId: 'test_image_2',
        filePath: '/path/to/image2.jpg',
        fileName: 'image2.jpg',
        fileSize: 1024000,
        mimeType: 'image/jpeg',
        sha256: 'xyz789hash',
        status: SyncStatus.done,
        createdAt: now,
        updatedAt: now,
      );

      print('✅ Test 2: Birinchi faylni qo\'shamiz');
      await db.insertOrIgnore(task1);

      print('🔍 Test 2: Bir xil hash, lekin boshqa size bilan tekshirish...');
      final isDuplicate = await db.isDoneByFingerprint(
        sha256: 'xyz789hash',
        fileSize: 512000,  // Boshqa size!
        mimeType: 'image/jpeg',
      );

      print('📊 Test 2: Natija: ${isDuplicate ? "DUBLIKAT" : "YANGI"}');
      expect(isDuplicate, false, reason: 'Boshqa size → dublikat bo\'lmasligi kerak');
    });

    test('Test 3: Bir xil hash + size, lekin boshqa mime → Dublikat EMAS', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final task1 = SyncTask(
        localId: 'test_image_3',
        filePath: '/path/to/image3.jpg',
        fileName: 'image3.jpg',
        fileSize: 2048000,
        mimeType: 'image/jpeg',
        sha256: 'def456hash',
        status: SyncStatus.done,
        createdAt: now,
        updatedAt: now,
      );

      print('✅ Test 3: JPEG faylni qo\'shamiz');
      await db.insertOrIgnore(task1);

      print('🔍 Test 3: Bir xil hash + size, lekin PNG mime bilan tekshirish...');
      final isDuplicate = await db.isDoneByFingerprint(
        sha256: 'def456hash',
        fileSize: 2048000,
        mimeType: 'image/png',  // Boshqa mime type!
      );

      print('📊 Test 3: Natija: ${isDuplicate ? "DUBLIKAT" : "YANGI"}');
      expect(isDuplicate, false, reason: 'Boshqa mime-type → dublikat bo\'lmasligi kerak');
    });

    test('Test 4: Video va Image bir xil hash → Dublikat EMAS (mime farqi)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final videoTask = SyncTask(
        localId: 'test_video_1',
        filePath: '/path/to/video.mp4',
        fileName: 'video.mp4',
        fileSize: 5000000,
        mimeType: 'video/mp4',
        sha256: 'same_hash_123',
        status: SyncStatus.done,
        createdAt: now,
        updatedAt: now,
      );

      print('✅ Test 4: Video faylni qo\'shamiz');
      await db.insertOrIgnore(videoTask);

      print('🔍 Test 4: Bir xil hash bilan image tekshirish...');
      final isDuplicate = await db.isDoneByFingerprint(
        sha256: 'same_hash_123',
        fileSize: 5000000,
        mimeType: 'image/jpeg',  // Video emas, image!
      );

      print('📊 Test 4: Natija: ${isDuplicate ? "DUBLIKAT" : "YANGI"}');
      expect(isDuplicate, false, reason: 'Video vs Image → dublikat bo\'lmasligi kerak');
    });

    test('Test 5: Pending status → Dublikat EMAS (faqat done tekshiriladi)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final pendingTask = SyncTask(
        localId: 'test_pending',
        filePath: '/path/to/pending.jpg',
        fileName: 'pending.jpg',
        fileSize: 3000000,
        mimeType: 'image/jpeg',
        sha256: 'pending_hash',
        status: SyncStatus.pending,  // PENDING!
        createdAt: now,
        updatedAt: now,
      );

      print('✅ Test 5: Pending status faylni qo\'shamiz');
      await db.insertOrIgnore(pendingTask);

      print('🔍 Test 5: Bir xil fingerprint bilan tekshirish (lekin pending)...');
      final isDuplicate = await db.isDoneByFingerprint(
        sha256: 'pending_hash',
        fileSize: 3000000,
        mimeType: 'image/jpeg',
      );

      print('📊 Test 5: Natija: ${isDuplicate ? "DUBLIKAT" : "YANGI"}');
      expect(isDuplicate, false, reason: 'Pending status → dublikat sanalmasligi kerak (faqat done)');
    });

    test('Test 6: Eski isDoneByHash vs Yangi isDoneByFingerprint farqi', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final task = SyncTask(
        localId: 'test_comparison',
        filePath: '/path/to/comparison.jpg',
        fileName: 'comparison.jpg',
        fileSize: 4000000,
        mimeType: 'image/jpeg',
        sha256: 'comparison_hash',
        status: SyncStatus.done,
        createdAt: now,
        updatedAt: now,
      );

      print('✅ Test 6: Test faylni qo\'shamiz');
      await db.insertOrIgnore(task);

      print('🔍 Test 6: Eski usul (faqat hash)...');
      final oldMethod = await db.isDoneByHash('comparison_hash');
      print('   Eski usul natija: ${oldMethod ? "DUBLIKAT" : "YANGI"}');

      print('🔍 Test 6: Yangi usul (hash + size + mime)...');
      final newMethodCorrect = await db.isDoneByFingerprint(
        sha256: 'comparison_hash',
        fileSize: 4000000,
        mimeType: 'image/jpeg',
      );
      print('   Yangi usul (to\'g\'ri): ${newMethodCorrect ? "DUBLIKAT" : "YANGI"}');

      print('🔍 Test 6: Yangi usul (hash to\'g\'ri, lekin size noto\'g\'ri)...');
      final newMethodWrongSize = await db.isDoneByFingerprint(
        sha256: 'comparison_hash',
        fileSize: 9999999,  // Noto'g'ri size
        mimeType: 'image/jpeg',
      );
      print('   Yangi usul (noto\'g\'ri size): ${newMethodWrongSize ? "DUBLIKAT" : "YANGI"}');

      expect(oldMethod, true, reason: 'Eski usul: faqat hash tekshiradi');
      expect(newMethodCorrect, true, reason: 'Yangi usul (to\'g\'ri): dublikat bo\'lishi kerak');
      expect(newMethodWrongSize, false, reason: 'Yangi usul (noto\'g\'ri): dublikat bo\'lmasligi kerak');
    });

    test('Test 7: Ko\'p fayllar - performance test', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      print('✅ Test 7: 100 ta fayl qo\'shamiz...');
      for (int i = 0; i < 100; i++) {
        await db.insertOrIgnore(SyncTask(
          localId: 'bulk_test_$i',
          filePath: '/path/to/file_$i.jpg',
          fileName: 'file_$i.jpg',
          fileSize: 1000000 + i,
          mimeType: 'image/jpeg',
          sha256: 'hash_$i',
          status: SyncStatus.done,
          createdAt: now,
          updatedAt: now,
        ));
      }

      print('🔍 Test 7: 100 ta dublikat tekshirish...');
      final stopwatch = Stopwatch()..start();

      int duplicateCount = 0;
      for (int i = 0; i < 100; i++) {
        final isDup = await db.isDoneByFingerprint(
          sha256: 'hash_$i',
          fileSize: 1000000 + i,
          mimeType: 'image/jpeg',
        );
        if (isDup) duplicateCount++;
      }

      stopwatch.stop();
      print('📊 Test 7: 100 ta tekshirish: ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Test 7: Dublikat topildi: $duplicateCount/100');

      expect(duplicateCount, 100, reason: 'Barcha 100 ta dublikat bo\'lishi kerak');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
             reason: 'Performance: 5 soniyadan kam bo\'lishi kerak');
    });
  });

  group('Debug Log Testlari', () {
    test('Test 8: Debug log\'lar ishlashini tekshirish', () async {
      print('\n═══════════════════════════════════════════');
      print('🐛 DEBUG LOG TEST');
      print('═══════════════════════════════════════════');

      final db = SyncQueueDb();
      await db.init();

      final now = DateTime.now().millisecondsSinceEpoch;
      final testTask = SyncTask(
        localId: 'debug_test',
        filePath: '/debug/path.jpg',
        fileName: 'debug.jpg',
        fileSize: 123456,
        mimeType: 'image/jpeg',
        sha256: 'debug_hash_xyz',
        status: SyncStatus.done,
        createdAt: now,
        updatedAt: now,
      );

      print('📝 Fayl qo\'shilmoqda: ${testTask.fileName}');
      print('   - SHA256: ${testTask.sha256}');
      print('   - Size: ${testTask.fileSize} bytes');
      print('   - MIME: ${testTask.mimeType}');

      await db.insertOrIgnore(testTask);

      print('\n🔍 Dublikat tekshirish boshlanmoqda...');
      final result = await db.isDoneByFingerprint(
        sha256: testTask.sha256!,
        fileSize: testTask.fileSize,
        mimeType: testTask.mimeType,
      );

      if (result) {
        print('✅ NATIJA: DUBLIKAT topildi!');
      } else {
        print('❌ NATIJA: Dublikat yo\'q (YANGI fayl)');
      }

      print('═══════════════════════════════════════════\n');

      await db.reset();
      expect(result, true);
    });
  });
}