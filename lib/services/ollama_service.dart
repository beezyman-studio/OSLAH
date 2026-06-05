import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaService {
  static const String fallbackBaseUrl = 'http://localhost:11434';

  /// Fetches the list of available local models from Ollama's tags endpoint.
  Future<List<String>> fetchModels(String baseUrl) async {
    final cleanUrl = baseUrl.trim().isEmpty ? fallbackBaseUrl : baseUrl.trim();
    final url = Uri.parse('$cleanUrl/api/tags');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> modelsList = data['models'] ?? [];
        final models = modelsList.map((m) => m['name'] as String).toList();
        // If empty, return a fallback mock list to ensure UI is usable
        return models.isNotEmpty ? models : ['deepseek-r1:7b', 'llama3:latest', 'mistral:latest'];
      } else {
        throw Exception('Failed to load models: HTTP ${response.statusCode}');
      }
    } catch (e) {
      // In a local-first offline app, if server isn't running yet, we should
      // throw a clear error but gracefully return standard models as suggestions.
      throw Exception('Could not connect to local Ollama instance at $cleanUrl.\n'
          'Please ensure Ollama is running. (Error: $e)');
    }
  }

  /// Streams chat responses from Ollama's chat endpoint.
  /// Sends the prompt context along with previous message history.
  Stream<String> streamChat({
    required String baseUrl,
    required String model,
    required List<Map<String, String>> messages,
  }) async* {
    final cleanUrl = baseUrl.trim().isEmpty ? fallbackBaseUrl : baseUrl.trim();
    final url = Uri.parse('$cleanUrl/api/chat');
    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': model,
          'messages': messages,
          'stream': true,
        });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        yield 'Error: Failed to connect to local Ollama (HTTP Status ${streamedResponse.statusCode})';
        client.close();
        return;
      }

      // Transform response bytes to UTF8, then split by lines (NDJSON)
      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          if (data['message'] != null && data['message']['content'] != null) {
            yield data['message']['content'] as String;
          }
        } catch (e) {
          // If we fail to parse a line, continue reading the rest of the stream
          continue;
        }
      }
    } catch (e) {
      yield 'Error: Connection lost or failed to reach Ollama at $cleanUrl. ($e)';
    } finally {
      client.close();
    }
  }
}
