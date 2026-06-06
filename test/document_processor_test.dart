import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oslah/core/rag/document_processor.dart';

void main() {
  group('DocumentProcessor Unit Tests', () {
    late DocumentProcessor processor;
    late Directory tempDir;
    late String txtFilePath;
    late String mdFilePath;
    late String unsupportedFilePath;

    setUp(() async {
      processor = DocumentProcessor();
      processor.clearDatabase();

      // Create a temporary workspace for test documents
      tempDir = await Directory.systemTemp.createTemp('oslah_rag_tests');
      
      txtFilePath = '${tempDir.path}/test_doc.txt';
      await File(txtFilePath).writeAsString(
        'OSLAH is a local-first desktop application designed by Beezyman Studio. '
        'It integrates local LLMs such as DeepSeek and Llama using Ollama. '
        'Hardware monitoring dashboards show CPU and RAM allocations. '
        'All data stays local, private, and secure inside an SQLite database.'
      );

      mdFilePath = '${tempDir.path}/test_guide.md';
      await File(mdFilePath).writeAsString(
        '# OSLAH Quick Start Guide\n\n'
        '1. Install Ollama from the official website.\n'
        '2. Run `ollama run deepseek-r1:7b` to pull the inference weights.\n'
        '3. Launch the OSLAH desktop application built using Flutter.\n'
        '4. Expose the server to the office LAN using the Enterprise Pro package.'
      );

      unsupportedFilePath = '${tempDir.path}/test_data.csv';
      await File(unsupportedFilePath).writeAsString('id,name,value\n1,test,100');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should slice txt file content and generate chunks with mock embeddings', () async {
      final chunks = await processor.processFile(txtFilePath, chunkSize: 100, overlap: 20);

      expect(chunks, isNotEmpty);
      expect(chunks.first.documentId, equals(txtFilePath));
      expect(chunks.first.mockEmbedding.length, equals(128));

      // Test that the mock embedding magnitude is normalised close to 1.0
      double sumOfSquares = 0.0;
      for (var val in chunks.first.mockEmbedding) {
        sumOfSquares += val * val;
      }
      expect(sumOfSquares, closeTo(1.0, 0.001));

      expect(processor.mockVectorDb.containsKey(txtFilePath), isTrue);
      expect(processor.mockVectorDb[txtFilePath]!.length, equals(chunks.length));
    });

    test('should retrieve relevant chunks based on token overlaps', () async {
      // Index both files
      await processor.processFile(txtFilePath, chunkSize: 150, overlap: 30);
      await processor.processFile(mdFilePath, chunkSize: 150, overlap: 30);

      // Search for query relating to Beezyman / SQLite
      final query = 'Beezyman Studio SQLite';
      final matches = processor.retrieveSimilarChunks(query, limit: 1);

      expect(matches, isNotEmpty);
      expect(matches.first.documentId, equals(txtFilePath));
      expect(matches.first.textContent.contains('Beezyman') || matches.first.textContent.contains('SQLite'), isTrue);

      // Search for query relating to Ollama setup
      final query2 = 'Ollama setup run';
      final matches2 = processor.retrieveSimilarChunks(query2, limit: 1);

      expect(matches2, isNotEmpty);
      expect(matches2.first.documentId, equals(mdFilePath));
      expect(matches2.first.textContent.contains('Ollama') || matches2.first.textContent.contains('run'), isTrue);
    });

    test('should fail to process unsupported file formats or missing files', () async {
      expect(
        () => processor.processFile(unsupportedFilePath),
        throwsA(predicate((e) => e.toString().contains('Unsupported file format'))),
      );

      expect(
        () => processor.processFile('${tempDir.path}/non_existent.txt'),
        throwsA(predicate((e) => e.toString().contains('File not found'))),
      );
    });
  });
}
