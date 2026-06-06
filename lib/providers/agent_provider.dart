import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/rag/document_processor.dart';
import '../services/ollama_service.dart';
import '../services/queue_manager.dart';
import '../services/database_service.dart';
import '../services/local_server_service.dart';
import '../services/rag_indexer_service.dart';
import '../services/agent_manager_service.dart';
import '../services/model_downloader_service.dart';
import '../premium/license_verifier.dart';

class Message {
  final String id;
  final String sender; // 'user' | 'assistant' | 'system'
  final String text;
  final DateTime timestamp;
  final bool isStreaming;

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isStreaming = false,
  });
}

class KnowledgeDocument {
  final String id;
  final String name;
  final String content;
  final int sizeBytes;
  final DateTime addedAt;

  KnowledgeDocument({
    required this.id,
    required this.name,
    required this.content,
    required this.sizeBytes,
    required this.addedAt,
  });
}

class AgentProvider extends ChangeNotifier {
  final OllamaService _ollamaService = OllamaService();
  final QueueManager _queueManager = QueueManager();
  final DatabaseService _dbService = DatabaseService();
  final RagIndexerService _ragIndexer = RagIndexerService();
  final LocalServerService _serverService = LocalServerService();
  final AgentManagerService _agentManager = AgentManagerService();
  final ModelDownloaderService _downloaderService = ModelDownloaderService();
  final Uuid _uuid = const Uuid();
  Timer? _metricsTimer;

  // App Navigation
  String _activeTab = 'chat'; // 'chat' | 'agentBuilder' | 'settings' | 'server' | 'metrics' | 'logs'
  String get activeTab => _activeTab;

  // Ollama Config & Models State
  String _ollamaUrl = 'http://localhost:11434';
  String get ollamaUrl => _ollamaUrl;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  List<String> _availableModels = [];
  List<String> get availableModels => _availableModels;

  String? _selectedModel;
  String? get selectedModel => _selectedModel;

  bool _isLoadingModels = false;
  bool get isLoadingModels => _isLoadingModels;

  String? _connectionError;
  String? get connectionError => _connectionError;

  // Chat History
  final List<Message> _messages = [];
  List<Message> get messages => _messages;

  // Knowledge Base Documents
  final List<KnowledgeDocument> _documents = [];
  List<KnowledgeDocument> get documents => _documents;

  // Queue Status State
  int _queueLength = 0;
  int get queueLength => _queueLength;

  bool _isQueueProcessing = false;
  bool get isQueueProcessing => _isQueueProcessing;

  // Mock Hardware Metrics
  double _cpuUsage = 4.2;
  double get cpuUsage => _cpuUsage;

  double _ramUsage = 32.5;
  double get ramUsage => _ramUsage;

  double _gpuUsage = 0.0;
  double get gpuUsage => _gpuUsage;

  // Custom Agents State
  bool _isFirstLaunch = true;
  bool get isFirstLaunch => _isFirstLaunch;

  List<CustomAgent> _customAgents = [];
  List<CustomAgent> get customAgents => _customAgents;

  CustomAgent? _activeAgent;
  CustomAgent? get activeAgent => _activeAgent;

  // Access Logs State
  List<Map<String, dynamic>> _accessLogs = [];
  List<Map<String, dynamic>> get accessLogs => _accessLogs;

  // Model Downloader State Getters
  bool get isModelDownloading => _downloaderService.isDownloading;
  DownloadStatusEvent get activeDownloadEvent => _downloaderService.currentEvent;

  // Agent Configurations (Agent Builder Tab - Local UI defaults)
  String _agentName = 'OSLAH Core';
  String get agentName => _agentName;

  String _systemPrompt = 'You are OSLAH, a local AI assistant. Help the user solve tasks step by step. Use clear formatting, markdown tables, and code snippets when needed.';
  String get systemPrompt => _systemPrompt;

  double _temperature = 0.7;
  double get temperature => _temperature;

  // Local Server Configuration & Dynamic State
  bool _isServerRunning = false;
  bool get isServerRunning => _isServerRunning;

  String _serverHost = '0.0.0.0';
  String get serverHost => _serverHost;

  int _serverPort = 8080;
  int get serverPort => _serverPort;

  String _serverApiKey = '';
  String get serverApiKey => _serverApiKey;

  String _localIpAddress = '127.0.0.1';
  String get localIpAddress => _localIpAddress;

  List<ActiveRequestInfo> _activeServerRequests = [];
  List<ActiveRequestInfo> get activeServerRequests => _activeServerRequests;

  StreamSubscription<List<ActiveRequestInfo>>? _serverTrafficSubscription;

