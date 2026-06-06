// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'query',
      abbr: 'q',
      help: 'The query to send to the local RAG engine.',
    )
    ..addOption(
      'key',
      abbr: 'k',
      help: 'The secure OSLAH API Key / authorization token.',
    )
    ..addOption(
      'filter',
      abbr: 'f',
      help: 'Optional document filter keyword to restrict document sources.',
    )
    ..addOption(
      'url',
      abbr: 'u',
      defaultsTo: 'http://localhost:8080/api/local-rag',
      help: 'Local server endpoint URL.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Prints usage instructions.',
    );

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    print('\x1B[31m[Error] Invalid command line options: ${e.message}\x1B[0m');
    print(parser.usage);
    exit(1);
  }

  if (results['help'] as bool) {
    print('\x1B[33m=== OSLAH CLI Tool ===\x1B[0m');
    print('Command line utility to query the local OSLAH RAG endpoint.\n');
    print(parser.usage);
    exit(0);
  }

  final query = results['query'] as String?;
  final key = results['key'] as String?;
  final filter = results['filter'] as String?;
  final url = results['url'] as String;

  if (query == null || query.trim().isEmpty) {
    print('\x1B[31m[Error] The query parameter (--query or -q) is required.\x1B[0m\n');
    print(parser.usage);
    exit(1);
  }

  print('\x1B[36m⚡ Connecting to OSLAH Local RAG Server...\x1B[0m');
  print('\x1B[36mQuery: "$query"\x1B[0m');
  if (filter != null) {
    print('\x1B[36mDocument Filter: "$filter"\x1B[0m');
  }
  print('');

  final headers = <String, String>{
    'Content-Type': 'application/json',
  };
  if (key != null && key.isNotEmpty) {
    headers['X-OSLAH-Key'] = key;
  }

  final body = <String, dynamic>{
    'query': query,
  };
  if (filter != null && filter.isNotEmpty) {
    body['documentFilter'] = filter;
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final answer = data['answer'] as String? ?? 'No response answer generated.';
      final sources = data['sources'] as List<dynamic>? ?? [];

      print('\x1B[32m=== ANSWER ===\x1B[0m');
      print(answer);
      print('');

      print('\x1B[33m=== SOURCES USED ===\x1B[0m');
      if (sources.isEmpty) {
        print('No matching knowledge base documents were used as context.');
      } else {
        for (var i = 0; i < sources.length; i++) {
          final source = sources[i] as Map<String, dynamic>;
          final docName = source['document'] ?? 'Unknown Document';
          final chunkId = source['chunkId'] ?? 'N/A';
          print('${i + 1}. \x1B[33m$docName\x1B[0m (Chunk ID: $chunkId)');
        }
      }
      print('====================');
    } else {
      print('\x1B[31m[Server Error: ${response.statusCode}]\x1B[0m');
      try {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        print(errData['error'] ?? response.body);
      } catch (_) {
        print(response.body);
      }
      exit(1);
    }
  } on SocketException catch (e) {
    print('\x1B[31m[Network Connection Offline]\x1B[0m');
    print('Could not establish connection to the OSLAH server at $url.');
    print('Please check that the OSLAH desktop application or server background process is active and running.');
    print('Details: ${e.message}');
    exit(1);
  } catch (e) {
    print('\x1B[31m[Execution Error] Failed to complete RAG request:\x1B[0m');
    print(e);
    exit(1);
  }
}
