import 'dart:io';
import 'dart:math';

class DocumentChunk {
  final String id;
  final String documentId;
  final String textContent;
  final List<double> mockEmbedding;

  DocumentChunk({
    required this.id,
    required this.documentId,
    required this.textContent,
    required this.mockEmbedding,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentId': documentId,
        'textContent': textContent,
        'mockEmbedding': mockEmbedding,
      };
}

class DocumentProcessor {
  static final DocumentProcessor _instance = DocumentProcessor._internal();
  factory DocumentProcessor() => _instance;
  DocumentProcessor._internal();

  // Local Memory Map representing Mock Vector Database
  // Key: Document Path / ID
  // Value: List of parsed DocumentChunks
  final Map<String, List<DocumentChunk>> _mockVectorDb = {};

  Map<String, List<DocumentChunk>> get mockVectorDb => Map.unmodifiable(_mockVectorDb);

  /// Helper to generate a 128-dimensional mock embedding based on character distribution.
  List<double> _generateMockEmbedding(String text) {
    final List<double> embedding = List.filled(128, 0.0);
    if (text.isEmpty) return embedding;

    // A clean deterministic mock mapping based on text character occurrences
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      final index = (codeUnit * (i + 1)) % 128;
      embedding[index] += 1.0;
    }

    // Normalise vector to unit length
    double sumOfSquares = 0.0;
    for (var val in embedding) {
      sumOfSquares += val * val;
    }
    final double magnitude = sqrt(sumOfSquares);
    if (magnitude > 0) {
      for (int i = 0; i < 128; i++) {
        embedding[i] /= magnitude;
      }
    }
    return embedding;
  }

  /// Extracts text chunks from a .txt or .md file.
  /// Slices content into blocks of [chunkSize] characters with [overlap] character overlap.
  Future<List<DocumentChunk>> processFile(String filePath, {int chunkSize = 500, int overlap = 100}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final String extension = filePath.split('.').last.toLowerCase();
    if (extension != 'txt' && extension != 'md') {
      throw Exception('Unsupported file format: Only .txt and .md files are supported.');
    }

    String textContent;
    try {
      textContent = await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file content: $e');
    }

    final chunks = <DocumentChunk>[];
    if (textContent.trim().isEmpty) return chunks;

    int start = 0;
    int index = 0;
    while (start < textContent.length) {
      int end = start + chunkSize;
      if (end > textContent.length) {
        end = textContent.length;
      }

      final chunkText = textContent.substring(start, end);
      final embedding = _generateMockEmbedding(chunkText);

      chunks.add(DocumentChunk(
        id: '${filePath}_chunk_$index',
        documentId: filePath,
        textContent: chunkText,
        mockEmbedding: embedding,
      ));

      if (end == textContent.length) break;

      start += (chunkSize - overlap);
      if (chunkSize <= overlap) {
        start += chunkSize; // Fallback to prevent infinite loops
      }
      index++;
    }

    _mockVectorDb[filePath] = chunks;
    return chunks;
  }

  /// Retrieves chunks from the memory database that are most relevant to the query.
  /// Uses a lightweight text-similarity match (mock cosine similarity matching).
  List<DocumentChunk> retrieveSimilarChunks(String query, {int limit = 3}) {
    if (query.trim().isEmpty || _mockVectorDb.isEmpty) return [];

    final queryTokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2)
        .toSet()
        .toList();

    final scoredChunks = <MapEntry<DocumentChunk, double>>[];

    _mockVectorDb.forEach((docId, chunks) {
      for (var chunk in chunks) {
        double score = 0.0;
        final textLower = chunk.textContent.toLowerCase();

        for (final token in queryTokens) {
          int count = 0;
          int index = textLower.indexOf(token);
          while (index != -1) {
            count++;
            index = textLower.indexOf(token, index + token.length);
          }

          if (count > 0) {
            score += 1.0 + (count * 0.2);
          }
        }

        if (score > 0) {
          scoredChunks.add(MapEntry(chunk, score));
        }
      }
    });

    // Sort scored chunks descending
    scoredChunks.sort((a, b) => b.value.compareTo(a.value));

    return scoredChunks.take(limit).map((entry) => entry.key).toList();
  }

  /// Clears the memory index vector database.
  void clearDatabase() {
    _mockVectorDb.clear();
  }
}
