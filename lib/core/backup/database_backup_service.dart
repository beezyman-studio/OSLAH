import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../services/database_service.dart';

class DatabaseBackupService {
  static final DatabaseBackupService _instance = DatabaseBackupService._internal();
  factory DatabaseBackupService() => _instance;
  DatabaseBackupService._internal();

  static const String _cipherModeName = 'AES-256 (CBC mode)';

  /// Exports and encrypts the active SQLite database file using AES-256 (CBC)
  Future<File> backupDatabase({
    required String targetDirectoryPath,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError('Master password cannot be empty for backup encryption.');
    }

    final dbService = DatabaseService();
    final dbPath = await dbService.getDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw FileSystemException('Active database file does not exist at $dbPath');
    }

    // Read active database raw bytes
    final rawBytes = await dbFile.readAsBytes();

    // Derive 256-bit Key from the master password using SHA-256
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));

    // Generate random 128-bit Initialization Vector (IV)
    final iv = enc.IV.fromSecureRandom(16);

    // Encrypt raw bytes
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(rawBytes, iv: iv);
    final cipherBytes = encrypted.bytes;

    // Concat: [16 bytes IV] + [encrypted ciphertext]
    final resultBytes = Uint8List(iv.bytes.length + cipherBytes.length);
    resultBytes.setRange(0, iv.bytes.length, iv.bytes);
    resultBytes.setRange(iv.bytes.length, resultBytes.length, cipherBytes);

    // Save with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.').first;
    final backupFileName = 'oslah_backup_$timestamp.enc';
    final targetDir = Directory(targetDirectoryPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    
    final backupFile = File(p.join(targetDir.path, backupFileName));
    await backupFile.writeAsBytes(resultBytes);

    debugPrint('Database backup completed successfully: ${backupFile.path} ($_cipherModeName)');
    return backupFile;
  }

  /// Restores an encrypted backup file, validating its decrypted SQLite integrity first
  Future<void> restoreEncryptedBackup({
    required File encryptedFile,
    required String password,
  }) async {
    if (!await encryptedFile.exists()) {
      throw FileSystemException('Encrypted backup file does not exist', encryptedFile.path);
    }
    if (password.isEmpty) {
      throw ArgumentError('Master password is required for database restoration.');
    }

    final fileBytes = await encryptedFile.readAsBytes();
    if (fileBytes.length <= 16) {
      throw const FormatException('Invalid backup file: Payload length is too short to contain IV header.');
    }

    // Extract IV (first 16 bytes)
    final ivBytes = fileBytes.sublist(0, 16);
    final iv = enc.IV(ivBytes);

    // Extract ciphertext
    final cipherBytes = fileBytes.sublist(16);

    // Derive Key
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));

    // Decrypt ciphertext bytes
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    Uint8List decryptedBytes;
    try {
      final decrypted = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
      decryptedBytes = Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed. Invalid password or corrupted backup payload.');
    }

    // Integrity Validation:
    // Write decrypted bytes to temporary file and execute SQLite PRAGMA integrity check
    final tempDir = Directory.systemTemp;
    final tempDbFile = File(p.join(tempDir.path, 'oslah_restore_val_${DateTime.now().microsecondsSinceEpoch}.db'));
    await tempDbFile.writeAsBytes(decryptedBytes);

    Database? tempDb;
    bool integrityPass = false;
    String validationError = 'Database structure validation failure';

    try {
      tempDb = await openDatabase(tempDbFile.path);
      final integrityCheck = await tempDb.rawQuery('PRAGMA integrity_check;');
      if (integrityCheck.isNotEmpty) {
        final result = integrityCheck.first.values.first as String;
        if (result.toLowerCase() == 'ok') {
          integrityPass = true;
        } else {
          validationError = 'SQLite integrity failed: $result';
        }
      }
    } catch (e) {
      validationError = 'Failed to open decrypted database: $e';
    } finally {
      if (tempDb != null) {
        await tempDb.close();
      }
      if (await tempDbFile.exists()) {
        await tempDbFile.delete();
      }
    }

    if (!integrityPass) {
      throw Exception('Restoration validation blocked: $validationError. Database integrity could not be verified.');
    }

    // Safe Replacement Procedure:
    // 1. Close current connection
    final dbService = DatabaseService();
    await dbService.closeDatabase();

    // 2. Overwrite main active database file path
    final dbPath = await dbService.getDatabasePath();
    final activeDbFile = File(dbPath);
    if (await activeDbFile.exists()) {
      await activeDbFile.delete();
    }
    await activeDbFile.writeAsBytes(decryptedBytes);

    debugPrint('Database restore completed successfully: Active file replaced with valid backup.');
  }
}
