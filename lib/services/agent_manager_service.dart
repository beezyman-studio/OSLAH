import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_service.dart';

class CustomAgent {
  final String id;
  final String name;
  final String systemPrompt;
  final String icon;
  final String description;

  CustomAgent({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.icon,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'system_prompt': systemPrompt,
      'icon': icon,
      'description': description,
    };
  }

  factory CustomAgent.fromMap(Map<String, dynamic> map) {
    return CustomAgent(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      systemPrompt: map['system_prompt'] as String? ?? '',
      icon: map['icon'] as String? ?? 'smart',
      description: map['description'] as String? ?? '',
    );
  }
}

class AgentManagerService {
  static final AgentManagerService _instance = AgentManagerService._internal();
  factory AgentManagerService() => _instance;
  AgentManagerService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Inserts or replaces a custom agent configuration in SQLite.
  Future<void> createAgent(CustomAgent agent) async {
    final db = await _dbService.database;
    try {
      await db.insert(
        'agents',
        agent.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error creating agent: $e');
    }
  }

  /// Retrieves all custom agents stored in the database.
  Future<List<CustomAgent>> getAllAgents() async {
    final db = await _dbService.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('agents');
      return maps.map((map) => CustomAgent.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error querying agents: $e');
      return [];
    }
  }

  /// Updates an existing custom agent configuration in SQLite.
  Future<void> updateAgent(CustomAgent agent) async {
    final db = await _dbService.database;
    try {
      await db.update(
        'agents',
        agent.toMap(),
        where: 'id = ?',
        whereArgs: [agent.id],
      );
    } catch (e) {
      debugPrint('Error updating agent: $e');
    }
  }

  /// Deletes a custom agent from database.
  Future<void> deleteAgent(String id) async {
    final db = await _dbService.database;
    try {
      await db.delete(
        'agents',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting agent: $e');
    }
  }
}
