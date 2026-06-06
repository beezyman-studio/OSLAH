import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Gets or initializes the SQLite database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocDir.path, 'oslah.db');

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        // Create tables
        await db.execute('''
          CREATE TABLE network_settings (
            host TEXT,
            port INTEGER,
            server_status INTEGER,
            first_launch INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE knowledge_chunks (
            id TEXT PRIMARY KEY,
            file_name TEXT,
            chunk_index INTEGER,
            text_content TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE agents (
            id TEXT PRIMARY KEY,
            name TEXT,
            system_prompt TEXT,
            icon TEXT,
            description TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE access_logs (
            id TEXT PRIMARY KEY,
            client_ip TEXT,
            timestamp TEXT,
            bytes_processed INTEGER,
            endpoint TEXT,
            status_code INTEGER,
            authenticated INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        // Insert initial default configuration settings
        await db.insert('network_settings', {
          'host': '0.0.0.0',
          'port': 8080,
          'server_status': 0, // 0 = stopped, 1 = running
          'first_launch': 1,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE network_settings ADD COLUMN first_launch INTEGER DEFAULT 1');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute('''
              CREATE TABLE app_metadata (
                key TEXT PRIMARY KEY,
                value TEXT
              )
            ''');
          } catch (_) {}
        }
      },
    );
  }

  // --- Network Settings CRUD ---

  /// Returns the current network server settings configuration.
  Future<Map<String, dynamic>> getNetworkSettings() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('network_settings', limit: 1);
      if (maps.isNotEmpty) {
        return maps.first;
      }
    } catch (e) {
      debugPrint('Database error reading network settings: $e');
    }
    // Return default values in case of any database read failures
    return {'host': '0.0.0.0', 'port': 8080, 'server_status': 0};
  }

  /// Updates the database server network settings.
  Future<void> updateNetworkSettings(String host, int port, int serverStatus) async {
    final db = await database;
    try {
      await db.update(
        'network_settings',
        {
          'host': host.trim(),
          'port': port,
          'server_status': serverStatus,
        },
      );
    } catch (e) {
      debugPrint('Database error updating network settings: $e');
    }
  }

  // --- Knowledge Chunks CRUD ---

  /// Batches inserting RAG chunks in a single transaction for efficiency.
  Future<void> insertChunks(List<Map<String, dynamic>> chunks) async {
    final db = await database;
    try {
      final batch = db.batch();
      for (var chunk in chunks) {
        batch.insert(
          'knowledge_chunks',
          {
            'id': chunk['id'],
            'file_name': chunk['file_name'],
            'chunk_index': chunk['chunk_index'],
            'text_content': chunk['text_content'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Database error inserting knowledge chunks: $e');
    }
  }

  /// Deletes knowledge chunks linked to a specific file.
  Future<void> deleteChunksByFileName(String fileName) async {
    final db = await database;
    try {
      await db.delete(
        'knowledge_chunks',
        where: 'file_name = ?',
        whereArgs: [fileName],
      );
    } catch (e) {
      debugPrint('Database error deleting file chunks: $e');
    }
  }

  /// Queries all knowledge chunks stored in the database.
  Future<List<Map<String, dynamic>>> queryAllChunks() async {
    final db = await database;
    try {
      return await db.query('knowledge_chunks');
    } catch (e) {
      debugPrint('Database error querying chunks: $e');
      return [];
    }
  }

  /// Clears all chunks from database.
  Future<void> clearAllChunks() async {
    final db = await database;
    try {
      await db.delete('knowledge_chunks');
    } catch (e) {
      debugPrint('Database error clearing chunks: $e');
    }
  }

  // --- Access Logs CRUD ---

  /// Inserts a new access log record.
  Future<void> insertAccessLog({
    required String clientIp,
    required String endpoint,
    required int bytesProcessed,
    required int statusCode,
    required bool authenticated,
  }) async {
    final db = await database;
    try {
      final logId = DateTime.now().microsecondsSinceEpoch.toString();
      await db.insert('access_logs', {
        'id': logId,
        'client_ip': clientIp,
        'timestamp': DateTime.now().toIso8601String(),
        'bytes_processed': bytesProcessed,
        'endpoint': endpoint,
        'status_code': statusCode,
        'authenticated': authenticated ? 1 : 0,
      });
    } catch (e) {
      debugPrint('Database error inserting access log: $e');
    }
  }

  /// Queries all access logs, ordered by newest first.
  Future<List<Map<String, dynamic>>> queryAccessLogs() async {
    final db = await database;
    try {
      return await db.query('access_logs', orderBy: 'timestamp DESC');
    } catch (e) {
      debugPrint('Database error querying access logs: $e');
      return [];
    }
  }

  /// Clears all access logs from database.
  Future<void> clearAccessLogs() async {
    final db = await database;
    try {
      await db.delete('access_logs');
    } catch (e) {
      debugPrint('Database error clearing access logs: $e');
    }
  }

  /// Returns whether this is the first launch of the application.
  Future<bool> checkFirstLaunch() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('network_settings', limit: 1);
      if (maps.isNotEmpty) {
        return (maps.first['first_launch'] as int? ?? 1) == 1;
      }
    } catch (e) {
      debugPrint('Database error checking first launch: $e');
    }
    return true;
  }

  /// Sets the first launch setting to completed (first_launch = 0).
  Future<void> completeFirstLaunch() async {
    final db = await database;
    try {
      await db.update(
        'network_settings',
        {'first_launch': 0},
      );
    } catch (e) {
      debugPrint('Database error completing first launch: $e');
    }
  }

  // --- App Metadata KV CRUD ---
  Future<void> setMetadataValue(String key, String value) async {
    final db = await database;
    try {
      await db.insert(
        'app_metadata',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Database error updating metadata: $e');
    }
  }

  Future<String?> getMetadataValue(String key) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }
    } catch (e) {
      debugPrint('Database error reading metadata: $e');
    }
    return null;
  }

  /// Exposes the absolute path to the SQLite database file
  Future<String> getDatabasePath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return p.join(appDocDir.path, 'oslah.db');
  }

  /// Closes the active database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      try {
        await _database!.close();
        _database = null;
        debugPrint('SQLite active connection closed successfully.');
      } catch (e) {
        debugPrint('Database error closing connection: $e');
      }
    }
  }
}
