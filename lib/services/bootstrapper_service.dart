import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import 'model_downloader_service.dart';

enum BootstrapperStatus {
  idle,
  checking,
  downloadingInstaller,
  installing,
  startingOllama,
  pullingModel,
  completed,
  failed,
}

class BootstrapperProgress {
  final BootstrapperStatus status;
  final double progress; // 0.0 to 100.0
  final double speedMBs; // MB/s
  final String errorMessage;

  BootstrapperProgress({
    required this.status,
    required this.progress,
    required this.speedMBs,
    this.errorMessage = '',
  });

  factory BootstrapperProgress.idle() {
    return BootstrapperProgress(status: BootstrapperStatus.idle, progress: 0.0, speedMBs: 0.0);
  }
}

class BootstrapperService {
  static final BootstrapperService _instance = BootstrapperService._internal();
  factory BootstrapperService() => _instance;
  BootstrapperService._internal();

  final _progressController = StreamController<BootstrapperProgress>.broadcast();
  Stream<BootstrapperProgress> get progressStream => _progressController.stream;

  final DatabaseService _dbService = DatabaseService();
  final ModelDownloaderService _modelDownloader = ModelDownloaderService();

  bool _isBootstrapping = false;
  bool get isBootstrapping => _isBootstrapping;

  BootstrapperProgress _currentProgress = BootstrapperProgress.idle();
  BootstrapperProgress get currentProgress => _currentProgress;

  /// Starts the onboarding bootstrap flow.
  Future<void> bootstrap(String modelName) async {
    if (_isBootstrapping) return;
    _isBootstrapping = true;

    _updateProgress(BootstrapperStatus.checking, 0.0, 0.0);

    try {
      // 1. Check if Ollama is present
      bool hasOllama = await _checkOllamaPresence();

      if (!hasOllama) {
        // 2. Download Ollama installer
        _updateProgress(BootstrapperStatus.downloadingInstaller, 0.0, 0.0);
        final installerPath = await _downloadOllamaInstaller();

        // 3. Install Ollama silently
        _updateProgress(BootstrapperStatus.installing, 0.0, 0.0);
        await _installOllamaSilently(installerPath);
      }

      // 4. Start Ollama and verify it is running
      _updateProgress(BootstrapperStatus.startingOllama, 0.0, 0.0);
      await _verifyAndStartOllamaServer();

      // 5. Pull selected model
      _updateProgress(BootstrapperStatus.pullingModel, 0.0, 0.0);
      await _pullModel(modelName);

      // 6. Complete Setup
      await _dbService.completeFirstLaunch();
      _updateProgress(BootstrapperStatus.completed, 100.0, 0.0);
    } catch (e) {
      _updateProgress(BootstrapperStatus.failed, 0.0, 0.0, errorMessage: e.toString());
    } finally {
      _isBootstrapping = false;
    }
  }

  void _updateProgress(BootstrapperStatus status, double progress, double speed, {String errorMessage = ''}) {
    _currentProgress = BootstrapperProgress(
      status: status,
      progress: progress,
      speedMBs: speed,
      errorMessage: errorMessage,
    );
    _progressController.add(_currentProgress);
  }

