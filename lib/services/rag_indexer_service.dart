import 'dart:async';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class RagIndexerService {
  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  /// Slices text into clean chunks of [chunkSize] characters with [overlap] overlap.
  List<String> chunkText(String text, {int chunkSize = 500, int overlap = 100}) {
    if (text.trim().isEmpty) return [];
    if (text.length <= chunkSize) return [text];

    final List<String> chunks = [];
    int start = 0;
    
    while (start < text.length) {
      int end = start + chunkSize;
      if (end > text.length) {
        end = text.length;
      }
      
      chunks.add(text.substring(start, end));
      
      // If we reached the end of the text, exit loop
      if (end == text.length) break;

      // Shift window forward
      start = start + (chunkSize - overlap);

      // Safety fallback: ensure start advances to prevent infinite loop
      if (chunkSize <= overlap) {
        start += chunkSize;
      }
    }
    
    return chunks;
  }

  /// Indexes document contents by chunking and saving to the SQLite database.
  Future<void> indexFile(String fileName, String textContent) async {
    // Delete any existing chunks for this file first to avoid redundant entries
    await _dbService.deleteChunksByFileName(fileName);

    final chunks = chunkText(textContent);
    final List<Map<String, dynamic>> chunksPayload = [];

    for (int i = 0; i < chunks.length; i++) {
      chunksPayload.add({
        'id': _uuid.v4(),
        'file_name': fileName,
        'chunk_index': i,
        'text_content': chunks[i],
      });
    }

    if (chunksPayload.isNotEmpty) {
      await _dbService.insertChunks(chunksPayload);
    }
  }

  /// Queries the SQLite database and finds the top [limit] matching context chunks.
  Future<List<String>> retrieveRelevantChunks(String query, {int limit = 3}) async {
    final allChunks = await _dbService.queryAllChunks();
    if (allChunks.isEmpty || query.trim().isEmpty) return [];

    // Parse query into unique lowercase search tokens longer than 2 characters
    final queryTokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Strip punctuation
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2)
        .toSet()
        .toList();

    if (queryTokens.isEmpty) {
      // Fallback: If query yields no tokens, return first few chunks
      return allChunks
          .take(limit)
          .map((chunk) => chunk['text_content'] as String)
          .toList();
    }

    final List<MapEntry<Map<String, dynamic>, double>> scoredChunks = [];

    for (var chunk in allChunks) {
      final content = chunk['text_content'] as String? ?? '';
      final score = _calculateRelevanceScore(content, queryTokens);
      if (score > 0) {
        scoredChunks.add(MapEntry(chunk, score));
      }
    }

    // Sort scored chunks in descending order of relevance
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    return scoredChunks
        .take(limit)
        .map((entry) => entry.key['text_content'] as String)
        .toList();
  }

  /// Calculates simple token occurrence/frequency matches in a chunk.
  double _calculateRelevanceScore(String textContent, List<String> queryTokens) {
    double score = 0.0;
    final textLower = textContent.toLowerCase();

    for (final token in queryTokens) {
      int count = 0;
      int index = textLower.indexOf(token);
      while (index != -1) {
        count++;
        // Advance search index past matched token
        index = textLower.indexOf(token, index + token.length);
      }
      
      if (count > 0) {
        // Boost matches, adding bonus for repetition
        score += 1.0 + (count * 0.2);
      }
    }
    return score;
  }
}
