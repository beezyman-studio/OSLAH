import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:oslah/services/database_service.dart';
import 'package:oslah/core/backup/database_backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseBackupService Integration Tests', () {
    final backupService = DatabaseBackupService();
    final dbService = DatabaseService();
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('oslah_backup_tests');

      // Mock path_provider channel to return the absolute temp directory path
      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      });
    });

    tearDownAll(() async {
      await dbService.closeDatabase();
      // Remove path provider mock handler
      const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    setUp(() async {
      // Clear database and recreate tables before each test
      await dbService.closeDatabase();
      final dbPath = await dbService.getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      
      // Seed initial data to database
      final db = await dbService.database;
      await db.insert('agents', {
        'id': 'test_agent',
        'name': 'Backup Test Agent',
        'system_prompt': 'Test Prompt',
        'icon': 'test',
        'description': 'Description'
      });
    });

    test('should successfully encrypt and back up active database', () async {
      final backupFile = await backupService.backupDatabase(
        targetDirectoryPath: tempDir.path,
        password: 'secure_password_123',
      );

      expect(await backupFile.exists(), isTrue);
      expect(p.extension(backupFile.path), equals('.enc'));
      expect(backupFile.lengthSync(), greaterThan(16));
    });

    test('should fail to restore using an incorrect password', () async {
      final backupFile = await backupService.backupDatabase(
        targetDirectoryPath: tempDir.path,
        password: 'secure_password_123',
      );

      expect(
        () async => await backupService.restoreEncryptedBackup(
          encryptedFile: backupFile,
          password: 'wrong_password',
        ),
        throwsA(predicate((e) => e.toString().contains('Decryption failed') || e.toString().contains('integrity'))),
      );
    });

    test('should fail to restore a corrupted backup payload', () async {
      final corruptedFile = File(p.join(tempDir.path, 'corrupted_backup.enc'));
      await corruptedFile.writeAsBytes(List<int>.filled(50, 0xFF));

      expect(
        () async => await backupService.restoreEncryptedBackup(
          encryptedFile: corruptedFile,
          password: 'secure_password_123',
        ),
        throwsA(anything),
      );
    });

    test('should successfully restore and verify database records', () async {
      // 1. Create a backup of the current database state (contains 'test_agent')
      final backupFile = await backupService.backupDatabase(
        targetDirectoryPath: tempDir.path,
        password: 'master_password',
      );

      // 2. Modify active database (insert a new agent 'other_agent')
      final db = await dbService.database;
      await db.insert('agents', {
        'id': 'other_agent',
        'name': 'Other Agent',
        'system_prompt': 'Other Prompt',
        'icon': 'other',
        'description': 'Other Description'
      });

      // Confirm 'other_agent' is present in active database
      var activeAgents = await db.query('agents');
      expect(activeAgents.length, equals(2));

      // 3. Restore the backup
      await backupService.restoreEncryptedBackup(
        encryptedFile: backupFile,
        password: 'master_password',
      );

      // 4. Query the database after restore (should only contain 'test_agent')
      final restoredDb = await dbService.database;
      var restoredAgents = await restoredDb.query('agents');
      
      expect(restoredAgents.length, equals(1));
      expect(restoredAgents.first['id'], equals('test_agent'));
    });
  });
}