  /// Runs 'ollama --version' or checks default directories to detect presence
  Future<bool> _checkOllamaPresence() async {
    try {
      final result = await Process.run('ollama', ['--version'], runInShell: true);
      if (result.exitCode == 0) return true;
    } catch (_) {
      // Fallback check standard installation folders on Windows
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        final localPath = p.join(userProfile, 'AppData', 'Local', 'Programs', 'Ollama', 'ollama.exe');
        if (await File(localPath).exists()) {
          return true;
        }
      }
    }
    return false;
  }

  /// Downloads OllamaSetup.exe from the official registry
  Future<String> _downloadOllamaInstaller() async {
    final client = HttpClient();
    final url = Uri.parse('https://ollama.com/download/OllamaSetup.exe');
    
    final tempDir = await getTemporaryDirectory();
    final installerPath = p.join(tempDir.path, 'OllamaSetup.exe');
    final file = File(installerPath);

    final request = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Ollama download server returned status: ${response.statusCode}');
    }

    final totalBytes = response.contentLength;
    int completedBytes = 0;
    final startTime = DateTime.now();

    final sink = file.openWrite();
    
    await for (final List<int> chunk in response) {
      sink.add(chunk);
      completedBytes += chunk.length;

      double progress = 0.0;
      if (totalBytes > 0) {
        progress = (completedBytes / totalBytes) * 100.0;
      }

      final seconds = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      double speed = 0.0;
      if (seconds > 0.1 && completedBytes > 0) {
        speed = (completedBytes / (1024 * 1024)) / seconds;
      }

      _updateProgress(BootstrapperStatus.downloadingInstaller, progress, speed);
    }

    await sink.flush();
    await sink.close();
    client.close();
    
    return installerPath;
  }

  /// Runs the Windows Ollama installer in silent mode
  Future<void> _installOllamaSilently(String installerPath) async {
    if (!Platform.isWindows) {
      // For macOS/Linux mock successful install execution
      await Future.delayed(const Duration(seconds: 3));
      return;
    }

    try {
      // Inno Setup installer silent flag
      final result = await Process.run(installerPath, ['/silent']);
      if (result.exitCode != 0) {
        throw Exception('Ollama installer exited with code: ${result.exitCode}');
      }
      // Wait a few seconds for registry changes to commit
      await Future.delayed(const Duration(seconds: 4));
    } catch (e) {
      throw Exception('Failed to run Ollama silent installer: $e');
    }
  }

  /// Polls server tag endpoint, attempting to start 'ollama serve' if down
  Future<void> _verifyAndStartOllamaServer() async {
    final client = HttpClient();
    final url = Uri.parse('http://localhost:11434/api/tags');
    
    int attempts = 0;
    bool isServerRunning = false;

    // Try verifying connection
    while (attempts < 15) {
      try {
        final request = await client.getUrl(url).timeout(const Duration(seconds: 2));
        final response = await request.close();
        if (response.statusCode == 200) {
          isServerRunning = true;
          break;
        }
      } catch (_) {
        if (attempts == 0) {
          // If first connection attempt failed, try starting the background daemon process
          try {
            if (Platform.isWindows) {
              final userProfile = Platform.environment['USERPROFILE'] ?? '';
              final localExec = p.join(userProfile, 'AppData', 'Local', 'Programs', 'Ollama', 'ollama.exe');
              if (await File(localExec).exists()) {
                await Process.start(localExec, ['serve'], runInShell: true);
              } else {
                await Process.start('ollama', ['serve'], runInShell: true);
              }
            } else {
              await Process.start('ollama', ['serve'], runInShell: true);
            }
          } catch (e) {
            debugPrint('Failed to start Ollama serve background process: $e');
          }
        }
      }
      attempts++;
      await Future.delayed(const Duration(seconds: 2));
    }

    client.close();
    if (!isServerRunning) {
      throw Exception('Unable to bind or connect to Ollama local server instance on port 11434.');
    }
  }

  /// Stream connects to pull selected model
  Future<void> _pullModel(String modelName) async {
    final downloaderSub = _modelDownloader.statusStream.listen((event) {
      if (event.status == 'error') {
        // Handled below
      } else {
        _updateProgress(
          BootstrapperStatus.pullingModel,
          event.progress,
          event.speedMBs,
        );
      }
    });

    try {
      await _modelDownloader.downloadModel('http://localhost:11434', modelName);
      final finalEvent = _modelDownloader.currentEvent;
      if (finalEvent.status == 'error') {
        throw Exception(finalEvent.error);
      }
    } finally {
      await downloaderSub.cancel();
    }
  }

  void dispose() {
    _progressController.close();
  }
}