  AgentProvider() {
    _startMetricsTimer();
    _listenToQueueStatus();
    _loadDatabaseSettings();
    refreshModels();
    loadAgents();
    fetchAccessLogs();
    _downloaderService.statusStream.listen((event) {
      if (event.status == 'success') {
        refreshModels();
      }
      notifyListeners();
    });
  }

  void setActiveTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void setOllamaUrl(String url) {
    if (_ollamaUrl == url) return;
    _ollamaUrl = url;
    notifyListeners();
  }

  void setSelectedModel(String? model) {
    _selectedModel = model;
    notifyListeners();
  }

  void updateAgentConfig({
    required String name,
    required String systemPrompt,
    required double temperature,
  }) {
    _agentName = name;
    _systemPrompt = systemPrompt;
    _temperature = temperature;
    notifyListeners();
  }

  /// Refreshes model tags from local Ollama instance.
  Future<void> refreshModels() async {
    _isLoadingModels = true;
    _connectionError = null;
    notifyListeners();

    try {
      final models = await _ollamaService.fetchModels(_ollamaUrl);
      _availableModels = models;
      _isConnected = true;
      if (models.isNotEmpty) {
        // Retain selection if available, else select the first model
        if (!_availableModels.contains(_selectedModel)) {
          _selectedModel = _availableModels.first;
        }
      } else {
        _selectedModel = null;
      }
    } catch (e) {
      _isConnected = false;
      _availableModels = ['deepseek-r1:7b', 'llama3:latest', 'mistral:latest'];
      _selectedModel = _availableModels.first;
      _connectionError = e.toString();
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  /// Processes text extraction from uploaded local files
  Future<void> pickKnowledgeFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'json', 'csv', 'py', 'dart', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        for (var platformFile in result.files) {
          String textContent = '';
          int sizeBytes = platformFile.size;

          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              if (platformFile.extension == 'pdf') {
                // Mock text extraction since parsing PDF binary requires heavy external packages
                textContent = '[EXTRACTED PDF CONTENT: ${platformFile.name}]\n'
                    'Size: ${(sizeBytes / 1024).toStringAsFixed(1)} KB\n'
                    'System Metadata: Local File Reference Indexing Completed.\n'
                    'Content Outline: Local knowledge base ingestion for offline semantic lookup.';
              } else {
                try {
                  textContent = await file.readAsString();
                } catch (e) {
                  textContent = 'Error reading file content: $e';
                }
              }
            }
          } else if (platformFile.bytes != null) {
            textContent = String.fromCharCodes(platformFile.bytes!);
          }

          final doc = KnowledgeDocument(
            id: _uuid.v4(),
            name: platformFile.name,
            content: textContent,
            sizeBytes: sizeBytes,
            addedAt: DateTime.now(),
          );

          _documents.add(doc);
          
          // Phase 2: Slice document into chunks and index inside SQLite
          await _ragIndexer.indexFile(platformFile.name, textContent);

          // Phase 3: Also index using memory DocumentProcessor if .txt or .md and path is not null
          if (platformFile.path != null) {
            final ext = platformFile.name.split('.').last.toLowerCase();
            if (ext == 'txt' || ext == 'md') {
              try {
                await DocumentProcessor().processFile(platformFile.path!);
              } catch (e) {
                debugPrint('DocumentProcessor index file error: $e');
              }
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  /// Removes a document from the active Knowledge Base context.
  void removeDocument(String id) {
    final idx = _documents.indexWhere((doc) => doc.id == id);
    if (idx != -1) {
      final docName = _documents[idx].name;
      _dbService.deleteChunksByFileName(docName);
      _documents.removeAt(idx);
      notifyListeners();
    }
  }

  /// Clears all files in the Knowledge Base context.
  void clearDocuments() {
    _documents.clear();
    _dbService.clearAllChunks();
    notifyListeners();
  }

  /// Clears active chat logs.
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  /// Sends a message into the thread-safe sequential QueueManager.
  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Active clock tamper check during inference loop
    await LicenseVerifier().checkClockTamper();
    if (LicenseVerifier.currentState == LicenseState.tampered) {
      final userMsg = Message(
        id: _uuid.v4(),
        sender: 'user',
        text: text,
        timestamp: DateTime.now(),
      );
      _messages.add(userMsg);
      final errorMsg = Message(
        id: _uuid.v4(),
        sender: 'assistant',
        text: '[CRITICAL SECURITY VIOLATION]: System clock tampering detected. Features are locked.',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMsg);
      notifyListeners();
      return;
    }

    // 1. User Message
    final userMsg = Message(
      id: _uuid.v4(),
      sender: 'user',
      text: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // 2. Assistant streaming placeholder message
    final assistantMsgId = _uuid.v4();
    final assistantMsg = Message(
      id: assistantMsgId,
      sender: 'assistant',
      text: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(assistantMsg);
    notifyListeners();

    // 3. Prepare payload with Injected Knowledge context
    final String fullUserPrompt = text;
    
    // Retrieve relevant matching chunks from SQLite RAG indexer and memory DocumentProcessor
    final dbChunks = await _ragIndexer.retrieveRelevantChunks(text, limit: 3);
    final memChunks = DocumentProcessor()
        .retrieveSimilarChunks(text, limit: 3)
        .map((c) => c.textContent)
        .toList();
    final allContextChunks = {...dbChunks, ...memChunks}.toList();

    final List<Map<String, String>> payload = [];

    // Add System Prompt profile
    payload.add({
      'role': 'system',
      'content': _activeAgent != null ? _activeAgent!.systemPrompt : _systemPrompt,
    });

    // Add conversation history (up to last 8 messages to prevent local token overflow)
    final historyOffset = max(0, _messages.length - 10);
    final history = _messages.sublist(historyOffset, _messages.length - 2);
    for (var msg in history) {
      if (msg.sender == 'user' || (msg.sender == 'assistant' && !msg.isStreaming)) {
        payload.add({
          'role': msg.sender == 'user' ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    }

    // Add active user query (with embedded document strings)
    payload.add({
      'role': 'user',
      'content': fullUserPrompt,
    });

    // 4. Enqueue in the Sequential Queue
    final responseStream = _queueManager.enqueueChat(
      id: assistantMsgId,
      baseUrl: _ollamaUrl,
      model: _selectedModel ?? 'deepseek-r1:7b',
      messages: payload,
      documentContext: allContextChunks,
    );

    // 5. Pipe streaming response to the UI state
    StreamSubscription<String>? subscription;
    subscription = responseStream.listen(
      (chunk) {
        final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (idx != -1) {
          _messages[idx] = Message(
            id: assistantMsgId,
            sender: 'assistant',
            text: '${_messages[idx].text}$chunk',
            timestamp: _messages[idx].timestamp,
            isStreaming: true,
          );
          notifyListeners();
        }
      },
      onError: (error) {
        final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (idx != -1) {
          _messages[idx] = Message(
            id: assistantMsgId,
            sender: 'assistant',
            text: '${_messages[idx].text}\n\n[Inference Error: $error]',
            timestamp: _messages[idx].timestamp,
            isStreaming: false,
          );
          notifyListeners();
        }
      },
      onDone: () {
        final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (idx != -1) {
          _messages[idx] = Message(
            id: assistantMsgId,
            sender: 'assistant',
            text: _messages[idx].text,
            timestamp: _messages[idx].timestamp,
            isStreaming: false, // Finished streaming
          );
          notifyListeners();
        }
        subscription?.cancel();
      },
      cancelOnError: true,
    );
  }

  /// Cancels an executing or queued request.
  void cancelGeneration(String messageId) {
    _queueManager.cancelTask(messageId);
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = Message(
        id: messageId,
        sender: 'assistant',
        text: '${_messages[idx].text}\n\n[Generation Terminated by User]',
        timestamp: _messages[idx].timestamp,
        isStreaming: false,
      );
      notifyListeners();
    }
  }

  /// Listens to QueueManager sequential status ticks
  void _listenToQueueStatus() {
    _queueManager.statusStream.listen((status) {
      _queueLength = status.queueLength;
      _isQueueProcessing = status.isProcessing;
      notifyListeners();
    });
  }

  /// Starts metrics tracker that responds to LLM activity triggers
  void _startMetricsTimer() {
    _metricsTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      final random = Random();
      if (_isQueueProcessing) {
        // Simulate local GPU/CPU running LLM weights
        _cpuUsage = 68.4 + random.nextDouble() * 18.0;
        _ramUsage = 72.8 + random.nextDouble() * 4.5;
        _gpuUsage = 82.3 + random.nextDouble() * 12.0;
      } else {
        // Idle state metrics
        _cpuUsage = 2.5 + random.nextDouble() * 4.5;
        _ramUsage = 31.2 + random.nextDouble() * 1.5;
        _gpuUsage = 0.5 + random.nextDouble() * 1.5;
      }
      notifyListeners();
    });
  }

  // --- Phase 2 Server Methods ---

  Future<void> _loadDatabaseSettings() async {
    // Clock tamper protection check on boot
    await LicenseVerifier().checkClockTamper();

    _isFirstLaunch = await _dbService.checkFirstLaunch();
    final settings = await _dbService.getNetworkSettings();
    _serverHost = settings['host'] ?? '0.0.0.0';
    _serverPort = settings['port'] ?? 8080;
    _localIpAddress = await _fetchLocalIp();

    final autoLaunch = (settings['server_status'] ?? 0) == 1;
    if (autoLaunch) {
      try {
        await startServer();
      } catch (e) {
        debugPrint('Auto-launch server failed: $e');
      }
    }
    
    _listenToServerTraffic();
    notifyListeners();
  }

  Future<String> _fetchLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get local IP: $e');
    }
    return '127.0.0.1';
  }

  Future<void> startServer() async {
    try {
      await _serverService.start(
        host: _serverHost,
        port: _serverPort,
        ollamaUrl: _ollamaUrl,
        apiKey: _serverApiKey,
      );
      _isServerRunning = true;
      await _dbService.updateNetworkSettings(_serverHost, _serverPort, 1);
      notifyListeners();
    } catch (e) {
      _isServerRunning = false;
      await _dbService.updateNetworkSettings(_serverHost, _serverPort, 0);
      rethrow;
    }
  }

  Future<void> stopServer() async {
    await _serverService.stop();
    _isServerRunning = false;
    await _dbService.updateNetworkSettings(_serverHost, _serverPort, 0);
    notifyListeners();
  }

  Future<void> toggleServer() async {
    if (_isServerRunning) {
      await stopServer();
    } else {
      await startServer();
    }
  }

  Future<void> updateServerConfig({
    required String host,
    required int port,
    required String apiKey,
  }) async {
    _serverHost = host;
    _serverPort = port;
    _serverApiKey = apiKey;
    await _dbService.updateNetworkSettings(host, port, _isServerRunning ? 1 : 0);
    notifyListeners();
  }

  void _listenToServerTraffic() {
    _serverTrafficSubscription?.cancel();
    _serverTrafficSubscription = _serverService.requestsStream.listen((requests) {
      _activeServerRequests = requests;
      fetchAccessLogs(); // Dynamic refresh logs list on network requests updates
      notifyListeners();
    });
  }

  // --- Phase 3 Custom Agent Manager Methods ---

  /// Loads custom agents from SQLite database. Pre-populates if empty.
  Future<void> loadAgents() async {
    _customAgents = await _agentManager.getAllAgents();
    if (_customAgents.isEmpty) {
      final smartEngineer = CustomAgent(
        id: 'smart_engineer',
        name: 'Smart Code Engineer',
        systemPrompt: 'You are a senior software architect and coding assistant. Write highly optimized, clean, and well-structured code. Suggest performance optimizations, security checks, and robust patterns. Focus on brevity and functional correctness.',
        icon: 'code',
        description: 'Elite programming and architecture companion.',
      );
      final creativeWriter = CustomAgent(
        id: 'creative_writer',
        name: 'Creative Content Writer',
        systemPrompt: 'You are an expert copywriter, creative author, and content strategist. Craft engaging narratives, headlines, emails, and articles. Use a natural, expressive, and persuasive tone tailored to human readers.',
        icon: 'edit',
        description: 'Professional copywriter and editor.',
      );
      await _agentManager.createAgent(smartEngineer);
      await _agentManager.createAgent(creativeWriter);
      _customAgents = await _agentManager.getAllAgents();
    }
    notifyListeners();
  }

  Future<void> createCustomAgent(CustomAgent agent) async {
    await _agentManager.createAgent(agent);
    await loadAgents();
  }

  Future<void> updateCustomAgent(CustomAgent agent) async {
    await _agentManager.updateAgent(agent);
    await loadAgents();
  }

  Future<void> deleteCustomAgent(String id) async {
    await _agentManager.deleteAgent(id);
    if (_activeAgent?.id == id) {
      _activeAgent = null;
    }
    await loadAgents();
  }

  void setActiveAgent(CustomAgent? agent) {
    _activeAgent = agent;
    notifyListeners();
  }

  void setFirstLaunchFinished() {
    _isFirstLaunch = false;
    notifyListeners();
  }

  // --- Phase 4 Model Downloader Methods ---

  /// Downloads a model via Ollama background HTTP client stream parsing
  Future<void> startModelDownload(String modelName) async {
    await _downloaderService.downloadModel(_ollamaUrl, modelName);
  }

  void cancelModelDownload() {
    _downloaderService.cancelDownload();
  }

  // --- Phase 5 Access Logs Methods ---

  Future<void> fetchAccessLogs() async {
    _accessLogs = await _dbService.queryAccessLogs();
    notifyListeners();
  }

  Future<void> clearAllAccessLogs() async {
    await _dbService.clearAccessLogs();
    await fetchAccessLogs();
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    _serverTrafficSubscription?.cancel();
    _serverService.dispose();
    _downloaderService.dispose();
    _queueManager.dispose();
    super.dispose();
  }
}
