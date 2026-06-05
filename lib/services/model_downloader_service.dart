import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DownloadStatusEvent {
  final String modelName;
  final String status; // 'idle', 'connecting', 'downloading', 'verifying', 'success', 'error'
  final double progress; // 0.0 to 100.0
  final double speedMBs; // MB/s
  final String error;

  DownloadStatusEvent({
    required this.modelName,
    required this.status,
    required this.progress,
    required this.speedMBs,
    this.error = '',
  });

  factory DownloadStatusEvent.idle() {
    return DownloadStatusEvent(modelName: '', status: 'idle', progress: 0.0, speedMBs: 0.0);
  }
}

class ModelDownloaderService {
  static final ModelDownloaderService _instance = ModelDownloaderService._internal();
  factory ModelDownloaderService() => _instance;
  ModelDownloaderService._internal();

  final _statusController = StreamController<DownloadStatusEvent>.broadcast();
  Stream<DownloadStatusEvent> get statusStream => _statusController.stream;

  HttpClient? _client;
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  DownloadStatusEvent _currentEvent = DownloadStatusEvent.idle();
  DownloadStatusEvent get currentEvent => _currentEvent;

  /// Starts downloading the specified model from Ollama.
  Future<void> downloadModel(String baseUrl, String modelName) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _currentEvent = DownloadStatusEvent(
      modelName: modelName,
      status: 'connecting',
      progress: 0.0,
      speedMBs: 0.0,
    );
    _statusController.add(_currentEvent);

    try {
      _client = HttpClient();
      final uri = Uri.parse('$baseUrl/api/pull');
      final request = await _client!.postUrl(uri);
      request.headers.contentType = ContentType.json;
      
      final payload = jsonEncode({'name': modelName});
      request.write(payload);
      
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('Ollama returned status code ${response.statusCode}');
      }

      final startTime = DateTime.now();
      
      await for (final String line in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          final data = jsonDecode(line);
          final status = data['status'] as String? ?? 'downloading';
          
          if (status.contains('success')) {
            _currentEvent = DownloadStatusEvent(
              modelName: modelName,
              status: 'success',
              progress: 100.0,
              speedMBs: 0.0,
            );
            _statusController.add(_currentEvent);
            break;
          }

          final completed = data['completed'] as int? ?? 0;
          final total = data['total'] as int? ?? 0;

          double progress = 0.0;
          if (total > 0) {
            progress = (completed / total) * 100.0;
          }

          final seconds = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
          double speed = 0.0;
          if (seconds > 0.1 && completed > 0) {
            speed = (completed / (1024 * 1024)) / seconds;
          }

          _currentEvent = DownloadStatusEvent(
            modelName: status.startsWith('downloading') ? modelName : '',
            status: status,
            progress: progress,
            speedMBs: speed,
          );
          _statusController.add(_currentEvent);
        } catch (e) {
          // Silent parse error for single line chunks
        }
      }
    } catch (e) {
      _currentEvent = DownloadStatusEvent(
        modelName: modelName,
        status: 'error',
        progress: 0.0,
        speedMBs: 0.0,
        error: e.toString(),
      );
      _statusController.add(_currentEvent);
    } finally {
      _isDownloading = false;
      _client?.close();
      _client = null;
    }
  }

  /// Cancels the current download task.
  void cancelDownload() {
    if (!_isDownloading) return;
    _client?.close(force: true);
    _client = null;
    _isDownloading = false;
    _currentEvent = DownloadStatusEvent.idle();
    _statusController.add(_currentEvent);
  }

  void dispose() {
    _statusController.close();
  }
}
