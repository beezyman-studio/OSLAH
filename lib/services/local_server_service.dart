import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/rag/document_processor.dart';
import 'database_service.dart';
import 'queue_manager.dart';
import 'rag_indexer_service.dart';

class ActiveRequestInfo {
  final String id;
  final String clientIp;
  final String model;
  final DateTime requestedAt;

  ActiveRequestInfo({
    required this.id,
    required this.clientIp,
    required this.model,
    required this.requestedAt,
  });
}

class LocalServerService {
  static final LocalServerService _instance = LocalServerService._internal();
  factory LocalServerService() => _instance;
  LocalServerService._internal();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 8080;
  String _host = '0.0.0.0';
  String _ollamaUrl = 'http://localhost:11434';

  bool get isRunning => _isRunning;
  int get port => _port;
  String get host => _host;

  final QueueManager _queueManager = QueueManager();
  final RagIndexerService _ragIndexer = RagIndexerService();
  final DatabaseService _dbService = DatabaseService();

  // Stream of active requests for the UI to monitor incoming traffic
  final StreamController<List<ActiveRequestInfo>> _requestsController = 
      StreamController<List<ActiveRequestInfo>>.broadcast();
  Stream<List<ActiveRequestInfo>> get requestsStream => _requestsController.stream;

  final List<ActiveRequestInfo> _activeRequests = [];
  List<ActiveRequestInfo> get activeRequests => _activeRequests;

  /// Starts the HTTP Server on the specified host and port.
  Future<void> start({
    required String host,
    required int port,
    required String ollamaUrl,
    String? apiKey,
  }) async {
    if (_isRunning) return;

    _host = host;
    _port = port;
    _ollamaUrl = ollamaUrl;

    try {
      _server = await HttpServer.bind(_host, _port, shared: true);
      _isRunning = true;
      _listen(apiKey);
    } catch (e) {
      _isRunning = false;
      _server = null;
      rethrow;
    }
  }

  /// Stops the running HTTP Server.
  Future<void> stop() async {
    if (!_isRunning) return;
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _activeRequests.clear();
    _requestsController.add([]);
  }

  void _listen(String? apiKey) {
    _server?.listen(
      (HttpRequest request) async {
        // Configure CORS headers
        request.response.headers
          ..add('Access-Control-Allow-Origin', '*')
          ..add('Access-Control-Allow-Methods', 'POST, OPTIONS')
          ..add('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-OSLAH-Key');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        if (request.uri.path == '/api/chat' && request.method == 'POST') {
          await _handleChatRequest(request, apiKey);
        } else if (request.uri.path == '/api/local-rag' && request.method == 'POST') {
          await _handleLocalRagRequest(request, apiKey);
        } else {
          final clientIp = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
          request.response.statusCode = HttpStatus.notFound;
          request.response.headers.contentType = ContentType.json;
          final errorBody = jsonEncode({'error': 'API Endpoint not found'});
          request.response.write(errorBody);
          await request.response.close();

          await _dbService.insertAccessLog(
            clientIp: clientIp,
            endpoint: request.uri.path,
            bytesProcessed: errorBody.length,
            statusCode: HttpStatus.notFound,
            authenticated: false,
          );
        }
      },
      onError: (error) {
        debugPrint('Local Server Listen Error: $error');
      },
    );
  }

  Future<void> _handleChatRequest(HttpRequest request, String? apiKey) async {
    final response = request.response;
    final clientIp = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
    int statusCode = HttpStatus.ok;
    int bytesProcessed = 0;
    bool authenticated = true;

    // Secure token verification
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      final authHeader = request.headers.value('Authorization') ?? '';
      final customHeader = request.headers.value('X-OSLAH-Key') ?? '';
      final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;

      if (token != apiKey && customHeader != apiKey) {
        statusCode = HttpStatus.unauthorized;
        authenticated = false;
        response.statusCode = HttpStatus.unauthorized;
        response.headers.contentType = ContentType.json;
        final errBody = jsonEncode({'error': 'Unauthorized: Invalid OSLAH API Key'});
        bytesProcessed += errBody.length;
        response.write(errBody);
        await response.close();

        await _dbService.insertAccessLog(
          clientIp: clientIp,
          endpoint: '/api/chat',
          bytesProcessed: bytesProcessed,
          statusCode: statusCode,
          authenticated: authenticated,
        );
        return;
      }
    }

    String requestId = const Uuid().v4();
    try {
      final String body = await utf8.decoder.bind(request).join();
      bytesProcessed += body.length;
      final Map<String, dynamic> json = jsonDecode(body);

      final String model = json['model'] ?? 'deepseek-r1:7b';
      final List<dynamic> messagesJson = json['messages'] ?? [];
      final bool stream = json['stream'] ?? true;
      final bool useRag = json['rag'] ?? false;

      final List<Map<String, String>> messages = [];
      for (var msg in messagesJson) {
        messages.add({
          'role': msg['role'] as String? ?? 'user',
          'content': msg['content'] as String? ?? '',
        });
      }

      if (messages.isEmpty) {
        statusCode = HttpStatus.badRequest;
        response.statusCode = HttpStatus.badRequest;
        response.headers.contentType = ContentType.json;
        final errBody = jsonEncode({'error': 'Bad Request: Messages content is empty'});
        bytesProcessed += errBody.length;
        response.write(errBody);
        await response.close();
        return;
      }

      // Context Injection via local RAG matches
      if (useRag && messages.last['role'] == 'user') {
        final lastUserMessage = messages.last['content'] ?? '';
        final chunks = await _ragIndexer.retrieveRelevantChunks(lastUserMessage, limit: 3);
        if (chunks.isNotEmpty) {
          String contextPayload = 'Injected Offline Knowledge Base Context:\n';
          for (var chunk in chunks) {
            contextPayload += 'Chunk Match: $chunk\n';
          }
          contextPayload += '\nUser Query: $lastUserMessage';
          messages.last['content'] = contextPayload;
        }
      }

      // Register request to network monitor list
      final activeReq = ActiveRequestInfo(
        id: requestId,
        clientIp: clientIp,
        model: model,
        requestedAt: DateTime.now(),
      );

      _activeRequests.add(activeReq);
      _requestsController.add(List.from(_activeRequests));

      // Route request directly to the singleton QueueManager
      final responseStream = _queueManager.enqueueChat(
        id: requestId,
        baseUrl: _ollamaUrl,
        model: model,
        messages: messages,
      );

      if (stream) {
        response.headers.contentType = ContentType('application', 'x-ndjson', charset: 'utf-8');
        response.headers.chunkedTransferEncoding = true;

        await for (final token in responseStream) {
          final chunk = jsonEncode({
            'model': model,
            'created_at': DateTime.now().toIso8601String(),
            'message': {'role': 'assistant', 'content': token},
            'done': false
          });
          bytesProcessed += chunk.length;
          response.write('$chunk\n');
        }

        // Emit final chunk
        final finalChunk = jsonEncode({
          'model': model,
          'created_at': DateTime.now().toIso8601String(),
          'done': true
        });
        bytesProcessed += finalChunk.length;
        response.write('$finalChunk\n');
      } else {
        response.headers.contentType = ContentType.json;
        final List<String> textBuffer = [];
        await for (final token in responseStream) {
          textBuffer.add(token);
        }
        
        final responseText = jsonEncode({
          'model': model,
          'created_at': DateTime.now().toIso8601String(),
          'message': {'role': 'assistant', 'content': textBuffer.join()},
          'done': true
        });
        bytesProcessed += responseText.length;
        response.write(responseText);
      }
    } catch (e) {
      statusCode = HttpStatus.internalServerError;
      response.statusCode = HttpStatus.internalServerError;
      response.headers.contentType = ContentType.json;
      final errorResponse = jsonEncode({'error': 'Local API execution failure: $e'});
      bytesProcessed += errorResponse.length;
      response.write(errorResponse);
    } finally {
      // Remove request from network monitor list
      _activeRequests.removeWhere((r) => r.id == requestId);
      _requestsController.add(List.from(_activeRequests));
      await response.close();

      // Log database network access request history
      await _dbService.insertAccessLog(
        clientIp: clientIp,
        endpoint: '/api/chat',
        bytesProcessed: bytesProcessed,
        statusCode: statusCode,
        authenticated: authenticated,
      );
    }
  }

  Future<void> _handleLocalRagRequest(HttpRequest request, String? apiKey) async {
    final response = request.response;
    final clientIp = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
    int statusCode = HttpStatus.ok;
    int bytesProcessed = 0;
    bool authenticated = true;

    // Secure token verification
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      final authHeader = request.headers.value('Authorization') ?? '';
      final customHeader = request.headers.value('X-OSLAH-Key') ?? '';
      final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;

      if (token != apiKey && customHeader != apiKey) {
        statusCode = HttpStatus.unauthorized;
        authenticated = false;
        response.statusCode = HttpStatus.unauthorized;
        response.headers.contentType = ContentType.json;
        final errBody = jsonEncode({'error': 'Unauthorized: Invalid OSLAH API Key'});
        bytesProcessed += errBody.length;
        response.write(errBody);
        await response.close();

        await _dbService.insertAccessLog(
          clientIp: clientIp,
          endpoint: '/api/local-rag',
          bytesProcessed: bytesProcessed,
          statusCode: statusCode,
          authenticated: authenticated,
        );
        return;
      }
    }

    String requestId = const Uuid().v4();
    try {
      final String body = await utf8.decoder.bind(request).join();
      bytesProcessed += body.length;
      final Map<String, dynamic> json = jsonDecode(body);

      final String? query = json['query'];
      final String? documentFilter = json['documentFilter'];
      final String model = json['model'] ?? 'deepseek-r1:7b';

      if (query == null || query.trim().isEmpty) {
        statusCode = HttpStatus.badRequest;
        response.statusCode = HttpStatus.badRequest;
        response.headers.contentType = ContentType.json;
        final errBody = jsonEncode({'error': 'Bad Request: "query" parameter is required and cannot be empty'});
        bytesProcessed += errBody.length;
        response.write(errBody);
        await response.close();
        return;
      }

      // Query similar chunks from our memory vector DocumentProcessor
      final DocumentProcessor docProcessor = DocumentProcessor();
      final chunks = docProcessor.retrieveSimilarChunks(query, limit: 3);

      // Apply optional documentFilter if provided
      final filteredChunks = chunks.where((chunk) {
        if (documentFilter != null && documentFilter.trim().isNotEmpty) {
          return chunk.documentId.toLowerCase().contains(documentFilter.trim().toLowerCase());
        }
        return true;
      }).toList();

      final allContextChunks = filteredChunks.map((c) => c.textContent).toList();

      // Register request to network monitor list
      final activeReq = ActiveRequestInfo(
        id: requestId,
        clientIp: clientIp,
        model: model,
        requestedAt: DateTime.now(),
      );

      _activeRequests.add(activeReq);
      _requestsController.add(List.from(_activeRequests));

      // Route request directly to the singleton QueueManager
      final responseStream = _queueManager.enqueueChat(
        id: requestId,
        baseUrl: _ollamaUrl,
        model: model,
        messages: [
          {'role': 'user', 'content': query}
        ],
        documentContext: allContextChunks,
      );

      // Collect streamed tokens into a single joined response string (non-streaming RAG API)
      final List<String> textBuffer = [];
      await for (final token in responseStream) {
        textBuffer.add(token);
      }
      final answer = textBuffer.join();

      response.headers.contentType = ContentType.json;
      final responseText = jsonEncode({
        'answer': answer,
        'sources': filteredChunks.map((c) => {
          'document': c.documentId,
          'chunkId': c.id,
        }).toList(),
      });
      bytesProcessed += responseText.length;
      response.write(responseText);
    } catch (e) {
      statusCode = HttpStatus.internalServerError;
      response.statusCode = HttpStatus.internalServerError;
      response.headers.contentType = ContentType.json;
      final errorResponse = jsonEncode({'error': 'Local RAG API execution failure: $e'});
      bytesProcessed += errorResponse.length;
      response.write(errorResponse);
    } finally {
      // Remove request from network monitor list
      _activeRequests.removeWhere((r) => r.id == requestId);
      _requestsController.add(List.from(_activeRequests));
      await response.close();

      // Log database network access request history
      await _dbService.insertAccessLog(
        clientIp: clientIp,
        endpoint: '/api/local-rag',
        bytesProcessed: bytesProcessed,
        statusCode: statusCode,
        authenticated: authenticated,
      );
    }
  }

  void dispose() {
    stop();
    _requestsController.close();
  }
}
